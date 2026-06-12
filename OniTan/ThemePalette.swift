import SwiftUI

// MARK: - App Theme

enum AppTheme: String, CaseIterable, Identifiable {
    case current  // 墨と朱 — primary OniTan premium theme
    case cool     // 夜の道場 — deeper ink variant
    case cute     // 和紙の灯 — warmer dark variant

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .current: return "墨と朱"
        case .cool:    return "夜の道場"
        case .cute:    return "和紙の灯"
        }
    }

    /// XP level required to unlock this theme. nil = always available.
    var unlockLevel: Int? {
        switch self {
        case .current: return nil
        case .cool:    return 10
        case .cute:    return 20
        }
    }

    var preferredColorScheme: ColorScheme {
        switch self {
        case .current, .cool, .cute: return .dark
        }
    }
}

// MARK: - Theme Palette

struct ThemePalette {

    // MARK: Gradient color arrays (used to build LinearGradients)

    let backgroundGradientColors: [Color]
    let correctGradientColors: [Color]
    let wrongGradientColors: [Color]
    let primaryGradientColors: [Color]
    let goldGradientColors: [Color]

    // MARK: Semantic colors

    let cardBackground: Color
    let cardBackgroundPressed: Color
    let cardBorder: Color

    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color

    let accentCorrect: Color
    let accentWrong: Color
    let accentWeak: Color
    let accentPrimary: Color

    let shadowGlowColor: Color

    // MARK: Computed gradients

    var backgroundGradient: LinearGradient {
        LinearGradient(colors: backgroundGradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var correctGradient: LinearGradient {
        LinearGradient(colors: correctGradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var wrongGradient: LinearGradient {
        LinearGradient(colors: wrongGradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var primaryGradient: LinearGradient {
        LinearGradient(colors: primaryGradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var goldGradient: LinearGradient {
        LinearGradient(colors: goldGradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Built-in Palettes

extension ThemePalette {

    /// "墨と朱" — OniTan dark premium (ink + oni-red, gold for highlights)
    static let current = ThemePalette(
        backgroundGradientColors: [
            OniTanTheme.inkBackground,
            OniTanTheme.inkBackgroundSecondary,
            OniTanTheme.inkBackgroundDeep
        ],
        correctGradientColors: [
            OniTanTheme.mutedGold,
            OniTanTheme.mutedGoldDark
        ],
        wrongGradientColors: [
            OniTanTheme.sealRed,
            OniTanTheme.sealRedDark
        ],
        primaryGradientColors: [
            OniTanTheme.sealRed,
            OniTanTheme.sealRedDark
        ],
        goldGradientColors: [
            OniTanTheme.mutedGold,
            OniTanTheme.mutedGoldDark
        ],
        cardBackground: OniTanTheme.inkCard.opacity(0.92),
        cardBackgroundPressed: OniTanTheme.inkCardPressed.opacity(0.96),
        cardBorder: OniTanTheme.mutedGold.opacity(0.16),
        textPrimary: OniTanTheme.washiText,
        textSecondary: OniTanTheme.washiSecondary,
        textTertiary: Color(hex: "766D64"),
        accentCorrect: OniTanTheme.mutedGold,
        accentWrong: OniTanTheme.sealRed,
        accentWeak: OniTanTheme.mutedGold,
        accentPrimary: OniTanTheme.sealRed,
        shadowGlowColor: OniTanTheme.sealRed.opacity(0.28)
    )

    /// "夜の道場" — deeper ink variant.
    static let cool = ThemePalette(
        backgroundGradientColors: [
            Color(hex: "040305"),
            Color(hex: "0B0709"),
            Color(hex: "17080D")
        ],
        correctGradientColors: [
            Color(hex: "E0BD62"),
            Color(hex: "927037")
        ],
        wrongGradientColors: [
            Color(hex: "A81624"),
            Color(hex: "650D17")
        ],
        primaryGradientColors: [
            Color(hex: "A81624"),
            Color(hex: "650D17")
        ],
        goldGradientColors: [
            Color(hex: "E0BD62"),
            Color(hex: "927037")
        ],
        cardBackground: Color(hex: "100D10").opacity(0.94),
        cardBackgroundPressed: Color(hex: "1B1115").opacity(0.96),
        cardBorder: Color(hex: "E0BD62").opacity(0.14),
        textPrimary: Color(hex: "F7F0E6"),
        textSecondary: Color(hex: "B4A898"),
        textTertiary: Color(hex: "716961"),
        accentCorrect: Color(hex: "E0BD62"),
        accentWrong: Color(hex: "A81624"),
        accentWeak: Color(hex: "E0BD62"),
        accentPrimary: Color(hex: "A81624"),
        shadowGlowColor: Color(hex: "A81624").opacity(0.25)
    )

    /// "和紙の灯" — warmer premium variant while staying in the dojo identity.
    static let cute = ThemePalette(
        backgroundGradientColors: [
            Color(hex: "100A08"),
            Color(hex: "170D09"),
            Color(hex: "090606")
        ],
        correctGradientColors: [
            Color(hex: "DCC06F"),
            Color(hex: "9C7938")
        ],
        wrongGradientColors: [
            Color(hex: "B72630"),
            Color(hex: "7D1519")
        ],
        primaryGradientColors: [
            Color(hex: "B72630"),
            Color(hex: "7D1519")
        ],
        goldGradientColors: [
            Color(hex: "DCC06F"),
            Color(hex: "9C7938")
        ],
        cardBackground: Color(hex: "1A1110").opacity(0.93),
        cardBackgroundPressed: Color(hex: "241715").opacity(0.96),
        cardBorder: Color(hex: "DCC06F").opacity(0.16),
        textPrimary: Color(hex: "F8EEDC"),
        textSecondary: Color(hex: "B9A991"),
        textTertiary: Color(hex: "7A6F61"),
        accentCorrect: Color(hex: "DCC06F"),
        accentWrong: Color(hex: "B72630"),
        accentWeak: Color(hex: "DCC06F"),
        accentPrimary: Color(hex: "B72630"),
        shadowGlowColor: Color(hex: "B72630").opacity(0.25)
    )
}
