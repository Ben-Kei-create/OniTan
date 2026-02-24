import Foundation
import OSLog

private let kindLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "OniTan",
                                category: "QuestionModel")

// MARK: - QuestionKind

/// All question categories that appear in 漢字検定準1級 exams.
/// Unknown raw values map to `.unknown` so future kinds never crash the app.
enum QuestionKind: String, Codable, CaseIterable {
    case reading          // 読み（音読み・訓読み・熟字訓）
    case writing          // 書き取り（かな→漢字）
    case composition      // 熟語の構成（5分類）
    case yojijukugo       // 四字熟語
    case synonym          // 類義語
    case antonym          // 対義語
    case okurigana        // 送り仮名
    case errorcorrection  // 誤字訂正
    case cloze            // 文章穴埋め
    case usage            // 語彙用法
    case unknown          // catch-all for forward compatibility

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        if let matched = QuestionKind(rawValue: raw) {
            self = matched
        } else {
            kindLogger.warning("Unknown QuestionKind '\(raw, privacy: .public)' — mapped to .unknown")
            self = .unknown
        }
    }
}

extension QuestionKind {
    var examLabel: String {
        switch self {
        case .reading: return "読み"
        case .writing: return "書き取り"
        case .composition: return "熟語の構成"
        case .yojijukugo: return "四字熟語"
        case .synonym: return "類義語"
        case .antonym: return "対義語"
        case .okurigana: return "送り仮名"
        case .errorcorrection: return "誤字訂正"
        case .cloze: return "文章穴埋め"
        case .usage: return "語彙用法"
        case .unknown: return "総合"
        }
    }

    var promptText: String {
        switch self {
        case .reading: return "この漢字の読みを選びましょう"
        case .writing: return "かなに合う漢字を選びましょう"
        case .composition: return "熟語の構成タイプを選びましょう"
        case .yojijukugo: return "四字熟語の空欄を埋めましょう"
        case .synonym: return "最も近い意味を選びましょう"
        case .antonym: return "反対の意味を選びましょう"
        case .okurigana: return "正しい送り仮名を選びましょう"
        case .errorcorrection: return "誤字の正しい字を選びましょう"
        case .cloze: return "文脈に合う語を選びましょう"
        case .usage: return "使い方として適切な語を選びましょう"
        case .unknown: return "最適な選択肢を選びましょう"
        }
    }
}

extension QuestionKind {
    /// Whitelist for `QuestionPayload.structureType` when kind == .composition.
    /// Based on the standard 漢字検定 5-category classification:
    ///   synonymChars  — 類義（岩石）
    ///   antonymChars  — 対義（高低）
    ///   modifier      — 修飾（美女）
    ///   verbObject    — 動目（着席）
    ///   subjectPredicate — 主述（地震）
    static let validStructureTypes: Set<String> = [
        "synonym_chars",
        "antonym_chars",
        "modifier",
        "verb_object",
        "subject_predicate"
    ]
}

// MARK: - QuestionPayload

/// Supplementary metadata for kind-specific questions.
/// All fields are optional at the struct level; required fields are enforced
/// per-kind by `validateQuizDataStrict()`.
struct QuestionPayload: Codable {
    /// Discriminator — should match `QuestionKind.rawValue`.
    /// Optional to be lenient on decoding; validated by validateQuizDataStrict.
    let type: String?

    // MARK: reading / writing
    let targetKanji: String?
    let kana: String?
    /// "on" | "kun" | "mixed" | "jukujikun"
    let readingType: String?

    // MARK: composition (熟語の構成5分類)
    /// Must be one of `QuestionKind.validStructureTypes` when present.
    let structureType: String?
    let compound: String?

    // MARK: yojijukugo
    /// 4-character string; may contain "□" for the blank to fill.
    let yoji: String?
    /// Index (0–3) of the missing character.
    let missingIndex: Int?
    let meaning: String?

    // MARK: cloze
    let sentence: String?
    /// The token that appears in choices and must also appear in `sentence`.
    let blankToken: String?

    // MARK: errorcorrection
    let originalSentence: String?
    let wrongKanji: String?
    let correctKanji: String?

    // MARK: usage / okurigana
    let targetWord: String?
    let ruleTag: String?

    // MARK: public domain source metadata
    let sourceTitle: String?
    let sourceAuthor: String?
    let sourceExcerpt: String?

    // MARK: - Convenience init (all fields default to nil)
    // Explicit defaults let call sites omit unused fields cleanly (tests, builders).
    init(
        type: String? = nil,
        targetKanji: String? = nil,
        kana: String? = nil,
        readingType: String? = nil,
        structureType: String? = nil,
        compound: String? = nil,
        yoji: String? = nil,
        missingIndex: Int? = nil,
        meaning: String? = nil,
        sentence: String? = nil,
        blankToken: String? = nil,
        originalSentence: String? = nil,
        wrongKanji: String? = nil,
        correctKanji: String? = nil,
        targetWord: String? = nil,
        ruleTag: String? = nil,
        sourceTitle: String? = nil,
        sourceAuthor: String? = nil,
        sourceExcerpt: String? = nil
    ) {
        self.type = type
        self.targetKanji = targetKanji
        self.kana = kana
        self.readingType = readingType
        self.structureType = structureType
        self.compound = compound
        self.yoji = yoji
        self.missingIndex = missingIndex
        self.meaning = meaning
        self.sentence = sentence
        self.blankToken = blankToken
        self.originalSentence = originalSentence
        self.wrongKanji = wrongKanji
        self.correctKanji = correctKanji
        self.targetWord = targetWord
        self.ruleTag = ruleTag
        self.sourceTitle = sourceTitle
        self.sourceAuthor = sourceAuthor
        self.sourceExcerpt = sourceExcerpt
    }
}
