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
    @Published private(set) var passNumber: Int = 1       // which review pass we're on
    @Published var activeAlert: OniAlert? = nil

    // MARK: Read-only

    let stage: Stage
    let mode: QuizMode
    let clearTitle: String

    /// Total distinct kanji in this session (may be < stage.questions.count in quick/exam modes).
    var totalGoal: Int { sessionQuestions.count }
    var stageNumber: Int { stage.stage }

    /// Remaining questions in current pass.
    var remainingCount: Int { pendingQueue.count + (phase == .answering ? 0 : 0) }

    /// Progress fraction (0.0 – 1.0) based on cleared kanji.
    var progressFraction: Double {
        guard totalGoal > 0 else { return 0 }
        return Double(clearedCount) / Double(totalGoal)
    }

    // MARK: Private

    private let appState: AppState
    private let statsRepo: StudyStatsRepository

    /// The resolved question list for this session (after mode filtering, shuffle, limit).
    private let sessionQuestions: [Question]

    /// Questions remaining in the current pass (answered wrong come back via reviewQueue).
    private var pendingQueue: [Question]

    /// Wrong answers accumulated in the current pass, to be retried next pass.
    private var reviewQueue: [Question] = []

    /// Kanji that have been answered correctly at least once.
    private var clearedKanji: Set<String> = []

    // MARK: - Init

    init(
        stage: Stage,
        appState: AppState,
        statsRepo: StudyStatsRepository,
        mode: QuizMode = .normal,
        clearTitle: String? = nil
    ) {
        self.stage = stage
        self.appState = appState
        self.statsRepo = statsRepo
        self.mode = mode
        self.clearTitle = clearTitle ?? Self.defaultClearTitle(for: mode, stageNumber: stage.stage)

        // Build the resolved question list using the mode's rules
        let weakKanji = Set(statsRepo.allWeakKanji(forStage: stage.stage))
        let resolved = mode.buildQuestionList(from: stage.questions, weakKanji: weakKanji)

        // Guard against empty question list (shouldn't happen with valid data)
        let safeResolved = resolved.isEmpty ? stage.questions : resolved
        self.sessionQuestions = safeResolved
        self.pendingQueue = safeResolved

        // Guaranteed safe: we ensured non-empty above
        self.currentQuestion = safeResolved[0]
    }

    // MARK: - Actions

    func answer(selected: String) {
        guard phase == .answering else { return }

        let question = currentQuestion
        let isCorrect = selected == question.answer

        statsRepo.record(stageNumber: stage.stage, kanji: question.kanji, wasCorrect: isCorrect)
        pendingQueue.removeFirst()

        if isCorrect {
            lastAnswerResult = .correct
            clearedKanji.insert(question.kanji)
            clearedCount = clearedKanji.count

            if clearedKanji.count >= totalGoal {
                // Only mark stage cleared in normal/weakFocus modes (not in exam/quick)
                if mode == .normal || mode == .weakFocus {
                    appState.markStageCleared(stage.stage)
                }
                phase = .stageCleared
                return
            }
            phase = .showingExplanation

        } else {
            lastAnswerResult = .wrong
            // Re-queue for review only in modes that use it
            if mode.usesReviewQueue, !reviewQueue.contains(where: { $0.kanji == question.kanji }) {
                reviewQueue.append(question)
            }
            phase = .showingWrongAnswer(correct: question.answer)
        }
    }

    /// Called after the user taps through an explanation or wrong-answer screen.
    func proceed() {
        guard phase != .answering, phase != .stageCleared else { return }
        lastAnswerResult = .none

        if pendingQueue.isEmpty {
            // Current pass finished — start review pass or declare clear
            if reviewQueue.isEmpty || !mode.usesReviewQueue {
                if mode == .normal || mode == .weakFocus {
                    appState.markStageCleared(stage.stage)
                }
                phase = .stageCleared
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

    /// Reset the session from the beginning.
    func resetGame() {
        let weakKanji = Set(statsRepo.allWeakKanji(forStage: stage.stage))
        let resolved = mode.buildQuestionList(from: stage.questions, weakKanji: weakKanji)
        let safe = resolved.isEmpty ? stage.questions : resolved
        pendingQueue = safe
        reviewQueue = []
        clearedKanji = []
        clearedCount = 0
        passNumber = 1
        lastAnswerResult = .none
        currentQuestion = safe[0]
        phase = .answering
    }

    func requestQuit() {
        if phase == .stageCleared {
            activeAlert = nil  // caller should dismiss view directly
        } else {
            activeAlert = .quitConfirmation
        }
    }

    // MARK: - Helpers

    private static func defaultClearTitle(for mode: QuizMode, stageNumber: Int) -> String {
        switch mode {
        case .quick10:   return "クイック完了！"
        case .exam30:    return "模試完了！"
        case .weakFocus: return "復習完了！"
        case .srsReview: return "SRS復習完了！"
        default:         return "ステージ \(stageNumber) クリア！"
        }
    }
}
