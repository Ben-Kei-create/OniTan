import SwiftUI

struct StudyProgressView: View {
    @EnvironmentObject var statsRepo: StudyStatsRepository

    private static let displayKinds: [QuestionKind] = [
        .sentenceReading, .hyogaiReading, .compoundReadingKun,
        .yojijukugo, .writing, .synonym, .antonym,
        .proverb, .commonKanji, .errorCorrection
    ]

    private var summary: StudyProgressSummary {
        StudyProgressSummary(stats: statsRepo.stageStats, stages: [])
    }

    var body: some View {
        ZStack {
            OniTanTheme.backgroundGradientFallback
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    overallCard
                    kindSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("学習進捗")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: - Overall Card

    private var overallCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 24) {
                ProgressRingView(
                    progress: summary.accuracy ?? 0,
                    lineWidth: 10,
                    size: 80
                )
                .accessibilityLabel("全体正答率 \(accuracyText(summary.accuracy))")

                VStack(alignment: .leading, spacing: 6) {
                    statRow(label: "全体正答率", value: accuracyText(summary.accuracy))
                    statRow(label: "総解答数",   value: "\(summary.total)問")
                    statRow(label: "正解数",     value: "\(summary.correct)問")
                }
                Spacer()
            }
        }
        .padding(16)
        .background(OniTanTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(OniTanTheme.cardBorder, lineWidth: 1))
    }

    // MARK: - Per-Kind Section

    private var kindSection: some View {
        VStack(spacing: 0) {
            ForEach(Array(Self.displayKinds.enumerated()), id: \.element) { idx, kind in
                let score = summary.byKind[kind]
                kindRow(kind: kind, score: score, isLast: idx == Self.displayKinds.count - 1)
            }
        }
        .background(OniTanTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(OniTanTheme.cardBorder, lineWidth: 1))
    }

    private func kindRow(kind: QuestionKind, score: KindScore?, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: kind.systemImage)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(OniTanTheme.accentPrimary)
                    .frame(width: 20)

                Text(kind.displayName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(OniTanTheme.textPrimary)

                Spacer()

                if let score, score.total > 0 {
                    let acc = Double(score.correct) / Double(score.total)
                    Text(accuracyText(acc))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(accuracyColor(acc))
                    Text("(\(score.correct)/\(score.total))")
                        .font(.system(size: 12))
                        .foregroundColor(OniTanTheme.textTertiary)
                } else {
                    Text("未学習")
                        .font(.system(size: 13))
                        .foregroundColor(OniTanTheme.textTertiary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)

            if !isLast {
                Divider()
                    .padding(.leading, 48)
            }
        }
    }

    // MARK: - Helpers

    private func statRow(label: String, value: String) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(OniTanTheme.textTertiary)
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(OniTanTheme.textPrimary)
        }
    }

    private func accuracyText(_ acc: Double?) -> String {
        guard let acc else { return "—" }
        return "\(Int(acc * 100))%"
    }

    private func accuracyColor(_ acc: Double) -> Color {
        switch acc {
        case 0.8...: return OniTanTheme.accentCorrect
        case 0.5...: return OniTanTheme.accentWeak
        default:     return OniTanTheme.accentWrong
        }
    }
}
