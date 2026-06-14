import SwiftUI
import StoreKit

// MARK: - Main Quiz View

struct MainView: View {
    @StateObject private var vm: QuizSessionViewModel
    @State private var activeReportContext: QuizProblemReportContext?
    @State private var hasPlayedCompletionHaptic = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview
    @EnvironmentObject var reviewPromptManager: ReviewPromptManager
    @EnvironmentObject var favoriteRepo: FavoriteKanjiRepository
    @EnvironmentObject var playFontManager: PlayFontManager
    @EnvironmentObject var donationManager: DonationManager
    @EnvironmentObject var adConsentManager: AdConsentManager
    @EnvironmentObject var interstitialManager: AdInterstitialManager
    @EnvironmentObject var streakRepo: StreakRepository
    @EnvironmentObject var xpRepo: GamificationRepository
    @EnvironmentObject var masteryRepo: MasteryRepository
    @EnvironmentObject var appNavState: AppNavigationState
    @EnvironmentObject var examResultRepo: ExamResultRepository

    private let appState: AppState
    private let statsRepo: StudyStatsRepository
    private let passedStreakRepo: StreakRepository?
    private let passedXPRepo: GamificationRepository?
    private let passedMasteryRepo: MasteryRepository?
    private let nextStage: Stage?
    private let nextStageTitle: String?

    init(
        stage: Stage,
        appState: AppState,
        statsRepo: StudyStatsRepository,
        streakRepo: StreakRepository? = nil,
        xpRepo: GamificationRepository? = nil,
        masteryRepo: MasteryRepository? = nil,
        examResultRepo: ExamResultRepository? = nil,
        examBlueprintID: String? = nil,
        mode: QuizMode = .normal,
        clearTitle: String? = nil,
        sessionTitle: String? = nil,
        nextStage: Stage? = nil,
        nextStageTitle: String? = nil
    ) {
        self.appState = appState
        self.statsRepo = statsRepo
        self.passedStreakRepo = streakRepo
        self.passedXPRepo = xpRepo
        self.passedMasteryRepo = masteryRepo
        self.nextStage = nextStage
        self.nextStageTitle = nextStageTitle
        _vm = StateObject(wrappedValue: QuizSessionViewModel(
            stage: stage,
            appState: appState,
            statsRepo: statsRepo,
            streakRepo: streakRepo,
            xpRepo: xpRepo,
            masteryRepo: masteryRepo,
            examResultRepo: examResultRepo,
            examBlueprintID: examBlueprintID,
            mode: mode,
            clearTitle: clearTitle,
            sessionTitle: sessionTitle
        ))
    }

    /// Whether we are in wrong-answer feedback state
    private var isShowingWrong: Bool {
        if case .showingWrongAnswer = vm.phase { return true }
        return false
    }

