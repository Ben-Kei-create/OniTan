import SwiftUI

// MARK: - Ink Palette
//
// Premium dark "ink & seal" palette for the Home screen.
// Avoids purple/blue; built around near-black ink, deep vermilion red and muted gold.

private enum HomeInk {
    static let background = OniTanTheme.inkBackground
    static let backgroundSecondary = OniTanTheme.inkBackgroundSecondary
    static let cardBackground = OniTanTheme.inkCard
    static let cardBackgroundAlt = OniTanTheme.inkCardPressed
    static let red = OniTanTheme.sealRed
    static let redDark = OniTanTheme.sealRedDark
    static let gold = OniTanTheme.mutedGold
    static let textPrimary = OniTanTheme.washiText
    static let textSecondary = OniTanTheme.washiSecondary
    static let border = OniTanTheme.mutedGold.opacity(0.12)
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

                            streakSection(isCompact: isCompactHeight)
                                .padding(.top, isCompactHeight ? 14 : 18)

                            primaryActions(isCompact: isCompactHeight)
                                .padding(.top, isCompactHeight ? 16 : 22)

                            Color.clear
                                .frame(height: donationManager.hasDonated ? 18 : 28)
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
        }
        .background(inkBackground.ignoresSafeArea())

        if !donationManager.hasDonated {
            AdBannerView()
                .padding(.top, 10)
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity)
                .background(
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(HomeInk.border)
                            .frame(height: 1)
                        HomeInk.background
                    }
                )
        }
        } // VStack
    }

    // MARK: - Background

    private var inkBackground: some View {
        LinearGradient(
            colors: [HomeInk.background, HomeInk.backgroundSecondary],
            startPoint: .top,
            endPoint: .bottom
        )
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

                OniOptionalArtwork(
                    assetName: OniArtworkAsset.home,
                    width: isCompact ? 86 : 106,
                    height: isCompact ? 86 : 106
                ) {
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
            }
            .padding(.top, isCompact ? 14 : 20)

            Text("準1級を、毎日少しずつ。")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(HomeInk.textSecondary)
        }
        .accessibilityHidden(true)
    }

    // MARK: - Streak Section

    private func streakSection(isCompact: Bool) -> some View {
        let state = xpRepo.levelState(for: xpRepo.totalXP)

        return VStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(HomeInk.gold)
                    .accessibilityHidden(true)

                Text(streakRepo.currentStreak > 0 ? "\(streakRepo.currentStreak)日連続" : "今日から始めよう")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(HomeInk.textPrimary)

                Spacer()

                if streakRepo.longestStreak > 0 {
                    Text("最長 \(streakRepo.longestStreak)日")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(HomeInk.textSecondary)
                }
            }

            StreakCalendarStrip(streakRepo: streakRepo)

            HStack(spacing: 8) {
                Text("Lv.\(state.level)")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundColor(HomeInk.gold)

                HomeInlineProgressBar(progress: state.progress)

                Text("\(state.xpInLevel)/\(state.xpToNext) XP")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(HomeInk.textSecondary)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("レベル\(state.level)、次のレベルまで\(state.xpToNext - state.xpInLevel)経験値")
        }
        .padding(14)
        .oniGlassCard()
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
            if quizData.stages.isEmpty {
                HomePrimaryActionCard(
                    title: "ランダム10問",
                    style: .disabled,
                    isCompact: isCompact,
                    destination: nil,
                    icon: "shuffle"
                )
                .accessibilityIdentifier("home_today_card")
            } else {
                HomePrimaryActionCard(
                    title: "ランダム10問",
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
                            clearTitle: "ランダム10問 完了！"
                        )
                    ),
                    subtitle: "全カテゴリからランダムに10問",
                    icon: "shuffle",
                    trailingBadge: streakRepo.todayCompleted ? "達成済み" : nil
                )
                .accessibilityIdentifier("home_today_card")
            }

            if statsRepo.hasWeakPoints {
                HomePrimaryActionCard(
                    title: "弱点復習",
                    style: .neutral,
                    isCompact: isCompact,
                    destination: AnyView(
                        QuizModeSelectView(
                            stage: WeakPointSessionBuilder.buildWeakStage(
                                statsRepo: statsRepo,
                                allStages: quizData.stages
                            ),
                            sessionTitle: "弱点復習"
                        )
                    ),
                    subtitle: "間違えた漢字を集中的に復習",
                    icon: "exclamationmark.triangle.fill"
                )
            }

            HomePrimaryActionCard(
                title: "道場選択",
                style: .neutral,
                isCompact: isCompact,
                destination: AnyView(CategoryTrainingView()),
                subtitle: "ステージを選んで集中練習",
                icon: "building.columns.fill"
            )

            HomePrimaryActionCard(
                title: "模擬試験",
                style: .neutral,
                isCompact: isCompact,
                destination: AnyView(examDestination),
                subtitle: "本番形式で実力を確認",
                icon: "doc.text.fill"
            )

            HomePrimaryActionCard(
                title: "漢字一覧",
                style: .neutral,
                isCompact: isCompact,
                destination: AnyView(KanjiCatalogView()),
                subtitle: "全漢字をチェック",
                icon: "books.vertical.fill"
            )

            HomePrimaryActionCard(
                title: "連続鬼たん",
                style: .neutral,
                isCompact: isCompact,
                destination: AnyView(StreakChallengeView(xpRepo: xpRepo)),
                subtitle: "1問8秒・ミスで終了のタイムアタック",
                icon: "bolt.fill"
            )

            HomePrimaryActionCard(
                title: "書き取り訓練",
                style: .neutral,
                isCompact: isCompact,
                destination: AnyView(
                    QuizModeSelectView(
                        stage: WritingSessionBuilder.buildWritingStage(),
                        sessionTitle: "書き取り訓練"
                    )
                ),
                subtitle: "漢字を書く力を多肢選択で確認",
                icon: "pencil.and.outline"
            )

            if favoriteRepo.count > 0 {
                HomePrimaryActionCard(
                    title: "お気に入り",
                    style: .neutral,
                    isCompact: isCompact,
                    destination: AnyView(
                        QuizModeSelectView(
                            stage: FavoriteSessionBuilder.buildFavoriteStage(
                                favoriteKanji: favoriteRepo.favoriteKanji
                            ),
                            sessionTitle: "お気に入り"
                        )
                    ),
                    subtitle: "保存した漢字を復習",
                    icon: "star.fill"
                )
            } else {
                HomePrimaryActionCard(
                    title: "お気に入り",
                    style: .disabled,
                    isCompact: isCompact,
                    destination: nil,
                    subtitle: "問題画面の★で漢字を保存できます",
                    icon: "star"
                )
            }
        }
    }

    @ViewBuilder
    private var examDestination: some View {
        ExamRoundSelectionView()
    }

    // MARK: - Error Banner

    private func dataErrorBanner(_ error: DataLoadError) -> some View {
        VStack {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption.bold())
                    .foregroundColor(HomeInk.gold)
                    .accessibilityHidden(true)
                Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundColor(HomeInk.textPrimary)
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
                .font(.system(size: compact ? 15 : 16, weight: .bold))
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
    case primary   // ランダム10問: 深い紅のグラデーション
    case neutral   // 道場選択: ダークカード
    case gold      // 模擬試験: ダークカード + 金アクセント
    case disabled  // データ読み込み失敗時のプレースホルダー
}

