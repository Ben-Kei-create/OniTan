import SwiftUI

struct StageSelectView: View {
    @EnvironmentObject var appState: AppState

    private let stages = quizData.stages.sorted { $0.stage < $1.stage }

    var body: some View {
        ScrollView {
            VStack(spacing: OniTheme.Spacing.md) {
                ForEach(stages, id: \.stage) { stage in
                    let isCleared = appState.isStageCleared(stage.stage)
                    let isUnlocked = appState.isStageUnlocked(stage.stage)

                    if isUnlocked {
                        NavigationLink(destination: MainView(stage: stage)) {
                            stageCard(stage: stage, isCleared: isCleared, isUnlocked: true)
                        }
                    } else {
                        stageCard(stage: stage, isCleared: false, isUnlocked: false)
                    }
                }
            }
            .padding(.horizontal, OniTheme.Spacing.md)
            .padding(.vertical, OniTheme.Spacing.sm)
        }
        .navigationTitle("ステージ選択")
        .navigationBarTitleDisplayMode(.large)
        .gradientBackground()
    }

    private func stageCard(stage: Stage, isCleared: Bool, isUnlocked: Bool) -> some View {
        HStack(spacing: OniTheme.Spacing.md) {
            // Status icon
            ZStack {
                Circle()
                    .fill(statusColor(isCleared: isCleared, isUnlocked: isUnlocked).opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: statusIcon(isCleared: isCleared, isUnlocked: isUnlocked))
                    .font(.title3.weight(.semibold))
                    .foregroundColor(statusColor(isCleared: isCleared, isUnlocked: isUnlocked))
            }

            VStack(alignment: .leading, spacing: OniTheme.Spacing.xs) {
                Text("ステージ \(stage.stage)")
                    .font(.title3.weight(.bold))
                    .foregroundColor(isUnlocked ? .primary : .secondary)

                Text(statusText(isCleared: isCleared, isUnlocked: isUnlocked))
                    .font(.caption)
                    .foregroundColor(isCleared ? OniTheme.Colors.success : .secondary)
            }

            Spacer()

            if isUnlocked {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundColor(.secondary)
            }
        }
        .padding(OniTheme.Spacing.md)
        .background(OniTheme.Colors.cardBackground)
        .cornerRadius(OniTheme.Radius.lg)
        .shadow(color: .black.opacity(isUnlocked ? 0.08 : 0.03), radius: isUnlocked ? 8 : 4, x: 0, y: 3)
        .opacity(isUnlocked ? 1.0 : 0.6)
    }

    private func statusIcon(isCleared: Bool, isUnlocked: Bool) -> String {
        if isCleared { return "checkmark.circle.fill" }
        if isUnlocked { return "play.circle.fill" }
        return "lock.fill"
    }

    private func statusColor(isCleared: Bool, isUnlocked: Bool) -> Color {
        if isCleared { return OniTheme.Colors.success }
        if isUnlocked { return OniTheme.Colors.quizBlue }
        return OniTheme.Colors.locked
    }

    private func statusText(isCleared: Bool, isUnlocked: Bool) -> String {
        if isCleared { return "クリア済み" }
        if isUnlocked { return "挑戦可能" }
        return "前のステージをクリアして解放"
    }
}
