import Foundation

struct Question: Identifiable, Codable {
    /// Not decoded from JSON — always generated locally so JSON files stay minimal.
    let id: UUID
    let kanji: String
    let choices: [String]
    let answer: String
    let explain: String

    // MARK: - Extended fields (all optional / defaulted — backward compatible)

    /// Question category. Defaults to `.reading` when absent from JSON.
    let kind: QuestionKind
    let tags: [String]?
    let difficulty: Int?
    /// Kind-specific supplementary metadata. Nil for all legacy questions.
    let payload: QuestionPayload?

    // MARK: - Memberwise init

    /// All new fields have safe defaults so existing call sites remain unchanged.
    init(
        kanji: String,
        choices: [String],
        answer: String,
        explain: String,
        kind: QuestionKind = .reading,
        tags: [String]? = nil,
        difficulty: Int? = nil,
        payload: QuestionPayload? = nil
    ) {
        self.id = UUID()
        self.kanji = kanji
        self.choices = choices
        self.answer = answer
        self.explain = explain
        self.kind = kind
        self.tags = tags
        self.difficulty = difficulty
        self.payload = payload
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case kanji, choices, answer
        case explain, explanation   // both accepted as input; "explain" written on output
        case kind, tags, difficulty, payload
        // `id` intentionally omitted — always generated locally
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id      = UUID()
        kanji   = try c.decode(String.self,   forKey: .kanji)
        choices = try c.decode([String].self,  forKey: .choices)
        answer  = try c.decode(String.self,   forKey: .answer)
        // Prefer "explanation" (new key); fall back to "explain" (legacy key).
        if let longForm = try c.decodeIfPresent(String.self, forKey: .explanation) {
            explain = longForm
        } else {
            explain = try c.decode(String.self, forKey: .explain)
        }
        kind       = (try c.decodeIfPresent(QuestionKind.self,    forKey: .kind)) ?? .reading
        tags       = try c.decodeIfPresent([String].self,         forKey: .tags)
        difficulty = try c.decodeIfPresent(Int.self,              forKey: .difficulty)
        payload    = try c.decodeIfPresent(QuestionPayload.self,  forKey: .payload)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(kanji,   forKey: .kanji)
        try c.encode(choices, forKey: .choices)
        try c.encode(answer,  forKey: .answer)
        try c.encode(explain, forKey: .explain)
        try c.encode(kind,    forKey: .kind)
        try c.encodeIfPresent(tags,       forKey: .tags)
        try c.encodeIfPresent(difficulty, forKey: .difficulty)
        try c.encodeIfPresent(payload,    forKey: .payload)
    }
}
