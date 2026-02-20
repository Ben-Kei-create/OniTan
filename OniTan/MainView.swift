import SwiftUI

// MARK: - Main Quiz View

struct MainView: View {
    @StateObject private var vm: QuizSessionViewModel
    @Environment(\.dismiss) private var dismiss

    init(
        stage: Stage,
        appState: AppState,
        statsRepo: StudyStatsRepository,
        streakRepo: StreakRepository? = nil,
        xpRepo: GamificationRepository? = nil,
        mode: QuizMode = .normal,
        clearTitle: String? = nil
    ) {
        _vm = StateObject(wrappedValue: QuizSessionViewModel(
            stage: stage,
            appState: appState,
            statsRepo: statsRepo,
            streakRepo: streakRepo,
            xpRepo: xpRepo,
            mode: mode,
            clearTitle: clearTitle
        ))
    }

    var body: some View {
        ZStack {
            OniTanTheme.backgroundGradientFallback
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                switch vm.phase {
                case .stageCleared:
                    stageClearedView
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.85).combined(with: .opacity),
                            removal: .opacity
                        ))
                default:
                    quizContentView
                }
            }
            .navigationBarBackButtonHidden(true)

            // Explanation overlay
            if vm.phase == .showingExplanation {
                ExplanationView(question: vm.currentQuestion) {
                    vm.proceed()
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: vm.phase)
                .zIndex(10)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: vm.phase)
        .alert(item: $vm.activeAlert) { alert in
            alertView(for: alert)
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 12) {
            // Quit button
            Button {
                if vm.phase == .stageCleared {
                    dismiss()
                } else {
                    vm.requestQuit()
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 26))
                    .foregroundColor(.white.opacity(0.7))
            }
            .accessibilityLabel("終了")
            .accessibilityHint("タップすると確認ダイアログが表示されます")

            Spacer()

            // Combo badge (appears at 3+ consecutive correct answers)
            if vm.consecutiveCorrect >= 3 {
                HStack(spacing: 4) {
                    Text("🔥")
                        .font(.system(size: 13))
                    Text("\(vm.consecutiveCorrect)連続！")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(OniTanTheme.accentWeak)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
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
            HStack(spacing: 4) {
                Image(systemName: vm.mode.systemImage)
                    .font(.system(size: 11))
                Text(vm.mode.displayName)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
            }
            .foregroundColor(.white.opacity(0.6))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.10))
            .cornerRadius(20)

            // Progress ring
            ProgressRingView(
                progress: vm.progressFraction,
                lineWidth: 5,
                size: 44,
                gradient: Gradient(colors: [OniTanTheme.accentPrimary, OniTanTheme.accentCorrect])
            )
            .accessibilityLabel("進捗 \(vm.clearedCount)問 / \(vm.totalGoal)問")
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Quiz Content

    private var quizContentView: some View {
        VStack(spacing: 20) {
            // Stage number + pass indicator
            stageHeader

            Spacer()

            // Kanji display
            kanjiDisplay

            Spacer()

            // Choice area
            switch vm.phase {
            case .answering:
                choiceGrid
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            case .showingWrongAnswer(let correct):
                wrongAnswerView(correctAnswer: correct)
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
            default:
                EmptyView()
            }

            Spacer().frame(maxHeight: 24)
        }
        .padding(.horizontal, 20)
    }

    private var stageHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(vm.displayTitle)
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                if vm.passNumber > 1 {
                    Text("復習パス \(vm.passNumber)")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(OniTanTheme.accentWeak)
                }
            }

            Spacer()

            Text("\(vm.clearedCount) / \(vm.totalGoal) 問")
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
        }
        .accessibilityElement()
        .accessibilityLabel("\(vm.displayTitle) \(vm.clearedCount)問中\(vm.totalGoal)問正解")
    }

    // MARK: - Kanji Display

    private var kanjiDisplay: some View {
        ZStack {
            // Background card
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.2), radius: 16, y: 8)

            // Flash on answer
            if vm.lastAnswerResult == .correct {
                RoundedRectangle(cornerRadius: 24)
                    .fill(OniTanTheme.accentCorrect.opacity(0.25))
                    .transition(.opacity)
            } else if vm.lastAnswerResult == .wrong {
                RoundedRectangle(cornerRadius: 24)
                    .fill(OniTanTheme.accentWrong.opacity(0.25))
                    .transition(.opacity)
            }

            VStack(spacing: 8) {
                Text(vm.currentQuestion.kanji)
                    .font(.system(size: 130, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                    .shadow(color: .black.opacity(0.3), radius: 4)
                    .id(vm.currentQuestion.id)   // force re-render on question change
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }
            .padding(24)
        }
        .frame(height: 220)
        .accessibilityElement()
        .accessibilityLabel("漢字: \(vm.currentQuestion.kanji)")
        .accessibilityHint("この漢字の読みを選んでください")
    }

    // MARK: - 2x2 Choice Grid

    private var choiceGrid: some View {
        let choices = vm.currentQuestion.choices
        let rows = choices.chunked(into: 2)

        return VStack(spacing: 12) {
            ForEach(rows.indices, id: \.self) { rowIndex in
                HStack(spacing: 12) {
                    ForEach(rows[rowIndex], id: \.self) { choice in
                        ChoiceCard(
                            text: choice,
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
    }

    // MARK: - Wrong Answer View

    private func wrongAnswerView(correctAnswer: String) -> some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(OniTanTheme.accentWrong)
                    .symbolEffect(.bounce, value: vm.phase)

                Text("不正解")
                    .font(.system(.title, design: .rounded))
                    .fontWeight(.black)
                    .foregroundColor(OniTanTheme.accentWrong)

                Text("正解は「\(correctAnswer)」")
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }

            Button {
                withAnimation { vm.proceed() }
                OniTanTheme.haptic(.light)
            } label: {
                Text("次へ")
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .background(
                        RoundedRectangle(cornerRadius: OniTanTheme.radiusButton)
                            .fill(OniTanTheme.wrongGradient)
                    )
                    .shadow(color: OniTanTheme.accentWrong.opacity(0.4), radius: 8, y: 4)
            }
            .accessibilityLabel("次の問題へ進む")
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: OniTanTheme.radiusCard)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: OniTanTheme.radiusCard)
                        .stroke(OniTanTheme.accentWrong.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Stage Cleared

    private var stageClearedView: some View {
        VStack(spacing: 32) {
            Spacer()

            // Trophy icon with glow
            ZStack {
                Circle()
                    .fill(OniTanTheme.accentCorrect.opacity(0.15))
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)

                Image(systemName: "trophy.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(OniTanTheme.goldGradient)
                    .shadow(color: .yellow.opacity(0.6), radius: 16)
            }

            VStack(spacing: 12) {
                Text(vm.clearTitle)
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("全 \(vm.totalGoal) 問クリア！")
                    .font(.system(.title3, design: .rounded))
                    .foregroundColor(OniTanTheme.textSecondary)
            }

            // Final progress ring (always 100%)
            ProgressRingView(
                progress: 1.0,
                lineWidth: 12,
                size: 100,
                gradient: Gradient(colors: [OniTanTheme.accentCorrect, OniTanTheme.accentPrimary]),
                label: "完了"
            )
            .shadow(color: OniTanTheme.accentCorrect.opacity(0.5), radius: 16)

            // XP earned this session
            if vm.sessionXPGained > 0 {
                sessionXPBadge(vm.sessionXPGained)
            }

            Spacer()

            VStack(spacing: 12) {
                Button {
                    OniTanTheme.hapticSuccess()
                    dismiss()
                } label: {
                    Text("ステージ選択へ戻る")
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(OniTanTheme.correctGradient)
                        .cornerRadius(OniTanTheme.radiusButton)
                        .shadow(color: OniTanTheme.accentCorrect.opacity(0.4), radius: 12, y: 6)
                }

                Button {
                    withAnimation { vm.resetGame() }
                } label: {
                    Text("もう一度")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.white.opacity(0.65))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
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
                .font(.system(.subheadline, design: .rounded))
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
}

// MARK: - Choice Card

private struct ChoiceCard: View {
    let text: String
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            Text(text)
                .font(.system(.title2, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 72)
                .padding(.horizontal, 8)
        }
        .background(
            RoundedRectangle(cornerRadius: OniTanTheme.radiusButton)
                .fill(
                    isPressed
                        ? OniTanTheme.primaryGradient
                        : LinearGradient(
                            colors: [Color.white.opacity(0.15), Color.white.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: OniTanTheme.radiusButton)
                        .stroke(Color.white.opacity(isPressed ? 0.5 : 0.2), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.2), radius: 6, y: 3)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.10), value: isPressed)
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
        .accessibilityLabel("選択肢: \(text)")
        .accessibilityHint("タップするとこの選択肢を選びます")
    }
}

// MARK: - Explanation Overlay

struct ExplanationView: View {
    let question: Question
    let onDismiss: () -> Void

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
                        .font(.system(size: 70, weight: .black, design: .rounded))
                        .foregroundStyle(OniTanTheme.primaryGradient)

                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(OniTanTheme.accentCorrect)
                        Text("正解！")
                            .font(.system(.headline, design: .rounded))
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
                        .font(.system(.body, design: .rounded))
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
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(OniTanTheme.primaryGradient)
                }
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

// MARK: - Array Chunk Helper

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
