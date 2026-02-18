import Foundation

/// Today flow prepared session (pure value type)
struct PreparedSession {
    enum Action: String {
        case review
        case gentle
    }

    let action: Action
    let questions: [Question]

    var questionCount: Int { questions.count }
}
