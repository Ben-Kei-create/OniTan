import SwiftUI

// MARK: - DailySummaryView

/// Full-screen celebration shown once per day when the user completes
/// today's daily goal ("今日のノルマ達成").
struct DailySummaryView: View {
    let streak: Int
    let isNewLongestStreak: Bool
    let answeredToday: Int
    let xpEarnedToday: Int
    let onDismiss: () -> Void

    @State private var sealOpacity: Double = 0
    @State private var sealScale: CGFloat = 0.6
    @State private var contentOpacity: Double = 0

    var body: some View {
        ZStack {
            OniTanTheme.inkGradient.ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(OniTanTheme.accentCorrect.opacity(0.18))
                        .frame(width: 140, height: 140)
                        .blur(radius: 20)

                    Image(systemName: "flame.fill")
                        .font(.system(size: 56, weight: .bold))
                        .foregroundStyle(OniTanTheme.goldGradient)
                        .shadow(color: OniTanTheme.accentWeak.opacity(0.5), radius: 12)
                        .accessibilityHidden(true)
                }
                .scaleEffect(sealScale)
                .opacity(sealOpacity)

                VStack(spacing: 8) {
                    Text("今日のノルマ達成！")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundColor(OniTanTheme.textPrimary)

                    Text("お疲れ様でした。今日も一歩前進です。")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(OniTanTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .opacity(contentOpacity)

                HStack(spacing: 14) {
                    summaryStat(icon: "flame.fill", value: "\(streak)", label: "連続日数", color: OniTanTheme.accentWeak)
                    summaryStat(icon: "checkmark.circle.fill", value: "\(answeredToday)", label: "今日の解答数", color: OniTanTheme.accentCorrect)
                    summaryStat(icon: "star.fill", value: "+\(xpEarnedToday)", label: "獲得XP", color: OniTanTheme.accentWeak)
                }
                .opacity(contentOpacity)

                if isNewLongestStreak && streak > 1 {
                    Text("自己最長記録を更新中！")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(OniTanTheme.accentWeak)
                        .opacity(contentOpacity)
                }

                Spacer()

                Button {
                    OniTanTheme.haptic(.light)
                    onDismiss()
                } label: {
                    Text("閉じる")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(OniTanTheme.textPrimary)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(OniTanTheme.goldGradient)
                        .cornerRadius(OniTanTheme.radiusButton)
                        .shadow(color: OniTanTheme.accentWeak.opacity(0.35), radius: 8, y: 4)
                }
                .opacity(contentOpacity)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .onAppear { runAnimation() }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("今日のノルマ達成。連続\(streak)日、今日の解答数\(answeredToday)問、獲得経験値\(xpEarnedToday)")
    }

    private func summaryStat(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)
                .accessibilityHidden(true)
            Text(value)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundColor(OniTanTheme.textPrimary)
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(OniTanTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(OniTanTheme.inkCard.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(OniTanTheme.cardBorder, lineWidth: 1)
                )
        )
    }

    private func runAnimation() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            sealOpacity = 1
            sealScale = 1.0
        }
        OniTanTheme.hapticSuccess()

        withAnimation(.easeOut(duration: 0.35).delay(0.2)) {
            contentOpacity = 1
        }
    }
}