private struct HomeInlineProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(HomeInk.border)

                Capsule()
                    .fill(HomeInk.gold)
                    .frame(width: max(0, min(proxy.size.width, proxy.size.width * progress)))
            }
        }
        .frame(height: 5)
    }
}

private struct HomePrimaryActionCard: View {
    let title: String
    let style: HomePrimaryCardStyle
    let isCompact: Bool
    let destination: AnyView?
    var subtitle: String? = nil
    var icon: String? = nil
    var trailingBadge: String? = nil

    @State private var isPressed = false

    var body: some View {
        Group {
            if let destination {
                NavigationLink(destination: destination) { cardContent }
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in isPressed = true }
                            .onEnded { _ in isPressed = false }
                    )
                    .buttonStyle(PlainButtonStyle())
            } else {
                cardContent
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(subtitle.map { "\(title) \($0)" } ?? title)
        .accessibilityHint(destination != nil ? "タップして\(title)を開始" : "")
    }

    private var cardContent: some View {
        HStack(spacing: 14) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: isCompact ? 17 : 19, weight: .bold))
                    .foregroundColor(titleColor)
                    .frame(width: isCompact ? 28 : 32)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: isCompact ? 17 : 19, weight: .black, design: .rounded))
                    .foregroundColor(titleColor)

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(subtitleColor)
                }
            }

            Spacer()

            if let trailingBadge {
                HStack(spacing: 3) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 11, weight: .bold))
                    Text(trailingBadge)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                }
                .foregroundColor(OniTanTheme.accentCorrect)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule().fill(OniTanTheme.accentCorrect.opacity(0.16))
                )
            }

            if destination != nil {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(subtitleColor)
                    .accessibilityHidden(true)
            }
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
        case .neutral, .gold, .disabled:
            return AnyView(HomeInk.cardBackground)
        }
    }

    private var titleColor: Color {
        switch style {
        case .primary: return HomeInk.textPrimary
        case .neutral, .gold: return HomeInk.textPrimary
        case .disabled: return HomeInk.textSecondary
        }
    }

    private var subtitleColor: Color {
        switch style {
        case .primary: return HomeInk.textPrimary.opacity(0.78)
        case .neutral, .gold: return HomeInk.textSecondary
        case .disabled: return HomeInk.textSecondary.opacity(0.6)
        }
    }

    private var borderColor: Color {
        switch style {
        case .primary: return HomeInk.textPrimary.opacity(0.10)
        case .neutral: return HomeInk.border
        case .gold: return HomeInk.gold.opacity(0.25)
        case .disabled: return HomeInk.border
        }
    }

    private var shadowColor: Color {
        switch style {
        case .primary: return HomeInk.red.opacity(0.40)
        case .neutral: return Color.black.opacity(0.30)
        case .gold: return HomeInk.gold.opacity(0.12)
        case .disabled: return Color.clear
        }
    }
}
