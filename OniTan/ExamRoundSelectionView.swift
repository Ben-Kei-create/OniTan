import SwiftUI

// MARK: - Exam Round

struct ExamRound: Identifiable, Equatable {
    /// Matches the default passing accuracy shown on ExamResultView so that
    /// the "合格" banner and the next-round unlock condition stay in sync.
    static let passThreshold = 0.90
    static let totalRounds = 10
    static let all = (1...totalRounds).map { ExamRound(number: $0) }

    let number: Int

    var id: String { blueprintID }
    var title: String { "第\(number)回" }
    var blueprintID: String { Self.blueprintID(for: number) }

    static func blueprintID(for number: Int) -> String {
        String(format: "exam_round_%02d", number)
    }

    @MainActor
    func isUnlocked(using repo: ExamResultRepository) -> Bool {
        guard number > 1 else { return true }
        return repo.hasPassed(
            blueprintID: Self.blueprintID(for: number - 1),
            threshold: Self.passThreshold
        )
    }

    /// Whether a fixed question set exists for this round yet.
    /// Only round 1 ships with content for now; later rounds remain "準備中".
    var hasContent: Bool {
        examBlueprints.contains { $0.id == blueprintID }
    }
}

// MARK: - Exam Round Selection View

struct ExamRoundSelectionView: View {
    @EnvironmentObject var examResultRepo: ExamResultRepository
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var statsRepo: StudyStatsRepository
    @EnvironmentObject var streakRepo: StreakRepository
    @EnvironmentObject var xpRepo: GamificationRepository
    @EnvironmentObject var masteryRepo: MasteryRepository

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ZStack {
            OniTanTheme.backgroundGradientFallback.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(ExamRound.all) { round in
                            let state = roundState(for: round)

                            if state.canStart {
                                NavigationLink(destination: examSessionView(for: round)) {
                                    ExamRoundButtonCard(
                                        round: round,
                                        state: state,
                                        bestAccuracy: examResultRepo.bestAccuracy(forBlueprintID: round.blueprintID)
                                    )
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(accessibilityLabel(for: round, state: state))
                                .accessibilityHint(state.accessibilityHint)
                            } else {
                                Button {
                                    OniTanTheme.haptic(.light)
                                } label: {
                                    ExamRoundButtonCard(
                                        round: round,
                                        state: state,
                                        bestAccuracy: examResultRepo.bestAccuracy(forBlueprintID: round.blueprintID)
                                    )
                                }
                                .buttonStyle(.plain)
                                .disabled(true)
                                .accessibilityLabel(accessibilityLabel(for: round, state: state))
                                .accessibilityHint(state.accessibilityHint)
                            }
                        }
                    }

                    footnote
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 36)
            }
        }
        .navigationTitle("模擬試験")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                OniSealMark(
                    text: "試",
                    size: 46,
                    fontSize: 22,
                    tint: OniTanTheme.accentPrimary,
                    fillOpacity: 0.16,
                    cornerRadius: 12
                )

                VStack(alignment: .leading, spacing: 5) {
                    Text("総合模試")
                        .font(.system(size: 25, weight: .black, design: .rounded))
                        .foregroundColor(OniTanTheme.textPrimary)

                    HStack(spacing: 7) {
                        badge("全10回")
                        badge("90%解放")
                    }
                }
            }

            Text("第1回から順に、本番形式の問題を固定セットで受ける。")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(OniTanTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Rectangle()
                .fill(OniTanTheme.goldGradient)
                .frame(width: 44, height: 2)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var footnote: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(OniTanTheme.textTertiary)
                .accessibilityHidden(true)

            Text("第2回以降は問題セット追加後に解放されます")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(OniTanTheme.textTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 11)
                .fill(OniTanTheme.cardBackground.opacity(0.46))
                .overlay(
                    RoundedRectangle(cornerRadius: 11)
                        .stroke(OniTanTheme.cardBorder.opacity(0.45), lineWidth: 1)
                )
        )
    }

    private func badge(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundColor(OniTanTheme.accentPrimary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(OniTanTheme.accentPrimary.opacity(0.12))
                    .overlay(Capsule().stroke(OniTanTheme.accentPrimary.opacity(0.24), lineWidth: 1))
            )
    }

    private func roundState(for round: ExamRound) -> ExamRoundButtonState {
        guard round.isUnlocked(using: examResultRepo) else { return .locked }
        return round.hasContent ? .available : .preparing
    }

    @ViewBuilder
    private func examSessionView(for round: ExamRound) -> some View {
        if let blueprint = examBlueprints.first(where: { $0.id == round.blueprintID }) {
            let pool = allQuestions.filter { $0.kind.isExamEligible }
            let questions = ExamBuilder.build(blueprint: blueprint, from: pool, fixedSet: true).questions
            MainView(
                stage: Stage(stage: 0, questions: questions),
                appState: appState,
                statsRepo: statsRepo,
                streakRepo: streakRepo,
                xpRepo: xpRepo,
                masteryRepo: masteryRepo,
                examResultRepo: examResultRepo,
                examBlueprintID: blueprint.id,
                mode: .exam30,
                sessionTitle: round.title
            )
        }
    }

    private func accessibilityLabel(for round: ExamRound, state: ExamRoundButtonState) -> String {
        "\(round.title) \(state.label)"
    }
}

