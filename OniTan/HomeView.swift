import SwiftUI

// MARK: - Ink Palette
//
// Premium dark "ink & seal" palette for the Home screen.
// Avoids purple/blue; built around near-black ink, deep vermilion red and muted gold.

private enum HomeInk {
    static let background = Color(hex: "08070A")
    static let backgroundSecondary = Color(hex: "13090C")
    static let cardBackground = Color(hex: "151015")
    static let cardBackgroundAlt = Color(hex: "181014")
    static let red = Color(hex: "B91C2B")
    static let redDark = Color(hex: "7F101B")
    static let gold = Color(hex: "D8B45A")
    static let textPrimary = Color(hex: "F6EFE2")
    static let textSecondary = Color(hex: "AFA393")
    static let border = Color.white.opacity(0.08)
}

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var statsRepo: StudyStatsRepository
    @EnvironmentObject var streakRepo: StreakRepository
    @EnvironmentObject var xpRepo: GamificationRepository
    @EnvironmentObject var favoriteRepo: FavoriteKanjiRepository
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var donationManager: DonationManager
    @EnvironmentObject var masteryRepo: MasteryRepository
    @EnvironmentObject var examResultRepo: ExamResultRepository

    @State private var freezeToastVisible = false
    @State private var lastShownFreezeID: Int = -1
    @State private var showLevelUpOverlay = false
    @State private var levelUpValue: Int = 0

    var body: some View {
        VStack(spacing: 0) {
        NavigationStack {
            GeometryReader { proxy in
                let availableHeight = proxy.size.height
                let isCompactHeight = availableHeight < 700
                let contentWidth = max(0, min(proxy.size.width - (isCompactHeight ? 16 : 20), 560))

                ZStack {
                    inkBackground
                        .ignoresSafeArea()

                    if let loadError = dataLoadError {
                        dataErrorBanner(loadError)
                    }

                    ScrollView {
                        VStack(spacing: 0) {
                            headerSection(isCompact: isCompactHeight)

                            heroEmblem(isCompact: isCompactHeight)

                            primaryActions(isCompact: isCompactHeight)
                                .padding(.top, isCompactHeight ? 16 : 22)

                            progressStrip
                                .padding(.top, isCompactHeight ? 14 : 18)

                            secondaryLinks(isCompact: isCompactHeight)
                                .padding(.top, isCompactHeight ? 16 : 20)

                            footerSection
                                .padding(.top, 14)
                                .padding(.bottom, donationManager.hasDonated ? 16 : 12)
                        }
                        .padding(.horizontal, isCompactHeight ? 16 : 20)
                        .padding(.top, isCompactHeight ? 8 : 14)
                        .frame(maxWidth: contentWidth)
                        .frame(maxWidth: .infinity)
                    }
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
            .onChange(of: xpRepo.recentLevelUp) { newLevel in
                guard let lv = newLevel else { return }
                levelUpValue = lv
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    showLevelUpOverlay = true
                }
                OniTanTheme.hapticSuccess()
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeOut(duration: 0.3)) { showLevelUpOverlay = false }
                    xpRepo.clearLevelUpFlag()
                }
            }
        }
        .background(inkBackground.ignoresSafeArea())

        if !donationManager.hasDonated {
            AdBannerView()
        }
        } // VStack
        .overlay {
            if showLevelUpOverlay {
                levelUpToast(level: levelUpValue)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(100)
            }
        }
    }

    // MARK: - Background

    private var inkBackground: some View {
        LinearGradient(
            colors: [HomeInk.background, HomeInk.backgroundSecondary],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Level Up Toast

    private func levelUpToast(level: Int) -> some View {
        VStack {
            HStack(spacing: 10) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(HomeInk.gold)
                VStack(alignment: .leading, spacing: 2) {
                    Text("レベルアップ！")
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(HomeInk.gold)
                    Text("Lv.\(level) に到達")
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.black)
                        .foregroundColor(HomeInk.textPrimary)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(HomeInk.cardBackgroundAlt.opacity(0.97))
                    .overlay(
                        Capsule()
                            .stroke(HomeInk.gold.opacity(0.5), lineWidth: 1.5)
                    )
            )
            .shadow(color: HomeInk.gold.opacity(0.30), radius: 16, y: 6)
            .padding(.top, 60)
            Spacer()
        }
    }

    private var freezeConsumedToast: some View {
        HStack(spacing: 8) {
            Image(systemName: "snowflake")
                .foregroundColor(HomeInk.red)
            Text("ストリーク保護を使って継続しました")
                .font(.system(.caption, design: .rounded))
                .foregroundColor(HomeInk.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.45))
                .overlay(Capsule().stroke(HomeInk.border, lineWidth: 1))
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
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 1) {
                Text("鬼単")
                    .font(.system(size: isCompact ? 24 : 28, weight: .black, design: .rounded))
                    .foregroundColor(HomeInk.textPrimary)
                    .accessibilityLabel("鬼単アプリ")

                Text("漢字検定準1級 対策")
                    .font(.system(size: isCompact ? 11 : 12, weight: .regular, design: .rounded))
                    .foregroundColor(HomeInk.textSecondary)
                    .accessibilityHidden(true)
            }

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
    }

    // MARK: - Hero Emblem

    private func heroEmblem(isCompact: Bool) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(HomeInk.gold.opacity(0.18), lineWidth: 1.2)
                    .frame(width: isCompact ? 78 : 92, height: isCompact ? 78 : 92)

                Circle()
                    .stroke(HomeInk.red.opacity(0.22), lineWidth: 1)
                    .frame(width: isCompact ? 92 : 108, height: isCompact ? 92 : 108)

                Text("鬼")
                    .font(.system(size: isCompact ? 38 : 46, weight: .black, design: .serif))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [HomeInk.gold, HomeInk.red],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .padding(.top, isCompact ? 14 : 20)

            Text("準1級を、毎日少しずつ。")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(HomeInk.textSecondary)
        }
        .accessibilityHidden(true)
    }

    // MARK: - Primary Actions

    private var todayStage: Stage {
        TodaySessionBuilder.buildTodayStage(
            allStages: quizData.stages,
            statsRepo: statsRepo,
            clearedStages: appState.clearedStages
        )
    }

    private func primaryActions(isCompact: Bool) -> some View {
        VStack(spacing: isCompact ? 10 : 12) {
            HomePrimaryActionCard(
                title: "ランダム10問",
                subtitle: "まずは10問だけ鍛える",
                icon: "shuffle",
                style: .primary,
                isCompact: isCompact,
                destination: AnyView(
                    MainView(
                        stage: todayStage,
                        appState: appState,
                        statsRepo: statsRepo,
                        streakRepo: streakRepo,
                        xpRepo: xpRepo,
                        masteryRepo: masteryRepo,
                        mode: .quick10,
                        clearTitle: "今日の10問 完了！"
                    )
                )
            )
            .accessibilityIdentifier("home_today_card")

            HomePrimaryActionCard(
                title: "道場選択",
                subtitle: "分野ごとに集中して鍛える",
                icon: "books.vertical",
                style: .neutral,
                isCompact: isCompact,
                destination: AnyView(CategoryTrainingView())
            )

            HomePrimaryActionCard(
                title: "模擬試験",
                subtitle: "本番形式で実力をはかる",
                icon: "doc.text.magnifyingglass",
                style: .gold,
                isCompact: isCompact,
                destination: AnyView(examDestination)
            )
        }
    }

    @ViewBuilder
    private var examDestination: some View {
        if let exam = examCategory {
            TrainingModePickerView(category: exam)
        } else {
            StageSelectView()
        }
    }

    // MARK: - Progress Strip

    private var readiness: ReadinessScore {
        ReadinessCalculator.calculate(
            masteryRepo: masteryRepo,
            allQuestions: allQuestions,
            examResultRepo: examResultRepo
        )
    }

    /// 「総合模試」カテゴリ（categories.jsonの"exam"エントリ）。
    private var examCategory: CategoryEntry? {
        categoryManifest?.categories.first { $0.id == "exam" }
    }

    private var progressStrip: some View {
        let score = readiness
        let estimatedScore = Int((score.estimatedExamScore * 200).rounded())

        return HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Lv.\(xpRepo.level)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(HomeInk.gold)
                Text("準1級到達度 \(score.overallPercent)%")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(HomeInk.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("推定 \(estimatedScore) / 200")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(HomeInk.textPrimary)
                if streakRepo.currentStreak > 0 {
                    Text("\(streakRepo.currentStreak)日連続")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(HomeInk.textSecondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(HomeInk.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(HomeInk.border, lineWidth: 1)
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("レベル\(xpRepo.level)、準1級到達度\(score.overallPercent)パーセント、推定得点\(estimatedScore)点 / 200点")
    }

    // MARK: - Secondary Links

    private func secondaryLinks(isCompact: Bool) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                HomeSecondaryLink(title: "漢字一覧", icon: "square.grid.2x2", destination: AnyView(KanjiCatalogView()))

                if statsRepo.recentWrongAnswers(limit: 1).count > 0 {
                    HomeSecondaryLink(title: "誤答ノート", icon: "note.text", destination: AnyView(WrongAnswerNoteView()))
                }

                HomeSecondaryLink(title: "記録", icon: "chart.bar", destination: AnyView(StatsView()))
            }

            let showFavorites = favoriteRepo.count > 0
            let showReview = !reviewQuestions.isEmpty && xpRepo.level >= 30
            let showStreakChallenge = xpRepo.level >= 50

            if showFavorites || showReview || showStreakChallenge {
                HStack(spacing: 8) {
                    if showFavorites {
                        HomeSecondaryLink(
                            title: "お気に入り",
                            icon: "star",
                            destination: AnyView(
                                QuizModeSelectView(
                                    stage: FavoriteSessionBuilder.buildFavoriteStage(
                                        favoriteKanji: favoriteRepo.favoriteKanji
                                    ),
                                    sessionTitle: "お気に入り"
                                )
                            )
                        )
                    }

                    if showReview {
                        HomeSecondaryLink(
                            title: "おさらい",
                            icon: "arrow.triangle.2.circlepath",
                            destination: AnyView(
                                QuizModeSelectView(
                                    stage: ReviewSessionBuilder.buildReviewStage(reviewQuestions: reviewQuestions),
                                    sessionTitle: "おさらい（準１級以下）",
                                    allowedModes: [.quick10, .exam30]
                                )
                            )
                        )
                    }

                    if showStreakChallenge {
                        HomeSecondaryLink(
                            title: "連続鬼たん",
                            icon: "flame",
                            destination: AnyView(StreakChallengeView(xpRepo: xpRepo))
                        )
                    }
                }
            }

            lockedFeaturesRow(isCompact: isCompact)
        }
    }

    /// 未解放機能をコンパクトな1行で表示する
    @ViewBuilder
    private func lockedFeaturesRow(isCompact: Bool) -> some View {
        let showReviewLock = !reviewQuestions.isEmpty && xpRepo.level < 30
        let showStreakLock = xpRepo.level < 50

        if showReviewLock || showStreakLock {
            HStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(HomeInk.textSecondary.opacity(0.4))
                if showReviewLock {
                    Text("おさらい Lv.30")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(HomeInk.textSecondary.opacity(0.5))
                }
                if showReviewLock && showStreakLock {
                    Text("·")
                        .foregroundColor(HomeInk.textSecondary.opacity(0.3))
                        .font(.system(size: 11))
                }
                if showStreakLock {
                    Text("連続鬼たん Lv.50")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(HomeInk.textSecondary.opacity(0.5))
                }
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(Color.white.opacity(0.03))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(HomeInk.border, lineWidth: 1)
            )
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        Group {
            if statsRepo.totalCorrect > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(HomeInk.gold)
                        .font(.caption)
                    Text("通算正解 \(statsRepo.totalCorrect) 問")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(HomeInk.textSecondary)
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
                .font(.system(size: compact ? 15 : 16, weight: .semibold))
                .foregroundColor(HomeInk.textPrimary)
                .frame(width: compact ? 36 : 38, height: compact ? 36 : 38)
                .background(
                    Circle()
                        .fill(HomeInk.cardBackground)
                        .overlay(
                            Circle()
                                .stroke(HomeInk.border, lineWidth: 1)
                        )
                )
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

// MARK: - Primary Action Card

private enum HomePrimaryCardStyle {
    case primary  // ランダム10問: 深い紅のグラデーション
    case neutral  // 道場選択: ダークカード
    case gold     // 模擬試験: ダークカード + 金アクセント
}

private struct HomePrimaryActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let style: HomePrimaryCardStyle
    let isCompact: Bool
    let destination: AnyView

    @State private var isPressed = false

    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: isCompact ? 19 : 21, weight: .semibold))
                    .foregroundColor(iconColor)
                    .frame(width: 48, height: 48)
                    .background(
                        Circle().fill(iconBackground)
                    )
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: isCompact ? 17 : 19, weight: .black, design: .rounded))
                        .foregroundColor(titleColor)
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(subtitleColor)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(subtitleColor)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, isCompact ? 16 : 20)
            .background(cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(borderColor, lineWidth: 1)
            )
            .cornerRadius(18)
            .shadow(color: shadowColor, radius: style == .primary ? 16 : 6, y: 6)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: isPressed)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityHint("タップして\(title)を開始")
    }

    private var cardBackground: AnyView {
        switch style {
        case .primary:
            return AnyView(
                LinearGradient(
                    colors: [HomeInk.red, HomeInk.redDark],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .neutral, .gold:
            return AnyView(HomeInk.cardBackground)
        }
    }

    private var iconBackground: Color {
        switch style {
        case .primary: return Color.white.opacity(0.18)
        case .neutral: return Color.white.opacity(0.06)
        case .gold: return HomeInk.gold.opacity(0.14)
        }
    }

    private var iconColor: Color {
        switch style {
        case .primary: return .white
        case .neutral: return HomeInk.textPrimary
        case .gold: return HomeInk.gold
        }
    }

    private var titleColor: Color {
        switch style {
        case .primary: return .white
        case .neutral, .gold: return HomeInk.textPrimary
        }
    }

    private var subtitleColor: Color {
        switch style {
        case .primary: return .white.opacity(0.78)
        case .neutral, .gold: return HomeInk.textSecondary
        }
    }

    private var borderColor: Color {
        switch style {
        case .primary: return Color.white.opacity(0.10)
        case .neutral: return HomeInk.border
        case .gold: return HomeInk.gold.opacity(0.25)
        }
    }

    private var shadowColor: Color {
        switch style {
        case .primary: return HomeInk.red.opacity(0.40)
        case .neutral: return Color.black.opacity(0.30)
        case .gold: return HomeInk.gold.opacity(0.12)
        }
    }
}

// MARK: - Secondary Link

private struct HomeSecondaryLink: View {
    let title: String
    let icon: String
    let destination: AnyView

    @State private var isPressed = false

    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .foregroundColor(HomeInk.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(HomeInk.cardBackground.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(HomeInk.border, lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(title)
        .accessibilityHint("タップして\(title)へ進む")
    }
}
