import SwiftUI

// MARK: - Passage Quiz View
// Full-screen view for passage-based kanji quiz mode.
// Displays a text passage with highlighted targets, and choices below.

struct PassageQuizView: View {
    @StateObject private var vm: PassageSessionViewModel
    @Environment(\.dismiss) private var dismiss

    init(
        passages: [Passage],
        stageNumber: Int,
        statsRepo: StudyStatsRepository,
        streakRepo: StreakRepository? = nil,
        xpRepo: GamificationRepository? = nil
    ) {
        _vm = StateObject(wrappedValue: PassageSessionViewModel(
            passages: passages,
            stageNumber: stageNumber,
            statsRepo: statsRepo,
            streakRepo: streakRepo,
            xpRepo: xpRepo
        ))
    }

    var body: some View {
        GeometryReader { proxy in
            let scale = layoutScale(containerHeight: proxy.size.height, safeArea: proxy.safeAreaInsets)

            ZStack {
                OniTanTheme.backgroundGradientFallback
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    topBar(scale: scale)

                    switch vm.phase {
                    case .sessionComplete:
                        sessionCompleteView
                            .transition(.scale(scale: 0.85).combined(with: .opacity))
                    default:
                        passageContentView(scale: scale)
                    }
                }
                .navigationBarBackButtonHidden(true)

                // Result overlay for correct answers
                if case .showingResult(let correct, let answer) = vm.phase, correct {
                    resultOverlay(correct: true, answer: answer)
                        .transition(.opacity)
                        .zIndex(10)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: vm.phase)
            .alert(item: $vm.activeAlert) { alert in
                alertView(for: alert)
            }
        }
    }

    // MARK: - Top Bar

