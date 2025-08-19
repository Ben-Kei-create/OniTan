
import Foundation

struct Choice: Identifiable, Codable, Hashable {
    let id = UUID()
    let text: String

    // Conform to Codable
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.text = try container.decode(String.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(text)
    }
    
    // Initializer for creating from a simple string
    init(text: String) {
        self.text = text
    }
}