    var body: some View {
        ZStack {
            OniTanTheme.backgroundGradientFallback
                .ignoresSafeArea()

            VStack(spacing: 0) {
                GeometryReader { proxy in
                    let scale = layoutScale(containerHeight: proxy.size.height, safeArea: proxy.safeAreaInsets)

                    ZStack {
                        VStack(spacing: 0) {
                            topBar(scale: scale)

                            switch vm.phase {
                            case .stageCleared:
                                if let result = vm.examResult {
                                    ExamResultView(
                                        result: result,
                                        blueprint: examBlueprints.first(where: { $0.id == result.blueprintID })
                                    )
                                    .environmentObject(playFontManager)
                                    .transition(.asymmetric(
                                        insertion: .scale(scale: 0.85).combined(with: .opacity),
                                        removal: .opacity
                                    ))
                                } else {
                                    stageClearedView
                                        .transition(.asymmetric(
                                            insertion: .scale(scale: 0.85).combined(with: .opacity),
                                            removal: .opacity
                                        ))
                                }
                            default:
                                quizContentView(scale: scale)
                            }
                        }
                        .navigationBarBackButtonHidden(true)

                    }
                    .animation(.easeInOut(duration: 0.25), value: vm.phase)
                }

            }
        }
        .alert(item: $vm.activeAlert) { alert in
            alertView(for: alert)
        }
        .sheet(item: $activeReportContext) { context in
            ProblemReportSheet(context: context)
        }
        .onAppear {
            if !donationManager.hasDonated {
                interstitialManager.loadIfNeeded(canRequestAds: adConsentManager.canRequestAds)
            }
        }
        .onChange(of: appNavState.shouldPopToRoot) { should in
            if should { dismiss() }
        }
        .onChange(of: vm.phase) { phase in
            if case .stageCleared = phase {
                if !hasPlayedCompletionHaptic {
                    hasPlayedCompletionHaptic = true
                    OniTanTheme.hapticSuccess()
                }
                if !donationManager.hasDonated {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        guard !appState.isDailySummaryPresented else { return }
                        interstitialManager.showIfReady(canRequestAds: adConsentManager.canRequestAds)
                    }
                }
                if reviewPromptManager.sessionCompleted(currentStreak: streakRepo.currentStreak) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        guard !appState.isDailySummaryPresented else { return }
                        requestReview()
                    }
                }
            } else {
                hasPlayedCompletionHaptic = false
            }
        }
    }

    // MARK: - Top Bar

    private func topBar(scale: CGFloat) -> some View {
        HStack(spacing: scaled(12, by: scale, min: 8)) {
            // Quit button
            Button {
                if vm.phase == .stageCleared {
                    dismiss()
                } else {
                    vm.requestQuit()
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: scaled(14, by: scale, min: 12), weight: .bold))
                    .foregroundColor(OniTanTheme.textSecondary)
                    .frame(width: scaled(34, by: scale, min: 30), height: scaled(34, by: scale, min: 30))
                    .background(Color.black.opacity(0.16))
                    .overlay(Circle().stroke(OniTanTheme.cardBorder, lineWidth: 1))
                    .clipShape(Circle())
            }
            .accessibilityLabel("終了")
            .accessibilityHint("タップすると確認ダイアログが表示されます")

            // Combo badge (appears at 3+ consecutive correct answers)
            Spacer()

            if vm.consecutiveCorrect >= 3 {
                HStack(spacing: scaled(4, by: scale, min: 2)) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: scaled(10, by: scale, min: 8), weight: .bold))
                        .foregroundColor(OniTanTheme.accentWeak)
                    Text("\(vm.consecutiveCorrect)連続！")
                        .font(playFont(scaled(12, by: scale, min: 10), weight: .bold))
                        .foregroundColor(OniTanTheme.accentWeak)
                }
                .padding(.horizontal, scaled(10, by: scale, min: 8))
                .padding(.vertical, scaled(4, by: scale, min: 3))
                .background(
                    Capsule()
                        .fill(OniTanTheme.accentWeak.opacity(0.12))
                        .overlay(Capsule().stroke(OniTanTheme.accentWeak.opacity(0.5), lineWidth: 1))
                )
                .transition(.scale(scale: 0.7).combined(with: .opacity))
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: vm.consecutiveCorrect)
                .accessibilityLabel("\(vm.consecutiveCorrect)連続正解")
            }

            if vm.phase != .stageCleared {
                quizUtilityCluster(scale: scale)
            }
        }
        .padding(.horizontal, scaled(20, by: scale, min: 14))
        .padding(.top, scaled(8, by: scale, min: 6))
        .padding(.bottom, scaled(4, by: scale, min: 2))
    }

    private func quizUtilityCluster(scale: CGFloat) -> some View {
        HStack(spacing: 2) {
            favoriteButton(scale: scale)
            reportButton(scale: scale)
        }
        .padding(3)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.18))
                .overlay(Capsule().stroke(OniTanTheme.cardBorder, lineWidth: 1))
        )
        .accessibilityElement(children: .contain)
    }

    // MARK: - Quiz Content

    private func quizContentView(scale: CGFloat) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            // Stage number + pass indicator
            stageHeader(scale: scale)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(OniTanTheme.cardBackground)
                    Capsule()
                        .fill(vm.lastAnswerResult == .wrong ? OniTanTheme.dangerGradient : OniTanTheme.goldGradient)
                        .frame(width: proxy.size.width * max(0, min(1, vm.progressFraction)))
                }
            }
            .frame(height: scaled(6, by: scale, min: 4))
            .padding(.top, scaled(4, by: scale, min: 3))
            .accessibilityHidden(true)

            Spacer(minLength: scaled(4, by: scale, min: 2))

            // Kanji display — shrinks when showing wrong answer
            kanjiDisplay(scale: scale)

            Spacer(minLength: scaled(8, by: scale, min: 4))

            // Choice area
            switch vm.phase {
            case .answering:
                choiceStack(scale: scale)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            case .showingExplanation:
                answerFeedbackView(isCorrect: true, correctAnswer: vm.currentQuestion.answer, scale: scale)
                    .transition(.scale(scale: 0.96).combined(with: .opacity))
            case .showingWrongAnswer(let correct):
                answerFeedbackView(isCorrect: false, correctAnswer: correct, scale: scale)
                    .transition(.scale(scale: 0.96).combined(with: .opacity))
            default:
                EmptyView()
            }

            Spacer(minLength: scaled(10, by: scale, min: 6))
        }
        .padding(.horizontal, scaled(20, by: scale, min: 14))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func stageHeader(scale: CGFloat) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: scaled(2, by: scale, min: 1)) {
                Text(vm.displayTitle)
                    .font(playFont(scaled(20, by: scale, min: 17), weight: .bold))
                    .fontWeight(.bold)
                    .foregroundColor(OniTanTheme.textPrimary)
                if vm.passNumber > 1 {
                    Text("復習パス \(vm.passNumber)")
                        .font(playFont(scaled(12, by: scale, min: 10), weight: .regular))
                        .foregroundColor(OniTanTheme.accentWeak)
                }
            }

            Spacer()

            Text("\(vm.clearedCount) / \(vm.totalGoal) 問")
                .font(playFont(scaled(16, by: scale, min: 12), weight: .regular))
                .foregroundColor(OniTanTheme.textSecondary)
        }
        .accessibilityElement()
        .accessibilityLabel("\(vm.displayTitle) \(vm.clearedCount)問中\(vm.totalGoal)問正解")
    }

    // MARK: - Kanji / Prompt Display

    private func kanjiDisplay(scale: CGFloat) -> some View {
        QuestionPromptView(
            question: vm.currentQuestion,
            scale: scale,
            isCorrect: vm.lastAnswerResult == .correct,
            isWrong:   vm.lastAnswerResult == .wrong
        )
        .id(vm.currentQuestion.id)
        .animation(.easeInOut(duration: 0.25), value: isShowingWrong)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("quiz_kanji")
    }

    @ViewBuilder
    private func favoriteButton(scale: CGFloat) -> some View {
        if let favoriteKanji = vm.currentQuestion.favoriteKanjiCharacter {
            let isFavorite = favoriteRepo.isFavorite(favoriteKanji)

            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                    favoriteRepo.toggle(favoriteKanji)
                }
                OniTanTheme.haptic(.light)
            } label: {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .font(.system(size: scaled(14, by: scale, min: 12), weight: .bold))
                    .foregroundColor(isFavorite ? OniTanTheme.accentWeak : OniTanTheme.textSecondary)
                    .frame(width: scaled(32, by: scale, min: 28), height: scaled(32, by: scale, min: 28))
                    .background(isFavorite ? OniTanTheme.accentWeak.opacity(0.12) : Color.clear)
                    .clipShape(Circle())
            }
            .accessibilityLabel(isFavorite ? "お気に入り解除" : "お気に入り追加")
            .accessibilityHint(isFavorite ? "この漢字をお気に入りから外します" : "この漢字をお気に入りに登録します")
            .accessibilityIdentifier("quiz_favorite_toggle")
        }
    }

    private func reportButton(scale: CGFloat) -> some View {
        Button {
            presentProblemReport(for: vm.currentQuestion)
            OniTanTheme.haptic(.light)
        } label: {
            Image(systemName: "exclamationmark.bubble")
                .font(.system(size: scaled(14, by: scale, min: 12), weight: .bold))
                .foregroundColor(OniTanTheme.textSecondary)
                .frame(width: scaled(32, by: scale, min: 28), height: scaled(32, by: scale, min: 28))
                .background(Color.clear)
                .clipShape(Circle())
        }
        .accessibilityLabel("問題を報告")
        .accessibilityHint("現在の問題内容を添えて報告画面を開きます")
        .accessibilityIdentifier("quiz_problem_report")
    }

    // MARK: - Choice Grid

    private func choiceStack(scale: CGFloat) -> some View {
        let shuffled = vm.currentChoices
        let usesMeaningChoices = vm.currentQuestion.kind == .proverb
        let gridSpacing = scaled(usesMeaningChoices ? 8 : 10, by: scale, min: 6)
        let columns = usesMeaningChoices
            ? [GridItem(.flexible(), spacing: gridSpacing)]
            : [
                GridItem(.flexible(), spacing: gridSpacing),
                GridItem(.flexible(), spacing: gridSpacing)
            ]

        return VStack(alignment: .leading, spacing: scaled(10, by: scale, min: 8)) {
            yojijukugoMeaningHint(scale: scale)

            choicePromptLabel(scale: scale)

            if let note = vm.currentQuestion.readingMetadata.playerNote(for: vm.currentQuestion.answer) {
                Text(note)
                    .font(playFont(scaled(12, by: scale, min: 10), weight: .regular))
                    .foregroundColor(OniTanTheme.accentWeak)
                    .padding(.leading, 4)
                    .fixedSize(horizontal: false, vertical: true)
            }

            LazyVGrid(columns: columns, spacing: gridSpacing) {
                ForEach(Array(shuffled.enumerated()), id: \.offset) { _, choice in
                    ChoiceCard(
                        text: choice,
                        scale: scale,
                        fontStyle: playFontManager.fontStyle,
                        layout: usesMeaningChoices ? .meaning : .standard,
                        onTap: {
                            let wasCorrect = choice == vm.currentQuestion.answer
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                vm.answer(selected: choice)
                            }
                            wasCorrect ? OniTanTheme.hapticSuccess() : OniTanTheme.hapticError()
                        }
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func choicePromptLabel(scale: CGFloat) -> some View {
        if vm.currentQuestion.kind == .synonym || vm.currentQuestion.kind == .antonym {
            let accent = relationAccent(for: vm.currentQuestion.kind)
            let label = vm.currentQuestion.kind.displayName

            HStack(spacing: scaled(6, by: scale, min: 4)) {
                Image(systemName: vm.currentQuestion.kind.systemImage)
                    .font(.system(size: scaled(12, by: scale, min: 10), weight: .bold))
                    .accessibilityHidden(true)

                Text(label)
                    .font(playFont(scaled(14, by: scale, min: 12), weight: .black))

                Text("を選びなさい")
                    .font(playFont(scaled(13, by: scale, min: 11), weight: .semibold))
                    .foregroundColor(OniTanTheme.textSecondary)
            }
            .foregroundColor(accent)
            .padding(.horizontal, scaled(11, by: scale, min: 9))
            .padding(.vertical, scaled(6, by: scale, min: 5))
            .background(
                Capsule()
                    .fill(accent.opacity(0.13))
                    .overlay(
                        Capsule()
                            .stroke(accent.opacity(0.32), lineWidth: 1)
                    )
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(label)を選びなさい")
        } else {
            Text(vm.currentQuestion.kind.choicePrompt)
                .font(playFont(scaled(13, by: scale, min: 11), weight: .semibold))
                .foregroundColor(OniTanTheme.textTertiary)
                .padding(.leading, 4)
        }
    }

    private func relationAccent(for kind: QuestionKind) -> Color {
        kind == .antonym ? Color(hex: "F87171") : Color(hex: "60A5FA")
    }

    @ViewBuilder
    private func yojijukugoMeaningHint(scale: CGFloat) -> some View {
        if vm.currentQuestion.kind == .yojijukugo,
           let meaning = yojijukugoMeaningText(for: vm.currentQuestion) {
            HStack(alignment: .top, spacing: scaled(9, by: scale, min: 7)) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: scaled(13, by: scale, min: 11), weight: .bold))
                    .foregroundColor(OniTanTheme.accentWeak)
                    .frame(width: scaled(22, by: scale, min: 18), height: scaled(22, by: scale, min: 18))
                    .background(OniTanTheme.accentWeak.opacity(0.12))
                    .clipShape(Circle())
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: scaled(3, by: scale, min: 2)) {
                    Text("意味")
                        .font(playFont(scaled(11, by: scale, min: 9), weight: .bold))
                        .foregroundColor(OniTanTheme.accentWeak)

                    Text(meaning)
                        .font(playFont(scaled(13, by: scale, min: 11), weight: .regular))
                        .foregroundColor(OniTanTheme.textSecondary)
                        .lineSpacing(2)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, scaled(12, by: scale, min: 10))
            .padding(.vertical, scaled(10, by: scale, min: 8))
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: scaled(14, by: scale, min: 12))
                    .fill(OniTanTheme.cardBackground.opacity(0.72))
                    .overlay(
                        RoundedRectangle(cornerRadius: scaled(14, by: scale, min: 12))
                            .stroke(OniTanTheme.accentWeak.opacity(0.22), lineWidth: 1)
                    )
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel("四字熟語の意味: \(meaning)")
        }
    }

    private func yojijukugoMeaningText(for question: Question) -> String? {
        [question.payload?.meaning, question.termMeaning]
            .compactMap { value -> String? in
                guard let value else { return nil }
                let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? nil : trimmed
            }
            .first
    }

    // MARK: - Answer Feedback View

    private func answerFeedbackView(isCorrect: Bool, correctAnswer: String, scale: CGFloat) -> some View {
        let tint = isCorrect ? OniTanTheme.feedbackCorrect : OniTanTheme.accentWrong
        let title = isCorrect ? "正解" : "不正解"
        let border = tint.opacity(isCorrect ? 0.34 : 0.42)

        return VStack(alignment: .leading, spacing: scaled(12, by: scale, min: 8)) {
            HStack(alignment: .center, spacing: scaled(10, by: scale, min: 6)) {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: scaled(22, by: scale, min: 18), weight: .bold))
                    .foregroundColor(tint)
                    .frame(width: scaled(40, by: scale, min: 34), height: scaled(40, by: scale, min: 34))
                    .background(
                        RoundedRectangle(cornerRadius: scaled(11, by: scale, min: 9))
                            .fill(tint.opacity(0.13))
                            .overlay(
                                RoundedRectangle(cornerRadius: scaled(11, by: scale, min: 9))
                                    .stroke(tint.opacity(0.34), lineWidth: 1)
                            )
                    )
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: scaled(3, by: scale, min: 2)) {
                    Text(title)
                        .font(playFont(scaled(22, by: scale, min: 18), weight: .black))
                        .foregroundColor(tint)

                    Text("正解は「\(correctAnswer)」")
                        .font(playFont(scaled(17, by: scale, min: 14), weight: .semibold))
                        .foregroundColor(OniTanTheme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(vm.currentQuestion.displayExplanation)
                .font(playFont(scaled(13, by: scale, min: 11), weight: .regular))
                .foregroundColor(OniTanTheme.textSecondary)
                .lineSpacing(4)
                .lineLimit(8)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                withAnimation { vm.proceed() }
                OniTanTheme.haptic(.light)
            } label: {
                Text("次へ")
                    .font(playFont(17, weight: .bold))
                    .fontWeight(.bold)
                    .foregroundColor(OniTanTheme.textPrimary)
                    .frame(maxWidth: .infinity, minHeight: scaled(50, by: scale, min: 44))
                    .background(
                        RoundedRectangle(cornerRadius: OniTanTheme.radiusButton)
                            .fill(isCorrect ? OniTanTheme.feedbackCorrectGradient : OniTanTheme.wrongGradient)
                    )
                    .shadow(
                        color: tint.opacity(0.35),
                        radius: scaled(8, by: scale, min: 4),
                        y: scaled(4, by: scale, min: 2)
                    )
            }
            .accessibilityLabel("次の問題へ進む")
            .accessibilityIdentifier(isCorrect ? "quiz_next_correct" : "quiz_next_wrong")
        }
        .padding(.horizontal, scaled(20, by: scale, min: 14))
        .padding(.vertical, scaled(16, by: scale, min: 12))
        .background(
            RoundedRectangle(cornerRadius: OniTanTheme.radiusCard)
                .fill(OniTanTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: OniTanTheme.radiusCard)
                        .stroke(border, lineWidth: 1)
                )
        )
        .frame(maxWidth: .infinity)
    }

    // MARK: - Stage Cleared

    private var stageClearedView: some View {
        let weakReviewStage = (!vm.isSpecialSession && !statsRepo.weakQuestions(for: vm.stage).isEmpty) ? vm.stage : nil
        let repeatLabel = vm.mode == .quick10 ? "もう一度10問" : "もう一度"

        return VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(OniTanTheme.accentCorrect.opacity(0.15))
                    .frame(width: 70, height: 70)
                    .blur(radius: 12)

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(OniTanTheme.goldGradient)
                    .shadow(color: OniTanTheme.accentWeak.opacity(0.45), radius: 10)
                    .accessibilityHidden(true)
            }

            VStack(spacing: 6) {
                Text(vm.clearTitle)
                    .font(playFont(24, weight: .black))
                    .foregroundColor(OniTanTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                Text("全 \(vm.totalGoal) 問クリア！")
                    .font(playFont(13, weight: .semibold))
                    .foregroundColor(OniTanTheme.textSecondary)
            }

            if let newLevel = (passedXPRepo ?? xpRepo).recentLevelUp {
                LevelUpBanner(level: newLevel)
            }

            ProgressRingView(
                progress: 1.0,
                lineWidth: 8,
                size: 70,
                gradient: Gradient(colors: [OniTanTheme.accentCorrect, OniTanTheme.accentPrimary]),
                label: "完了"
            )
            .shadow(color: OniTanTheme.accentCorrect.opacity(0.5), radius: 10)

            VStack(spacing: 8) {
                if let next = nextStage {
                    let nextNext = stageAfter(next)
                    let nextNextTitle = nextNext.map { displayTitle(for: $0) }

                    NavigationLink(
                        destination: MainView(
                            stage: next,
                            appState: appState,
                            statsRepo: statsRepo,
                            streakRepo: passedStreakRepo ?? streakRepo,
                            xpRepo: passedXPRepo ?? xpRepo,
                            masteryRepo: passedMasteryRepo ?? masteryRepo,
                            mode: .normal,
                            clearTitle: "\(displayTitle(for: next)) クリア！",
                            sessionTitle: nextStageTitle,
                            nextStage: nextNext,
                            nextStageTitle: nextNextTitle
                        )
                    ) {
                        HStack(spacing: 8) {
                            Text("次の稽古へ")
                                .font(playFont(15, weight: .bold))
                                .fontWeight(.bold)
                                .foregroundColor(OniTanTheme.textPrimary)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(OniTanTheme.textPrimary.opacity(0.8))
                                .accessibilityHidden(true)
                        }
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(OniTanTheme.primaryGradient)
                        .cornerRadius(OniTanTheme.radiusButton)
                        .shadow(color: OniTanTheme.accentPrimary.opacity(0.4), radius: 6, y: 3)
                    }
                    .buttonStyle(PlainButtonStyle())

                } else {
                    Button {
                        withAnimation { vm.resetGame() }
                        OniTanTheme.haptic(.light)
                    } label: {
                        Text(repeatLabel)
                            .font(playFont(15, weight: .bold))
                            .fontWeight(.bold)
                            .foregroundColor(OniTanTheme.textPrimary)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(OniTanTheme.goldGradient)
                            .cornerRadius(OniTanTheme.radiusButton)
                            .shadow(color: OniTanTheme.accentWeak.opacity(0.28), radius: 6, y: 3)
                    }
                }

                if let weakReviewStage {
                    NavigationLink(
                        destination: MainView(
                            stage: weakReviewStage,
                            appState: appState,
                            statsRepo: statsRepo,
                            streakRepo: passedStreakRepo ?? streakRepo,
                            xpRepo: passedXPRepo ?? xpRepo,
                            masteryRepo: passedMasteryRepo ?? masteryRepo,
                            mode: .weakFocus,
                            clearTitle: "苦手復習 完了！",
                            sessionTitle: "苦手を復習"
                        )
                    ) {
                        Text("苦手を復習")
                            .font(playFont(14, weight: .bold))
                            .foregroundColor(OniTanTheme.textPrimary)
                            .frame(maxWidth: .infinity, minHeight: 42)
                            .background(OniTanTheme.cardBackgroundPressed)
                            .overlay(
                                RoundedRectangle(cornerRadius: OniTanTheme.radiusButton)
                                    .stroke(OniTanTheme.accentWeak.opacity(0.28), lineWidth: 1)
                            )
                            .cornerRadius(OniTanTheme.radiusButton)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                Button {
                    OniTanTheme.haptic(.light)
                    appNavState.popToRoot()
                    dismiss()
                } label: {
                    Text("ホームへ戻る")
                        .font(playFont(13, weight: .semibold))
                        .foregroundColor(OniTanTheme.textTertiary)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(vm.clearTitle) 全\(vm.totalGoal)問クリアしました")
        .onDisappear {
            (passedXPRepo ?? xpRepo).clearLevelUpFlag()
        }
    }

    // MARK: - Alert

    private func alertView(for alert: OniAlert) -> Alert {
        if alert.isDestructive {
            return Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                primaryButton: .destructive(Text("OK")) { dismiss() },
                secondaryButton: .cancel(Text("キャンセル"))
            )
        } else {
            return Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private func layoutScale(containerHeight: CGFloat, safeArea: EdgeInsets) -> CGFloat {
        let usable = max(1, containerHeight - safeArea.top - safeArea.bottom)
        let baseHeight: CGFloat = 780
        let raw = usable / baseHeight
        return min(1.0, max(0.75, raw))
    }

    private func scaled(_ value: CGFloat, by scale: CGFloat, min minValue: CGFloat) -> CGFloat {
        max(minValue, value * scale)
    }

    private func playFont(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        playFontManager.font(size: size, weight: weight)
    }

    // MARK: - Stage Navigation Helpers

    private func stageAfter(_ s: Stage) -> Stage? {
        let sorted = quizData.stages.sorted { $0.stage < $1.stage }
        guard let idx = sorted.firstIndex(where: { $0.stage == s.stage }),
              idx + 1 < sorted.count else { return nil }
        return sorted[idx + 1]
    }

    private func displayTitle(for s: Stage) -> String {
        let sorted = quizData.stages.sorted { $0.stage < $1.stage }
        let num = (sorted.firstIndex(where: { $0.stage == s.stage }) ?? 0) + 1
        return "稽古 \(num)"
    }

    private func presentProblemReport(for question: Question) {
        activeReportContext = QuizProblemReportContext(
            question: question,
            sessionTitle: vm.displayTitle,
            modeName: vm.mode.displayName,
            stageNumber: vm.stageNumber > 0 ? vm.stageNumber : nil
        )
    }
}

// MARK: - Choice Card

private enum ChoiceCardLayout {
    case standard
    case meaning
}

private struct ChoiceCard: View {
    let text: String
    let scale: CGFloat
    let fontStyle: PlayFontStyle
    let layout: ChoiceCardLayout
    let onTap: () -> Void

    @State private var isPressed = false

    private var isMeaningLayout: Bool { layout == .meaning }
    private var textSize: CGFloat { isMeaningLayout ? max(14, 16 * scale) : max(18, 24 * scale) }
    private var minHeight: CGFloat { isMeaningLayout ? max(58, 64 * scale) : max(50, 64 * scale) }
    private var horizontalPadding: CGFloat { isMeaningLayout ? max(14, 16 * scale) : 0 }
    private var verticalPadding: CGFloat { isMeaningLayout ? max(8, 10 * scale) : 0 }

    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.10)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.10)) {
                    isPressed = false
                }
            }
            onTap()
        }) {
            Text(text)
                .font(fontStyle.font(size: textSize, weight: .bold))
                .fontWeight(.bold)
                .foregroundColor(OniTanTheme.textPrimary)
                .minimumScaleFactor(isMeaningLayout ? 0.78 : 0.6)
                .lineLimit(isMeaningLayout ? 3 : 2)
                .multilineTextAlignment(isMeaningLayout ? .leading : .center)
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, verticalPadding)
                .frame(
                    maxWidth: .infinity,
                    minHeight: minHeight,
                    alignment: isMeaningLayout ? .leading : .center
                )
        }
        .background(
            RoundedRectangle(cornerRadius: max(12, OniTanTheme.radiusButton * scale))
                .fill(
                    isPressed
                        ? OniTanTheme.primaryGradient
                        : LinearGradient(
                            colors: [OniTanTheme.cardBackground, OniTanTheme.cardBackground.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: max(12, OniTanTheme.radiusButton * scale))
                        .stroke(isPressed ? OniTanTheme.accentPrimary.opacity(0.5) : OniTanTheme.cardBorder, lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.2), radius: max(3, 6 * scale), y: max(2, 3 * scale))
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("選択肢: \(text)")
        .accessibilityHint("タップするとこの選択肢を選びます")
        .accessibilityIdentifier("quiz_choice_\(text)")
    }
}

