import Foundation

// MARK: - Passage Quiz Phase

enum PassagePhase: Equatable {
    case reading                        // User reading the passage before starting
    case answering                      // Target highlighted, choices shown
    case showingResult(correct: Bool, answer: String)  // Feedback per target
    case passageComplete                // All targets in current passage done
    case sessionComplete                // All passages done
}

// MARK: - Passage Session ViewModel

@MainActor
final class PassageSessionViewModel: ObservableObject {

    // MARK: Published State
    @Published private(set) var phase: PassagePhase = .reading
    @Published private(set) var passageIndex: Int = 0
    @Published private(set) var targetIndex: Int = 0
    @Published private(set) var lastAnswerResult: AnswerResult = .none
    @Published private(set) var consecutiveCorrect: Int = 0
    @Published private(set) var sessionXPGained: Int = 0
    @Published private(set) var totalCorrect: Int = 0
    @Published private(set) var totalAnswered: Int = 0
    @Published private(set) var completedTargetIndices: Set<Int> = []
    @Published var activeAlert: OniAlert? = nil

    // MARK: Read-only

    let passages: [Passage]
    let stageNumber: Int

    var currentPassage: Passage { passages[passageIndex] }
    var currentTarget: PassageTarget { currentPassage.targets[targetIndex] }
    var totalPassages: Int { passages.count }
    var targetsInCurrentPassage: Int { currentPassage.targets.count }
    var totalTargets: Int { passages.reduce(0) { $0 + $1.targets.count } }

    var progressFraction: Double {
        let total = totalTargets
        guard total > 0 else { return 0 }
        return Double(totalAnswered) / Double(total)
    }

    // MARK: Private

    private let statsRepo: StudyStatsRepository
    private let streakRepo: StreakRepository?
    private let xpRepo: GamificationRepository?
    private var sessionStartTime = Date()

    // MARK: - Init

    init(
        passages: [Passage],
        stageNumber: Int,
        statsRepo: StudyStatsRepository,
        streakRepo: StreakRepository? = nil,
        xpRepo: GamificationRepository? = nil
    ) {
        precondition(!passages.isEmpty, "PassageSessionViewModel: passages must not be empty")
        precondition(passages.allSatisfy { !$0.targets.isEmpty }, "PassageSessionViewModel: all passages must have targets")
        self.passages = passages
        self.stageNumber = stageNumber
        self.statsRepo = statsRepo
        self.streakRepo = streakRepo
        self.xpRepo = xpRepo
    }

    // MARK: - Actions

    /// Transition from reading phase to answering the first target.
    func startAnswering() {
        guard phase == .reading || phase == .passageComplete else { return }
        targetIndex = 0
        completedTargetIndices = []
        phase = .answering
    }

    /// Submit an answer for the current target.
    func answer(selected: String) {
        guard phase == .answering else { return }

        let target = currentTarget
        let targetWord = target.targetWord(in: currentPassage.text) ?? "?"
        let isCorrect = selected == target.reading

        // Record stats using the target word as the "kanji" identifier
        statsRepo.record(
            stageNumber: stageNumber,
            kanji: targetWord,
            wasCorrect: isCorrect,
            selectedAnswer: selected,
            correctAnswer: target.reading
        )

        totalAnswered += 1

        if isCorrect {
            lastAnswerResult = .correct
            consecutiveCorrect += 1
            totalCorrect += 1

            // XP
            let xpGained = xpRepo?.addXP(.correctAnswer) ?? 0
            sessionXPGained += xpGained

            if consecutiveCorrect > 0, consecutiveCorrect % 3 == 0 {
                let comboXP = xpRepo?.addXP(.comboBonus) ?? 0
                sessionXPGained += comboXP
            }

            streakRepo?.recordCorrectAnswer()
        } else {
            lastAnswerResult = .wrong
            consecutiveCorrect = 0
        }

        completedTargetIndices.insert(targetIndex)
        phase = .showingResult(correct: isCorrect, answer: target.reading)
    }

    /// Proceed after seeing a target result.
    func proceed() {
        guard case .showingResult = phase else { return }
        lastAnswerResult = .none

        let nextIdx = targetIndex + 1
        if nextIdx < currentPassage.targets.count {
            targetIndex = nextIdx
            phase = .answering
        } else {
            // All targets in this passage are done
            if passageIndex + 1 < passages.count {
                phase = .passageComplete
            } else {
                onSessionComplete()
            }
        }
    }

    /// Move to the next passage.
    func nextPassage() {
        guard phase == .passageComplete else { return }
        passageIndex += 1
        targetIndex = 0
        completedTargetIndices = []
        phase = .reading
    }

    func requestQuit() {
        if phase == .sessionComplete {
            activeAlert = nil
        } else {
            activeAlert = .quitConfirmation
        }
    }

    // MARK: - Private

    private func onSessionComplete() {
        let sessionXP = xpRepo?.addXP(.sessionComplete) ?? 0
        sessionXPGained += sessionXP

        let studyTime = Date().timeIntervalSince(sessionStartTime)
        streakRepo?.addStudyTime(studyTime)

        phase = .sessionComplete
    }
}
