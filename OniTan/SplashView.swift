import SwiftUI

struct SplashView: View {
    let onComplete: () -> Void

    @State private var titleOpacity: Double = 0
    @State private var titleScale: CGFloat = 0.65
    @State private var subtitleOpacity: Double = 0
    @State private var glowOpacity: Double = 0
    @State private var glowRadius: CGFloat = 0
    @State private var bgKanjiOpacity: Double = 0
    @State private var bgKanjiScale: CGFloat = 1.5

    var body: some View {
        ZStack {
            OniTanTheme.backgroundGradientFallback
                .ignoresSafeArea()

            // Decorative background kanji — smouldering oni-red glow
            Text("鬼")
                .font(.system(size: 320, weight: .black))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(hex: "B3192B").opacity(0.22),
                            Color(hex: "D8B45A").opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blur(radius: 4)
                .scaleEffect(bgKanjiScale)
                .opacity(bgKanjiOpacity)

            // Glow bloom behind title — gold
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "E8C66A").opacity(0.40),
                            Color(hex: "E8C66A").opacity(0.0)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 140
                    )
                )
                .frame(width: 280, height: 280)
                .blur(radius: glowRadius)
                .opacity(glowOpacity)

            VStack(spacing: 10) {
                Text("鬼単")
                    .font(.system(size: 44, weight: .black, design: .serif))
                    .foregroundStyle(OniTanTheme.goldGradient)
                    .shadow(color: Color(hex: "E8C66A").opacity(0.8), radius: 20, y: 4)
                    .scaleEffect(titleScale)
                    .opacity(titleOpacity)

                Text("OniTan")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundColor(OniTanTheme.textPrimary)
                    .opacity(titleOpacity)

                Text("漢検準一級・鬼の修練場")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .tracking(5)
                    .foregroundColor(OniTanTheme.textTertiary)
                    .opacity(subtitleOpacity)
            }
        }
        .onAppear { runAnimation() }
    }

    private func runAnimation() {
        // Background kanji drifts in
        withAnimation(.easeOut(duration: 1.0)) {
            bgKanjiOpacity = 1
            bgKanjiScale = 1.0
        }

        // Glow blooms
        withAnimation(.easeOut(duration: 1.0).delay(0.1)) {
            glowOpacity = 1
            glowRadius = 30
        }

        // Title springs up
        withAnimation(.spring(response: 0.55, dampingFraction: 0.68).delay(0.18)) {
            titleOpacity = 1
            titleScale = 1.0
        }

        // Subtitle fades in
        withAnimation(.easeOut(duration: 0.45).delay(0.52)) {
            subtitleOpacity = 1
        }

        // Dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.9) {
            onComplete()
        }
    }
}
