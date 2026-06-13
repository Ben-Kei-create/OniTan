import SwiftUI
import UIKit

// MARK: - Artwork Assets

enum OniArtworkAsset {
    static let splash = "OniSplashIllustration"
    static let home = "OniHomeIllustration"
}

struct OniOptionalArtwork<Fallback: View>: View {
    let assetName: String
    let width: CGFloat
    let height: CGFloat
    let fallback: () -> Fallback

    init(
        assetName: String,
        width: CGFloat,
        height: CGFloat,
        @ViewBuilder fallback: @escaping () -> Fallback
    ) {
        self.assetName = assetName
        self.width = width
        self.height = height
        self.fallback = fallback
    }

    var body: some View {
        if UIImage(named: assetName) != nil {
            Image(assetName)
                .resizable()
                .scaledToFit()
                .frame(width: width, height: height)
                .accessibilityHidden(true)
        } else {
            fallback()
        }
    }
}

// MARK: - OniSealMark
//
// Square kanji seal used instead of SF Symbols for primary navigation marks.

struct OniSealMark: View {
    let text: String
    var size: CGFloat = 48
    var fontSize: CGFloat = 22
    var tint: Color = OniTanTheme.accentWeak
    var fillOpacity: Double = 0.14
    var cornerRadius: CGFloat = 12

    var body: some View {
        Text(text)
            .font(.system(size: fontSize, weight: .black, design: .serif))
            .foregroundColor(tint)
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(tint.opacity(fillOpacity))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(tint.opacity(0.34), lineWidth: 1)
                    )
            )
            .accessibilityHidden(true)
    }
}

extension QuizMode {
    var sealMark: String {
        switch self {
        case .normal: return "道"
        case .quick10: return "十"
        case .exam30: return "試"
        case .weakFocus: return "誤"
        }
    }
}

extension TrainingMode {
    var sealMark: String {
        switch self {
        case .normal: return "道"
        case .quick10: return "十"
        case .categoryFocus: return "道"
        case .weakFocus: return "弱"
        case .mistakeReview: return "誤"
        case .masteryReview: return "定"
        case .examMini, .examFull: return "試"
        case .finalBoss: return "鬼"
        }
    }
}

extension QuestionKind {
    var sealMark: String {
        switch self {
        case .reading, .sentenceReading, .hyogaiReading, .compoundReadingKun:
            return "読"
        case .commonKanji:
            return "共"
        case .errorCorrection:
            return "訂"
        case .yojijukugo:
            return "熟"
        case .synonym, .antonym:
            return "対"
        case .proverb:
            return "諺"
        case .passageReading, .passageVocabulary:
            return "文"
        case .writingSkipped:
            return "書"
        case .unknown:
            return "?"
        }
    }
}

extension CategoryEntry {
    var sealMark: String {
        switch id {
        case "reading": return "読"
        case "commonKanji": return "共"
        case "errorCorrection": return "訂"
        case "yojijukugo": return "熟"
        case "synonym_antonym": return "対"
        case "proverb": return "諺"
        case "passage": return "文"
        default: return String(title.prefix(1))
        }
    }
}

// MARK: - OniGlassCard
//
// Premium ink card: translucent dark fill, thin gold hairline, soft shadow.
// Use instead of ad-hoc `.background(...)` blocks for new UI surfaces.

struct OniGlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = OniTanTheme.radiusCard
    var borderColor: Color = OniTanTheme.cardBorder
    var glow: Bool = false

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.black.opacity(0.16))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(OniTanTheme.cardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(borderColor, lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.36), radius: 14, y: 8)
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
// Primary call-to-action button style: vermilion fill with ivory text.

struct OniGoldButtonStyle: ButtonStyle {
    var fullWidth: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundColor(OniTanTheme.textPrimary)
            .padding(.vertical, 14)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(
                RoundedRectangle(cornerRadius: OniTanTheme.radiusButton)
                    .fill(OniTanTheme.primaryGradient)
            )
            .overlay(
                RoundedRectangle(cornerRadius: OniTanTheme.radiusButton)
                    .stroke(Color(hex: "D8B45A").opacity(0.20), lineWidth: 1)
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
// Thin horizontal progress bar with a gold/vermilion gradient fill and a
// subtle track. Used for quiz progress and exam accuracy indicators.

struct OniProgressBar: View {
    let progress: Double   // 0.0 - 1.0
    var height: CGFloat = 6
    var gradient: LinearGradient = OniTanTheme.goldGradient

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(OniTanTheme.cardBackgroundPressed.opacity(0.7))
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
                .fill(tint.opacity(0.12))
                .overlay(Capsule().stroke(tint.opacity(0.30), lineWidth: 1))
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
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(OniTanTheme.accentWeak)
            }
            Text(title)
                .font(.system(size: 15, weight: .bold, design: .rounded))
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
                .font(.system(size: 24, weight: .black, design: .rounded))
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
