import SwiftUI

// MARK: - Theme Manager

final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @AppStorage("appTheme") var themeRawValue: String = AppTheme.current.rawValue {
        didSet { objectWillChange.send() }
    }

    var theme: AppTheme {
        get { AppTheme(rawValue: themeRawValue) ?? .current }
        set { themeRawValue = newValue.rawValue }
    }

    var palette: ThemePalette {
        switch theme {
        case .current: return .current
        case .cool:    return .cool
        case .cute:    return .cute
        }
    }

    var preferredColorScheme: ColorScheme {
        theme.preferredColorScheme
    }
}
