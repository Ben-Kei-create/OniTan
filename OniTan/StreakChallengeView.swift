import SwiftUI

// MARK: - Streak Challenge Phase

enum StreakChallengePhase: Equatable {
    case answering
    case showingExplanation
    case gameOver
}

// MARK: - Streak Challenge ViewModel

@MainActor
final class StreakChallengeViewModel: ObservableObject {

    // MARK: Published

    @Published private(set) var currentQuestion: Question
    @Published private(set) var consecutiveCorrect: Int = 0
    @Published private(set) var phase: StreakChallengePhase = .answering
    @Published private(set) var lastAnswerResult: AnswerResult = .none
    @Published private(set) var sessionXPGained: Int = 0
    @Published private(set) var bestStreak: Int
    @Published private(set) var isNewBest: Bool = false
    @Published private(set) var timerProgress: Double = 0  // 0→1, game over at 1

    // MARK: Private

    private let xpRepo: GamificationRepository?
    private var questionPool: [Question]
    private var poolIndex: Int = 0
    private var timerTask: Task<Void, Never>?
    static let timeLimit: Double = 8.0  // seconds per question

    static let bestStreakKey = "streakChallenge_bestStreak_v1"

    // MARK: - Init

    init(xpRepo: GamificationRepository? = nil) {
        self.xpRepo = xpRepo
        self.bestStreak = UserDefaults.standard.integer(forKey: Self.bestStreakKey)
        self.questionPool = quizData.stages.flatMap { $0.questions }.shuffled()
        self.currentQuestion = questionPool[0]
    }

    func startTimer() {
        stopTimer()
        timerProgress = 0
        timerTask = Task { @MainActor [weak self] in
            let tickInterval: Double = 0.05  // 50ms ticks
            let increment = tickInterval / Self.timeLimit
            while let self = self, !Task.isCancelled, self.phase == .answering {
                try? await Task.sleep(nanoseconds: UInt64(tickInterval * 1_000_000_000))
                guard !Task.isCancelled, self.phase == .answering else { break }
                self.timerProgress = min(self.timerProgress + increment, 1.0)
                if self.timerProgress >= 1.0 {
                    self.phase = .gameOver
                    break
                }
            }
        }
    }

    func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
    }

    // MARK: - Actions

    func answer(selected: String) {
        guard phase == .answering else { return }
        stopTimer()

        let isCorrect = selected == currentQuestion.answer
        lastAnswerResult = isCorrect ? .correct : .wrong

        if isCorrect {
            consecutiveCorrect += 1

            if consecutiveCorrect > bestStreak {
                bestStreak = consecutiveCorrect
                isNewBest = true
                UserDefaults.standard.set(bestStreak, forKey: Self.bestStreakKey)
            }

            let xp = xpRepo?.addXP(.correctAnswer) ?? 0
            sessionXPGained += xp

            if consecutiveCorrect % 3 == 0 {
                sessionXPGained += xpRepo?.addXP(.comboBonus) ?? 0
            }

            phase = .showingExplanation
        } else {
            phase = .gameOver
        }
    }

    func proceedAfterExplanation() {
        guard phase == .showingExplanation else { return }
        lastAnswerResult = .none
        advanceQuestion()
        phase = .answering
        startTimer()
    }

    func restart() {
        questionPool = quizData.stages.flatMap { $0.questions }.shuffled()
        poolIndex = 0
        consecutiveCorrect = 0
        sessionXPGained = 0
        lastAnswerResult = .none
        isNewBest = false
        currentQuestion = questionPool[0]
        phase = .answering
        startTimer()
    }

    // MARK: - Private

    private func advanceQuestion() {
        poolIndex += 1
        if poolIndex >= questionPool.count {
            questionPool = quizData.stages.flatMap { $0.questions }.shuffled()
            poolIndex = 0
        }
        currentQuestion = questionPool[poolIndex]
    }

    static func twoChoices(from choices: [String], answer: String) -> [String] {
        let wrongs = choices.filter { $0 != answer }
        guard let firstWrong = wrongs.first else { return [answer] }
        let pair = Set([answer, firstWrong])
        return choices.filter { pair.contains($0) }.prefix(2).map { $0 }
    }
}

// MARK: - Streak Challenge View

struct StreakChallengeView: View {
    @StateObject private var vm: StreakChallengeViewModel
    @State private var activeReportContext: QuizProblemReportContext?
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var playFontManager: PlayFontManager
    @EnvironmentObject var donationManager: DonationManager

