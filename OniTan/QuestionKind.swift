import Foundation
import OSLog

private let kindLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "OniTan",
                                category: "QuestionModel")

// MARK: - QuestionKind

/// Canonical question types matching the actual Kanken Pre-1 exam format.
/// Legacy kind strings from old JSON are remapped via the custom decoder below.
enum QuestionKind: String, Codable, CaseIterable {

    // MARK: 読み系
    case reading              // 読み（語・熟語・文中の読み）
    case sentenceReading      // 例文読み（例文中の下線部の読み）
    case hyogaiReading        // 表外の読み（標準外の読み方）
    case compoundReadingKun   // 熟語の読み・一字訓（熟語中の特定漢字）

    // MARK: 漢字選択
    case commonKanji          // 共通漢字（複数語に共通する一字）

    // MARK: 訂正
    case errorCorrection      // 誤字訂正（文中の誤字を選ぶ）

    // MARK: 熟語・成語
    case yojijukugo           // 四字熟語（欠字・意味照合）
    case synonym              // 類義語
    case antonym              // 対義語
    case proverb              // 故事・成語・ことわざ

    // MARK: 文章題
    case passageReading       // 文章題（文中の読み問題）
    case passageVocabulary    // 文章題（語彙・文脈・文章穴埋め）

    // MARK: スキップ
    case writingSkipped       // 書き取り（多肢選択では未対応、模試から除外）

    // MARK: フォールバック
    case unknown              // 前方互換用キャッチオール

    // MARK: - Decoding with legacy rawValue aliases

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)

        // Direct match first
        if let matched = QuestionKind(rawValue: raw) {
            self = matched
            return
        }

        // Legacy rawValue → new case
        switch raw {
        case "errorcorrection":
            self = .errorCorrection
        case "writing":
            self = .writingSkipped
        case "jukujikun":
            // 熟字訓 is closest to 読み in exam terms
            self = .reading
        case "cloze", "usage":
            self = .passageVocabulary
        case "composition", "okurigana", "radical", "examMixed":
            // Deprecated — no direct exam equivalent in Pre-1
            self = .unknown
        default:
            kindLogger.warning("Unknown QuestionKind '\(raw, privacy: .public)' — mapped to .unknown")
            self = .unknown
        }
    }
}

// MARK: - UI Labels

extension QuestionKind {

    /// Short display name for badges and stats.
    var displayName: String {
        switch self {
        case .reading:            return "読み（旧）"
        case .sentenceReading:    return "例文読み"
        case .hyogaiReading:      return "表外の読み"
        case .compoundReadingKun: return "熟語の読み"
        case .commonKanji:        return "共通漢字"
        case .errorCorrection:    return "誤字訂正"
        case .yojijukugo:         return "四字熟語"
        case .synonym:            return "類義語"
        case .antonym:            return "対義語"
        case .proverb:            return "故事・ことわざ"
        case .passageReading:     return "文章題（読み）"
        case .passageVocabulary:  return "文章題（語彙）"
        case .writingSkipped:     return "書き取り"
        case .unknown:            return "その他"
        }
    }

    /// Instruction label shown above the answer choices.
    var choicePrompt: String {
        switch self {
        case .reading:            return "読みをひらがなで選びなさい"
        case .sentenceReading:    return "下線部の読みを選びなさい"
        case .hyogaiReading:      return "表外の読みを選びなさい"
        case .compoundReadingKun: return "一字の読みを選びなさい"
        case .commonKanji:        return "共通する漢字を選びなさい"
        case .errorCorrection:    return "誤っている漢字を選びなさい"
        case .yojijukugo:         return "□に入る漢字を選びなさい"
        case .synonym:            return "類義語を選びなさい"
        case .antonym:            return "対義語を選びなさい"
        case .proverb:            return "正しい語句を選びなさい"
        case .passageReading:     return "下線部の読みを選びなさい"
        case .passageVocabulary:  return "□に入る語句を選びなさい"
        case .writingSkipped:     return "答えを選びなさい"
        case .unknown:            return "答えを選びなさい"
        }
    }

    /// SF Symbol for this kind.
    var systemImage: String {
        switch self {
        case .reading:            return "character.book.closed"
        case .sentenceReading:    return "text.quote"
        case .hyogaiReading:      return "book.pages"
        case .compoundReadingKun: return "text.magnifyingglass"
        case .commonKanji:        return "square.on.square"
        case .errorCorrection:    return "checkmark.circle"
        case .yojijukugo:         return "square.grid.2x2"
        case .synonym:            return "equal.circle"
        case .antonym:            return "arrow.left.arrow.right"
        case .proverb:            return "quote.bubble"
        case .passageReading:     return "doc.text.below.ecg"
        case .passageVocabulary:  return "doc.text"
        case .writingSkipped:     return "pencil.slash"
        case .unknown:            return "questionmark.circle"
        }
    }

    /// Whether this kind should use a full-sentence card layout.
    var isSentenceKind: Bool {
        switch self {
        case .errorCorrection, .proverb,
             .sentenceReading, .passageReading, .passageVocabulary:
            return true
        default:
            return false
        }
    }

