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
    /// Choices for `currentQuestion`, shuffled once per question so the layout
    /// stays stable across re-renders (e.g. opening/closing the meaning sheet).
    @Published private(set) var currentChoices: [String] = []
    @Published private(set) var clearedCount: Int = 0
    @Published private(set) var phase: QuizPhase = .answering
    private var pendingSessionClear = false
    @Published private(set) var lastAnswerResult: AnswerResult = .none
    @Published private(set) var passNumber: Int = 1
    @Published private(set) var consecutiveCorrect: Int = 0   // for combo display
    @Published private(set) var sessionXPGained: Int = 0
    @Published var activeAlert: OniAlert? = nil
    @Published private(set) var examResult: ExamResult? = nil
    @Published private(set) var previousBestAccuracy: Double? = nil

    // MARK: Read-only

    let stage: Stage
    let mode: QuizMode
    let clearTitle: String
    let sessionTitle: String?

    /// Whether this is the cross-stage random 10-question session (stageNumber == 0).
    var isToday: Bool { stage.stage == 0 }
    var isSpecialSession: Bool { stage.stage <= 0 }

    /// Human-readable header shown in the quiz top bar.
    var displayTitle: String {
        if isToday {
            return sessionTitle ?? "ランダム10問"
        }
        if let sessionTitle {
            return sessionTitle
        }
        return "稽古 \(stage.stage)"
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
    private let masteryRepo: MasteryRepository?
    private let examResultRepo: ExamResultRepository?
    private let examBlueprintID: String?

    private let sessionQuestions: [Question]
    private var pendingQueue: [Question]
    private var reviewQueue: [Question] = []
    private var clearedKanji: Set<String> = []
    private var sessionStartTime = Date()
    private var sessionAnswers: [String: String] = [:]

    // MARK: - Init

    init(
        stage: Stage,
        appState: AppState,
        statsRepo: StudyStatsRepository,
        streakRepo: StreakRepository? = nil,
        xpRepo: GamificationRepository? = nil,
        masteryRepo: MasteryRepository? = nil,
        examResultRepo: ExamResultRepository? = nil,
        examBlueprintID: String? = nil,
        mode: QuizMode = .normal,
        clearTitle: String? = nil,
        sessionTitle: String? = nil
    ) {
        self.stage = stage
        self.appState = appState
        self.statsRepo = statsRepo
        self.streakRepo = streakRepo
        self.xpRepo = xpRepo
        self.masteryRepo = masteryRepo
        self.examResultRepo = examResultRepo
        self.examBlueprintID = examBlueprintID
        self.mode = mode
        self.sessionTitle = sessionTitle
        self.clearTitle = clearTitle ?? Self.defaultClearTitle(
            for: mode,
            stageNumber: stage.stage,
            sessionTitle: sessionTitle
        )

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
        self.currentChoices = Self.shuffledChoices(from: firstQuestion.choices, answer: firstQuestion.answer)
    }

    // MARK: - Actions

    func answer(selected: String) {
        guard phase == .answering else { return }

        let question = currentQuestion
        let isCorrect = selected == question.answer
        sessionAnswers[question.id] = selected

        statsRepo.record(
            stageNumber: stage.stage,
            kanji: question.kanji,
            questionID: question.id,
            questionKind: question.kind,
            wasCorrect: isCorrect,
            selectedAnswer: selected,
            correctAnswer: question.answer
        )
        if stage.stage == -3, isCorrect {
            statsRepo.removeFromWeakStock(question: question)
        }
        masteryRepo?.record(question: question, wasCorrect: isCorrect)
        pendingQueue.removeFirst()

        if isCorrect {
            lastAnswerResult = .correct
            consecutiveCorrect += 1
            clearedKanji.insert(question.kanji)

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

            if mode.usesReviewQueue {
                // normal/weakFocus: count unique mastered kanji
                clearedCount = clearedKanji.count
                if clearedKanji.count >= totalGoal {
                    pendingSessionClear = true
                }
            } else {
                // quick10/exam30: count total answered (correct + wrong)
                clearedCount += 1
                if pendingQueue.isEmpty {
                    pendingSessionClear = true
                }
            }
            phase = .showingExplanation

        } else {
            lastAnswerResult = .wrong
            consecutiveCorrect = 0

            if mode.usesReviewQueue, !reviewQueue.contains(where: { $0.kanji == question.kanji }) {
                reviewQueue.append(question)
            } else if !mode.usesReviewQueue {
                clearedCount += 1
            }
            phase = .showingWrongAnswer(correct: question.answer)
        }

        // Exam mode: withhold per-question feedback (real exam conditions) and
        // move straight to the next question; results are revealed all at once
        // afterward in ExamResultView. `phase` stays non-.answering briefly
        // (MainView keeps showing the choice grid) so a rapid double-tap
        // can't re-trigger `answer()` before we advance.
        if mode.deferredFeedback {
            lastAnswerResult = .none
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                self?.advanceToNextQuestion()
            }
        }
    }

    func proceed() {
        guard phase != .answering, phase != .stageCleared else { return }
        lastAnswerResult = .none
        advanceToNextQuestion()
    }

    private func advanceToNextQuestion() {
        if pendingSessionClear {
            pendingSessionClear = false
            onSessionCleared()
            return
        }

        if pendingQueue.isEmpty {
            if reviewQueue.isEmpty || !mode.usesReviewQueue {
                onSessionCleared()
            } else {
                passNumber += 1
                pendingQueue = reviewQueue
                reviewQueue = []
                currentQuestion = pendingQueue[0]
                currentChoices = Self.shuffledChoices(from: currentQuestion.choices, answer: currentQuestion.answer)
                phase = .answering
            }
        } else {
            currentQuestion = pendingQueue[0]
            currentChoices = Self.shuffledChoices(from: currentQuestion.choices, answer: currentQuestion.answer)
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
        guard let firstQuestion = safe.first else {
            preconditionFailure("QuizSessionViewModel.resetGame: question pool is empty for stage \(stage.stage).")
        }
        pendingQueue = safe
        reviewQueue = []
        clearedKanji = []
        clearedCount = 0
        passNumber = 1
        lastAnswerResult = .none
        consecutiveCorrect = 0
        sessionXPGained = 0
        pendingSessionClear = false
        sessionAnswers = [:]
        examResult = nil
        sessionStartTime = Date()
        currentQuestion = firstQuestion
        currentChoices = Self.shuffledChoices(from: firstQuestion.choices, answer: firstQuestion.answer)
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
        if !isSpecialSession, mode == .normal || mode == .weakFocus {
            appState.markStageCleared(stage.stage)
        }

        // Award session-complete XP
        let sessionXP = xpRepo?.addXP(.sessionComplete) ?? 0
        sessionXPGained += sessionXP

        // Record study time for streak
        let studyTime = Date().timeIntervalSince(sessionStartTime)
        streakRepo?.addStudyTime(studyTime)

        if let blueprintID = examBlueprintID,
           let blueprint = examBlueprints.first(where: { $0.id == blueprintID }) {
            let session = ExamSession(
                blueprint: blueprint,
                questions: sessionQuestions,
                startedAt: sessionStartTime
            )
            let result = ExamBuilder.score(session: session, answers: sessionAnswers)
            previousBestAccuracy = examResultRepo?.bestAccuracy(forBlueprintID: blueprintID)
            examResult = result
            examResultRepo?.save(result)

            // Celebrate unlocking the hidden 11th round when round 10 is
            // newly cleared at its 95% threshold.
            if blueprintID == ExamRound.blueprintID(for: 10),
               result.accuracy >= ExamRound.passThreshold(for: 10),
               (previousBestAccuracy ?? 0) < ExamRound.passThreshold(for: 10) {
                xpRepo?.addUnlockNotice("隠し第11回が解放されました！")
            }
        }

        phase = .stageCleared
    }

    /// Returns all choices (up to 4) in random order, ensuring the correct answer is included.
    private static func shuffledChoices(from choices: [String], answer: String) -> [String] {
        var pool = choices
        if !pool.contains(answer) { pool.append(answer) }
        return pool.shuffled()
    }

    private static func defaultClearTitle(for mode: QuizMode, stageNumber: Int, sessionTitle: String?) -> String {
        if stageNumber < 0 {
            return "\(sessionTitle ?? "復習") 完了！"
        }
        switch mode {
        case .quick10:   return "ランダム10問 完了！"
        case .exam30:    return "模試完了！"
        case .weakFocus: return "復習完了！"
        default:         return stageNumber == 0 ? "ランダム10問 完了！" : "稽古 \(stageNumber) 完了！"
        }
    }
}
