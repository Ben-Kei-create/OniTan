import SwiftUI

// MARK: - Quiz Mode Select View
// Presented between StageSelectView and MainView.
// Allows users to choose a learning mode for the selected stage.

struct QuizModeSelectView: View {
    let stage: Stage

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var statsRepo: StudyStatsRepository
    @Environment(\.dismiss) private var dismiss

    private var weakCount: Int {
        statsRepo.weakQuestions(for: stage).count
    }

    private var availableModes: [QuizMode] {
        QuizMode.allCases.filter { mode in
            guard !mode.isSRSPlaceholder else { return false }
            if mode == .weakFocus { return weakCount > 0 }
            return true
        }
    }

    var body: some View {
        ZStack {
            OniTanTheme.backgroundGradientFallback
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerSection

                // Mode list
                ScrollView {
                    VStack(spacing: 14) {
                        ForEach(availableModes) { mode in
                            ModeCard(
                                mode: mode,
                                stage: stage,
                                weakCount: weakCount,
                                appState: appState,
                                statsRepo: statsRepo
                            )
                        }

                        // SRS placeholder
                        srsBadge
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                }
            }
        }
        .navigationTitle("モード選択")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: Header

    private var headerSection: some View {
        VStack(spacing: 6) {
            Text("ステージ \(stage.stage)")
                .font(.system(.title2, design: .rounded))
                .fontWeight(.black)
                .foregroundColor(.white)

            HStack(spacing: 16) {
                Label("\(stage.questions.count) 問", systemImage: "doc.text")
                if weakCount > 0 {
                    Label("苦手 \(weakCount) 問", systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(OniTanTheme.accentWeak)
                }
            }
            .font(.system(.caption, design: .rounded))
            .foregroundColor(.white.opacity(0.65))
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.05))
    }

    // MARK: SRS Badge

    private var srsBadge: some View {
        HStack(spacing: 12) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 20))
                .foregroundColor(.white.opacity(0.35))
                .frame(width: 44)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("SRS復習")
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.white.opacity(0.35))

                    Text("Coming Soon")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.3))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(6)
                }

                Text("間隔反復アルゴリズムによる最適復習")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.white.opacity(0.25))
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: OniTanTheme.radiusCard)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: OniTanTheme.radiusCard)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .accessibilityLabel("SRS復習モード（準備中）")
    }
}

// MARK: - Mode Card

private struct ModeCard: View {
    let mode: QuizMode
    let stage: Stage
    let weakCount: Int
    let appState: AppState
    let statsRepo: StudyStatsRepository

    @EnvironmentObject var streakRepo: StreakRepository
    @EnvironmentObject var xpRepo: GamificationRepository

    @State private var isPressed = false

    private var questionCount: Int {
        if mode == .weakFocus { return weakCount }
        let limit = mode.questionLimit ?? stage.questions.count
        return min(limit, stage.questions.count)
    }

    var body: some View {
        NavigationLink(
            destination: MainView(
                stage: stage,
                appState: appState,
                statsRepo: statsRepo,
                streakRepo: streakRepo,
                xpRepo: xpRepo,
                mode: mode
            )
        ) {
            HStack(spacing: 14) {
                // Icon circle
                ZStack {
                    Circle()
                        .fill(iconBackground)
                        .frame(width: 48, height: 48)

                    Image(systemName: mode.systemImage)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(mode.displayName)
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        // Question count badge
                        Text("\(questionCount) 問")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.65))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.12))
                            .cornerRadius(8)
                    }

                    Text(mode.description)
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.4))
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: OniTanTheme.radiusCard)
                    .fill(cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: OniTanTheme.radiusCard)
                            .stroke(cardBorder, lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(mode.displayName) \(questionCount)問 \(mode.description)")
        .accessibilityHint("タップして\(mode.displayName)で開始")
    }

    private var iconBackground: LinearGradient {
        switch mode {
        case .normal:    return OniTanTheme.primaryGradient
        case .quick10:   return LinearGradient(colors: [Color(red: 1.0, green: 0.5, blue: 0.0), Color(red: 0.9, green: 0.35, blue: 0.0)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .exam30:    return LinearGradient(colors: [Color(red: 0.2, green: 0.5, blue: 0.9), Color(red: 0.1, green: 0.35, blue: 0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .weakFocus: return LinearGradient(colors: [OniTanTheme.accentWeak, Color(red: 0.9, green: 0.4, blue: 0.0)], startPoint: .topLeading, endPoint: .bottomTrailing)
        default:         return OniTanTheme.primaryGradient
        }
    }

    private var cardBackground: Color {
        mode == .weakFocus ? Color(red: 0.25, green: 0.15, blue: 0.05).opacity(0.7) : Color.white.opacity(0.10)
    }

    private var cardBorder: Color {
        mode == .weakFocus ? OniTanTheme.accentWeak.opacity(0.35) : Color.white.opacity(0.18)
    }
}
