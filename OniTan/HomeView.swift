import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var statsRepo: StudyStatsRepository
    @EnvironmentObject var streakRepo: StreakRepository
    @EnvironmentObject var xpRepo: GamificationRepository
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var donationManager: DonationManager

    @State private var freezeToastVisible = false
    @State private var lastShownFreezeID: Int = -1
    @State private var bgAnimPhase = false

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let availableHeight = proxy.size.height
                let isCompactHeight = availableHeight < 700
                let contentWidth = min(proxy.size.width - (isCompactHeight ? 16 : 20), 560)

                ZStack {
                    animatedBackground
                        .ignoresSafeArea()

                    if let loadError = dataLoadError {
                        dataErrorBanner(loadError)
                    }

                    VStack(spacing: 0) {
                        Spacer(minLength: 0)

                        headerSection(isCompact: isCompactHeight)

                        Spacer(minLength: isCompactHeight ? 12 : 20)

                        menuSection(isCompact: isCompactHeight)

                        Spacer(minLength: isCompactHeight ? 8 : 14)

                        footerSection

                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: contentWidth)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        .background(animatedBackground.ignoresSafeArea())
    }

    private var animatedBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.10, blue: 0.30),
                    Color(red: 0.20, green: 0.05, blue: 0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            LinearGradient(
                colors: [
                    Color(red: 0.16, green: 0.08, blue: 0.38),
                    Color(red: 0.10, green: 0.02, blue: 0.18)
                ],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
            .opacity(bgAnimPhase ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                bgAnimPhase = true
            }
        }
    }


    private var freezeConsumedToast: some View {
        HStack(spacing: 8) {
            Image(systemName: "snowflake")
                .foregroundColor(OniTanTheme.accentPrimary)
            Text("ストリーク保護を使って継続しました")
                .font(.system(.caption, design: .rounded))
                .foregroundColor(OniTanTheme.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.45))
                .overlay(Capsule().stroke(OniTanTheme.cardBorder, lineWidth: 1))
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
                        colors: [OniTanTheme.textPrimary, OniTanTheme.accentPrimary.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: OniTanTheme.shadowGlow.color, radius: 16, y: 8)
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
                        : OniTanTheme.textTertiary)
                    .symbolEffect(.bounce, value: streakRepo.todayCompleted)
            } else {
                Image(systemName: streakRepo.todayCompleted ? "flame.fill" : "flame")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(streakRepo.currentStreak > 0
                        ? OniTanTheme.accentWeak
                        : OniTanTheme.textTertiary)
            }

            if streakRepo.currentStreak > 0 {
                Text("\(streakRepo.currentStreak)日連続")
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(streakRepo.todayCompleted
                        ? OniTanTheme.accentWeak
                        : OniTanTheme.textSecondary)

                Text("🧊\(streakRepo.freezeCount)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(OniTanTheme.textSecondary)
            } else {
                Text("記録を作ろう")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(OniTanTheme.textTertiary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(streakRepo.todayCompleted
                    ? Color(red: 0.5, green: 0.25, blue: 0.0).opacity(0.55)
                    : OniTanTheme.cardBackground)
                .overlay(
                    Capsule()
                        .stroke(
                            streakRepo.currentStreak > 0
                                ? OniTanTheme.accentWeak.opacity(0.4)
                                : OniTanTheme.cardBorder,
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
                .foregroundColor(OniTanTheme.textPrimary)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(OniTanTheme.cardBorder)
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

            if xpRepo.level >= 5 {
                HomeMenuButton(
                    title: "連続鬼たん",
                    icon: "flame.fill",
                    gradient: LinearGradient(
                        colors: [Color(red: 0.85, green: 0.15, blue: 0.15), Color(red: 0.55, green: 0.05, blue: 0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    compact: isCompact,
                    destination: StreakChallengeView(xpRepo: xpRepo)
                )
            } else {
                lockedStreakButton(isCompact: isCompact)
            }

            HomeSRSReviewButton(compact: isCompact)
        }
    }

    private func lockedStreakButton(isCompact: Bool) -> some View {
        HStack(spacing: isCompact ? 10 : 12) {
            Image(systemName: "lock.fill")
                .font(.system(size: isCompact ? 16 : 17, weight: .semibold))
                .foregroundColor(.white.opacity(0.35))
                .frame(width: isCompact ? 34 : 36, height: isCompact ? 34 : 36)
                .background(Color.white.opacity(0.08))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text("連続鬼たん")
                    .font(.system(size: isCompact ? 15 : 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.35))
                Text("Lv.5で解放")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.3))
            }

            Spacer()

            Image(systemName: "lock.fill")
                .font(.system(size: isCompact ? 12 : 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.25))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, isCompact ? 13 : 15)
        .padding(.vertical, isCompact ? 9 : 11)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.07), Color.white.opacity(0.04)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(OniTanTheme.radiusCard)
        .overlay(
            RoundedRectangle(cornerRadius: OniTanTheme.radiusCard)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
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
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
        .buttonStyle(PlainButtonStyle())
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
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.easeInOut(duration: 0.12), value: isPressed)
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
                .foregroundColor(OniTanTheme.textPrimary)
                .frame(width: compact ? 38 : 40, height: compact ? 38 : 40)
                .background(
                    Circle()
                        .fill(isPressed ? OniTanTheme.cardBackgroundPressed : OniTanTheme.cardBackground)
                        .overlay(
                            Circle()
                                .stroke(OniTanTheme.cardBorder, lineWidth: 1)
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

struct HomeMenuButton<Destination: View>: View {
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

// MARK: - SRS Review Button

private struct HomeSRSReviewButton: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var statsRepo: StudyStatsRepository
    @EnvironmentObject var streakRepo: StreakRepository
    @EnvironmentObject var xpRepo: GamificationRepository
    let compact: Bool

    @State private var isPressed = false

    /// Build a Stage containing all weak-kanji questions from every stage.
    private var srsStage: Stage? {
        var weakQuestions: [Question] = []
        for stage in quizData.stages {
            let weakKanji = Set(statsRepo.allWeakKanji(forStage: stage.stage))
            if !weakKanji.isEmpty {
                weakQuestions.append(contentsOf: stage.questions.filter { weakKanji.contains($0.kanji) })
            }
        }
        guard !weakQuestions.isEmpty else { return nil }
        return Stage(stage: 0, questions: weakQuestions)
    }

    private var weakCount: Int {
        statsRepo.stageStats.values.reduce(0) { $0 + $1.wrongKanji.count }
    }

    private let gradient = LinearGradient(
        colors: [Color(red: 0.4, green: 0.2, blue: 0.7), Color(red: 0.25, green: 0.1, blue: 0.5)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        if let stage = srsStage {
            NavigationLink(
                destination: MainView(
                    stage: stage,
                    appState: appState,
                    statsRepo: statsRepo,
                    streakRepo: streakRepo,
                    xpRepo: xpRepo,
                    mode: .srsReview,
                    clearTitle: "SRS復習完了！"
                )
            ) {
                buttonContent
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded   { _ in isPressed = false }
            )
            .buttonStyle(PlainButtonStyle())
            .accessibilityElement(children: .combine)
            .accessibilityLabel("SRS復習 苦手\(weakCount)問")
            .accessibilityHint("タップしてSRS復習を開始")
            .accessibilityIdentifier("home_menu_srs_review")
        } else {
            disabledButton
        }
    }

    private var buttonContent: some View {
        HStack(spacing: compact ? 10 : 12) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: compact ? 16 : 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: compact ? 34 : 36, height: compact ? 34 : 36)
                .background(Color.white.opacity(0.2))
                .clipShape(Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("SRS復習")
                    .font(.system(size: compact ? 15 : 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text("苦手 \(weakCount) 問")
                    .font(.system(size: compact ? 10 : 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }

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

    private var disabledButton: some View {
        HStack(spacing: compact ? 10 : 12) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: compact ? 16 : 17, weight: .semibold))
                .foregroundColor(OniTanTheme.textTertiary)
                .frame(width: compact ? 34 : 36, height: compact ? 34 : 36)
                .background(OniTanTheme.cardBackground)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text("SRS復習")
                    .font(.system(size: compact ? 15 : 16, weight: .bold, design: .rounded))
                    .foregroundColor(OniTanTheme.textTertiary)
                Text("苦手漢字なし")
                    .font(.system(size: compact ? 10 : 11, weight: .semibold, design: .rounded))
                    .foregroundColor(OniTanTheme.textTertiary.opacity(0.6))
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, compact ? 13 : 15)
        .padding(.vertical, compact ? 9 : 11)
        .background(OniTanTheme.cardBackground.opacity(0.5))
        .cornerRadius(OniTanTheme.radiusCard)
        .overlay(
            RoundedRectangle(cornerRadius: OniTanTheme.radiusCard)
                .stroke(OniTanTheme.cardBorder, lineWidth: 1)
        )
        .accessibilityLabel("SRS復習 苦手漢字なし")
    }
}
