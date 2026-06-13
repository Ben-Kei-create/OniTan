import Foundation

// MARK: - TrainingMode

/// Replaces QuizMode with a richer session-type system.
/// QuizMode is kept for backward compatibility with existing session code.
enum TrainingMode: String, CaseIterable, Identifiable, Codable {
    case normal          // All questions in category, review queue on
    case quick10         // Random 10, shuffled, no review queue
    case categoryFocus   // Selected category or kind only
    case weakFocus       // Weak + learning questions only
    case mistakeReview   // Recent wrong answers
    case masteryReview   // Spaced repetition review
    case examMini        // 30 mixed questions across all categories
    case examFull        // 100 questions, full Kanken-style mock
    case finalBoss       // Hardest weak + high-difficulty questions (unlocks at 80% readiness)

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .normal:        return "ノーマル"
        case .quick10:       return "カテゴリ10問"
        case .categoryFocus: return "カテゴリ集中"
        case .weakFocus:     return "苦手集中"
        case .mistakeReview: return "まちがいノート"
        case .masteryReview: return "スペースド復習"
        case .examMini:      return "模試ミニ（30問）"
        case .examFull:      return "本番模試（100問）"
        case .finalBoss:     return "鬼の最終試練"
        }
    }

    var description: String {
        switch self {
        case .normal:
            return "全問正解を目指す標準モード。誤答は繰り返し出題されます。"
        case .quick10:
            return "この道場のカテゴリからランダムに10問。短時間で取り組めます。"
        case .categoryFocus:
            return "選択したカテゴリの問題だけを集中的に練習します。"
        case .weakFocus:
            return "苦手・習得中の問題だけを集中的に練習します。"
        case .mistakeReview:
            return "最近まちがえた問題を復習します。"
        case .masteryReview:
            return "定着度に基づくスペースドレピティションで復習します。"
        case .examMini:
            return "全カテゴリからランダム30問。実力を確認します。"
        case .examFull:
            return "漢検準1級形式の本番模試。100問、合格ライン90%。"
        case .finalBoss:
            return "最難関の苦手問題に挑む最終試練。準備完了度80%で解放。"
        }
    }

    var systemImage: String {
        switch self {
        case .normal:        return "book.fill"
        case .quick10:       return "bolt.fill"
        case .categoryFocus: return "rectangle.grid.2x2.fill"
        case .weakFocus:     return "exclamationmark.triangle.fill"
        case .mistakeReview: return "arrow.counterclockwise"
        case .masteryReview: return "clock.arrow.2.circlepath"
        case .examMini:      return "doc.text.fill"
        case .examFull:      return "doc.richtext.fill"
        case .finalBoss:     return "flame.fill"
        }
    }

    /// Whether wrong answers get re-queued within the session.
    var usesReviewQueue: Bool {
        switch self {
        case .normal, .weakFocus, .categoryFocus,
             .mistakeReview, .masteryReview: return true
        case .quick10, .examMini, .examFull, .finalBoss: return false
        }
    }

    /// Maximum questions to draw; nil = use full pool.
    var questionLimit: Int? {
        switch self {
        case .quick10:   return 10
        case .examMini:  return 30
        case .examFull:  return 100
        default:         return nil
        }
    }

    var shufflesQuestions: Bool {
        switch self {
        case .quick10, .examMini, .examFull, .finalBoss: return true
        default: return false
        }
    }

    /// Whether this mode requires a minimum readiness level to unlock.
    var minimumReadiness: Double {
        switch self {
        case .finalBoss: return 0.80
        default:         return 0.0
        }
    }

    var requiresWeakPoints: Bool { self == .weakFocus || self == .mistakeReview }

    /// Equivalent legacy QuizMode, used while migrating.
    var legacyQuizMode: QuizMode? {
        switch self {
        case .normal:    return .normal
        case .quick10:   return .quick10
        case .examMini:  return .exam30
        case .weakFocus: return .weakFocus
        default:         return nil
        }
    }
}
