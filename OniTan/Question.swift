import Foundation

struct Question: Identifiable, Codable {
    let id = UUID()
    let kanji: String
    let choices: [String]
    let answer: String
    let explain: String

    // Tell Codable to ignore the 'id' field when decoding/encoding from JSON
    enum CodingKeys: String, CodingKey {
        case kanji
        case choices
        case answer
        case explain
    }

    // Custom initializer for Codable to add logging
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        kanji = try container.decode(String.self, forKey: .kanji)
        choices = try container.decode([String].self, forKey: .choices)
        answer = try container.decode(String.self, forKey: .answer)
        explain = try container.decode(String.self, forKey: .explain)

        // Add logging for the explain property
        print("Question decoded: kanji='\(kanji)', explain='\(explain)'")
    }
}
