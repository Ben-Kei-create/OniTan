import Foundation

// MARK: - Passage Model
// Represents a text passage from a copyright-free book with embedded quiz targets.

struct Passage: Codable, Identifiable {
    let id: UUID
    let title: String          // e.g., "走れメロス（太宰治）"
    let source: String?        // e.g., "青空文庫"
    let text: String           // Full passage text
    let targets: [PassageTarget]

    private enum CodingKeys: String, CodingKey {
        case title, source, text, targets
    }

    init(id: UUID = UUID(), title: String, source: String? = nil, text: String, targets: [PassageTarget]) {
        self.id = id
        self.title = title
        self.source = source
        self.text = text
        self.targets = targets
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.title = try c.decode(String.self, forKey: .title)
        self.source = try c.decodeIfPresent(String.self, forKey: .source)
        self.text = try c.decode(String.self, forKey: .text)
        self.targets = try c.decode([PassageTarget].self, forKey: .targets)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(title, forKey: .title)
        try c.encodeIfPresent(source, forKey: .source)
        try c.encode(text, forKey: .text)
        try c.encode(targets, forKey: .targets)
    }
}

// MARK: - Passage Target

struct PassageTarget: Codable, Identifiable {
    let id: UUID
    let position: Int          // Character offset in passage text
    let length: Int            // Character length of the target word
    let reading: String        // Correct answer
    let choices: [String]      // Answer options (reading must be included)
    let explain: String        // Explanation shown after answering

    private enum CodingKeys: String, CodingKey {
        case position, length, reading, choices, explain
    }

    init(id: UUID = UUID(), position: Int, length: Int, reading: String, choices: [String], explain: String) {
        self.id = id
        self.position = position
        self.length = length
        self.reading = reading
        self.choices = choices
        self.explain = explain
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.position = try c.decode(Int.self, forKey: .position)
        self.length = try c.decode(Int.self, forKey: .length)
        self.reading = try c.decode(String.self, forKey: .reading)
        self.choices = try c.decode([String].self, forKey: .choices)
        self.explain = try c.decode(String.self, forKey: .explain)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(position, forKey: .position)
        try c.encode(length, forKey: .length)
        try c.encode(reading, forKey: .reading)
        try c.encode(choices, forKey: .choices)
        try c.encode(explain, forKey: .explain)
    }

    /// Extract the target word from the passage text.
    func targetWord(in text: String) -> String? {
        let chars = Array(text)
        guard position >= 0, position + length <= chars.count else { return nil }
        return String(chars[position..<position + length])
    }
}
