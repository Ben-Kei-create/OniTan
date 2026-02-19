import Foundation

// MARK: - App-level Alert / Error State
// Replaces scattered Bool @State flags with a unified enum.
// All alert presentation is driven through this single source.

enum OniAlert: Identifiable, Equatable {
    // Quiz
    case quitConfirmation
    case stageAlreadyCleared(stageNumber: Int)

    // Settings
    case resetConfirmation
    case resetComplete
    case nothingToReset

    // Data / Load errors
    case dataLoadError(message: String)
    case jsonValidationError(details: String)

    // Generic
    case info(title: String, message: String)

    var id: String {
        switch self {
        case .quitConfirmation:              return "quitConfirmation"
        case .stageAlreadyCleared(let n):   return "stageAlreadyCleared_\(n)"
        case .resetConfirmation:             return "resetConfirmation"
        case .resetComplete:                 return "resetComplete"
        case .nothingToReset:               return "nothingToReset"
        case .dataLoadError:                return "dataLoadError"
        case .jsonValidationError:           return "jsonValidationError"
        case .info(let t, _):               return "info_\(t)"
        }
    }

    var title: String {
        switch self {
        case .quitConfirmation:     return "確認"
        case .stageAlreadyCleared:  return "クリア済み"
        case .resetConfirmation:    return "初期化の確認"
        case .resetComplete:        return "完了"
        case .nothingToReset:       return "初期化できません"
        case .dataLoadError:        return "データエラー"
        case .jsonValidationError:  return "JSONエラー"
        case .info(let t, _):       return t
        }
    }

    var message: String {
        switch self {
        case .quitConfirmation:
            return "途中で辞めると、ステージクリアになりません。本当に辞めますか？"
        case .stageAlreadyCleared(let n):
            return "ステージ \(n) はすでにクリア済みです。"
        case .resetConfirmation:
            return "本当に進行状況を初期化しますか？\nすべてのクリア情報と統計が失われます。"
        case .resetComplete:
            return "進行状況が初期化されました。"
        case .nothingToReset:
            return "まだステージをクリアしていないため、初期化できません。"
        case .dataLoadError(let msg):
            return "問題データの読み込みに失敗しました。\n\(msg)"
        case .jsonValidationError(let details):
            return "JSONデータに問題が見つかりました。\n\(details)"
        case .info(_, let msg):
            return msg
        }
    }

    var isDestructive: Bool {
        switch self {
        case .resetConfirmation, .quitConfirmation: return true
        default: return false
        }
    }
}

// MARK: - Data Load Result
// Replaces fatalError in Data.swift with a recoverable result type.

enum DataLoadResult<T> {
    case success(T)
    case failure(DataLoadError)

    var value: T? {
        if case .success(let v) = self { return v }
        return nil
    }
}

enum DataLoadError: Error, LocalizedError {
    case fileNotFound(String)
    case decodingFailed(String, underlying: Error)
    case validationFailed([String])

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let name):
            return "ファイルが見つかりません: \(name)"
        case .decodingFailed(let name, let err):
            return "\(name) の解析に失敗: \(err.localizedDescription)"
        case .validationFailed(let issues):
            return issues.joined(separator: "\n")
        }
    }
}
