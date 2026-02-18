import Foundation

enum TodayAction {
    case review
    case gentle
}

struct PreparedSession {
    let action: TodayAction
    let questions: [Question]

    var count: Int { questions.count }
    var title: String { action == .review ? "Review" : "Gentle" }
}