    private func topBar(scale: CGFloat) -> some View {
        HStack(spacing: scaled(12, by: scale, min: 8)) {
            Button {
                vm.requestQuit()
                OniTanTheme.haptic(.light)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: scaled(16, by: scale, min: 14), weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: scaled(36, by: scale, min: 30), height: scaled(36, by: scale, min: 30))
                    .background(Color.white.opacity(0.12))
                    .clipShape(Circle())
            }
            .accessibilityLabel("クイズを中断")

            Spacer()

            // Passage progress
            Text("文章 \(vm.passageIndex + 1)/\(vm.totalPassages)")
                .font(.system(size: scaled(14, by: scale, min: 11), weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.7))

            // Combo badge
            if vm.consecutiveCorrect >= 3 {
                HStack(spacing: 3) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: scaled(12, by: scale, min: 10)))
                    Text("\(vm.consecutiveCorrect)")
                        .font(.system(size: scaled(13, by: scale, min: 10), weight: .bold, design: .rounded))
                }
                .foregroundColor(.orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.15))
                .cornerRadius(12)
            }

            // Progress ring
            ProgressRingView(
                progress: vm.progressFraction,
                lineWidth: scaled(3, by: scale, min: 2),
                gradient: OniTanTheme.primaryGradient
            )
            .frame(width: scaled(32, by: scale, min: 26), height: scaled(32, by: scale, min: 26))
        }
        .padding(.horizontal, scaled(20, by: scale, min: 14))
        .padding(.top, scaled(12, by: scale, min: 8))
        .padding(.bottom, scaled(8, by: scale, min: 4))
    }

    // MARK: - Passage Content

    private func passageContentView(scale: CGFloat) -> some View {
        VStack(spacing: 0) {
            // Passage title
            Text(vm.currentPassage.title)
                .font(.system(size: scaled(18, by: scale, min: 14), weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.bottom, scaled(4, by: scale, min: 2))

            if let source = vm.currentPassage.source {
                Text(source)
                    .font(.system(size: scaled(11, by: scale, min: 9), weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.bottom, scaled(8, by: scale, min: 4))
            }

            // Passage text with highlighted targets
            passageTextCard(scale: scale)
                .padding(.bottom, scaled(8, by: scale, min: 4))

            Spacer(minLength: 4)

            // Target indicator + choices
            switch vm.phase {
            case .reading:
                startButton(scale: scale)
            case .answering:
                targetChoices(scale: scale)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            case .showingResult(let correct, let answer):
                if !correct {
                    wrongResultView(answer: answer, scale: scale)
                        .transition(.scale(scale: 0.9).combined(with: .opacity))
                }
            case .passageComplete:
                passageCompleteSection(scale: scale)
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
            case .sessionComplete:
                EmptyView()
            }

            Spacer(minLength: scaled(12, by: scale, min: 6))
        }
        .padding(.horizontal, scaled(20, by: scale, min: 14))
    }

    // MARK: - Passage Text Card

    private func passageTextCard(scale: CGFloat) -> some View {
        let attributed = buildAttributedText()
        let fontSize: CGFloat = scaled(18, by: scale, min: 14)

        return ScrollView {
            Text(attributed)
                .font(.system(size: fontSize, design: .rounded))
                .lineSpacing(8)
                .padding(scaled(16, by: scale, min: 10))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxHeight: scaled(240, by: scale, min: 160))
        .background(
            RoundedRectangle(cornerRadius: scaled(20, by: scale, min: 14))
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: scaled(20, by: scale, min: 14))
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
    }

    private func buildAttributedText() -> AttributedString {
        let text = vm.currentPassage.text
        let chars = Array(text)
        var result = AttributedString()

        // Sort targets by position to process in order
        let sortedTargets = vm.currentPassage.targets.enumerated()
            .sorted { $0.element.position < $1.element.position }

        var cursor = 0

        for (idx, target) in sortedTargets {
            // Add text before this target
            if target.position > cursor {
                let before = String(chars[cursor..<target.position])
                var seg = AttributedString(before)
                seg.foregroundColor = .white.opacity(0.85)
                result.append(seg)
            }

            // Add the target word
            let endPos = min(target.position + target.length, chars.count)
            let word = String(chars[target.position..<endPos])
            var seg = AttributedString(word)

            let isCompleted = vm.completedTargetIndices.contains(idx)
            let isCurrent = idx == vm.targetIndex && (vm.phase == .answering || {
                if case .showingResult = vm.phase { return true }
                return false
            }())

            if isCurrent {
                // Current target: bold + highlight background
                seg.foregroundColor = Color(red: 1.0, green: 0.85, blue: 0.2)
                seg.font = .system(size: 18, weight: .bold, design: .rounded)
                seg.underlineStyle = .thick
                seg.underlineColor = Color(red: 1.0, green: 0.85, blue: 0.2)
            } else if isCompleted {
                // Completed target: green with checkmark
                seg.foregroundColor = Color(red: 0.4, green: 0.9, blue: 0.5)
                seg.font = .system(size: 18, weight: .semibold, design: .rounded)
            } else {
                // Upcoming target: underlined but subtle
                seg.foregroundColor = .white
                seg.underlineStyle = .single
                seg.underlineColor = .white.opacity(0.4)
            }

            result.append(seg)
            cursor = endPos
        }

        // Add remaining text after the last target
        if cursor < chars.count {
            let remaining = String(chars[cursor..<chars.count])
            var seg = AttributedString(remaining)
            seg.foregroundColor = .white.opacity(0.85)
            result.append(seg)
        }

        return result
    }

    // MARK: - Start Button

    private func startButton(scale: CGFloat) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                vm.startAnswering()
            }
            OniTanTheme.haptic(.medium)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "play.fill")
                Text("読み始める")
            }
            .font(.system(.headline, design: .rounded))
            .fontWeight(.bold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: scaled(52, by: scale, min: 44))
            .background(OniTanTheme.primaryGradient)
            .cornerRadius(OniTanTheme.radiusButton)
            .shadow(color: OniTanTheme.accentPrimary.opacity(0.4), radius: 8, y: 4)
        }
        .accessibilityLabel("読み始める")
    }

    // MARK: - Target Choices

    private func targetChoices(scale: CGFloat) -> some View {
        let target = vm.currentTarget
        let targetWord = target.targetWord(in: vm.currentPassage.text) ?? "?"

        return VStack(spacing: scaled(10, by: scale, min: 6)) {
            HStack {
                Text("問題 \(vm.targetIndex + 1)/\(vm.targetsInCurrentPassage)")
                    .font(.system(size: scaled(13, by: scale, min: 10), weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))

                Spacer()

                Text("「\(targetWord)」の読みは？")
                    .font(.system(size: scaled(14, by: scale, min: 11), weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            // 2x2 choice grid
            let rows = target.choices.chunked(into: 2)
            VStack(spacing: scaled(10, by: scale, min: 6)) {
                ForEach(rows.indices, id: \.self) { rowIndex in
                    HStack(spacing: scaled(10, by: scale, min: 6)) {
                        ForEach(Array(rows[rowIndex].enumerated()), id: \.offset) { _, choice in
                            PassageChoiceCard(text: choice, scale: scale) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    vm.answer(selected: choice)
                                }
                                OniTanTheme.haptic(.medium)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Wrong Result View

    private func wrongResultView(answer: String, scale: CGFloat) -> some View {
        VStack(spacing: scaled(12, by: scale, min: 8)) {
            HStack(spacing: scaled(8, by: scale, min: 6)) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: scaled(30, by: scale, min: 24)))
                    .foregroundColor(OniTanTheme.accentWrong)

                VStack(alignment: .leading, spacing: 2) {
                    Text("不正解")
                        .font(.system(size: scaled(20, by: scale, min: 16), weight: .black, design: .rounded))
                        .foregroundColor(OniTanTheme.accentWrong)

                    Text("正解は「\(answer)」")
                        .font(.system(size: scaled(16, by: scale, min: 13), weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                withAnimation { vm.proceed() }
                OniTanTheme.haptic(.light)
            } label: {
                Text("次へ")
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: scaled(44, by: scale, min: 38))
                    .background(OniTanTheme.wrongGradient)
                    .cornerRadius(OniTanTheme.radiusButton)
            }
        }
        .padding(scaled(16, by: scale, min: 10))
        .background(
            RoundedRectangle(cornerRadius: OniTanTheme.radiusCard)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: OniTanTheme.radiusCard)
                        .stroke(OniTanTheme.accentWrong.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Result Overlay (correct)

    private func resultOverlay(correct: Bool, answer: String) -> some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation { vm.proceed() }
                }

            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(OniTanTheme.accentCorrect)

                Text("正解！")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(OniTanTheme.accentCorrect)

                Text(vm.currentTarget.explain)
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(Color(red: 0.85, green: 0.85, blue: 0.95))
                    .lineSpacing(4)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .lineLimit(4)

                Button {
                    withAnimation { vm.proceed() }
                    OniTanTheme.haptic(.light)
                } label: {
                    Text("次へ")
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(OniTanTheme.correctGradient)
                        .cornerRadius(OniTanTheme.radiusButton)
                }
                .padding(.horizontal, 20)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(red: 0.12, green: 0.10, blue: 0.20))
            )
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Passage Complete

    private func passageCompleteSection(scale: CGFloat) -> some View {
        VStack(spacing: scaled(16, by: scale, min: 10)) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: scaled(40, by: scale, min: 32)))
                .foregroundStyle(OniTanTheme.correctGradient)

            Text("文章クリア！")
                .font(.system(size: scaled(22, by: scale, min: 18), weight: .black, design: .rounded))
                .foregroundColor(.white)

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    vm.nextPassage()
                }
                OniTanTheme.haptic(.medium)
            } label: {
                HStack(spacing: 8) {
                    Text("次の文章へ")
                    Image(systemName: "arrow.right")
                }
                .font(.system(.headline, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: scaled(52, by: scale, min: 44))
                .background(OniTanTheme.primaryGradient)
                .cornerRadius(OniTanTheme.radiusButton)
            }
        }
    }

    // MARK: - Session Complete

    private var sessionCompleteView: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 12)

            ZStack {
                Circle()
                    .fill(OniTanTheme.accentCorrect.opacity(0.15))
                    .frame(width: 90, height: 90)
                    .blur(radius: 16)

                Image(systemName: "trophy.fill")
                    .font(.system(size: 54))
                    .foregroundStyle(OniTanTheme.goldGradient)
                    .shadow(color: .yellow.opacity(0.6), radius: 12)
            }

            Spacer(minLength: 16)

            VStack(spacing: 8) {
                Text("文章題 完了！")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(.white)

                Text("\(vm.totalCorrect)/\(vm.totalTargets) 問正解")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(OniTanTheme.textSecondary)

                if vm.sessionXPGained > 0 {
                    Text("+\(vm.sessionXPGained) XP")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(OniTanTheme.goldGradient)
                        .padding(.top, 4)
                }
            }

            Spacer(minLength: 24)

            Button {
                dismiss()
            } label: {
                Text("ホームに戻る")
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(OniTanTheme.primaryGradient)
                    .cornerRadius(OniTanTheme.radiusButton)
            }
            .padding(.horizontal, 24)

            Spacer(minLength: 12)
        }
    }

    // MARK: - Alert

    private func alertView(for alert: OniAlert) -> Alert {
        switch alert {
        case .quitConfirmation:
            return Alert(
                title: Text("中断しますか？"),
                message: Text("進捗は保存されます。"),
                primaryButton: .destructive(Text("中断する")) { dismiss() },
                secondaryButton: .cancel(Text("続ける"))
            )
        default:
            return Alert(title: Text("エラー"))
        }
    }

    // MARK: - Layout Helpers

    private func layoutScale(containerHeight: CGFloat, safeArea: EdgeInsets) -> CGFloat {
        let usable = max(1, containerHeight - safeArea.top - safeArea.bottom)
        let baseHeight: CGFloat = 780
        let raw = usable / baseHeight
        return min(1.0, max(0.75, raw))
    }

    private func scaled(_ value: CGFloat, by scale: CGFloat, min minValue: CGFloat) -> CGFloat {
        max(minValue, value * scale)
    }
}

// MARK: - Passage Choice Card

private struct PassageChoiceCard: View {
    let text: String
    let scale: CGFloat
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
                .font(.system(size: max(16, 22 * scale), weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: max(48, 64 * scale))
        }
        .background(
            RoundedRectangle(cornerRadius: max(12, OniTanTheme.radiusButton * scale))
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
                    RoundedRectangle(cornerRadius: max(12, OniTanTheme.radiusButton * scale))
                        .stroke(Color.white.opacity(isPressed ? 0.5 : 0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, max(4, 6 * scale))
        .shadow(color: .black.opacity(0.2), radius: max(3, 6 * scale), y: max(2, 3 * scale))
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("選択肢: \(text)")
    }
}

// MARK: - Array Chunk Helper (shared)

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