    init(xpRepo: GamificationRepository? = nil) {
        _vm = StateObject(wrappedValue: StreakChallengeViewModel(xpRepo: xpRepo))
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

                            // Timer bar
                            if vm.phase == .answering {
                                timerBar(scale: scale)
                            }

                            switch vm.phase {
                            case .gameOver:
                                gameOverView
                                    .transition(.asymmetric(
                                        insertion: .scale(scale: 0.85).combined(with: .opacity),
                                        removal: .opacity
                                    ))
                            default:
                                quizContent(scale: scale)
                            }
                        }
                        .navigationBarBackButtonHidden(true)

                        if vm.phase == .showingExplanation {
                            StreakExplanationView(
                                question: vm.currentQuestion,
                                streak: vm.consecutiveCorrect
                            ) {
                                vm.proceedAfterExplanation()
                            } onReport: {
                                presentProblemReport(for: vm.currentQuestion)
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
        .navigationTitle("連続鬼たん")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear { vm.startTimer() }
        .onDisappear { vm.stopTimer() }
        .sheet(item: $activeReportContext) { context in
            ProblemReportSheet(context: context)
        }
    }

    // MARK: - Timer Bar

    private func timerBar(scale: CGFloat) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(OniTanTheme.cardBorder)
                    .frame(height: 6)

                RoundedRectangle(cornerRadius: 3)
                    .fill(timerGradient)
                    .frame(width: geo.size.width * vm.timerProgress, height: 6)
                    .animation(.linear(duration: 0.05), value: vm.timerProgress)
            }
        }
        .frame(height: 6)
        .padding(.horizontal, scaled(20, by: scale, min: 14))
        .padding(.top, scaled(4, by: scale, min: 2))
        .accessibilityLabel("残り時間")
    }

    private var timerGradient: LinearGradient {
        if vm.timerProgress > 0.7 {
            return LinearGradient(colors: [OniTanTheme.accentWrong, Color.red], startPoint: .leading, endPoint: .trailing)
        } else if vm.timerProgress > 0.4 {
            return LinearGradient(colors: [OniTanTheme.accentWeak, Color.orange], startPoint: .leading, endPoint: .trailing)
        }
        return LinearGradient(colors: [OniTanTheme.accentCorrect, Color.green], startPoint: .leading, endPoint: .trailing)
    }

    // MARK: - Top Bar

    private func topBar(scale: CGFloat) -> some View {
        HStack(spacing: scaled(12, by: scale, min: 8)) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: scaled(26, by: scale, min: 20)))
                    .foregroundColor(OniTanTheme.textSecondary)
            }
            .accessibilityLabel("終了")

            Spacer()

            // Current streak counter
            VStack(alignment: .center, spacing: 1) {
                HStack(spacing: 4) {
                    Text("🔥")
                        .font(.system(size: scaled(18, by: scale, min: 14)))
                    Text("\(vm.consecutiveCorrect)")
                        .font(playFont(scaled(30, by: scale, min: 24), weight: .black))
                        .foregroundColor(vm.consecutiveCorrect >= 10 ? OniTanTheme.accentWeak : OniTanTheme.textPrimary)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: vm.consecutiveCorrect)
                }
                Text("連続正解")
                    .font(playFont(scaled(10, by: scale, min: 9), weight: .semibold))
                    .foregroundColor(OniTanTheme.textTertiary)
            }

            Spacer()

            // Best streak
            VStack(alignment: .trailing, spacing: 1) {
                HStack(spacing: 3) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: scaled(11, by: scale, min: 10)))
                        .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.2))
                    Text("\(vm.bestStreak)")
                        .font(playFont(scaled(16, by: scale, min: 13), weight: .black))
                        .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.2))
                }
                Text("ベスト")
                    .font(playFont(scaled(10, by: scale, min: 9), weight: .regular))
                    .foregroundColor(OniTanTheme.textTertiary)
            }
        }
        .padding(.horizontal, scaled(20, by: scale, min: 14))
        .padding(.top, scaled(12, by: scale, min: 8))
        .padding(.bottom, scaled(8, by: scale, min: 4))
    }

    // MARK: - Quiz Content

    private func quizContent(scale: CGFloat) -> some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "bolt.fill")
                    .font(.system(size: scaled(11, by: scale, min: 10)))
                    .foregroundColor(OniTanTheme.accentWeak)
                Text("全ステージからランダム出題 — 1問でもミスでゲームオーバー！")
                    .font(playFont(scaled(11, by: scale, min: 10), weight: .regular))
                    .foregroundColor(OniTanTheme.textTertiary)
                    .lineLimit(2)
                Spacer()
            }
            .padding(.bottom, scaled(8, by: scale, min: 4))

            kanjiDisplay(scale: scale)
                .padding(.bottom, scaled(16, by: scale, min: 8))

            Spacer(minLength: 4)

            if vm.phase == .answering {
                streakChoiceGrid(scale: scale)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            Spacer(minLength: scaled(12, by: scale, min: 6))
        }
        .padding(.horizontal, scaled(20, by: scale, min: 14))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func kanjiDisplay(scale: CGFloat) -> some View {
        let corner = scaled(24, by: scale, min: 16)
        let height: CGFloat = scaled(220, by: scale, min: 170)
        let fontSize: CGFloat = scaled(130, by: scale, min: 92)

        return ZStack {
            RoundedRectangle(cornerRadius: corner)
                .fill(OniTanTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: corner)
                        .stroke(OniTanTheme.cardBorder, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.2), radius: scaled(16, by: scale, min: 8), y: scaled(8, by: scale, min: 4))

            if vm.lastAnswerResult == .correct {
                RoundedRectangle(cornerRadius: corner)
                    .fill(OniTanTheme.accentCorrect.opacity(0.25))
                    .transition(.opacity)
            }

            Text(vm.currentQuestion.kanji)
                .font(playFont(fontSize, weight: .black))
                .foregroundColor(OniTanTheme.textPrimary)
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .shadow(color: .black.opacity(0.3), radius: 4)
                .id(vm.currentQuestion.id)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .padding(scaled(16, by: scale, min: 8))
        }
        .frame(height: height)
        .overlay(alignment: .topTrailing) {
            reportButton(scale: scale)
                .padding(scaled(14, by: scale, min: 10))
        }
        .animation(.easeInOut(duration: 0.25), value: vm.currentQuestion.kanji)
        .accessibilityElement()
        .accessibilityLabel("漢字: \(vm.currentQuestion.kanji)")
    }

    private func reportButton(scale: CGFloat) -> some View {
        Button {
            presentProblemReport(for: vm.currentQuestion)
            OniTanTheme.haptic(.light)
        } label: {
            Image(systemName: "exclamationmark.bubble")
                .font(.system(size: scaled(17, by: scale, min: 14), weight: .bold))
                .foregroundColor(OniTanTheme.textSecondary)
                .frame(width: scaled(40, by: scale, min: 34), height: scaled(40, by: scale, min: 34))
                .background(Color.black.opacity(0.18))
                .overlay(
                    Circle()
                        .stroke(OniTanTheme.cardBorder, lineWidth: 1)
                )
                .clipShape(Circle())
        }
        .accessibilityLabel("問題を報告")
        .accessibilityHint("現在の問題内容を添えて報告画面を開きます")
        .accessibilityIdentifier("streak_problem_report")
    }

    private func streakChoiceGrid(scale: CGFloat) -> some View {
        let choices = StreakChallengeViewModel.twoChoices(
            from: vm.currentQuestion.choices,
            answer: vm.currentQuestion.answer
        )
        return VStack(alignment: .leading, spacing: scaled(10, by: scale, min: 8)) {
            if let note = vm.currentQuestion.readingMetadata.playerNote(for: vm.currentQuestion.answer) {
                Text(note)
                    .font(playFont(scaled(12, by: scale, min: 10), weight: .regular))
                    .foregroundColor(OniTanTheme.accentWeak)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: scaled(12, by: scale, min: 8)) {
                ForEach(Array(choices.enumerated()), id: \.offset) { _, choice in
                    StreakChoiceCard(
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
    }

    // MARK: - Game Over

    private var gameOverView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Game over icon
                ZStack {
                    Circle()
                        .fill(OniTanTheme.accentWrong.opacity(0.15))
                        .frame(width: 80, height: 80)
                        .blur(radius: 12)
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 54))
                        .foregroundColor(OniTanTheme.accentWrong)
                        .shadow(color: OniTanTheme.accentWrong.opacity(0.5), radius: 8)
                }

                VStack(spacing: 6) {
                    Text("ゲームオーバー！")
                        .font(playFont(26, weight: .black))
                        .foregroundColor(OniTanTheme.textPrimary)

                    VStack(spacing: 2) {
                        Text("\(vm.consecutiveCorrect)")
                            .font(playFont(72, weight: .black))
                            .foregroundStyle(OniTanTheme.primaryGradient)
                        Text("連続正解")
                            .font(playFont(16, weight: .semibold))
                            .foregroundColor(OniTanTheme.textSecondary)
                    }

                    if vm.isNewBest {
                        HStack(spacing: 6) {
                            Image(systemName: "crown.fill")
                                .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.2))
                            Text("新記録達成！")
                                .font(playFont(17, weight: .bold))
                                .fontWeight(.bold)
                                .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.2))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color(red: 0.35, green: 0.28, blue: 0.05).opacity(0.65))
                                .overlay(Capsule().stroke(Color(red: 1.0, green: 0.85, blue: 0.2).opacity(0.5), lineWidth: 1))
                        )
                    } else {
                        Text("ベスト: \(vm.bestStreak) 連続")
                            .font(playFont(15, weight: .regular))
                            .foregroundColor(OniTanTheme.textTertiary)
                    }
                }

                if vm.sessionXPGained > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.2))
                        Text("+\(vm.sessionXPGained) XP 獲得！")
                            .font(playFont(15, weight: .bold))
                            .fontWeight(.bold)
                            .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.2))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color(red: 0.35, green: 0.28, blue: 0.05).opacity(0.65))
                            .overlay(Capsule().stroke(Color(red: 1.0, green: 0.85, blue: 0.2).opacity(0.5), lineWidth: 1))
                    )
                }

                VStack(spacing: 10) {
                    Button {
                        withAnimation { vm.restart() }
                        OniTanTheme.hapticSuccess()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("もう一度挑戦！")
                        }
                        .font(playFont(17, weight: .bold))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.8, green: 0.15, blue: 0.15), Color(red: 0.6, green: 0.05, blue: 0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(OniTanTheme.radiusButton)
                        .shadow(color: Color(red: 0.7, green: 0.1, blue: 0.1).opacity(0.4), radius: 8, y: 4)
                    }

                    Button {
                        dismiss()
                    } label: {
                        Text("ホームへ戻る")
                            .font(playFont(14, weight: .semibold))
                            .foregroundColor(OniTanTheme.textTertiary)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

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

    private func presentProblemReport(for question: Question) {
        activeReportContext = QuizProblemReportContext(
            question: question,
            sessionTitle: "連続鬼たん",
            modeName: "連続鬼たん",
            stageNumber: nil
        )
    }
}

