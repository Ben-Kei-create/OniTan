import Foundation
import OSLog

private let kindLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "OniTan",
                                category: "QuestionModel")

// MARK: - QuestionKind

enum QuestionKind: String, Codable, CaseIterable {
    case reading          // 読み（音読み・訓読み）
    case writing          // 書き取り（かな→漢字）
    case composition      // 熟語の構成（5分類）
    case yojijukugo       // 四字熟語
    case synonym          // 類義語
    case antonym          // 対義語
    case okurigana        // 送り仮名
    case errorcorrection  // 誤字訂正
    case cloze            // 文章穴埋め
    case usage            // 語彙用法
    case radical          // 部首
    case jukujikun        // 熟字訓・当て字
    case proverb          // 故事成語・ことわざ
    case examMixed        // 模試専用ミックス（複数カテゴリ混在）
    case unknown          // forward-compatibility catch-all

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

// MARK: - UI Labels

extension QuestionKind {
    /// Short display name used in mode badges, stats, etc.
    var displayName: String {
        switch self {
        case .reading:         return "読み"
        case .writing:         return "書き取り"
        case .composition:     return "熟語の構成"
        case .yojijukugo:      return "四字熟語"
        case .synonym:         return "類義語"
        case .antonym:         return "対義語"
        case .okurigana:       return "送り仮名"
        case .errorcorrection: return "誤字訂正"
        case .cloze:           return "文章穴埋め"
        case .usage:           return "語彙用法"
        case .radical:         return "部首"
        case .jukujikun:       return "熟字訓・当て字"
        case .proverb:         return "故事成語"
        case .examMixed:       return "模試"
        case .unknown:         return "その他"
        }
    }

    /// Instruction label shown above the answer choices during a quiz.
    var choicePrompt: String {
        switch self {
        case .reading:         return "読みを選びなさい"
        case .writing:         return "正しい漢字を選びなさい"
        case .composition:     return "熟語の構成を選びなさい"
        case .yojijukugo:      return "□に入る漢字を選びなさい"
        case .synonym:         return "類義語を選びなさい"
        case .antonym:         return "対義語を選びなさい"
        case .okurigana:       return "送り仮名を選びなさい"
        case .errorcorrection: return "誤っている漢字を選びなさい"
        case .cloze:           return "□に入る語句を選びなさい"
        case .usage:           return "正しい用法を選びなさい"
        case .radical:         return "部首を選びなさい"
        case .jukujikun:       return "読みを選びなさい"
        case .proverb:         return "正しい語句を選びなさい"
        case .examMixed:       return "答えを選びなさい"
        case .unknown:         return "答えを選びなさい"
        }
    }

    /// SF Symbol for this question kind.
    var systemImage: String {
        switch self {
        case .reading:         return "character.book.closed"
        case .writing:         return "pencil"
        case .composition:     return "arrow.triangle.2.circlepath"
        case .yojijukugo:      return "square.grid.2x2"
        case .synonym:         return "equal.circle"
        case .antonym:         return "arrow.left.arrow.right"
        case .okurigana:       return "textformat"
        case .errorcorrection: return "checkmark.circle"
        case .cloze:           return "doc.text.below.ecg"
        case .usage:           return "text.bubble"
        case .radical:         return "character"
        case .jukujikun:       return "character.ja.hiragana"
        case .proverb:         return "quote.bubble"
        case .examMixed:       return "doc.text.fill"
        case .unknown:         return "questionmark.circle"
        }
    }

    /// Whether this kind requires displaying a full sentence rather than a single word/kanji.
    var isSentenceKind: Bool {
        switch self {
        case .cloze, .errorcorrection, .proverb: return true
        default: return false
        }
    }
}

// MARK: - Composition Valid Structure Types

extension QuestionKind {
    static let validStructureTypes: Set<String> = [
        "synonym_chars",
        "antonym_chars",
        "modifier",
        "verb_object",
        "subject_predicate"
    ]
}

// MARK: - QuestionPayload

struct QuestionPayload: Codable {

    // MARK: Discriminator
    let type: String?

    // MARK: Common
    let title: String?          // optional section title shown in explanation
    let instruction: String?    // overrides choicePrompt if present

    // MARK: reading / writing
    let targetKanji: String?
    let kana: String?
    let readingType: String?    // "on" | "kun" | "mixed" | "jukujikun"
    let kanaPrompt: String?     // writing: the kana shown as the prompt

    // MARK: composition
    let structureType: String?  // one of QuestionKind.validStructureTypes
    let compound: String?

    // MARK: yojijukugo
    let yoji: String?           // 4-char string with "□" for the blank
    let missingIndex: Int?      // 0–3
    let meaning: String?

    // MARK: synonym / antonym / usage
    let targetWord: String?
    let relationWord: String?   // hint: related word for synonym/antonym

    // MARK: okurigana
    let baseWord: String?       // e.g. "おくる" → choose correct okurigana
    let okuriganaRule: String?

    // MARK: cloze
    let sentence: String?
    let blankToken: String?

    // MARK: error correction
    let originalSentence: String?
    let wrongKanji: String?
    let correctKanji: String?
    let correctedSentence: String?

    // MARK: radical
    let radical: String?
    let radicalName: String?

    // MARK: jukujikun
    let jukujikunWord: String?  // the full word (e.g. 今日)
    let jukujikunReading: String?  // the reading (e.g. きょう)

    // MARK: proverb
    let proverbText: String?
    let proverbMeaning: String?

    // MARK: - Convenience init
    init(
        type: String? = nil,
        title: String? = nil,
        instruction: String? = nil,
        targetKanji: String? = nil,
        kana: String? = nil,
        readingType: String? = nil,
        kanaPrompt: String? = nil,
        structureType: String? = nil,
        compound: String? = nil,
        yoji: String? = nil,
        missingIndex: Int? = nil,
        meaning: String? = nil,
        targetWord: String? = nil,
        relationWord: String? = nil,
        baseWord: String? = nil,
        okuriganaRule: String? = nil,
        sentence: String? = nil,
        blankToken: String? = nil,
        originalSentence: String? = nil,
        wrongKanji: String? = nil,
        correctKanji: String? = nil,
        correctedSentence: String? = nil,
        radical: String? = nil,
        radicalName: String? = nil,
        jukujikunWord: String? = nil,
        jukujikunReading: String? = nil,
        proverbText: String? = nil,
        proverbMeaning: String? = nil
    ) {
        self.type = type
        self.title = title
        self.instruction = instruction
        self.targetKanji = targetKanji
        self.kana = kana
        self.readingType = readingType
        self.kanaPrompt = kanaPrompt
        self.structureType = structureType
        self.compound = compound
        self.yoji = yoji
        self.missingIndex = missingIndex
        self.meaning = meaning
        self.targetWord = targetWord
        self.relationWord = relationWord
        self.baseWord = baseWord
        self.okuriganaRule = okuriganaRule
        self.sentence = sentence
        self.blankToken = blankToken
        self.originalSentence = originalSentence
        self.wrongKanji = wrongKanji
        self.correctKanji = correctKanji
        self.correctedSentence = correctedSentence
        self.radical = radical
        self.radicalName = radicalName
        self.jukujikunWord = jukujikunWord
        self.jukujikunReading = jukujikunReading
        self.proverbText = proverbText
        self.proverbMeaning = proverbMeaning
    }
}
