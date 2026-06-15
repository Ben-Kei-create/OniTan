import Foundation

// MARK: - Quiz Mode

enum QuizMode: String, CaseIterable, Identifiable, Codable {
    case normal      // 全問通常プレイ（誤答は復習キューへ）
    case quick10     // ランダム10問クイックモード
    case exam30      // ランダム30問模試モード（誤答キュー無し）
    case weakFocus   // 苦手問題集中モード

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .normal:    return "ノーマル"
        case .quick10:   return "ランダム10問"
        case .exam30:    return "模試30問"
        case .weakFocus: return "苦手集中"
        }
    }

    var description: String {
        switch self {
        case .normal:    return "全問正解を目指す標準モード。誤答は繰り返し出題されます。"
        case .quick10:   return "ランダムな10問を素早く解く短時間モード。"
        case .exam30:    return "ランダム30問。本番同様、正誤は表示せず最後にまとめて結果を確認します。"
        case .weakFocus: return "苦手な問題だけを集中的に練習します。"
        }
    }

    var systemImage: String {
        switch self {
        case .normal:    return "book.fill"
        case .quick10:   return "bolt.fill"
        case .exam30:    return "doc.text.fill"
        case .weakFocus: return "exclamationmark.triangle.fill"
        }
    }

    /// Whether wrong answers get re-queued for review within the session.
    var usesReviewQueue: Bool {
        switch self {
        case .normal, .weakFocus: return true
        case .quick10, .exam30:   return false
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
        case .quick10, .exam30:   return true
        }
    }

    var isAvailableWithoutWeakPoints: Bool {
        self != .weakFocus
    }

    /// Whether per-question correct/incorrect feedback is withheld until the
    /// session ends, to mimic real exam conditions. Only the exam mode defers
    /// feedback; results are shown all at once in ExamResultView.
    var deferredFeedback: Bool {
        self == .exam30
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
