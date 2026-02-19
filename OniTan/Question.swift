import Foundation

struct Question: Identifiable, Codable {
    let id: UUID
    let kanji: String
    let choices: [String]
    let answer: String
    let explain: String

    enum CodingKeys: String, CodingKey {
        case kanji, choices, answer, explain
    }

    init(kanji: String, choices: [String], answer: String, explain: String) {
        self.id = UUID()
        self.kanji = kanji
        self.choices = choices
        self.answer = answer
        self.explain = explain
    }
}
