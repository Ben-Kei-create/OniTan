import Foundation

struct Question: Identifiable, Codable {
    let id = UUID()
    let kanji: String
    var choices: [Choice]
    let answer: String
    let explain: String

    // Tell Codable to ignore the 'id' field when decoding/encoding from JSON
    enum CodingKeys: String, CodingKey {
        case kanji
        case choices
        case answer
        case explain
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        kanji = try container.decode(String.self, forKey: .kanji)
        // Decode as [String] and map to [Choice]
        let choiceStrings = try container.decode([String].self, forKey: .choices)
        choices = choiceStrings.map { Choice(text: $0) }
        answer = try container.decode(String.self, forKey: .answer)
        explain = try container.decode(String.self, forKey: .explain)
    }
    
    // Add a regular initializer for creating dummy questions
    init(kanji: String, answer: String, choices: [String], explain: String) {
        self.kanji = kanji
        self.answer = answer
        self.choices = choices.map { Choice(text: $0) }
        self.explain = explain
    }
}