    /// Whether this kind is included in mock exams.
    var isExamEligible: Bool {
        self != .reading && self != .writingSkipped && self != .unknown
    }

    /// Kinds that appear in the real Kanken Pre-1 exam (used by ReadinessCalculator).
    static let examKinds: [QuestionKind] = [
        .sentenceReading, .hyogaiReading, .compoundReadingKun,
        .commonKanji, .errorCorrection,
        .yojijukugo, .synonym, .antonym,
        .proverb, .passageReading, .passageVocabulary
    ]
}

// MARK: - QuestionPayload

struct QuestionPayload: Codable {

    // MARK: Discriminator
    let type: String?

    // MARK: Common overrides
    let title: String?        // optional section title shown in explanation
    let instruction: String?  // overrides choicePrompt if present

    // MARK: reading / hyogaiReading
    let targetKanji: String?
    let kana: String?
    let readingType: String?       // "on" | "kun" | "mixed" | "hyogai"
    let sentenceContext: String?   // sentence showing the kanji in context

    // MARK: compoundReadingKun
    let targetCompound: String?         // the compound word (e.g. "山河")
    let targetKanjiInCompound: String?  // which kanji is asked (e.g. "山")

    // MARK: commonKanji
    let blankTerms: [String]?   // e.g. ["□国", "□王", "□族"]

    // MARK: yojijukugo
    let yoji: String?         // 4-char string with "□" for the blank
    let missingIndex: Int?    // 0–3
    let meaning: String?

    // MARK: synonym / antonym
    let targetWord: String?
    let relationWord: String?

    // MARK: errorCorrection
    let originalSentence: String?
    let wrongKanji: String?
    let correctKanji: String?
    let correctedSentence: String?

    // MARK: proverb
    let proverbText: String?
    let proverbMeaning: String?

    // MARK: passageReading / passageVocabulary
    let passageText: String?         // the full passage text
    let passageTarget: Int?          // which numbered blank/underline (1-based)
    let passageTargetText: String?   // the specific text being asked about
    let passageBlankToken: String?   // the token to replace in the passage

    // MARK: legacy / deprecated (kept for backward compatibility)
    let kanaPrompt: String?
    let baseWord: String?
    let okuriganaRule: String?
    let sentence: String?
    let blankToken: String?
    let compound: String?
    let structureType: String?
    let radical: String?
    let radicalName: String?
    let jukujikunWord: String?
    let jukujikunReading: String?

    // MARK: - Convenience init

    init(
        type: String? = nil,
        title: String? = nil,
        instruction: String? = nil,
        targetKanji: String? = nil,
        kana: String? = nil,
        readingType: String? = nil,
        sentenceContext: String? = nil,
        targetCompound: String? = nil,
        targetKanjiInCompound: String? = nil,
        blankTerms: [String]? = nil,
        yoji: String? = nil,
        missingIndex: Int? = nil,
        meaning: String? = nil,
        targetWord: String? = nil,
        relationWord: String? = nil,
        originalSentence: String? = nil,
        wrongKanji: String? = nil,
        correctKanji: String? = nil,
        correctedSentence: String? = nil,
        proverbText: String? = nil,
        proverbMeaning: String? = nil,
        passageText: String? = nil,
        passageTarget: Int? = nil,
        passageTargetText: String? = nil,
        passageBlankToken: String? = nil,
        kanaPrompt: String? = nil,
        baseWord: String? = nil,
        okuriganaRule: String? = nil,
        sentence: String? = nil,
        blankToken: String? = nil,
        compound: String? = nil,
        structureType: String? = nil,
        radical: String? = nil,
        radicalName: String? = nil,
        jukujikunWord: String? = nil,
        jukujikunReading: String? = nil
    ) {
        self.type = type
        self.title = title
        self.instruction = instruction
        self.targetKanji = targetKanji
        self.kana = kana
        self.readingType = readingType
        self.sentenceContext = sentenceContext
        self.targetCompound = targetCompound
        self.targetKanjiInCompound = targetKanjiInCompound
        self.blankTerms = blankTerms
        self.yoji = yoji
        self.missingIndex = missingIndex
        self.meaning = meaning
        self.targetWord = targetWord
        self.relationWord = relationWord
        self.originalSentence = originalSentence
        self.wrongKanji = wrongKanji
        self.correctKanji = correctKanji
        self.correctedSentence = correctedSentence
        self.proverbText = proverbText
        self.proverbMeaning = proverbMeaning
        self.passageText = passageText
        self.passageTarget = passageTarget
        self.passageTargetText = passageTargetText
        self.passageBlankToken = passageBlankToken
        self.kanaPrompt = kanaPrompt
        self.baseWord = baseWord
        self.okuriganaRule = okuriganaRule
        self.sentence = sentence
        self.blankToken = blankToken
        self.compound = compound
        self.structureType = structureType
        self.radical = radical
        self.radicalName = radicalName
        self.jukujikunWord = jukujikunWord
        self.jukujikunReading = jukujikunReading
    }
}
