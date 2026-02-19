import SwiftUI

// MARK: - Design System for OniTan
// Single source of truth for colors, gradients, typography, and spacing.
// All Views should reference these tokens instead of hardcoded values.

enum OniTanTheme {

    // MARK: - Gradients

    static let backgroundGradient = LinearGradient(
        colors: [Color("GradientTop"), Color("GradientBottom")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let backgroundGradientFallback = LinearGradient(
        colors: [
            Color(red: 0.10, green: 0.10, blue: 0.30),
            Color(red: 0.20, green: 0.05, blue: 0.25)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let correctGradient = LinearGradient(
        colors: [Color(red: 0.13, green: 0.70, blue: 0.45), Color(red: 0.10, green: 0.55, blue: 0.35)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let wrongGradient = LinearGradient(
        colors: [Color(red: 0.85, green: 0.22, blue: 0.22), Color(red: 0.70, green: 0.12, blue: 0.15)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let primaryGradient = LinearGradient(
        colors: [Color(red: 0.38, green: 0.32, blue: 0.90), Color(red: 0.60, green: 0.20, blue: 0.80)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let goldGradient = LinearGradient(
        colors: [Color(red: 1.0, green: 0.80, blue: 0.10), Color(red: 0.95, green: 0.60, blue: 0.05)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Colors (semantic)

    static let cardBackground = Color.white.opacity(0.12)
    static let cardBackgroundPressed = Color.white.opacity(0.22)
    static let cardBorder = Color.white.opacity(0.25)

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.70)
    static let textTertiary = Color.white.opacity(0.50)

    static let accentCorrect = Color(red: 0.13, green: 0.70, blue: 0.45)
    static let accentWrong   = Color(red: 0.85, green: 0.22, blue: 0.22)
    static let accentWeak    = Color(red: 1.00, green: 0.60, blue: 0.10)
    static let accentPrimary = Color(red: 0.48, green: 0.38, blue: 0.95)

    // MARK: - Corner Radius

    static let radiusCard: CGFloat    = 20
    static let radiusButton: CGFloat  = 16
    static let radiusBadge: CGFloat   = 12

    // MARK: - Shadow

    static let shadowCard  = (color: Color.black.opacity(0.25), radius: CGFloat(12), y: CGFloat(6))
    static let shadowGlow  = (color: Color.purple.opacity(0.4), radius: CGFloat(20), y: CGFloat(0))

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
