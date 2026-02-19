import Foundation

// MARK: - Quiz Phase

enum QuizPhase: Equatable {
    case answering
    case showingExplanation
    case showingWrongAnswer(correct: String)
    case stageCleared
}

// MARK: - ViewModel

@MainActor
final class QuizSessionViewModel: ObservableObject {

    // MARK: Published State
    @Published private(set) var currentQuestion: Question
    @Published private(set) var clearedCount: Int = 0
    @Published private(set) var phase: QuizPhase = .answering
    @Published var showingQuitAlert: Bool = false

    // MARK: Read-only
    let stage: Stage
    var totalGoal: Int { stage.questions.count }
    var stageNumber: Int { stage.stage }

    // MARK: Private
    private let appState: AppState
    private let statsRepo: StudyStatsRepository

    /// Questions remaining in the current pass (answered wrong come back via reviewQueue)
    private var pendingQueue: [Question]
    /// Wrong answers accumulated in the current pass, to be retried next pass
    private var reviewQueue: [Question] = []
    /// Kanji that have been answered correctly at least once
    private var clearedKanji: Set<String> = []

    // MARK: Init

    init(stage: Stage, appState: AppState, statsRepo: StudyStatsRepository) {
        self.stage = stage
        self.appState = appState
        self.statsRepo = statsRepo
        self.pendingQueue = stage.questions
        self.currentQuestion = stage.questions[0]
    }

    // MARK: - Actions

    func answer(selected: String) {
        guard phase == .answering else { return }

        let question = currentQuestion
        let isCorrect = selected == question.answer

        statsRepo.record(stageNumber: stage.stage, kanji: question.kanji, wasCorrect: isCorrect)
        pendingQueue.removeFirst()

        if isCorrect {
            clearedKanji.insert(question.kanji)
            clearedCount = clearedKanji.count

            if clearedKanji.count >= totalGoal {
                appState.markStageCleared(stage.stage)
                phase = .stageCleared
                return
            }
            phase = .showingExplanation
        } else {
            // Queue for review if not already queued
            if !reviewQueue.contains(where: { $0.kanji == question.kanji }) {
                reviewQueue.append(question)
            }
            phase = .showingWrongAnswer(correct: question.answer)
        }
    }

    /// Call after the user taps through an explanation or wrong-answer screen.
    func proceed() {
        guard phase != .answering, phase != .stageCleared else { return }

        if pendingQueue.isEmpty {
            // Current pass finished — start review pass or declare clear
            if reviewQueue.isEmpty {
                appState.markStageCleared(stage.stage)
                phase = .stageCleared
            } else {
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
        pendingQueue = stage.questions
        reviewQueue = []
        clearedKanji = []
        clearedCount = 0
        currentQuestion = stage.questions[0]
        phase = .answering
    }
}
