import SwiftUI

// MARK: - Exam Result View

/// Shown after an exam-mode session (examMini / examFull) finishes.
/// Displays overall score, per-format breakdown, weak points, and a
/// recommendation for which dojo to train next.
struct ExamResultView: View {
    let result: ExamResult
    let blueprint: ExamBlueprint?
    let previousBestAccuracy: Double?

    @EnvironmentObject var playFontManager: PlayFontManager
    @State private var showRecommendedTraining = false
    @State private var showWrongAnswers = false

    private var passingAccuracy: Double { blueprint?.passingAccuracy ?? 0.90 }

    private var passed: Bool { result.accuracy >= passingAccuracy }

    private var examTitle: String { blueprint?.title ?? "模試" }

    /// Per-kind scores sorted by accuracy ascending (weakest first), only kinds with attempts.
    private var sortedKindScores: [(kind: QuestionKind, score: KindScore)] {
        result.byKind
            .compactMap { key, score -> (QuestionKind, KindScore)? in
                guard let kind = QuestionKind(rawValue: key), score.total > 0 else { return nil }
                return (kind, score)
            }
            .sorted { $0.1.accuracy < $1.1.accuracy }
    }

    private var weakestThree: [(kind: QuestionKind, score: KindScore)] {
        Array(sortedKindScores.prefix(3))
    }

    /// Recommended dojo category for the weakest format.
    private var recommendedCategory: CategoryEntry? {
        guard let weakest = sortedKindScores.first?.kind else { return nil }
        return categoryManifest?.categories.first { $0.questionKinds.contains(weakest) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header

                scoreSummary

                if !sortedKindScores.isEmpty {
                    kindBreakdown
                }

                if !result.wrongAttempts.isEmpty {
                    wrongAnswersSection
                }

                if !weakestThree.isEmpty {
                    weakPointsSection
                }

                if let recommended = recommendedCategory {
                    recommendationSection(recommended)
                }

                disclaimer
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showRecommendedTraining) {
            if let recommended = recommendedCategory {
                NavigationStack {
                    TrainingModePickerView(category: recommended)
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill((passed ? OniTanTheme.accentWeak : OniTanTheme.accentWrong).opacity(0.14))
                    .frame(width: 70, height: 70)
                    .blur(radius: 12)

                OniSymbolMark(
                    systemName: passed ? "checkmark.seal.fill" : "doc.text.fill",
                    size: 70,
                    fontSize: 30,
                    tint: OniTanTheme.accentWeak,
                    fillOpacity: 0.16,
                    cornerRadius: 18
                )
            }

            Text(examTitle)
                .font(playFont(22, weight: .black))
                .foregroundColor(OniTanTheme.textPrimary)

            Text(passed ? "合格ライン到達！" : "もう一歩！")
                .font(playFont(13, weight: .semibold))
                .foregroundColor(passed ? OniTanTheme.accentWeak : OniTanTheme.accentWrong)
        }
    }

    // MARK: - Score Summary

    private var scoreSummary: some View {
        VStack(spacing: 12) {
            ZStack {
                ProgressRingView(
                    progress: result.accuracy,
                    lineWidth: 10,
                    size: 120,
                    gradient: Gradient(colors: [OniTanTheme.accentWeak, Color(hex: "9B7432")]),
                    label: ""
                )

                // 90% (or blueprint passing line) target marker
                Circle()
                    .trim(from: 0, to: 0.003)
                    .stroke(OniTanTheme.accentPrimary, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90 + 360 * passingAccuracy))
                    .frame(width: 120, height: 120)

                VStack(spacing: 2) {
                    Text(formattedPercent(result.accuracy))
                        .font(playFont(24, weight: .black))
                        .foregroundColor(OniTanTheme.textPrimary)
                    Text("正答率")
                        .font(playFont(11, weight: .medium))
                        .foregroundColor(OniTanTheme.textTertiary)
                }
            }
            .accessibilityElement()
            .accessibilityLabel("正答率 \(formattedPercent(result.accuracy))、合格目安 \(formattedPercent(passingAccuracy))")

            Text("\(result.correctCount) / \(result.totalQuestions) 問正解")
                .font(playFont(20, weight: .bold))
                .foregroundColor(OniTanTheme.textPrimary)

            Text("合格目安: \(formattedPercent(passingAccuracy))")
                .font(playFont(12, weight: .medium))
                .foregroundColor(passed ? OniTanTheme.accentWeak : OniTanTheme.accentWrong)

            if let previousBestAccuracy {
                accuracyDiffBadge(previousBestAccuracy: previousBestAccuracy)
            }
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .oniCard()
    }

    private func accuracyDiffBadge(previousBestAccuracy: Double) -> some View {
        let diff = result.accuracy - previousBestAccuracy
        let diffPercent = Int((diff * 100).rounded())

        let (text, color): (String, Color) = {
            if diff > 0.0001 {
                return ("自己ベスト更新！ 前回比 +\(diffPercent)%", OniTanTheme.accentWeak)
            } else if diff < -0.0001 {
                return ("前回ベスト比 \(diffPercent)%", OniTanTheme.textSecondary)
            } else {
                return ("前回ベストと同じ", OniTanTheme.textSecondary)
            }
        }()

        return HStack(spacing: 6) {
            if diff > 0.0001 {
                Image(systemName: "arrow.up.circle.fill")
                    .accessibilityHidden(true)
            }
            Text(text)
        }
        .font(playFont(12, weight: .bold))
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(color.opacity(0.12))
                .overlay(Capsule().stroke(color.opacity(0.28), lineWidth: 1))
        )
    }

    // MARK: - Kind Breakdown

