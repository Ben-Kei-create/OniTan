import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var statsRepo: StudyStatsRepository
    @EnvironmentObject var streakRepo: StreakRepository
    @EnvironmentObject var xpRepo: GamificationRepository

    @State private var freezeToastVisible = false
    /// Tracks the last freeze-notice ID we showed, so onAppear can catch
    /// a freeze consumed during StreakRepository.init (before onChange fires).
    @State private var lastShownFreezeID: Int = -1

    private let totalStages = quizData.stages.count

    var body: some View {
        NavigationStack {
            ZStack {
                OniTanTheme.backgroundGradientFallback
                    .ignoresSafeArea()

                if let loadError = dataLoadError {
                    dataErrorBanner(loadError)
                }

                ScrollView {
                    VStack(spacing: 0) {
                        headerSection
                            .padding(.top, 40)

                        menuSection
                            .padding(.top, 24)

                        footerSection
                            .padding(.top, 20)
                            .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationBarHidden(true)
            .overlay(alignment: .top) {
                if freezeToastVisible {
                    freezeConsumedToast
                        .padding(.top, 12)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .onAppear {
                // A freeze consumed during StreakRepository.init fires before
                // the view subscribes, so onChange would miss it. Catch it here.
                let current = streakRepo.freezeConsumedNoticeID
                if lastShownFreezeID == -1 {
                    lastShownFreezeID = current
                    if current > 0 { showFreezeToast() }
                }
            }
            .onChange(of: streakRepo.freezeConsumedNoticeID) { newID in
                guard newID != lastShownFreezeID else { return }
                lastShownFreezeID = newID
                showFreezeToast()
            }
        }
    }


    private var freezeConsumedToast: some View {
        HStack(spacing: 8) {
            Image(systemName: "snowflake")
                .foregroundColor(OniTanTheme.accentPrimary)
            Text("ストリーク保護を使って継続しました")
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.45))
                .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
        )
        .accessibilityLabel("ストリーク保護を使用しました")
    }

    private func showFreezeToast() {
        withAnimation(.easeInOut(duration: 0.2)) {
            freezeToastVisible = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.2)) {
                freezeToastVisible = false
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("鬼単")
                .font(.system(size: 80, weight: .black, design: .rounded))
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

            HStack(spacing: 12) {
                streakChip
                xpChip
            }
            .padding(.top, 4)

            overallProgressRing
        }
    }

    // MARK: - Streak Chip

    private var streakChip: some View {
        HStack(spacing: 5) {
            Image(systemName: streakRepo.todayCompleted ? "flame.fill" : "flame")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(streakRepo.currentStreak > 0
                    ? OniTanTheme.accentWeak
                    : .white.opacity(0.4))
                .symbolEffect(.bounce, value: streakRepo.todayCompleted)

            if streakRepo.currentStreak > 0 {
                Text("\(streakRepo.currentStreak)日連続")
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(streakRepo.todayCompleted
                        ? OniTanTheme.accentWeak
                        : .white.opacity(0.7))

                Text("🧊\(streakRepo.freezeCount)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
            } else {
                Text("記録を作ろう")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(streakRepo.todayCompleted
                    ? Color(red: 0.5, green: 0.25, blue: 0.0).opacity(0.55)
                    : Color.white.opacity(0.08))
                .overlay(
                    Capsule()
                        .stroke(
                            streakRepo.currentStreak > 0
                                ? OniTanTheme.accentWeak.opacity(0.4)
                                : Color.white.opacity(0.12),
                            lineWidth: 1
                        )
                )
        )
        .accessibilityElement()
        .accessibilityLabel(streakRepo.currentStreak > 0
            ? "\(streakRepo.currentStreak)日連続学習中。保護\(streakRepo.freezeCount)"
            : "ストリーク未記録。保護\(streakRepo.freezeCount)")
    }

    // MARK: - XP Chip

    private var xpChip: some View {
        HStack(spacing: 5) {
            Image(systemName: "star.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.2))

            Text("Lv.\(xpRepo.level)")
                .font(.system(.caption, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.white)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(LinearGradient(
                            colors: [Color(red: 1.0, green: 0.85, blue: 0.2),
                                     Color(red: 1.0, green: 0.55, blue: 0.0)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(
                            width: geo.size.width * CGFloat(xpRepo.levelProgress),
                            height: 4
                        )
                        .animation(.easeInOut(duration: 0.4), value: xpRepo.levelProgress)
                }
            }
            .frame(width: 44, height: 4)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color(red: 0.35, green: 0.28, blue: 0.05).opacity(0.55))
                .overlay(
                    Capsule()
                        .stroke(Color(red: 1.0, green: 0.85, blue: 0.2).opacity(0.35), lineWidth: 1)
                )
        )
        .accessibilityElement()
        .accessibilityLabel("レベル\(xpRepo.level)、XP\(xpRepo.xpInCurrentLevel)/\(xpRepo.xpToNextLevel)")
    }

    // MARK: - Progress Ring

    private var overallProgressRing: some View {
        let progress = appState.overallProgress(totalStages: totalStages)
        let cleared = appState.clearedStages.count

        return VStack(spacing: 6) {
            ProgressRingView(
                progress: progress,
                lineWidth: 9,
                size: 70,
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
        VStack(spacing: 14) {
            HomeTodayCard()

            HomeMenuButton(
                title: "ステージ選択",
                subtitle: "ステージを選んで学習",
                icon: "books.vertical.fill",
                gradient: OniTanTheme.primaryGradient,
                destination: StageSelectView()
            )

            HomeMenuButton(
                title: "誤答ノート",
                subtitle: "間違えた漢字を復習 → XP獲得",
                icon: "exclamationmark.triangle.fill",
                gradient: LinearGradient(
                    colors: [OniTanTheme.accentWeak, Color(red: 0.9, green: 0.4, blue: 0.0)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                destination: WrongAnswerNoteView()
            )

            HStack(spacing: 14) {
                HomeMenuButton(
                    title: "統計",
                    subtitle: nil,
                    icon: "chart.bar.fill",
                    gradient: LinearGradient(
                        colors: [Color(red: 0.3, green: 0.5, blue: 0.9),
                                 Color(red: 0.2, green: 0.4, blue: 0.7)],
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
                        colors: [Color(red: 0.4, green: 0.4, blue: 0.5),
                                 Color(red: 0.3, green: 0.3, blue: 0.4)],
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

// MARK: - Today Card

private struct HomeTodayCard: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var statsRepo: StudyStatsRepository
    @EnvironmentObject var streakRepo: StreakRepository
    @EnvironmentObject var xpRepo: GamificationRepository

    @State private var isPressed = false

    /// Today stage is built lazily when NavigationLink destination is created.
    private var todayStage: Stage {
        TodaySessionBuilder.buildTodayStage(
            allStages: quizData.stages,
            statsRepo: statsRepo,
            clearedStages: appState.clearedStages
        )
    }

    var body: some View {
        NavigationLink(
            destination: MainView(
                stage: todayStage,
                appState: appState,
                statsRepo: statsRepo,
                streakRepo: streakRepo,
                xpRepo: xpRepo,
                mode: .quick10,
                clearTitle: "今日の10問 完了！"
            )
        ) {
            cardContent
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.easeInOut(duration: 0.12), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(streakRepo.todayCompleted
            ? "今日の10問 完了済み。もう一度挑戦できます"
            : "今日の10問 弱点強化と新規問題ミックス。ワンタップで開始")
        .accessibilityHint("タップして今日の10問を開始")
        .accessibilityIdentifier("home_today_card")
    }

    private var cardContent: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 52, height: 52)

                Image(systemName: streakRepo.todayCompleted ? "checkmark.seal.fill" : "bolt.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                    .symbolEffect(.bounce, value: streakRepo.todayCompleted)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("今日の10問")
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.black)
                        .foregroundColor(.white)

                    if streakRepo.todayCompleted {
                        Text("達成！")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.25))
                            .cornerRadius(6)
                    }
                }

                Text(streakRepo.todayCompleted
                     ? "本日の目標クリア 🎉 もう一度やる？"
                     : "弱点優先 + 新規問題 ・ ワンタップで開始")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.white.opacity(0.80))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.65))
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(cardGradient)
        .cornerRadius(OniTanTheme.radiusCard)
        .shadow(
            color: (streakRepo.todayCompleted
                ? OniTanTheme.accentCorrect
                : OniTanTheme.accentWeak).opacity(0.45),
            radius: 14,
            y: 6
        )
    }

    private var cardGradient: LinearGradient {
        if streakRepo.todayCompleted {
            return LinearGradient(
                colors: [Color(red: 0.10, green: 0.55, blue: 0.30),
                         Color(red: 0.08, green: 0.40, blue: 0.22)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        return LinearGradient(
            colors: [Color(red: 0.95, green: 0.55, blue: 0.05),
                     Color(red: 0.80, green: 0.30, blue: 0.0)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
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
        .accessibilityIdentifier("home_menu_\(title)")
    }
}
