import SwiftUI

// MARK: - Main Quiz View

struct MainView: View {
    @StateObject private var vm: QuizSessionViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var favoriteRepo: FavoriteKanjiRepository
    @EnvironmentObject var playFontManager: PlayFontManager
    @EnvironmentObject var donationManager: DonationManager

    init(
        stage: Stage,
        appState: AppState,
        statsRepo: StudyStatsRepository,
        streakRepo: StreakRepository? = nil,
        xpRepo: GamificationRepository? = nil,
        mode: QuizMode = .normal,
        clearTitle: String? = nil,
        sessionTitle: String? = nil
    ) {
        _vm = StateObject(wrappedValue: QuizSessionViewModel(
            stage: stage,
            appState: appState,
            statsRepo: statsRepo,
            streakRepo: streakRepo,
            xpRepo: xpRepo,
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
                                stageClearedView
                                    .transition(.asymmetric(
                                        insertion: .scale(scale: 0.85).combined(with: .opacity),
                                        removal: .opacity
                                    ))
                            default:
                                quizContentView(scale: scale)
                            }
                        }
                        .navigationBarBackButtonHidden(true)

                        // Explanation overlay
                        if vm.phase == .showingExplanation {
                            ExplanationView(question: vm.currentQuestion) {
                                vm.proceed()
                            }
                            .environmentObject(playFontManager)
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.2), value: vm.phase)
                            .zIndex(10)
                        }
                    }
                    .animation(.easeInOut(duration: 0.25), value: vm.phase)
                }

                if !donationManager.hasDonated {
                    AdBannerView()
                }
            }
        }
        .alert(item: $vm.activeAlert) { alert in
            alertView(for: alert)
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
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: scaled(26, by: scale, min: 20)))
                    .foregroundColor(OniTanTheme.textSecondary)
            }
            .accessibilityLabel("終了")
            .accessibilityHint("タップすると確認ダイアログが表示されます")

            Spacer()

            // Combo badge (appears at 3+ consecutive correct answers)
            if vm.consecutiveCorrect >= 3 {
                HStack(spacing: scaled(4, by: scale, min: 2)) {
                    Text("🔥")
                        .font(.system(size: scaled(13, by: scale, min: 10)))
                    Text("\(vm.consecutiveCorrect)連続！")
                        .font(playFont(scaled(12, by: scale, min: 10), weight: .bold))
                        .foregroundColor(OniTanTheme.accentWeak)
                }
                .padding(.horizontal, scaled(10, by: scale, min: 8))
                .padding(.vertical, scaled(4, by: scale, min: 3))
                .background(
                    Capsule()
                        .fill(Color(red: 0.5, green: 0.25, blue: 0.0).opacity(0.55))
                        .overlay(Capsule().stroke(OniTanTheme.accentWeak.opacity(0.5), lineWidth: 1))
                )
                .transition(.scale(scale: 0.7).combined(with: .opacity))
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: vm.consecutiveCorrect)
                .accessibilityLabel("\(vm.consecutiveCorrect)連続正解")
            }

            // Mode badge
            HStack(spacing: scaled(4, by: scale, min: 2)) {
                Image(systemName: vm.mode.systemImage)
                    .font(.system(size: scaled(11, by: scale, min: 9)))
                Text(vm.mode.displayName)
                    .font(playFont(scaled(12, by: scale, min: 10), weight: .semibold))
            }
            .foregroundColor(OniTanTheme.textTertiary)
            .padding(.horizontal, scaled(10, by: scale, min: 8))
            .padding(.vertical, scaled(4, by: scale, min: 3))
            .background(OniTanTheme.cardBackground)
            .cornerRadius(20)

            // Progress ring
            ProgressRingView(
                progress: vm.progressFraction,
                lineWidth: scaled(5, by: scale, min: 4),
                size: scaled(44, by: scale, min: 36),
                gradient: Gradient(colors: [OniTanTheme.accentPrimary, OniTanTheme.accentCorrect])
            )
            .accessibilityLabel("進捗 \(vm.clearedCount)問 / \(vm.totalGoal)問")
        }
        .padding(.horizontal, scaled(20, by: scale, min: 14))
        .padding(.top, scaled(12, by: scale, min: 8))
        .padding(.bottom, scaled(8, by: scale, min: 4))
    }

    // MARK: - Quiz Content

    private func quizContentView(scale: CGFloat) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: scaled(10, by: scale, min: 6))

            // Stage number + pass indicator
            stageHeader(scale: scale)

            Spacer(minLength: scaled(14, by: scale, min: 10))

            // Kanji display — shrinks when showing wrong answer
            kanjiDisplay(scale: scale)

            Spacer(minLength: scaled(18, by: scale, min: 12))

            // Choice area
            switch vm.phase {
            case .answering:
                choiceStack(scale: scale)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            case .showingWrongAnswer(let correct):
                wrongAnswerView(correctAnswer: correct, scale: scale)
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
            default:
                EmptyView()
            }

            Spacer(minLength: scaled(22, by: scale, min: 14))
        }
        .padding(.horizontal, scaled(20, by: scale, min: 14))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func stageHeader(scale: CGFloat) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: scaled(2, by: scale, min: 1)) {
                Text(vm.displayTitle)
                    .font(playFont(scaled(22, by: scale, min: 18), weight: .bold))
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

    // MARK: - Kanji Display

    private func kanjiDisplay(scale: CGFloat) -> some View {
        let corner = scaled(24, by: scale, min: 16)
        let kanjiHeight: CGFloat = scaled(208, by: scale, min: 164)
        let kanjiFont: CGFloat = scaled(122, by: scale, min: 88)

        return ZStack {
            // Background card
            RoundedRectangle(cornerRadius: corner)
                .fill(OniTanTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: corner)
                        .stroke(OniTanTheme.cardBorder, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.2), radius: scaled(16, by: scale, min: 8), y: scaled(8, by: scale, min: 4))

            // Flash on answer
            if vm.lastAnswerResult == .correct {
                RoundedRectangle(cornerRadius: corner)
                    .fill(OniTanTheme.accentCorrect.opacity(0.25))
                    .transition(.opacity)
            } else if vm.lastAnswerResult == .wrong {
                RoundedRectangle(cornerRadius: corner)
                    .fill(OniTanTheme.accentWrong.opacity(0.25))
                    .transition(.opacity)
            }

            Text(vm.currentQuestion.kanji)
                .font(playFont(kanjiFont, weight: .black))
                .foregroundColor(OniTanTheme.textPrimary)
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .shadow(color: .black.opacity(0.3), radius: 4)
                .id(vm.currentQuestion.id)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .padding(scaled(16, by: scale, min: 8))
        }
        .frame(height: kanjiHeight)
        .overlay(alignment: .topTrailing) {
            favoriteButton(scale: scale)
                .padding(scaled(14, by: scale, min: 10))
        }
        .animation(.easeInOut(duration: 0.25), value: isShowingWrong)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("quiz_kanji")
    }

    private func favoriteButton(scale: CGFloat) -> some View {
        let isFavorite = favoriteRepo.isFavorite(vm.currentQuestion.kanji)

        return Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                favoriteRepo.toggle(vm.currentQuestion.kanji)
            }
            OniTanTheme.haptic(.light)
        } label: {
            Image(systemName: isFavorite ? "star.fill" : "star")
                .font(.system(size: scaled(18, by: scale, min: 15), weight: .bold))
                .foregroundColor(isFavorite ? Color(red: 1.0, green: 0.84, blue: 0.28) : OniTanTheme.textSecondary)
                .frame(width: scaled(40, by: scale, min: 34), height: scaled(40, by: scale, min: 34))
                .background(Color.black.opacity(0.18))
                .overlay(
                    Circle()
                        .stroke(
                            isFavorite
                                ? Color(red: 1.0, green: 0.84, blue: 0.28).opacity(0.5)
                                : OniTanTheme.cardBorder,
                            lineWidth: 1
                        )
                )
                .clipShape(Circle())
        }
        .accessibilityLabel(isFavorite ? "お気に入り解除" : "お気に入り追加")
        .accessibilityHint(isFavorite ? "この漢字をお気に入りから外します" : "この漢字をお気に入りに登録します")
        .accessibilityIdentifier("quiz_favorite_toggle")
    }

    // MARK: - 2-Choice Stack

    private func choiceStack(scale: CGFloat) -> some View {
        let twoChoices = Self.twoChoices(
            from: vm.currentQuestion.choices,
            answer: vm.currentQuestion.answer
        )

        return VStack(alignment: .leading, spacing: scaled(10, by: scale, min: 8)) {
            Text("読みを選ぶ")
                .font(playFont(scaled(13, by: scale, min: 11), weight: .semibold))
                .foregroundColor(OniTanTheme.textTertiary)
                .padding(.leading, 4)

            ForEach(Array(twoChoices.enumerated()), id: \.offset) { _, choice in
                ChoiceCard(
                    text: choice,
                    scale: scale,
                    fontStyle: playFontManager.fontStyle,
                    onTap: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            vm.answer(selected: choice)
                        }
                        OniTanTheme.haptic(.medium)
                    }
                )
            }
        }
    }

    /// Returns exactly 2 choices: the correct answer + 1 wrong choice, in random order.
    private static func twoChoices(from choices: [String], answer: String) -> [String] {
        let wrongs = choices.filter { $0 != answer }
        guard let firstWrong = wrongs.first else { return [answer] }
        return [answer, firstWrong].shuffled()
    }

    // MARK: - Wrong Answer View

    private func wrongAnswerView(correctAnswer: String, scale: CGFloat) -> some View {
        VStack(spacing: scaled(16, by: scale, min: 10)) {
            // Compact feedback: icon + text on the same line
            HStack(spacing: scaled(10, by: scale, min: 6)) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: scaled(36, by: scale, min: 28)))
                    .foregroundColor(OniTanTheme.accentWrong)

                VStack(alignment: .leading, spacing: scaled(4, by: scale, min: 2)) {
                    Text("不正解")
                        .font(playFont(scaled(26, by: scale, min: 20), weight: .black))
                        .foregroundColor(OniTanTheme.accentWrong)

                    Text("正解は「\(correctAnswer)」")
                        .font(playFont(scaled(20, by: scale, min: 16), weight: .semibold))
                        .foregroundColor(OniTanTheme.textPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                withAnimation { vm.proceed() }
                OniTanTheme.haptic(.light)
            } label: {
                Text("次へ")
                    .font(playFont(17, weight: .bold))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: scaled(50, by: scale, min: 44))
                    .background(
                        RoundedRectangle(cornerRadius: OniTanTheme.radiusButton)
                            .fill(OniTanTheme.wrongGradient)
                    )
                    .shadow(
                        color: OniTanTheme.accentWrong.opacity(0.4),
                        radius: scaled(8, by: scale, min: 4),
                        y: scaled(4, by: scale, min: 2)
                    )
            }
            .accessibilityLabel("次の問題へ進む")
            .accessibilityIdentifier("quiz_next_wrong")
        }
        .padding(.horizontal, scaled(20, by: scale, min: 14))
        .padding(.vertical, scaled(18, by: scale, min: 12))
        .background(
            RoundedRectangle(cornerRadius: OniTanTheme.radiusCard)
                .fill(OniTanTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: OniTanTheme.radiusCard)
                        .stroke(OniTanTheme.accentWrong.opacity(0.3), lineWidth: 1)
                )
        )
        .frame(maxWidth: .infinity)
    }

    // MARK: - Stage Cleared

    private var stageClearedView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(OniTanTheme.accentCorrect.opacity(0.15))
                    .frame(width: 70, height: 70)
                    .blur(radius: 12)

                Image(systemName: "trophy.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(OniTanTheme.goldGradient)
                    .shadow(color: .yellow.opacity(0.6), radius: 10)
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

            ProgressRingView(
                progress: 1.0,
                lineWidth: 8,
                size: 70,
                gradient: Gradient(colors: [OniTanTheme.accentCorrect, OniTanTheme.accentPrimary]),
                label: "完了"
            )
            .shadow(color: OniTanTheme.accentCorrect.opacity(0.5), radius: 10)

            if vm.sessionXPGained > 0 {
                sessionXPBadge(vm.sessionXPGained)
            }

            VStack(spacing: 8) {
                Button {
                    OniTanTheme.hapticSuccess()
                    dismiss()
                } label: {
                    Text("ステージ選択へ戻る")
                        .font(playFont(15, weight: .bold))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(OniTanTheme.correctGradient)
                        .cornerRadius(OniTanTheme.radiusButton)
                        .shadow(color: OniTanTheme.accentCorrect.opacity(0.4), radius: 6, y: 3)
                }

                Button {
                    withAnimation { vm.resetGame() }
                } label: {
                    Text("もう一度")
                        .font(playFont(13, weight: .semibold))
                        .foregroundColor(OniTanTheme.textTertiary)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(vm.clearTitle) 全\(vm.totalGoal)問クリアしました"
            + (vm.sessionXPGained > 0 ? " +\(vm.sessionXPGained) XP獲得" : ""))
    }

    // MARK: - XP Badge

    private func sessionXPBadge(_ xp: Int) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "star.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.2))
            Text("+\(xp) XP 獲得！")
                .font(playFont(15, weight: .bold))
                .fontWeight(.bold)
                .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.2))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color(red: 0.35, green: 0.28, blue: 0.05).opacity(0.65))
                .overlay(
                    Capsule()
                        .stroke(Color(red: 1.0, green: 0.85, blue: 0.2).opacity(0.5), lineWidth: 1)
                )
        )
        .shadow(color: Color(red: 1.0, green: 0.75, blue: 0.0).opacity(0.3), radius: 8)
        .transition(.scale(scale: 0.8).combined(with: .opacity))
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
}

