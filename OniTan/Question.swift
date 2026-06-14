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

    /// Extracts the term's meaning (the line beginning with "意味:") from the explanation, if present.
    var termMeaning: String? {
        for line in explain.split(separator: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("意味:") || trimmed.hasPrefix("意味：") {
                return trimmed
                    .replacingOccurrences(of: "意味:", with: "")
                    .replacingOccurrences(of: "意味：", with: "")
                    .trimmingCharacters(in: .whitespaces)
            }
        }
        return nil
    }

    /// Single-kanji dictionary/catalog keys related to this question.
    ///
    /// `kanji` is kept as the legacy prompt/tracking field, but modern catalog
    /// surfaces should use this derived list so compounds, labels, and sentence
    /// prompts do not masquerade as standalone kanji entries.
    var catalogKanjiCharacters: [String] {
        var candidates: [String] = []

        func appendSingle(_ value: String?) {
            guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
                  value.isSingleKanjiCharacter else { return }
            candidates.append(value)
        }

        func appendCharacters(from value: String?) {
            guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
            candidates.append(contentsOf: value.kanjiCharacters)
        }

        switch kind {
        case .reading, .sentenceReading, .hyogaiReading:
            appendCharacters(from: payload?.targetKanji)
            appendCharacters(from: kanji)
        case .compoundReadingKun:
            appendSingle(payload?.targetKanjiInCompound)
            appendCharacters(from: payload?.targetCompound)
            appendCharacters(from: kanji)
        case .commonKanji:
            appendSingle(answer)
        case .errorCorrection:
            appendSingle(payload?.wrongKanji)
            appendSingle(payload?.correctKanji)
        case .yojijukugo:
            appendSingle(answer)
            appendCharacters(from: payload?.yoji?.replacingOccurrences(of: "□", with: ""))
        case .writing:
            appendCharacters(from: payload?.targetKanji)
            appendCharacters(from: answer)
            appendCharacters(from: kanji)
        default:
            appendSingle(kanji)
            appendSingle(answer)
        }

        var seen = Set<String>()
        return candidates.filter { candidate in
            seen.insert(candidate).inserted
        }
    }

    /// Single kanji that can be safely used for favorite actions.
    ///
    /// Some question kinds are word- or phrase-based, so they should contribute
    /// multiple catalog entries but should not pretend to have one favorite key.
    var favoriteKanjiCharacter: String? {
        func single(_ value: String?) -> String? {
            guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
                  value.isSingleKanjiCharacter else { return nil }
            return value
        }

        func onlyCatalogCharacter() -> String? {
            let characters = catalogKanjiCharacters
            return characters.count == 1 ? characters[0] : nil
        }

        switch kind {
        case .compoundReadingKun:
            return single(payload?.targetKanjiInCompound) ?? onlyCatalogCharacter()
        case .errorCorrection:
            return single(payload?.correctKanji)
        case .yojijukugo:
            return single(answer)
        case .reading, .sentenceReading, .hyogaiReading, .commonKanji:
            return single(payload?.targetKanji) ?? single(kanji) ?? single(answer) ?? onlyCatalogCharacter()
        case .writing:
            return single(payload?.targetKanji) ?? onlyCatalogCharacter()
        default:
            return single(kanji) ?? single(answer) ?? onlyCatalogCharacter()
        }
    }
}

extension String {
    var isSingleKanjiCharacter: Bool {
        guard count == 1, let firstScalar = unicodeScalars.first else { return false }
        return firstScalar.isCJKIdeograph
    }

    var containsKanjiCharacter: Bool {
        unicodeScalars.contains { $0.isCJKIdeograph }
    }

    var kanjiCharacters: [String] {
        map(String.init).filter(\.isSingleKanjiCharacter)
    }
}

private extension UnicodeScalar {
    var isCJKIdeograph: Bool {
        let scalarValue = Int(value)
        return (0x3400...0x4DBF).contains(scalarValue)
            || (0x4E00...0x9FFF).contains(scalarValue)
            || (0xF900...0xFAFF).contains(scalarValue)
            || (0x20000...0x2A6DF).contains(scalarValue)
            || (0x2A700...0x2B73F).contains(scalarValue)
            || (0x2B740...0x2B81F).contains(scalarValue)
            || (0x2B820...0x2CEAF).contains(scalarValue)
            || (0x2CEB0...0x2EBEF).contains(scalarValue)
            || (0x30000...0x3134F).contains(scalarValue)
    }
}