private enum ExamRoundButtonState {
    case available
    case preparing
    case locked

    var label: String {
        switch self {
        case .available: return "挑戦できる"
        case .preparing: return "準備中"
        case .locked: return "未解放"
        }
    }

    var detail: String {
        switch self {
        case .available: return "タップして開始"
        case .preparing: return "問題セット待ち"
        case .locked: return "前回90%以上で解放"
        }
    }

    var canStart: Bool { self == .available }

    var accessibilityHint: String {
        switch self {
        case .available: return "タップして模擬試験を開始します"
        case .preparing: return "問題セット追加後に開始できます"
        case .locked: return "直前の回を90%以上でクリアすると解放されます"
        }
    }
}

private struct ExamRoundButtonCard: View {
    let round: ExamRound
    let state: ExamRoundButtonState
    let bestAccuracy: Double?

    private var isLocked: Bool { state == .locked }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Text("\(round.number)")
                    .font(.system(size: 22, weight: .black, design: .serif))
                    .foregroundColor(isLocked ? OniTanTheme.textTertiary.opacity(0.55) : OniTanTheme.accentPrimary)
                    .frame(width: 42, height: 42)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill((isLocked ? OniTanTheme.textTertiary : OniTanTheme.accentPrimary).opacity(isLocked ? 0.08 : 0.16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke((isLocked ? OniTanTheme.cardBorder : OniTanTheme.accentPrimary).opacity(0.34), lineWidth: 1)
                            )
                    )

                Spacer(minLength: 8)

                Text(state.label)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(isLocked ? OniTanTheme.textTertiary : OniTanTheme.accentPrimary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill((isLocked ? OniTanTheme.cardBackgroundPressed : OniTanTheme.accentPrimary).opacity(isLocked ? 0.5 : 0.12))
                            .overlay(
                                Capsule()
                                    .stroke((isLocked ? OniTanTheme.cardBorder : OniTanTheme.accentPrimary).opacity(0.25), lineWidth: 1)
                            )
                    )
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(round.title)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(isLocked ? OniTanTheme.textTertiary : OniTanTheme.textPrimary)

                Text(state.detail)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(isLocked ? OniTanTheme.textTertiary.opacity(0.72) : OniTanTheme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)

            Text(bestAccuracyText)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(OniTanTheme.textTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 142, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: OniTanTheme.radiusCard)
                .fill(isLocked ? OniTanTheme.cardBackground.opacity(0.44) : OniTanTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: OniTanTheme.radiusCard)
                        .stroke(
                            isLocked ? OniTanTheme.cardBorder.opacity(0.35) : OniTanTheme.accentPrimary.opacity(0.28),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: .black.opacity(isLocked ? 0.08 : 0.22), radius: 9, y: 4)
    }

    private var bestAccuracyText: String {
        guard let bestAccuracy else { return "最高 --%" }
        return "最高 \(Int((bestAccuracy * 100).rounded()))%"
    }
}
