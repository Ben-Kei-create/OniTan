import Foundation

struct Question: Identifiable, Codable {
    /// JSONには無いのでデコード対象外。アプリ側で生成する
    let id: UUID = UUID()

    let kanji: String
    let choices: [String]
    let answer: String
    let explain: String

    private enum CodingKeys: String, CodingKey {
        case kanji, choices, answer, explain
    }
}
