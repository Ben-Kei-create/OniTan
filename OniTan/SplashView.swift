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
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.10, blue: 0.30),
                    Color(red: 0.20, green: 0.05, blue: 0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Decorative background kanji
            Text("鬼")
                .font(.system(size: 320, weight: .black))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.60, green: 0.20, blue: 0.80).opacity(0.18),
                            Color(red: 0.38, green: 0.32, blue: 0.90).opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blur(radius: 4)
                .scaleEffect(bgKanjiScale)
                .opacity(bgKanjiOpacity)

            // Glow bloom behind title
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.48, green: 0.38, blue: 0.95).opacity(0.45),
                            Color(red: 0.60, green: 0.20, blue: 0.80).opacity(0.0)
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
                Text("OniTan")
                    .font(.system(size: 58, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                .white,
                                Color(red: 0.88, green: 0.82, blue: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color(red: 0.48, green: 0.38, blue: 0.95).opacity(0.9), radius: 24, y: 4)
                    .scaleEffect(titleScale)
                    .opacity(titleOpacity)

                Text("KANJI STUDY")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .tracking(5)
                    .foregroundColor(Color(red: 0.72, green: 0.62, blue: 1.0))
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
