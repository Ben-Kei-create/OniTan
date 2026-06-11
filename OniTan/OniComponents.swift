import SwiftUI

// MARK: - OniGlassCard
//
// Premium glassmorphism card: translucent dark fill, thin border, soft shadow.
// Use instead of ad-hoc `.background(...)` blocks for new UI surfaces.

struct OniGlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = OniTanTheme.radiusCard
    var borderColor: Color = OniTanTheme.cardBorder
    var glow: Bool = false

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(OniTanTheme.cardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(borderColor, lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.30), radius: 14, y: 8)
            .shadow(
                color: glow ? OniTanTheme.shadowGlow.color : .clear,
                radius: glow ? OniTanTheme.shadowGlow.radius : 0
            )
    }
}

extension View {
    /// Applies the standard OniTan glass card background + border + shadow.
    func oniGlassCard(cornerRadius: CGFloat = OniTanTheme.radiusCard,
                       borderColor: Color = OniTanTheme.cardBorder,
                       glow: Bool = false) -> some View {
        modifier(OniGlassCardModifier(cornerRadius: cornerRadius, borderColor: borderColor, glow: glow))
    }
}

// MARK: - OniGoldButton
//
// Primary call-to-action button style: gold gradient fill, dark text, soft glow.

struct OniGoldButtonStyle: ButtonStyle {
    var fullWidth: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundColor(Color(hex: "1A1308"))
            .padding(.vertical, 14)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(
                RoundedRectangle(cornerRadius: OniTanTheme.radiusButton)
                    .fill(OniTanTheme.goldGradient)
            )
            .shadow(color: OniTanTheme.shadowGlow.color, radius: 10, y: 4)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == OniGoldButtonStyle {
    static var oniGold: OniGoldButtonStyle { OniGoldButtonStyle() }
    static func oniGold(fullWidth: Bool) -> OniGoldButtonStyle { OniGoldButtonStyle(fullWidth: fullWidth) }
}

// MARK: - OniProgressBar
//
// Thin horizontal progress bar with a gold/purple gradient fill and a
// subtle track. Used for quiz progress and exam accuracy indicators.

struct OniProgressBar: View {
    let progress: Double   // 0.0 - 1.0
    var height: CGFloat = 6
    var gradient: LinearGradient = OniTanTheme.goldGradient

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(OniTanTheme.cardBackground)
                    .overlay(Capsule().stroke(OniTanTheme.cardBorder, lineWidth: 1))

                Capsule()
                    .fill(gradient)
                    .frame(width: proxy.size.width * max(0, min(1, progress)))
                    .animation(.easeInOut(duration: 0.4), value: progress)
            }
        }
        .frame(height: height)
    }
}

// MARK: - OniBadge
//
// Small rounded capsule badge for question kind / category tags.

struct OniBadge: View {
    let text: String
    var systemImage: String? = nil
    var tint: Color = OniTanTheme.accentPrimary

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 10, weight: .semibold))
            }
            Text(text)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
        }
        .foregroundColor(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(tint.opacity(0.14))
                .overlay(Capsule().stroke(tint.opacity(0.35), lineWidth: 1))
        )
    }
}

// MARK: - OniSectionHeader
//
// Standard section title used to introduce dojo / dashboard sections.

struct OniSectionHeader: View {
    let title: String
    var systemImage: String? = nil
    var trailingText: String? = nil

    var body: some View {
        HStack(spacing: 8) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(OniTanTheme.accentWeak)
            }
            Text(title)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(OniTanTheme.textPrimary)

            Spacer()

            if let trailingText {
                Text(trailingText)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(OniTanTheme.textTertiary)
            }
        }
    }
}

// MARK: - OniMetricCard
//
// Compact card showing a single labelled metric (e.g. 推定得点 153 / 200).

struct OniMetricCard: View {
    let title: String
    let value: String
    var unit: String? = nil
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(OniTanTheme.textTertiary)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundColor(OniTanTheme.textPrimary)
                if let unit {
                    Text(unit)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(OniTanTheme.textTertiary)
                }
            }

            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundColor(OniTanTheme.textTertiary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .oniGlassCard()
    }
}
