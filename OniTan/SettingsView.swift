import SwiftUI

struct SettingsView: View {
    @AppStorage("colorScheme") private var colorSchemeString: String = "system"
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var statsRepo: StudyStatsRepository

    // Unified alert state — replaces three separate Bool flags
    @State private var activeAlert: OniAlert? = nil

    var body: some View {
        ZStack {
            OniTanTheme.backgroundGradientFallback
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    appearanceSection
                    dataSection
                    appInfoSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 24)
            }
        }
        .navigationTitle("設定")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .alert(item: $activeAlert) { alert in
            buildAlert(for: alert)
        }
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        SettingsCard(title: "表示設定", icon: "paintbrush.fill", iconColor: OniTanTheme.accentPrimary) {
            VStack(alignment: .leading, spacing: 12) {
                Text("カラーモード")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.white.opacity(0.65))
                    .accessibilityHidden(true)

                Picker("カラーモード", selection: $colorSchemeString) {
                    Text("システム").tag("system")
                    Text("ライト").tag("light")
                    Text("ダーク").tag("dark")
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("カラーモードの選択")
            }
        }
    }

    // MARK: - Data

    private var dataSection: some View {
        SettingsCard(title: "データ管理", icon: "folder.fill", iconColor: OniTanTheme.accentWeak) {
            VStack(spacing: 12) {
                // Progress summary
                progressSummaryRow

                Divider().background(Color.white.opacity(0.12))

                // Reset button
                Button {
                    if appState.clearedStages.isEmpty && statsRepo.stageStats.isEmpty {
                        activeAlert = .nothingToReset
                    } else {
                        activeAlert = .resetConfirmation
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 14, weight: .semibold))
                        Text("進行状況を初期化")
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(OniTanTheme.wrongGradient)
                    .cornerRadius(OniTanTheme.radiusButton)
                    .shadow(color: OniTanTheme.accentWrong.opacity(0.3), radius: 6, y: 3)
                }
                .accessibilityLabel("進行状況を初期化する")
                .accessibilityHint("全クリア情報と統計が削除されます。確認ダイアログが表示されます。")
            }
        }
    }

    private var progressSummaryRow: some View {
        HStack(spacing: 20) {
            progressPill(
                value: "\(appState.clearedStages.count)",
                label: "クリア済み",
                iconColor: OniTanTheme.accentCorrect
            )
            progressPill(
                value: String(format: "%.0f%%", statsRepo.overallAccuracy * 100),
                label: "正答率",
                iconColor: OniTanTheme.accentPrimary
            )
            progressPill(
                value: "\(statsRepo.totalCorrect)",
                label: "総正解",
                iconColor: OniTanTheme.accentWeak
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("クリア\(appState.clearedStages.count)ステージ 正答率\(Int(statsRepo.overallAccuracy * 100))% 総正解\(statsRepo.totalCorrect)問")
    }

    private func progressPill(value: String, label: String, iconColor: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(.headline, design: .rounded))
                .fontWeight(.black)
                .foregroundColor(iconColor)
            Text(label)
                .font(.system(size: 10, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .accessibilityHidden(true)
    }

    // MARK: - App Info

    private var appInfoSection: some View {
        SettingsCard(title: "アプリ情報", icon: "info.circle.fill", iconColor: Color(red: 0.3, green: 0.5, blue: 0.9)) {
            VStack(spacing: 10) {
                infoRow(label: "バージョン", value: appVersion)
                infoRow(label: "対象範囲", value: "漢字検定準1級")
                infoRow(label: "収録ステージ", value: "\(quizData.stages.count) ステージ")
                infoRow(label: "収録問題数", value: "\(questions.count) 問")
            }
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.white.opacity(0.55))
            Spacer()
            Text(value)
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.9))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    // MARK: - Alert builder

    private func buildAlert(for alert: OniAlert) -> Alert {
        switch alert {
        case .resetConfirmation:
            return Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                primaryButton: .destructive(Text("初期化する")) {
                    appState.reset()
                    statsRepo.reset()
                    activeAlert = .resetComplete
                },
                secondaryButton: .cancel(Text("キャンセル"))
            )
        default:
            return Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

// MARK: - Settings Card

private struct SettingsCard<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Card header
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(iconColor)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.55))
                    .textCase(.uppercase)
            }

            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: OniTanTheme.radiusCard)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: OniTanTheme.radiusCard)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
    }
}