    private var kindBreakdown: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("出題形式別の正答率")
                .font(playFont(14, weight: .bold))
                .foregroundColor(OniTanTheme.textPrimary)

            VStack(spacing: 8) {
                ForEach(sortedKindScores, id: \.kind) { entry in
                    HStack {
                        Text(entry.kind.displayName)
                            .font(playFont(13, weight: .medium))
                            .foregroundColor(OniTanTheme.textSecondary)

                        Spacer()

                        Text("\(entry.score.correct) / \(entry.score.total)")
                            .font(playFont(12, weight: .semibold))
                            .foregroundColor(OniTanTheme.textTertiary)

                        Text(formattedPercent(entry.score.accuracy))
                            .font(playFont(13, weight: .bold))
                            .foregroundColor(OniTanTheme.textPrimary)
                            .frame(width: 56, alignment: .trailing)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .oniCard()
    }

    // MARK: - Wrong Answers Review

    private var wrongAnswersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showWrongAnswers.toggle()
                }
            } label: {
                HStack {
                    Text("間違えた問題 (\(result.wrongAttempts.count)問)")
                        .font(playFont(14, weight: .bold))
                        .foregroundColor(OniTanTheme.textPrimary)

                    Spacer()

                    Image(systemName: showWrongAnswers ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(OniTanTheme.textTertiary)
                }
            }
            .buttonStyle(.plain)

            if showWrongAnswers {
                VStack(spacing: 0) {
                    ForEach(Array(result.wrongAttempts.enumerated()), id: \.element.questionID) { index, attempt in
                        if index > 0 {
                            Rectangle()
                                .fill(OniTanTheme.cardBorder)
                                .frame(height: 1)
                                .padding(.horizontal, 4)
                        }
                        wrongAnswerRow(attempt: attempt, index: index + 1)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .oniCard()
    }

    private func wrongAnswerRow(attempt: QuestionAttempt, index: Int) -> some View {
        let question = allQuestions.first { $0.id == attempt.questionID }

        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text("\(index)")
                    .font(playFont(10, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 18, height: 18)
                    .background(Circle().fill(OniTanTheme.accentWrong.opacity(0.82)))

                Text(attempt.kind.displayName)
                    .font(playFont(10, weight: .semibold))
                    .foregroundColor(OniTanTheme.textTertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.18))
                            .overlay(Capsule().stroke(OniTanTheme.cardBorder, lineWidth: 1))
                    )
            }

            Text(question?.displayPrompt ?? attempt.kanji)
                .font(playFont(14, weight: .bold))
                .foregroundColor(OniTanTheme.textPrimary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(OniTanTheme.accentWrong)
                    Text(attempt.userAnswer ?? "未回答")
                        .font(playFont(13, weight: .medium))
                        .foregroundColor(OniTanTheme.accentWrong)
                }

                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(OniTanTheme.accentWeak)
                    Text(attempt.correctAnswer)
                        .font(playFont(13, weight: .bold))
                        .foregroundColor(OniTanTheme.accentWeak)
                }
            }

            if let explain = question?.explain, !explain.isEmpty {
                Text(explain)
                    .font(playFont(11, weight: .regular))
                    .foregroundColor(OniTanTheme.textSecondary)
                    .lineLimit(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 10)
    }

    // MARK: - Weak Points

    private var weakPointsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("苦手形式トップ3")
                .font(playFont(14, weight: .bold))
                .foregroundColor(OniTanTheme.textPrimary)

            VStack(spacing: 6) {
                ForEach(Array(weakestThree.enumerated()), id: \.element.kind) { index, entry in
                    HStack(spacing: 10) {
                        Text("\(index + 1)")
                            .font(playFont(12, weight: .bold))
                            .foregroundColor(OniTanTheme.textPrimary)
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(OniTanTheme.accentWrong.opacity(0.82)))

                        Text(entry.kind.displayName)
                            .font(playFont(13, weight: .medium))
                            .foregroundColor(OniTanTheme.textSecondary)

                        Spacer()

                        Text(formattedPercent(entry.score.accuracy))
                            .font(playFont(13, weight: .bold))
                            .foregroundColor(OniTanTheme.textPrimary)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .oniCard()
    }

    // MARK: - Recommendation

    private func recommendationSection(_ category: CategoryEntry) -> some View {
        Button {
            showRecommendedTraining = true
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text("次にやるべき道場")
                    .font(playFont(14, weight: .bold))
                    .foregroundColor(OniTanTheme.textPrimary)

                HStack(spacing: 10) {
                    OniSymbolMark(
                        systemName: category.iconName,
                        size: 34,
                        fontSize: 15,
                        tint: OniTanTheme.accentWeak,
                        fillOpacity: 0.12,
                        cornerRadius: 9
                    )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(category.title)
                            .font(playFont(14, weight: .bold))
                            .foregroundColor(OniTanTheme.textPrimary)
                        Text(category.description)
                            .font(playFont(11, weight: .regular))
                            .foregroundColor(OniTanTheme.textTertiary)
                            .lineLimit(2)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(OniTanTheme.textTertiary)
                        .accessibilityHidden(true)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .oniCard()
        }
        .buttonStyle(.plain)
        .accessibilityHint("タップして次の道場へ進む")
    }

    // MARK: - Disclaimer

    private var disclaimer: some View {
        Text("現在の問題は開発用サンプルを含みます。本番得点を保証するものではありません。")
            .font(playFont(11, weight: .regular))
            .foregroundColor(OniTanTheme.textTertiary)
            .multilineTextAlignment(.center)
            .padding(.top, 4)
    }

    // MARK: - Helpers

    private func formattedPercent(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }

    private func playFont(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        playFontManager.font(size: size, weight: weight)
    }
}
