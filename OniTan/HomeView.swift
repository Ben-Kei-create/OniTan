import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState

    @State private var titleScale: CGFloat = 0.8
    @State private var titleOpacity: Double = 0
    @State private var buttonsOffset: CGFloat = 40
    @State private var buttonsOpacity: Double = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: OniTheme.Spacing.xl) {
                Spacer()

                // Title with entrance animation
                VStack(spacing: OniTheme.Spacing.sm) {
                    Text("鬼単")
                        .font(.system(size: 80, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [OniTheme.Colors.quizBlue, Color.purple.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("漢字クイズで力試し")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .scaleEffect(titleScale)
                .opacity(titleOpacity)

                Spacer()

                // Buttons with slide-up animation
                VStack(spacing: OniTheme.Spacing.md) {
                    NavigationLink(destination: StageSelectView()) {
                        HStack(spacing: OniTheme.Spacing.sm) {
                            Image(systemName: "play.fill")
                            Text("スタート")
                        }
                        .primaryButton(color: OniTheme.Colors.quizBlue)
                    }

                    NavigationLink(destination: SettingsView()) {
                        HStack(spacing: OniTheme.Spacing.sm) {
                            Image(systemName: "gearshape.fill")
                            Text("設定")
                        }
                        .primaryButton(color: OniTheme.Colors.locked)
                    }
                }
                .padding(.horizontal, OniTheme.Spacing.xl)
                .offset(y: buttonsOffset)
                .opacity(buttonsOpacity)

                Spacer()
            }
            .navigationBarHidden(true)
            .gradientBackground()
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                    titleScale = 1.0
                    titleOpacity = 1.0
                }
                withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                    buttonsOffset = 0
                    buttonsOpacity = 1.0
                }
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(AppState())
    }
}
