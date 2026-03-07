import Foundation

struct QuizData: Codable {
    let stages: [Stage]
    let review_questions: [Question]?
    let unused_questions: [Question]?

    init(
        stages: [Stage],
        review_questions: [Question]? = nil,
        unused_questions: [Question]? = nil
    ) {
        self.stages = stages
        self.review_questions = review_questions
        self.unused_questions = unused_questions
    }
}

struct Stage: Codable {
    let stage: Int
    let questions: [Question]
}

// MARK: - Stage Manifest

/// stages.json のトップレベル
struct StageManifest: Codable {
    let stages: [StageEntry]
}

/// stages.json の各エントリ。問題ファイルへの参照と属性を持つ
struct StageEntry: Codable {
    let id: Int
    let file: String
    let title: String
    let difficulty: Int
}
