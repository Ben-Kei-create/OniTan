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

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let contentMinHeight = proxy.size.height - proxy.safeAreaInsets.top - proxy.safeAreaInsets.bottom
                let isCompactHeight = contentMinHeight < 760
                let contentWidth = min(proxy.size.width - (isCompactHeight ? 16 : 20), 560)
                let verticalInset: CGFloat = isCompactHeight ? 8 : 14

                ZStack {
                    OniTanTheme.backgroundGradientFallback
                        .ignoresSafeArea()

                    if let loadError = dataLoadError {
                        dataErrorBanner(loadError)
                    }

                    VStack(spacing: 0) {
                        headerSection(isCompact: isCompactHeight)
                            .padding(.top, isCompactHeight ? 2 : 6)

                        menuSection(isCompact: isCompactHeight)
                            .padding(.top, isCompactHeight ? 8 : 12)

                        footerSection
                            .padding(.top, isCompactHeight ? 6 : 10)
                    }
                    .frame(maxWidth: contentWidth)
                    .padding(.vertical, verticalInset)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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

    private func headerSection(isCompact: Bool) -> some View {
        VStack(spacing: isCompact ? 6 : 10) {
            HStack(spacing: isCompact ? 8 : 10) {
                Spacer()

                HomeHeaderIconButton(
                    icon: "chart.bar.fill",
                    accessibilityTitle: "統計",
                    compact: isCompact,
                    destination: StatsView()
                )

                HomeHeaderIconButton(
                    icon: "gearshape.fill",
                    accessibilityTitle: "設定",
                    compact: isCompact,
                    destination: SettingsView()
                )
            }

            Text("鬼単")
                .font(.system(size: isCompact ? 60 : 74, weight: .black, design: .rounded))
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
                .font(.system(size: isCompact ? 14 : 16, weight: .regular, design: .rounded))
                .foregroundColor(OniTanTheme.textSecondary)
                .accessibilityHidden(true)

            HStack(spacing: 12) {
                streakChip
                xpChip
            }
            .padding(.top, isCompact ? 1 : 3)
        }
    }

    // MARK: - Streak Chip

    private var streakChip: some View {
        HStack(spacing: 5) {
            if #available(iOS 17.0, *) {
                Image(systemName: streakRepo.todayCompleted ? "flame.fill" : "flame")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(streakRepo.currentStreak > 0
                        ? OniTanTheme.accentWeak
                        : .white.opacity(0.4))
                    .symbolEffect(.bounce, value: streakRepo.todayCompleted)
            } else {
                Image(systemName: streakRepo.todayCompleted ? "flame.fill" : "flame")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(streakRepo.currentStreak > 0
                        ? OniTanTheme.accentWeak
                        : .white.opacity(0.4))
            }

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
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
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
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
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

    // MARK: - Menu

    private func menuSection(isCompact: Bool) -> some View {
        VStack(spacing: isCompact ? 8 : 10) {
            HomeTodayCard(compact: isCompact)

            HomeMenuButton(
                title: "ステージ選択",
                icon: "books.vertical.fill",
                gradient: OniTanTheme.primaryGradient,
                compact: isCompact,
                destination: StageSelectView()
            )

            HomeMenuButton(
                title: "誤答ノート",
                icon: "exclamationmark.triangle.fill",
                gradient: LinearGradient(
                    colors: [OniTanTheme.accentWeak, Color(red: 0.9, green: 0.4, blue: 0.0)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                compact: isCompact,
                destination: WrongAnswerNoteView()
            )
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
                Text(error.localizedDescription)
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
    let compact: Bool

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
            : "今日の10問を開始")
        .accessibilityHint("タップして今日の10問を開始")
        .accessibilityIdentifier("home_today_card")
    }

    private var cardContent: some View {
        HStack(spacing: compact ? 10 : 12) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: compact ? 38 : 42, height: compact ? 38 : 42)

                if #available(iOS 17.0, *) {
                    Image(systemName: streakRepo.todayCompleted ? "checkmark.seal.fill" : "bolt.fill")
                        .font(.system(size: compact ? 16 : 18, weight: .semibold))
                        .foregroundColor(.white)
                        .symbolEffect(.bounce, value: streakRepo.todayCompleted)
                } else {
                    Image(systemName: streakRepo.todayCompleted ? "checkmark.seal.fill" : "bolt.fill")
                        .font(.system(size: compact ? 16 : 18, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .accessibilityHidden(true)

            HStack(spacing: 6) {
                Text("今日の10問")
                    .font(.system(size: compact ? 15 : 16, weight: .black, design: .rounded))
                    .fontWeight(.black)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                if streakRepo.todayCompleted {
                    Text("達成！")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.25))
                        .cornerRadius(6)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: compact ? 12 : 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.65))
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, compact ? 13 : 15)
        .padding(.vertical, compact ? 9 : 11)
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

// MARK: - Header Icon Button

private struct HomeHeaderIconButton<Destination: View>: View {
    let icon: String
    let accessibilityTitle: String
    let compact: Bool
    let destination: Destination

    @State private var isPressed = false

    var body: some View {
        NavigationLink(destination: destination) {
            Image(systemName: icon)
                .font(.system(size: compact ? 16 : 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: compact ? 38 : 40, height: compact ? 38 : 40)
                .background(
                    Circle()
                        .fill(Color.white.opacity(isPressed ? 0.26 : 0.18))
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.22), lineWidth: 1)
                        )
                )
                .shadow(color: .black.opacity(0.24), radius: 6, y: 3)
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.12), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityLabel(accessibilityTitle)
        .accessibilityHint("タップして\(accessibilityTitle)へ進む")
        .accessibilityIdentifier("home_header_icon_\(accessibilityTitle)")
    }
}

// MARK: - Home Menu Button

private struct HomeMenuButton<Destination: View>: View {
    let title: String
    let icon: String
    let gradient: LinearGradient
    let compact: Bool
    let destination: Destination

    @State private var isPressed = false

    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: compact ? 10 : 12) {
                Image(systemName: icon)
                    .font(.system(size: compact ? 16 : 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: compact ? 34 : 36, height: compact ? 34 : 36)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
                    .accessibilityHidden(true)

                Text(title)
                    .font(.system(size: compact ? 15 : 16, weight: .bold, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: compact ? 12 : 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, compact ? 13 : 15)
            .padding(.vertical, compact ? 9 : 11)
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
        .accessibilityLabel(title)
        .accessibilityHint("タップして\(title)へ進む")
        .accessibilityIdentifier("home_menu_\(title)")
    }
}
