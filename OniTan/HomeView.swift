import SwiftUI

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
    @State private var bgAnimPhase = false
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
                            .padding(.bottom, donationManager.hasDonated ? 4 : 12)

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
        .background(animatedBackground.ignoresSafeArea())

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

    // MARK: - Level Up Toast

    private func levelUpToast(level: Int) -> some View {
        VStack {
            HStack(spacing: 10) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(LinearGradient(
                        colors: [Color(red: 1.0, green: 0.85, blue: 0.2), Color(red: 1.0, green: 0.55, blue: 0.0)],
                        startPoint: .top, endPoint: .bottom
                    ))
                VStack(alignment: .leading, spacing: 2) {
                    Text("レベルアップ！")
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.2))
                    Text("Lv.\(level) に到達")
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.black)
                        .foregroundColor(OniTanTheme.textPrimary)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Color(red: 0.15, green: 0.12, blue: 0.30).opacity(0.95))
                    .overlay(
                        Capsule()
                            .stroke(Color(red: 1.0, green: 0.85, blue: 0.2).opacity(0.5), lineWidth: 1.5)
                    )
            )
            .shadow(color: Color(red: 1.0, green: 0.75, blue: 0.0).opacity(0.35), radius: 16, y: 6)
            .padding(.top, 60)
            Spacer()
        }
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
        VStack(spacing: isCompact ? 6 : 8) {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("鬼単")
                        .font(.system(size: isCompact ? 26 : 30, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [OniTanTheme.textPrimary, OniTanTheme.accentPrimary.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .accessibilityLabel("鬼単アプリ")

                    Text("漢字検定準1級 対策")
                        .font(.system(size: isCompact ? 11 : 12, weight: .regular, design: .rounded))
                        .foregroundColor(OniTanTheme.textSecondary)
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

            HStack(spacing: 12) {
                streakChip
                xpChip
                Spacer()
            }
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

    private func menuSection(isCompact: Bool) -> some View {
        let score = readiness
        let weakestEntry: (kind: QuestionKind, accuracy: Double, category: CategoryEntry)? = {
            guard let weakest = score.weakestKinds.first,
                  let category = categoryManifest?.categories.first(where: { $0.questionKinds.contains(weakest) })
            else { return nil }
            return (weakest, score.byKind[weakest] ?? 0, category)
        }()

        return VStack(spacing: isCompact ? 8 : 10) {
            HomeReadinessCard(readiness: score)

            // 推奨アクション: 苦手カテゴリがあればそれを最優先、なければ今日の10問
            if let weakest = weakestEntry {
                HomeWeakestCategoryCard(
                    kind: weakest.kind,
                    accuracy: weakest.accuracy,
                    category: weakest.category
                )
            } else {
                HomeTodayCard(compact: isCompact, featured: true)
            }

            // セカンダリアクション: コンパクトな2〜3枚のタイル
            HStack(spacing: 8) {
                if weakestEntry != nil {
                    HomeTodayQuickTile()
                }

                if let exam = examCategory {
                    HomeQuickActionTile(
                        title: "総合模試",
                        icon: "doc.text.magnifyingglass",
                        tint: OniTanTheme.accentPrimary,
                        destination: TrainingModePickerView(category: exam)
                    )
                }

                HomeQuickActionTile(
                    title: "ステージ選択",
                    icon: "books.vertical.fill",
                    tint: OniTanTheme.textSecondary,
                    destination: StageSelectView()
                )
            }

            HomeDojoBanner(compact: isCompact)

            HomeMenuButton(
                title: "漢字一覧",
                icon: "square.grid.3x3.fill",
                gradient: LinearGradient(
                    colors: [Color(red: 0.12, green: 0.50, blue: 0.72), Color(red: 0.08, green: 0.24, blue: 0.46)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                compact: isCompact,
                destination: KanjiCatalogView()
            )

            if favoriteRepo.count > 0 {
                HomeMenuButton(
                    title: "お気に入りから学習",
                    icon: "star.fill",
                    gradient: LinearGradient(
                        colors: [Color(red: 0.95, green: 0.72, blue: 0.14), Color(red: 0.72, green: 0.42, blue: 0.04)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    compact: isCompact,
                    destination: QuizModeSelectView(
                        stage: FavoriteSessionBuilder.buildFavoriteStage(
                            favoriteKanji: favoriteRepo.favoriteKanji
                        ),
                        sessionTitle: "お気に入り"
                    )
                )
            }

            if statsRepo.recentWrongAnswers(limit: 1).count > 0 {
                HomeMenuButton(
                    title: "誤答ノート",
                    icon: "note.text",
                    gradient: LinearGradient(
                        colors: [Color(red: 0.55, green: 0.20, blue: 0.55), Color(red: 0.35, green: 0.08, blue: 0.38)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    compact: isCompact,
                    destination: WrongAnswerNoteView()
                )
            }

            if !reviewQuestions.isEmpty {
                if xpRepo.level >= 30 {
                    reviewMenuButton(isCompact: isCompact)
                }
            }

            if xpRepo.level >= 50 {
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
            }

            lockedFeaturesRow(isCompact: isCompact)

        }
    }

    private func reviewMenuButton(isCompact: Bool) -> some View {
        HomeMenuButton(
            title: "おさらい（準１級以下）",
            icon: "arrow.triangle.2.circlepath.circle.fill",
            gradient: LinearGradient(
                colors: [Color(red: 0.78, green: 0.44, blue: 0.10), Color(red: 0.48, green: 0.20, blue: 0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            compact: isCompact,
            destination: QuizModeSelectView(
                stage: ReviewSessionBuilder.buildReviewStage(reviewQuestions: reviewQuestions),
                sessionTitle: "おさらい（準１級以下）",
                allowedModes: [.quick10, .exam30]
            )
        )
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
                    .foregroundColor(.white.opacity(0.25))
                if showReviewLock {
                    Text("おさらい Lv.30")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.3))
                }
                if showReviewLock && showStreakLock {
                    Text("·")
                        .foregroundColor(.white.opacity(0.2))
                        .font(.system(size: 11))
                }
                if showStreakLock {
                    Text("連続鬼たん Lv.50")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.3))
                }
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(Color.white.opacity(0.04))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.07), lineWidth: 1)
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
    @EnvironmentObject var masteryRepo: MasteryRepository
    let compact: Bool
    var featured: Bool = false

    @State private var isPressed = false

    private var todayStage: Stage {
        TodaySessionBuilder.buildTodayStage(
            allStages: quizData.stages,
            statsRepo: statsRepo,
            clearedStages: appState.clearedStages
        )
    }

    private var allWeakQuestions: [Question] {
        quizData.stages.flatMap { statsRepo.weakQuestions(for: $0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if featured {
                Text("今日やるべき一手")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(OniTanTheme.textTertiary)
                    .padding(.horizontal, 2)
            }

            NavigationLink(
                destination: MainView(
                    stage: todayStage,
                    appState: appState,
                    statsRepo: statsRepo,
                    streakRepo: streakRepo,
                    xpRepo: xpRepo,
                    masteryRepo: masteryRepo,
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

            if streakRepo.todayCompleted {
                weakFocusCTA
            }
        }
    }

    @ViewBuilder
    private var weakFocusCTA: some View {
        let weak = allWeakQuestions
        if !weak.isEmpty {
            let weakStage = Stage(stage: -99, questions: weak)
            NavigationLink(
                destination: MainView(
                    stage: weakStage,
                    appState: appState,
                    statsRepo: statsRepo,
                    streakRepo: streakRepo,
                    xpRepo: xpRepo,
                    masteryRepo: masteryRepo,
                    mode: .normal,
                    sessionTitle: "苦手問題 \(weak.count)問"
                )
            ) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(OniTanTheme.accentWeak)
                    Text("苦手問題を続けて解く（\(weak.count) 問）")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(OniTanTheme.textSecondary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11))
                        .foregroundColor(OniTanTheme.textTertiary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: OniTanTheme.radiusCard)
                        .fill(OniTanTheme.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: OniTanTheme.radiusCard)
                                .stroke(OniTanTheme.accentWeak.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("苦手問題\(weak.count)問に挑戦")
        }
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
            return OniTanTheme.correctGradient
        }
        return OniTanTheme.primaryGradient
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

// MARK: - Readiness Card (Phase 2 placeholder)

private struct HomeReadinessCard: View {
    let readiness: ReadinessScore

    /// 漢検準1級は200点満点。
    private var estimatedScore: Int { Int((readiness.estimatedExamScore * 200).rounded()) }

    var body: some View {
        HStack(spacing: 14) {
            ProgressRingView(
                progress: readiness.overall,
                lineWidth: 7,
                size: 64,
                gradient: Gradient(colors: [OniTanTheme.accentWeak, OniTanTheme.accentPrimary]),
                label: "\(readiness.overallPercent)%"
            )

            VStack(alignment: .leading, spacing: 3) {
                Text("準1級到達度")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(OniTanTheme.textTertiary)
                Text("\(readiness.overallPercent)%")
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.black)
                    .foregroundColor(OniTanTheme.textPrimary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("推定得点")
                    .font(.system(size: 10, design: .rounded))
                    .foregroundColor(OniTanTheme.textTertiary)
                Text("\(estimatedScore) / 200")
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(OniTanTheme.accentWeak)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .oniCard()
        .overlay(alignment: .bottom) {
            Text("本番得点を保証するものではありません")
                .font(.system(size: 9, design: .rounded))
                .foregroundColor(OniTanTheme.textTertiary.opacity(0.6))
                .padding(.bottom, 4)
        }
        .accessibilityElement()
        .accessibilityLabel("準1級到達度 \(readiness.overallPercent)パーセント、推定得点 \(estimatedScore)点 / 200点")
    }
}

// MARK: - Weakest Category Card

private struct HomeWeakestCategoryCard: View {
    let kind: QuestionKind
    let accuracy: Double
    let category: CategoryEntry

    var body: some View {
        NavigationLink(destination: TrainingModePickerView(category: category)) {
            VStack(alignment: .leading, spacing: 10) {
                Text("今日やるべき一手")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(OniTanTheme.textTertiary)

                HStack(spacing: 14) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.white.opacity(0.18)))

                    VStack(alignment: .leading, spacing: 3) {
                        Text("最優先: \(kind.displayName)")
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.black)
                            .foregroundColor(.white)
                        Text("正答率 \(Int((accuracy * 100).rounded()))%")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(.white.opacity(0.85))
                    }

                    Spacer()

                    Text("ここから鍛える")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.white.opacity(0.20)))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(OniTanTheme.primaryGradient)
            .cornerRadius(OniTanTheme.radiusCard)
            .shadow(color: OniTanTheme.shadowCard.color, radius: OniTanTheme.shadowCard.radius, y: OniTanTheme.shadowCard.y)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("今日やるべき一手。最優先 \(kind.displayName)、正答率\(Int((accuracy * 100).rounded()))パーセント")
        .accessibilityHint("タップして集中トレーニングを開始")
    }
}

// MARK: - Dojo Banner

private struct HomeDojoBanner: View {
    let compact: Bool

    private var featuredCategories: [CategoryEntry] {
        guard let manifest = categoryManifest else { return Array(CategoryEntry.fallbacks.prefix(3)) }
        let ids = ["reading", "yojijukugo", "proverb"]
        let found = ids.compactMap { manifest.entry(for: $0) }
        return found.isEmpty ? Array(CategoryEntry.fallbacks.prefix(3)) : found
    }

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 6 : 8) {
            HStack {
                Text("道場")
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(OniTanTheme.textSecondary)
                Spacer()
                NavigationLink(destination: CategoryTrainingView()) {
                    HStack(spacing: 3) {
                        Text("すべて見る")
                        Image(systemName: "chevron.right")
                    }
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(OniTanTheme.accentPrimary)
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("すべての道場を見る")
            }

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)],
                spacing: 8
            ) {
                ForEach(featuredCategories) { entry in
                    NavigationLink(destination: TrainingModePickerView(category: entry)) {
                        MiniDojoCard(entry: entry, compact: compact)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel(entry.title)
                    .accessibilityHint("タップして\(entry.title)へ進む")
                }
            }
        }
    }
}

// MARK: - Mini Dojo Card (2-col grid cell)

private struct MiniDojoCard: View {
    let entry: CategoryEntry
    let compact: Bool
    @State private var isPressed = false

    private var accentColor: Color { Color(hex: entry.colorHex) }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: entry.iconName)
                .font(.system(size: compact ? 13 : 15, weight: .semibold))
                .foregroundColor(accentColor)
                .frame(width: 22, alignment: .center)
            Text(entry.title)
                .font(.system(size: compact ? 12 : 13, weight: .semibold, design: .rounded))
                .foregroundColor(OniTanTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, compact ? 9 : 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(OniTanTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(accentColor.opacity(0.30), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.18), radius: 4, y: 2)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
    }
}

// MARK: - Today Quick Tile (compact secondary "今日の10問")

private struct HomeTodayQuickTile: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var statsRepo: StudyStatsRepository
    @EnvironmentObject var streakRepo: StreakRepository
    @EnvironmentObject var xpRepo: GamificationRepository
    @EnvironmentObject var masteryRepo: MasteryRepository

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
                masteryRepo: masteryRepo,
                mode: .quick10,
                clearTitle: "今日の10問 完了！"
            )
        ) {
            VStack(spacing: 6) {
                Image(systemName: streakRepo.todayCompleted ? "checkmark.seal.fill" : "bolt.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(OniTanTheme.accentWeak)
                Text("今日の10問")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(OniTanTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .oniCard()
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(streakRepo.todayCompleted ? "今日の10問 完了済み" : "今日の10問を開始")
        .accessibilityIdentifier("home_today_quick_tile")
    }
}

// MARK: - Quick Action Tile (compact secondary action)

private struct HomeQuickActionTile<Destination: View>: View {
    let title: String
    let icon: String
    var tint: Color = OniTanTheme.accentPrimary
    let destination: Destination

    @State private var isPressed = false

    var body: some View {
        NavigationLink(destination: destination) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(tint)
                Text(title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(OniTanTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .oniCard()
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(title)
        .accessibilityHint("タップして\(title)へ進む")
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