// MARK: - Choice Card

private struct ChoiceCard: View {
    let text: String
    let scale: CGFloat
    let fontStyle: PlayFontStyle
    let onTap: () -> Void

    @State private var isPressed = false

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
                .font(fontStyle.font(size: max(18, 24 * scale), weight: .bold))
                .fontWeight(.bold)
                .foregroundColor(OniTanTheme.textPrimary)
                .minimumScaleFactor(0.6)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: max(56, 72 * scale))
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

    @EnvironmentObject private var playFontManager: PlayFontManager
    @State private var appear = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.72)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 0) {
                // Kanji header
                VStack(spacing: 8) {
                    Text(question.kanji)
                        .font(playFontManager.font(size: 70, weight: .black))
                        .foregroundStyle(OniTanTheme.primaryGradient)

                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(OniTanTheme.accentCorrect)
                        Text("正解！")
                            .font(playFontManager.font(size: 17, weight: .bold))
                            .fontWeight(.bold)
                            .foregroundColor(OniTanTheme.accentCorrect)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(Color(red: 0.12, green: 0.10, blue: 0.20))

                Divider().background(Color.white.opacity(0.15))

                // Explanation body
                ScrollView {
                    Text(question.explain)
                        .font(playFontManager.font(size: 17))
                        .foregroundColor(Color(red: 0.85, green: 0.85, blue: 0.95))
                        .lineSpacing(6)
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 260)
                .background(Color(red: 0.10, green: 0.08, blue: 0.18))

                // Dismiss button
                Button {
                    onDismiss()
                    OniTanTheme.haptic(.light)
                } label: {
                    Text("次へ")
                        .font(playFontManager.font(size: 17, weight: .bold))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(OniTanTheme.primaryGradient)
                }
                .accessibilityIdentifier("quiz_next_explanation")
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))
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
        .accessibilityLabel("正解の解説: \(question.kanji). \(question.explain)")
        .accessibilityHint("タップまたは次へボタンで閉じます")
    }
}