// MARK: - Explanation Overlay

struct ExplanationView: View {
    let question: Question
    let onDismiss: () -> Void
    let onReport: () -> Void

    @EnvironmentObject private var playFontManager: PlayFontManager
    @EnvironmentObject private var favoriteRepo: FavoriteKanjiRepository
    @State private var appear = false

    private var favoriteKanjiCharacter: String? { question.favoriteKanjiCharacter }
    private var isFavorite: Bool {
        favoriteKanjiCharacter.map { favoriteRepo.isFavorite($0) } ?? false
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.72)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 0) {
                // Utility button row
                HStack {
                    Spacer()
                    HStack(spacing: 2) {
                        if let favoriteKanjiCharacter {
                            Button {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                                    favoriteRepo.toggle(favoriteKanjiCharacter)
                                }
                                OniTanTheme.haptic(.light)
                            } label: {
                                Image(systemName: isFavorite ? "star.fill" : "star")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(isFavorite ? OniTanTheme.accentWeak : OniTanTheme.textSecondary)
                                    .frame(width: 32, height: 32)
                                    .background(isFavorite ? OniTanTheme.accentWeak.opacity(0.12) : Color.clear)
                                    .clipShape(Circle())
                            }
                            .accessibilityLabel(isFavorite ? "お気に入り解除" : "お気に入り追加")
                            .accessibilityIdentifier("quiz_explanation_favorite")
                        }

                        Button {
                            onReport()
                        } label: {
                            Image(systemName: "exclamationmark.bubble")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(OniTanTheme.textSecondary)
                                .frame(width: 32, height: 32)
                        }
                        .accessibilityLabel("問題を報告")
                    }
                    .padding(3)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.18))
                            .overlay(Capsule().stroke(OniTanTheme.cardBorder, lineWidth: 1))
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .background(OniTanTheme.cardBackgroundPressed)

                // Kind-aware header + explanation
                ScrollView {
                    ExplanationContentView(question: question)
                        .environmentObject(playFontManager)
                }
                .frame(maxHeight: 360)
                .background(OniTanTheme.cardBackground)

                // Reading-specific note (shown for all reading kinds)
                if (question.kind == .reading
                    || question.kind == .sentenceReading
                    || question.kind == .hyogaiReading
                    || question.kind == .compoundReadingKun),
                   let note = question.readingMetadata.playerNote(for: question.answer) {
                    Text(note)
                        .font(playFontManager.font(size: 12))
                        .foregroundColor(OniTanTheme.accentWeak)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(OniTanTheme.cardBackgroundPressed)
                }

                // Bottom action row
                HStack(spacing: 0) {
                    Button {
                        onDismiss()
                        OniTanTheme.haptic(.light)
                    } label: {
                        Text("次の問題へ")
                            .font(playFontManager.font(size: 17, weight: .bold))
                            .fontWeight(.bold)
                            .foregroundColor(OniTanTheme.textPrimary)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .background(OniTanTheme.primaryGradient)
                    }
                    .accessibilityIdentifier("quiz_next_explanation")
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(OniTanTheme.cardBorder, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.5), radius: 30)
            .padding(.horizontal, 20)
            .scaleEffect(appear ? 1 : 0.88)
            .opacity(appear ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    appear = true
                }
                OniTanTheme.hapticSuccess()
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("正解の解説: \(question.kanji). \(question.displayExplanation)")
        .accessibilityHint("タップまたは次へボタンで閉じます")
    }
}
