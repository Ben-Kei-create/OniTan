import SwiftUI
import UIKit

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

    fileprivate var uiKitDesign: UIFontDescriptor.SystemDesign {
        switch self {
        case .default: return .rounded
        case .mincho: return .serif
        case .monospaced: return .monospaced
        }
    }

    /// Returns a font that honors the user's Dynamic Type setting while keeping
    /// `size` as the baseline at the default content size category.
    /// The scaled size is capped at 1.6x to avoid breaking layouts at the
    /// largest accessibility text sizes.
    func font(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let baseFont = UIFont.systemFont(ofSize: size, weight: weight.uiKitWeight)
        let descriptor = baseFont.fontDescriptor.withDesign(uiKitDesign) ?? baseFont.fontDescriptor
        let designedFont = UIFont(descriptor: descriptor, size: size)
        let scaledFont = UIFontMetrics(forTextStyle: .body).scaledFont(
            for: designedFont,
            maximumPointSize: size * 1.6
        )
        return Font(scaledFont)
    }
}

private extension Font.Weight {
    var uiKitWeight: UIFont.Weight {
        switch self {
        case .ultraLight: return .ultraLight
        case .thin: return .thin
        case .light: return .light
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        case .heavy: return .heavy
        case .black: return .black
        default: return .regular
        }
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
