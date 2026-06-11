import Foundation

struct Question: Identifiable, Codable {

    // MARK: - Core Fields

    /// Stable deterministic ID. Format: "{stage}-{index}-{kanji}-{answer}" when
    /// stamped at load time; "{kanji}-{answer}" fallback during JSON decode.
    let id: String

    /// Primary prompt character / word / sentence (for learning-record tracking).
    let kanji: String

    /// Explicit display override from JSON ("prompt" key). When absent, displayPrompt
    /// is derived from kind + payload (see computed property below).
    let rawPrompt: String?

    let choices: [String]
    let answer: String
    let explain: String

    // MARK: - Extended Fields (all backward-compatible defaults)

    let kind: QuestionKind
    let tags: [String]?
    let difficulty: Int?
    let payload: QuestionPayload?

    // MARK: - Computed

    /// What the quiz card displays as the question.
    /// Priority: rawPrompt → kind-specific payload → kanji
    var displayPrompt: String {
        if let r = rawPrompt, !r.isEmpty { return r }
        if let p = payload {
            switch kind {
            case .yojijukugo:
                if let y = p.yoji, !y.isEmpty { return y }
            case .errorCorrection:
                if let s = p.originalSentence, !s.isEmpty { return s }
            case .synonym, .antonym:
                if let w = p.targetWord, !w.isEmpty { return w }
            case .proverb:
                if let t = p.proverbText, !t.isEmpty { return t }
            case .commonKanji:
                if let terms = p.blankTerms, !terms.isEmpty {
                    return terms.joined(separator: " ／ ")
                }
            case .passageReading, .passageVocabulary:
                if let text = p.passageText, !text.isEmpty { return text }
            case .hyogaiReading:
                if let ctx = p.sentenceContext, !ctx.isEmpty { return ctx }
                if let w = p.targetWord, !w.isEmpty { return w }
            case .sentenceReading:
                if let ctx = p.sentenceContext, !ctx.isEmpty { return ctx }
                if let w = p.targetKanji, !w.isEmpty { return w }
            case .compoundReadingKun:
                if let c = p.targetCompound, !c.isEmpty { return c }
            default:
                break
            }
        }
        return kanji
    }

    /// True when the prompt is long-form text (sentence card layout).
    var isSentenceKind: Bool {
        switch kind {
        case .sentenceReading, .errorCorrection, .proverb,
             .passageReading, .passageVocabulary:
            return true
        default:
            return false
        }
    }

    // MARK: - Memberwise Init

    init(
        id: String = "",
        kanji: String,
        rawPrompt: String? = nil,
        choices: [String],
        answer: String,
        explain: String,
        kind: QuestionKind = .reading,
        tags: [String]? = nil,
        difficulty: Int? = nil,
        payload: QuestionPayload? = nil
    ) {
        self.id = id.isEmpty ? "\(kanji)-\(answer)" : id
        self.kanji = kanji
        self.rawPrompt = rawPrompt
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
        case id
        case kanji
        case prompt             // maps to rawPrompt
        case choices, answer
        case explain, explanation
        case kind, tags, difficulty, payload
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        kanji    = try c.decode(String.self,  forKey: .kanji)
        choices  = try c.decode([String].self, forKey: .choices)
        answer   = try c.decode(String.self,  forKey: .answer)
        if let longForm = try c.decodeIfPresent(String.self, forKey: .explanation) {
            explain = longForm
        } else {
            explain = try c.decode(String.self, forKey: .explain)
        }
        kind       = (try c.decodeIfPresent(QuestionKind.self,   forKey: .kind)) ?? .reading
        tags       = try c.decodeIfPresent([String].self,        forKey: .tags)
        difficulty = try c.decodeIfPresent(Int.self,             forKey: .difficulty)
        payload    = try c.decodeIfPresent(QuestionPayload.self, forKey: .payload)
        rawPrompt  = try c.decodeIfPresent(String.self,          forKey: .prompt)

        let explicit = try c.decodeIfPresent(String.self, forKey: .id)
        id = explicit ?? "\(kanji)-\(answer)"
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id,      forKey: .id)
        try c.encode(kanji,   forKey: .kanji)
        try c.encodeIfPresent(rawPrompt, forKey: .prompt)
        try c.encode(choices, forKey: .choices)
        try c.encode(answer,  forKey: .answer)
        try c.encode(explain, forKey: .explain)
        try c.encode(kind,    forKey: .kind)
        try c.encodeIfPresent(tags,       forKey: .tags)
        try c.encodeIfPresent(difficulty, forKey: .difficulty)
        try c.encodeIfPresent(payload,    forKey: .payload)
    }
}

// MARK: - Stamping

extension Question {
    /// Returns a copy of this question with a stage-prefixed deterministic ID.
    func stamped(stageNumber: Int, index: Int) -> Question {
        Question(
            id: "\(stageNumber)-\(index)-\(kanji)-\(answer)",
            kanji: kanji,
            rawPrompt: rawPrompt,
            choices: choices,
            answer: answer,
            explain: explain,
            kind: kind,
            tags: tags,
            difficulty: difficulty,
            payload: payload
        )
    }
}

// MARK: - Display Helpers

extension Question {
    var displayExplanation: String {
        explain
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("出典:") }
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
