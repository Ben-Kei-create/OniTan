import Foundation

struct QuizData: Codable {
    let stages: [Stage]
    let unused_questions: [Question]?
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
