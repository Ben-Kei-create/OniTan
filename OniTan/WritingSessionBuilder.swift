import Foundation

enum WritingSessionBuilder {

    static func buildWritingStage(questions: [Question] = allQuestions) -> Stage {
        let filtered = questions.filter { $0.kind == .writing }
        return Stage(stage: -4, questions: filtered)
    }
}
