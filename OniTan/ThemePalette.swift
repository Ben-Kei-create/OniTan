import SwiftUI

// MARK: - App Theme

enum AppTheme: String, CaseIterable, Identifiable {
    case current  // 現在のカラー — existing purple gradient dark theme
    case cool     // カッコいい — cyberpunk dark
    case cute     // 可愛い — pastel light

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .current: return "現在のカラー"
        case .cool:    return "カッコいい"
        case .cute:    return "可愛い"
        }
    }

    var preferredColorScheme: ColorScheme {
        switch self {
        case .current, .cool: return .dark
        case .cute:           return .light
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

    /// "現在のカラー" — The original purple gradient dark theme
    static let current = ThemePalette(
        backgroundGradientColors: [
            Color(red: 0.10, green: 0.10, blue: 0.30),
            Color(red: 0.20, green: 0.05, blue: 0.25)
        ],
        correctGradientColors: [
            Color(red: 0.13, green: 0.70, blue: 0.45),
            Color(red: 0.10, green: 0.55, blue: 0.35)
        ],
        wrongGradientColors: [
            Color(red: 0.85, green: 0.22, blue: 0.22),
            Color(red: 0.70, green: 0.12, blue: 0.15)
        ],
        primaryGradientColors: [
            Color(red: 0.38, green: 0.32, blue: 0.90),
            Color(red: 0.60, green: 0.20, blue: 0.80)
        ],
        goldGradientColors: [
            Color(red: 1.0, green: 0.80, blue: 0.10),
            Color(red: 0.95, green: 0.60, blue: 0.05)
        ],
        cardBackground: Color.white.opacity(0.12),
        cardBackgroundPressed: Color.white.opacity(0.22),
        cardBorder: Color.white.opacity(0.25),
        textPrimary: .white,
        textSecondary: Color.white.opacity(0.70),
        textTertiary: Color.white.opacity(0.50),
        accentCorrect: Color(red: 0.13, green: 0.70, blue: 0.45),
        accentWrong: Color(red: 0.85, green: 0.22, blue: 0.22),
        accentWeak: Color(red: 1.00, green: 0.60, blue: 0.10),
        accentPrimary: Color(red: 0.48, green: 0.38, blue: 0.95),
        shadowGlowColor: Color.purple.opacity(0.4)
    )

    /// "カッコいい" — Cyberpunk dark theme
    static let cool = ThemePalette(
        backgroundGradientColors: [
            Color(red: 0.008, green: 0.008, blue: 0.03),   // #020208
            Color(red: 0.0, green: 0.06, blue: 0.16)       // #000F28
        ],
        correctGradientColors: [
            Color(red: 0.0, green: 0.85, blue: 0.55),
            Color(red: 0.0, green: 0.65, blue: 0.40)
        ],
        wrongGradientColors: [
            Color(red: 1.0, green: 0.15, blue: 0.25),
            Color(red: 0.75, green: 0.08, blue: 0.15)
        ],
        primaryGradientColors: [
            Color(red: 0.0, green: 0.90, blue: 1.0),       // #00E5FF
            Color(red: 0.0, green: 0.55, blue: 0.85)
        ],
        goldGradientColors: [
            Color(red: 1.0, green: 0.85, blue: 0.0),
            Color(red: 1.0, green: 0.65, blue: 0.0)
        ],
        cardBackground: Color.white.opacity(0.08),
        cardBackgroundPressed: Color.white.opacity(0.16),
        cardBorder: Color(red: 0.0, green: 0.90, blue: 1.0).opacity(0.20),
        textPrimary: .white,
        textSecondary: Color.white.opacity(0.70),
        textTertiary: Color.white.opacity(0.50),
        accentCorrect: Color(red: 0.0, green: 0.85, blue: 0.55),
        accentWrong: Color(red: 1.0, green: 0.15, blue: 0.25),
        accentWeak: Color(red: 1.0, green: 0.65, blue: 0.0),
        accentPrimary: Color(red: 0.0, green: 0.90, blue: 1.0),
        shadowGlowColor: Color(red: 0.0, green: 0.90, blue: 1.0).opacity(0.4)
    )

    /// "可愛い" — Pastel light theme
    static let cute = ThemePalette(
        backgroundGradientColors: [
            Color(red: 1.0, green: 0.90, blue: 0.94),      // #FFE6F0
            Color(red: 0.90, green: 0.855, blue: 1.0)      // #E6DAFF
        ],
        correctGradientColors: [
            Color(red: 0.40, green: 0.78, blue: 0.55),
            Color(red: 0.30, green: 0.65, blue: 0.45)
        ],
        wrongGradientColors: [
            Color(red: 0.90, green: 0.35, blue: 0.40),
            Color(red: 0.78, green: 0.25, blue: 0.30)
        ],
        primaryGradientColors: [
            Color(red: 0.85, green: 0.50, blue: 0.75),     // sakura pink
            Color(red: 0.65, green: 0.40, blue: 0.80)
        ],
        goldGradientColors: [
            Color(red: 1.0, green: 0.80, blue: 0.30),
            Color(red: 0.95, green: 0.65, blue: 0.20)
        ],
        cardBackground: Color(red: 0.24, green: 0.16, blue: 0.31).opacity(0.08),
        cardBackgroundPressed: Color(red: 0.24, green: 0.16, blue: 0.31).opacity(0.14),
        cardBorder: Color(red: 0.24, green: 0.16, blue: 0.31).opacity(0.15),
        textPrimary: Color(red: 0.24, green: 0.16, blue: 0.31),    // #3D2850
        textSecondary: Color(red: 0.24, green: 0.16, blue: 0.31).opacity(0.65),
        textTertiary: Color(red: 0.24, green: 0.16, blue: 0.31).opacity(0.45),
        accentCorrect: Color(red: 0.25, green: 0.68, blue: 0.42),
        accentWrong: Color(red: 0.85, green: 0.30, blue: 0.35),
        accentWeak: Color(red: 0.90, green: 0.55, blue: 0.15),
        accentPrimary: Color(red: 0.75, green: 0.40, blue: 0.70),
        shadowGlowColor: Color(red: 0.75, green: 0.40, blue: 0.70).opacity(0.3)
    )
}
