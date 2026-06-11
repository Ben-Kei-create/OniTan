import SwiftUI

struct SplashView: View {
    let onComplete: () -> Void

    @State private var sealOpacity: Double = 0
    @State private var sealScale: CGFloat = 1.18
    @State private var sealRotation: Double = -2.5
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0

    var body: some View {
        ZStack {
            OniTanTheme.inkGradient
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Text("鬼")
                    .font(.system(size: 76, weight: .black, design: .serif))
                    .foregroundColor(OniTanTheme.washiText)
                    .frame(width: 118, height: 118)
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(OniTanTheme.sealRed.opacity(0.94))
                            .overlay(
                                RoundedRectangle(cornerRadius: 22)
                                    .stroke(OniTanTheme.washiText.opacity(0.26), lineWidth: 2)
                            )
                    )
                    .rotationEffect(.degrees(sealRotation))
                    .scaleEffect(sealScale)
                    .opacity(sealOpacity)
                    .shadow(color: OniTanTheme.sealRed.opacity(0.28), radius: 18, y: 8)

                Text("鬼単")
                    .font(.system(size: 28, weight: .black, design: .serif))
                    .foregroundColor(OniTanTheme.textPrimary)
                    .opacity(titleOpacity)

                Text("漢字検定準1級 対策")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(OniTanTheme.textSecondary)
                    .opacity(subtitleOpacity)
            }
        }
        .onAppear { runAnimation() }
    }

    private func runAnimation() {
        withAnimation(.spring(response: 0.26, dampingFraction: 0.58)) {
            sealOpacity = 1
            sealScale = 1.0
            sealRotation = -1
        }
        OniTanTheme.haptic(.light)

        withAnimation(.easeOut(duration: 0.35).delay(0.18)) {
            titleOpacity = 1
        }

        withAnimation(.easeOut(duration: 0.35).delay(0.34)) {
            subtitleOpacity = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.35) {
            onComplete()
        }
    }
}
