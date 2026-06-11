import SwiftUI

// MARK: - Design System for OniTan
// Single source of truth for colors, gradients, typography, and spacing.
// All Views should reference these tokens instead of hardcoded values.
// Delegates to ThemeManager.shared.palette for theme-aware colors.

enum OniTanTheme {

    private static var p: ThemePalette { ThemeManager.shared.palette }

    // MARK: - Gradients

    static var backgroundGradientFallback: LinearGradient { p.backgroundGradient }

    static var correctGradient: LinearGradient { p.correctGradient }

    static var wrongGradient: LinearGradient { p.wrongGradient }

    static var primaryGradient: LinearGradient { p.primaryGradient }

    static var goldGradient: LinearGradient { p.goldGradient }

    /// Alias for the wrong/danger (red) gradient — used for warnings & oni accents.
    static var dangerGradient: LinearGradient { p.wrongGradient }

    // MARK: - Colors (semantic)

    static var cardBackground: Color { p.cardBackground }
    static var cardBackgroundPressed: Color { p.cardBackgroundPressed }
    static var cardBorder: Color { p.cardBorder }

    static var textPrimary: Color { p.textPrimary }
    static var textSecondary: Color { p.textSecondary }
    static var textTertiary: Color { p.textTertiary }

    static var accentCorrect: Color { p.accentCorrect }
    static var accentWrong: Color { p.accentWrong }
    static var accentWeak: Color { p.accentWeak }
    static var accentPrimary: Color { p.accentPrimary }

    // MARK: - Corner Radius

    static let radiusCard: CGFloat    = 18
    static let radiusButton: CGFloat  = 14
    static let radiusBadge: CGFloat   = 10

    // MARK: - Shadow

    static var shadowCard: (color: Color, radius: CGFloat, y: CGFloat) {
        (color: Color.black.opacity(0.34), radius: 14, y: 7)
    }
    static var shadowGlow: (color: Color, radius: CGFloat, y: CGFloat) {
        (color: p.shadowGlowColor, radius: 16, y: 0)
    }

    // MARK: - Haptics

    static func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    static func hapticSuccess() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func hapticError() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}

// MARK: - Modifier: Card

struct CardModifier: ViewModifier {
    var pressed: Bool = false

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: OniTanTheme.radiusCard)
                    .fill(pressed ? OniTanTheme.cardBackgroundPressed : OniTanTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: OniTanTheme.radiusCard)
                            .stroke(OniTanTheme.cardBorder, lineWidth: 1)
                    )
            )
            .shadow(
                color: OniTanTheme.shadowCard.color,
                radius: OniTanTheme.shadowCard.radius,
                y: OniTanTheme.shadowCard.y
            )
    }
}

extension View {
    func oniCard(pressed: Bool = false) -> some View {
        modifier(CardModifier(pressed: pressed))
    }
}

// MARK: - Modifier: Full-screen gradient background

struct OniBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            OniTanTheme.backgroundGradientFallback
                .ignoresSafeArea()
            content
        }
    }
}

extension View {
    func oniBackground() -> some View {
        modifier(OniBackgroundModifier())
    }
}

// MARK: - Color Hex Init

extension Color {
    init(hex: String) {
        var cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        if cleaned.isEmpty { cleaned = "888888" }
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
