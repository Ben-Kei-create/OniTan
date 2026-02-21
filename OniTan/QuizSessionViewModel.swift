import Foundation

// MARK: - Quiz Phase

enum QuizPhase: Equatable {
    case answering
    case showingExplanation
    case showingWrongAnswer(correct: String)
    case stageCleared
}

// MARK: - Answer Result (for animation feedback)

enum AnswerResult: Equatable {
    case correct
    case wrong
    case none
}

// MARK: - ViewModel

@MainActor
final class QuizSessionViewModel: ObservableObject {

    // MARK: Published State
    @Published private(set) var currentQuestion: Question
    @Published private(set) var clearedCount: Int = 0
    @Published private(set) var phase: QuizPhase = .answering
    @Published private(set) var lastAnswerResult: AnswerResult = .none
    @Published private(set) var passNumber: Int = 1
    @Published private(set) var consecutiveCorrect: Int = 0   // for combo display
    @Published private(set) var sessionXPGained: Int = 0      // shown in cleared screen
    @Published var activeAlert: OniAlert? = nil

    // MARK: Read-only

    let stage: Stage
    let mode: QuizMode
    let clearTitle: String

    /// Whether this is the cross-stage "今日の10問" session (stageNumber == 0).
    var isToday: Bool { stage.stage == 0 }

    /// Human-readable header shown in the quiz top bar.
    var displayTitle: String {
        isToday ? "今日の10問" : "ステージ \(stage.stage)"
    }

    var totalGoal: Int { sessionQuestions.count }
    var stageNumber: Int { stage.stage }
    var remainingCount: Int { pendingQueue.count }

    var progressFraction: Double {
        guard totalGoal > 0 else { return 0 }
        return Double(clearedCount) / Double(totalGoal)
    }

    // MARK: Private

    private let appState: AppState
    private let statsRepo: StudyStatsRepository
    private let streakRepo: StreakRepository?
    private let xpRepo: GamificationRepository?

    private let sessionQuestions: [Question]
    private var pendingQueue: [Question]
    private var reviewQueue: [Question] = []
    private var clearedKanji: Set<String> = []
    private var sessionStartTime = Date()

    // MARK: - Init

    init(
        stage: Stage,
        appState: AppState,
        statsRepo: StudyStatsRepository,
        streakRepo: StreakRepository? = nil,
        xpRepo: GamificationRepository? = nil,
        mode: QuizMode = .normal,
        clearTitle: String? = nil
    ) {
        self.stage = stage
        self.appState = appState
        self.statsRepo = statsRepo
        self.streakRepo = streakRepo
        self.xpRepo = xpRepo
        self.mode = mode
        self.clearTitle = clearTitle ?? Self.defaultClearTitle(for: mode, stageNumber: stage.stage)

        let weakKanji = Set(statsRepo.allWeakKanji(forStage: stage.stage))
        // For today-session (stage 0) the pool is pre-built; don't re-filter by mode
        let resolved: [Question]
        if stage.stage == 0 {
            resolved = stage.questions  // already curated by TodaySessionBuilder
        } else {
            resolved = mode.buildQuestionList(from: stage.questions, weakKanji: weakKanji)
        }

        let safeResolved = resolved.isEmpty ? stage.questions : resolved
        // safeResolved should never be empty when data loads correctly.
        // Guard here to surface the failure clearly rather than crash silently.
        guard let firstQuestion = safeResolved.first else {
            preconditionFailure("QuizSessionViewModel: question pool is empty for stage \(stage.stage). " +
                "Check that JSON data loaded successfully (see dataLoadError in HomeView).")
        }
        self.sessionQuestions = safeResolved
        self.pendingQueue = safeResolved
        self.currentQuestion = firstQuestion
    }

    // MARK: - Actions

    func answer(selected: String) {
        guard phase == .answering else { return }

        let question = currentQuestion
        let isCorrect = selected == question.answer

        statsRepo.record(
            stageNumber: stage.stage,
            kanji: question.kanji,
            wasCorrect: isCorrect,
            selectedAnswer: selected,
            correctAnswer: question.answer
        )
        pendingQueue.removeFirst()

        if isCorrect {
            lastAnswerResult = .correct
            consecutiveCorrect += 1
            clearedKanji.insert(question.kanji)
            clearedCount = clearedKanji.count

            // XP for correct answer
            let xpGained = xpRepo?.addXP(.correctAnswer) ?? 0
            sessionXPGained += xpGained

            // Combo bonus every 3 consecutive correct answers
            if consecutiveCorrect > 0, consecutiveCorrect % 3 == 0 {
                let comboXP = xpRepo?.addXP(.comboBonus) ?? 0
                sessionXPGained += comboXP
            }

            // Streak
            streakRepo?.recordCorrectAnswer()

            if clearedKanji.count >= totalGoal {
                onSessionCleared()
                return
            }
            phase = .showingExplanation

        } else {
            lastAnswerResult = .wrong
            consecutiveCorrect = 0

            if mode.usesReviewQueue, !reviewQueue.contains(where: { $0.kanji == question.kanji }) {
                reviewQueue.append(question)
            }
            phase = .showingWrongAnswer(correct: question.answer)
        }
    }

    func proceed() {
        guard phase != .answering, phase != .stageCleared else { return }
        lastAnswerResult = .none

        if pendingQueue.isEmpty {
            if reviewQueue.isEmpty || !mode.usesReviewQueue {
                onSessionCleared()
            } else {
                passNumber += 1
                pendingQueue = reviewQueue
                reviewQueue = []
                currentQuestion = pendingQueue[0]
                phase = .answering
            }
        } else {
            currentQuestion = pendingQueue[0]
            phase = .answering
        }
    }

    func resetGame() {
        let weakKanji = Set(statsRepo.allWeakKanji(forStage: stage.stage))
        let resolved: [Question]
        if stage.stage == 0 {
            resolved = stage.questions
        } else {
            resolved = mode.buildQuestionList(from: stage.questions, weakKanji: weakKanji)
        }
        let safe = resolved.isEmpty ? stage.questions : resolved
        pendingQueue = safe
        reviewQueue = []
        clearedKanji = []
        clearedCount = 0
        passNumber = 1
        lastAnswerResult = .none
        consecutiveCorrect = 0
        sessionXPGained = 0
        sessionStartTime = Date()
        currentQuestion = safe[0]
        phase = .answering
    }

    func requestQuit() {
        if phase == .stageCleared {
            activeAlert = nil
        } else {
            activeAlert = .quitConfirmation
        }
    }

    // MARK: - Private

    private func onSessionCleared() {
        // Mark stage cleared only for normal/weakFocus on real stages
        if !isToday, mode == .normal || mode == .weakFocus {
            appState.markStageCleared(stage.stage)
        }

        // Award session-complete XP
        let sessionXP = xpRepo?.addXP(.sessionComplete) ?? 0
        sessionXPGained += sessionXP

        // Record study time for streak
        let studyTime = Date().timeIntervalSince(sessionStartTime)
        streakRepo?.addStudyTime(studyTime)

        phase = .stageCleared
    }

    private static func defaultClearTitle(for mode: QuizMode, stageNumber: Int) -> String {
        if stageNumber == 0 { return "今日の10問 完了！" }
        switch mode {
        case .quick10:   return "クイック完了！"
        case .exam30:    return "模試完了！"
        case .weakFocus: return "復習完了！"
        case .srsReview: return "SRS復習完了！"
        default:         return "ステージ \(stageNumber) クリア！"
        }
    }
}
