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
}
