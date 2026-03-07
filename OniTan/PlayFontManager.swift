import SwiftUI

enum PlayFontStyle: String, CaseIterable, Identifiable {
    case `default`
    case mincho
    case monospaced

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .default: return "デフォルト"
        case .mincho: return "明朝"
        case .monospaced: return "等幅"
        }
    }

    var subtitle: String {
        switch self {
        case .default: return "今の見た目"
        case .mincho: return "落ち着いた筆記感"
        case .monospaced: return "シャープな表示"
        }
    }

    var unlockLevel: Int? {
        switch self {
        case .default: return nil
        case .mincho: return 15
        case .monospaced: return 25
        }
    }

    var previewText: String {
        switch self {
        case .default: return "漢"
        case .mincho: return "語"
        case .monospaced: return "字"
        }
    }

    fileprivate var design: Font.Design {
        switch self {
        case .default: return .rounded
        case .mincho: return .serif
        case .monospaced: return .monospaced
        }
    }

    func font(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: design)
    }
}

final class PlayFontManager: ObservableObject {
    static let shared = PlayFontManager()

    @AppStorage("playFontStyle") private var fontRawValue: String = PlayFontStyle.default.rawValue {
        didSet { objectWillChange.send() }
    }

    init(store: UserDefaults = .standard) {
        _fontRawValue = AppStorage(wrappedValue: PlayFontStyle.default.rawValue, "playFontStyle", store: store)
    }

    var fontStyle: PlayFontStyle {
        get { PlayFontStyle(rawValue: fontRawValue) ?? .default }
        set { fontRawValue = newValue.rawValue }
    }

    func font(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        fontStyle.font(size: size, weight: weight)
    }
}
