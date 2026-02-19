import Foundation

// MARK: - Quiz Mode
// Defines available learning modes. Designed for future SRS extension.

enum QuizMode: String, CaseIterable, Identifiable, Codable {
    case normal      // 全問通常プレイ（誤答は復習キューへ）
    case quick10     // ランダム10問クイックモード
    case exam30      // ランダム30問模試モード（誤答キュー無し）
    case weakFocus   // 苦手問題集中モード
    case srsReview   // 将来SRS実装用プレースホルダー

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .normal:    return "ノーマル"
        case .quick10:   return "クイック10問"
        case .exam30:    return "模試30問"
        case .weakFocus: return "苦手集中"
        case .srsReview: return "SRS復習"
        }
    }

    var description: String {
        switch self {
        case .normal:    return "全問正解を目指す標準モード。誤答は繰り返し出題されます。"
        case .quick10:   return "ランダムな10問を素早く解く短時間モード。"
        case .exam30:    return "ランダム30問。誤答の再出題なし。実力をテストします。"
        case .weakFocus: return "苦手な問題だけを集中的に練習します。"
        case .srsReview: return "Coming soon: 間隔反復アルゴリズムによる復習。"
        }
    }

    var systemImage: String {
        switch self {
        case .normal:    return "book.fill"
        case .quick10:   return "bolt.fill"
        case .exam30:    return "doc.text.fill"
        case .weakFocus: return "exclamationmark.triangle.fill"
        case .srsReview: return "brain.head.profile"
        }
    }

    /// Whether wrong answers get re-queued for review within the session.
    var usesReviewQueue: Bool {
        switch self {
        case .normal, .weakFocus: return true
        case .quick10, .exam30, .srsReview: return false
        }
    }

    /// Maximum number of questions to draw. nil = all.
    var questionLimit: Int? {
        switch self {
        case .quick10:   return 10
        case .exam30:    return 30
        default:         return nil
        }
    }

    /// Whether to shuffle questions at session start.
    var shufflesQuestions: Bool {
        switch self {
        case .normal, .weakFocus: return false
        case .quick10, .exam30, .srsReview: return true
        }
    }

    var isAvailableWithoutWeakPoints: Bool {
        self != .weakFocus
    }

    var isSRSPlaceholder: Bool {
        self == .srsReview
    }
}

// MARK: - Question Selection Helper

extension QuizMode {
    /// Build the ordered question list for this mode from a pool.
    func buildQuestionList(from pool: [Question], weakKanji: Set<String> = []) -> [Question] {
        var source: [Question]

        switch self {
        case .weakFocus:
            source = pool.filter { weakKanji.contains($0.kanji) }
            if source.isEmpty { source = pool }  // fallback if no weak points
        default:
            source = pool
        }

        if shufflesQuestions {
            source = source.shuffled()
        }

        // Deduplicate by kanji (preserve order)
        var seen = Set<String>()
        source = source.filter { seen.insert($0.kanji).inserted }

        if let limit = questionLimit {
            source = Array(source.prefix(limit))
        }

        return source
    }
}
