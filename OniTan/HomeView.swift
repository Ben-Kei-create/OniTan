import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var statsRepo: StudyStatsRepository

    private let totalStages = quizData.stages.count

    var body: some View {
        NavigationStack {
            ZStack {
                OniTanTheme.backgroundGradientFallback
                    .ignoresSafeArea()

                // Data load error banner (non-fatal)
                if let loadError = dataLoadError {
                    dataErrorBanner(loadError)
                }

                VStack(spacing: 0) {
                    headerSection
                    Spacer()
                    menuSection
                    Spacer()
                    footerSection
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 40)
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 16) {
            // App logo / title
            Text("鬼単")
                .font(.system(size: 88, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, Color(red: 0.75, green: 0.65, blue: 1.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .purple.opacity(0.5), radius: 16, y: 8)
                .accessibilityLabel("鬼単アプリ")

            Text("漢字検定準1級 対策")
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(OniTanTheme.textSecondary)
                .accessibilityHidden(true)

            // Overall achievement ring
            overallProgressRing
        }
        .padding(.top, 8)
    }

    private var overallProgressRing: some View {
        let progress = appState.overallProgress(totalStages: totalStages)
        let cleared = appState.clearedStages.count

        return VStack(spacing: 8) {
            ProgressRingView(
                progress: progress,
                lineWidth: 10,
                size: 80,
                gradient: Gradient(colors: [OniTanTheme.accentPrimary, OniTanTheme.accentCorrect])
            )
            .shadow(color: OniTanTheme.accentPrimary.opacity(0.4), radius: 12)

            Text("\(cleared) / \(totalStages) ステージクリア")
                .font(.system(.caption, design: .rounded))
                .foregroundColor(OniTanTheme.textSecondary)
        }
        .accessibilityElement()
        .accessibilityLabel("達成率: \(cleared)ステージ中\(totalStages)クリア済み")
    }

    // MARK: - Menu

    private var menuSection: some View {
        VStack(spacing: 16) {
            HomeMenuButton(
                title: "スタート",
                subtitle: "ステージを選んで学習",
                icon: "books.vertical.fill",
                gradient: OniTanTheme.primaryGradient,
                destination: StageSelectView()
            )

            HomeMenuButton(
                title: "誤答ノート",
                subtitle: "間違えた漢字を復習",
                icon: "exclamationmark.triangle.fill",
                gradient: LinearGradient(
                    colors: [OniTanTheme.accentWeak, Color(red: 0.9, green: 0.4, blue: 0.0)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                destination: WrongAnswerNoteView()
            )

            HStack(spacing: 16) {
                HomeMenuButton(
                    title: "統計",
                    subtitle: nil,
                    icon: "chart.bar.fill",
                    gradient: LinearGradient(
                        colors: [Color(red: 0.3, green: 0.5, blue: 0.9), Color(red: 0.2, green: 0.4, blue: 0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    destination: StatsView()
                )

                HomeMenuButton(
                    title: "設定",
                    subtitle: nil,
                    icon: "gearshape.fill",
                    gradient: LinearGradient(
                        colors: [Color(red: 0.4, green: 0.4, blue: 0.5), Color(red: 0.3, green: 0.3, blue: 0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    destination: SettingsView()
                )
            }
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        Group {
            if statsRepo.totalCorrect > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(OniTanTheme.accentWeak)
                        .font(.caption)
                    Text("通算正解 \(statsRepo.totalCorrect) 問")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(OniTanTheme.textTertiary)
                }
                .accessibilityElement()
                .accessibilityLabel("通算正解数: \(statsRepo.totalCorrect)問")
            }
        }
    }

    // MARK: - Error Banner

    private func dataErrorBanner(_ error: DataLoadError) -> some View {
        VStack {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.yellow)
                Text(error.localizedDescription ?? "データ読み込みエラー")
                    .font(.caption)
                    .foregroundColor(.white)
                    .lineLimit(2)
            }
            .padding(12)
            .background(Color.red.opacity(0.8))
            .cornerRadius(10)
            .padding(.horizontal)

            Spacer()
        }
        .padding(.top, 8)
        .zIndex(1)
    }
}

// MARK: - Home Menu Button

private struct HomeMenuButton<Destination: View>: View {
    let title: String
    let subtitle: String?
    let icon: String
    let gradient: LinearGradient
    let destination: Destination

    @State private var isPressed = false

    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    if let subtitle {
                        Text(subtitle)
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.white.opacity(0.75))
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(gradient)
            .cornerRadius(OniTanTheme.radiusCard)
            .shadow(
                color: OniTanTheme.shadowCard.color,
                radius: OniTanTheme.shadowCard.radius,
                y: OniTanTheme.shadowCard.y
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: isPressed)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(subtitle != nil ? "\(title): \(subtitle!)" : title)
        .accessibilityHint("タップして\(title)へ進む")
    }
}