// MARK: - Streak Choice Card

private struct StreakChoiceCard: View {
    let text: String
    let scale: CGFloat
    let fontStyle: PlayFontStyle
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.10)) { isPressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.10)) { isPressed = false }
            }
            onTap()
        }) {
            Text(text)
                .font(fontStyle.font(size: max(18, 24 * scale), weight: .bold))
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
        .padding(.horizontal, max(6, 8 * scale))
        .shadow(color: .black.opacity(0.2), radius: max(3, 6 * scale), y: max(2, 3 * scale))
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("選択肢: \(text)")
        .accessibilityIdentifier("streak_choice_\(text)")
    }
}

// MARK: - Streak Explanation View

struct StreakExplanationView: View {
    let question: Question
    let streak: Int
    let onDismiss: () -> Void
    let onReport: () -> Void

    @EnvironmentObject private var playFontManager: PlayFontManager
    @State private var appear = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.72)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    HStack {
                        Spacer()

                        Button {
                            onReport()
                        } label: {
                            Image(systemName: "exclamationmark.bubble")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(OniTanTheme.textSecondary)
                                .frame(width: 36, height: 36)
                                .background(Color.white.opacity(0.08))
                                .clipShape(Circle())
                        }
                        .accessibilityLabel("問題を報告")
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                    Text(question.kanji)
                        .font(playFontManager.font(size: 70, weight: .black))
                        .foregroundStyle(OniTanTheme.primaryGradient)

                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(OniTanTheme.accentCorrect)
                        Text("正解！")
                            .font(playFontManager.font(size: 17, weight: .bold))
                            .fontWeight(.bold)
                            .foregroundColor(OniTanTheme.accentCorrect)

                        if streak >= 3 {
                            Text("🔥 \(streak)連続！")
                                .font(playFontManager.font(size: 17, weight: .bold))
                                .fontWeight(.bold)
                                .foregroundColor(OniTanTheme.accentWeak)
                        }
                    }

                    if let note = question.readingMetadata.playerNote(for: question.answer) {
                        Text(note)
                            .font(playFontManager.font(size: 12))
                            .foregroundColor(OniTanTheme.accentWeak)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 24)
                .background(Color(red: 0.12, green: 0.10, blue: 0.20))

                Divider().background(Color.white.opacity(0.15))

                ScrollView {
                    Text(question.displayExplanation)
                        .font(playFontManager.font(size: 17))
                        .foregroundColor(Color(red: 0.85, green: 0.85, blue: 0.95))
                        .lineSpacing(6)
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 200)
                .background(Color(red: 0.10, green: 0.08, blue: 0.18))

                Button {
                    onDismiss()
                    OniTanTheme.haptic(.light)
                } label: {
                    HStack(spacing: 6) {
                        Text("次の問題へ")
                        Image(systemName: "arrow.right")
                    }
                    .font(playFontManager.font(size: 17, weight: .bold))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(OniTanTheme.primaryGradient)
                }
                .accessibilityIdentifier("streak_next_explanation")
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
        .accessibilityLabel("正解の解説: \(question.kanji). \(question.displayExplanation)")
    }
}
