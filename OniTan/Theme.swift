import SwiftUI

// MARK: - Design System

enum OniTheme {
    // MARK: - Colors
    enum Colors {
        static let primary = Color("AccentColor")
        static let quizBlue = Color(red: 0.25, green: 0.48, blue: 0.85)
        static let success = Color(red: 0.20, green: 0.78, blue: 0.45)
        static let danger = Color(red: 0.90, green: 0.30, blue: 0.30)
        static let warning = Color(red: 0.95, green: 0.60, blue: 0.20)
        static let locked = Color(red: 0.60, green: 0.60, blue: 0.65)

        static let backgroundGradientStart = Color(red: 0.22, green: 0.40, blue: 0.80).opacity(0.15)
        static let backgroundGradientEnd = Color(red: 0.55, green: 0.30, blue: 0.75).opacity(0.10)

        static let cardBackground = Color(.systemBackground)
        static let overlayBackground = Color.black.opacity(0.6)
        static let subtleBackground = Color(.secondarySystemBackground)
    }

    // MARK: - Spacing
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: - Corner Radius
    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let pill: CGFloat = 50
    }

    // MARK: - Shadow
    static func shadow(color: Color = .black.opacity(0.12), radius: CGFloat = 8, y: CGFloat = 4) -> some ViewModifier {
        ShadowModifier(color: color, radius: radius, y: y)
    }
}

// MARK: - View Modifiers

struct ShadowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat
    let y: CGFloat

    func body(content: Content) -> some View {
        content.shadow(color: color, radius: radius, x: 0, y: y)
    }
}

struct PrimaryButtonStyle: ViewModifier {
    let backgroundColor: Color
    let minHeight: CGFloat

    init(backgroundColor: Color = OniTheme.Colors.quizBlue, minHeight: CGFloat = 56) {
        self.backgroundColor = backgroundColor
        self.minHeight = minHeight
    }

    func body(content: Content) -> some View {
        content
            .font(.title3.weight(.bold))
            .frame(maxWidth: .infinity, minHeight: minHeight)
            .background(backgroundColor)
            .foregroundColor(.white)
            .cornerRadius(OniTheme.Radius.lg)
            .shadow(color: backgroundColor.opacity(0.35), radius: 8, x: 0, y: 6)
    }
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(OniTheme.Colors.cardBackground)
            .cornerRadius(OniTheme.Radius.lg)
            .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
    }
}

struct GradientBackground: ViewModifier {
    func body(content: Content) -> some View {
        content.background(
            LinearGradient(
                gradient: Gradient(colors: [
                    OniTheme.Colors.backgroundGradientStart,
                    OniTheme.Colors.backgroundGradientEnd
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
        )
    }
}

// MARK: - View Extensions

extension View {
    func primaryButton(color: Color = OniTheme.Colors.quizBlue, minHeight: CGFloat = 56) -> some View {
        modifier(PrimaryButtonStyle(backgroundColor: color, minHeight: minHeight))
    }

    func cardStyle() -> some View {
        modifier(CardStyle())
    }

    func gradientBackground() -> some View {
        modifier(GradientBackground())
    }
}
