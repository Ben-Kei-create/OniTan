import SwiftUI

// MARK: - Exam Round

struct ExamRound: Identifiable, Equatable {
    /// A hidden 11th round appears once round 10 is cleared at its 95% threshold.
    static let hiddenRound = 11
    static let totalRounds = hiddenRound
    static let all = (1...totalRounds).map { ExamRound(number: $0) }

    /// Rounds 1-3 are available from the start. From round 4 onward, every
    /// dojo category must be unlocked (i.e. the player has reached the
    /// level required for 文章題道場, the last category to unlock).
    static let freeRounds = 3
    static let allCategoriesUnlockedLevel = 15

    let number: Int

    var id: String { blueprintID }
    var title: String { "第\(number)回" }
    var blueprintID: String { Self.blueprintID(for: number) }

    static func blueprintID(for number: Int) -> String {
        String(format: "exam_round_%02d", number)
    }

    /// Accuracy required to clear this round and unlock the next one.
    /// 第1〜4回: 80% / 第5〜7回: 85% / 第8〜9回: 90% / 第10回: 95% / 第11回(隠し): 100%
    static func passThreshold(for number: Int) -> Double {
        switch number {
        case 1...4: return 0.80
        case 5...7: return 0.85
        case 8...9: return 0.90
        case 10: return 0.95
        default: return 1.0
        }
    }

    var passThreshold: Double { Self.passThreshold(for: number) }

    @MainActor
    func isUnlocked(using repo: ExamResultRepository, xpRepo: GamificationRepository) -> Bool {
        if number <= Self.freeRounds { return true }

        guard xpRepo.level >= Self.allCategoriesUnlockedLevel else { return false }

        let previous = number - 1
        return repo.hasPassed(
            blueprintID: Self.blueprintID(for: previous),
            threshold: Self.passThreshold(for: previous)
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
                        ForEach(visibleRounds) { round in
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
                                .accessibilityHint(state.accessibilityHint(for: round))
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
                                .accessibilityHint(state.accessibilityHint(for: round))
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
                OniSymbolMark(
                    systemName: "doc.text.fill",
                    size: 46,
                    fontSize: 20,
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
                        badge("\(unlockedRoundCount)/10回 解放済み")
                    }
                }
            }

            Text("第1回から順に、本番形式の問題を固定セットで受ける。第4回以降は全道場解放後、前回の合格ライン突破で解放。")
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

            Text("第4回以降は全道場解放後・問題セット追加後に解放されます")
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

    /// Rounds 1-10 are always shown (locked/preparing as appropriate). The hidden
    /// 11th round only appears once it is actually unlocked (round 10 cleared at 95%).
    private var unlockedRoundCount: Int {
        ExamRound.all
            .filter { $0.number <= 10 }
            .filter { $0.isUnlocked(using: examResultRepo, xpRepo: xpRepo) }
            .count
    }

    private var visibleRounds: [ExamRound] {
        ExamRound.all.filter { round in
            round.number < ExamRound.hiddenRound || round.isUnlocked(using: examResultRepo, xpRepo: xpRepo)
        }
    }

    private func roundState(for round: ExamRound) -> ExamRoundButtonState {
        guard round.isUnlocked(using: examResultRepo, xpRepo: xpRepo) else { return .locked }
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

    func detail(for round: ExamRound) -> String {
        switch self {
        case .available: return "タップして開始"
        case .preparing: return "問題セット待ち"
        case .locked: return ExamRoundButtonState.lockedReason(for: round)
        }
    }

    var canStart: Bool { self == .available }

    func accessibilityHint(for round: ExamRound) -> String {
        switch self {
        case .available: return "タップして模擬試験を開始します"
        case .preparing: return "問題セット追加後に開始できます"
        case .locked: return ExamRoundButtonState.lockedReason(for: round)
        }
    }

    /// Human-readable explanation of why a round is still locked.
    static func lockedReason(for round: ExamRound) -> String {
        if round.number == ExamRound.hiddenRound {
            return "第10回を95%以上でクリアすると解放"
        }
        if round.number > ExamRound.freeRounds {
            let previousThreshold = Int(ExamRound.passThreshold(for: round.number - 1) * 100)
            return "全道場解放後、前回\(previousThreshold)%以上で解放"
        }
        return "未解放"
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
                            .fill((isLocked ? OniTanTheme.cardBackgroundPressed : OniTanTheme.accentPrimary).opacity(isLocked ? 0.18 : 0.12))
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

                Text(state.detail(for: round))
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
