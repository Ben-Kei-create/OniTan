import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var statsRepo: StudyStatsRepository
    @EnvironmentObject var streakRepo: StreakRepository
    @EnvironmentObject var xpRepo: GamificationRepository
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var donationManager: DonationManager

    // Unified alert state
    @State private var activeAlert: OniAlert? = nil

    var body: some View {
        ZStack {
            OniTanTheme.backgroundGradientFallback
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    appearanceSection
                    donationSection
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
        .toolbarColorScheme(themeManager.preferredColorScheme == .dark ? .dark : .light, for: .navigationBar)
        .alert(item: $activeAlert) { alert in
            buildAlert(for: alert)
        }
    }

    // MARK: - Donation

    private var donationSection: some View {
        SettingsCard(
            title: "開発者への寄付",
            icon: "heart.fill",
            iconColor: Color(red: 1.0, green: 0.3, blue: 0.4)
        ) {
            VStack(spacing: 12) {
                if donationManager.hasDonated {
                    // 寄付済みの場合
                    VStack(spacing: 8) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 28))
                            .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.2))

                        Text("Thank you!")
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.black)
                            .foregroundColor(OniTanTheme.textPrimary)

                        Text("ご支援ありがとうございます。\n広告が非表示になりました。")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(OniTanTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                } else {
                    // 未寄付の場合
                    Text("広告を非表示にして、開発を応援しよう！\n寄付が完了するとプレイ画面の広告が消えます。")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(OniTanTheme.textSecondary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        Task { await donationManager.purchase() }
                    } label: {
                        HStack(spacing: 8) {
                            if donationManager.isPurchasing {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            Text(donationManager.product.map { $0.displayPrice + " 寄付する" } ?? "寄付する")
                                .font(.system(.headline, design: .rounded))
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 1.0, green: 0.3, blue: 0.5),
                                         Color(red: 0.8, green: 0.1, blue: 0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(OniTanTheme.radiusButton)
                        .shadow(color: Color(red: 1.0, green: 0.3, blue: 0.4).opacity(0.3), radius: 6, y: 3)
                    }
                    .disabled(donationManager.isPurchasing || donationManager.product == nil)
                    .accessibilityLabel("開発者に寄付する")

                    Button {
                        Task { await donationManager.restore() }
                    } label: {
                        Text("購入を復元する")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(OniTanTheme.textTertiary)
                            .underline()
                    }
                    .disabled(donationManager.isPurchasing)
                    .frame(maxWidth: .infinity)

                    if let error = donationManager.purchaseError {
                        Text(error)
                            .font(.system(.caption2, design: .rounded))
                            .foregroundColor(OniTanTheme.accentWrong)
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        SettingsCard(title: "表示設定", icon: "paintbrush.fill", iconColor: OniTanTheme.accentPrimary) {
            VStack(alignment: .leading, spacing: 12) {
                Text("テーマ")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(OniTanTheme.textTertiary)
                    .accessibilityHidden(true)

                HStack(spacing: 10) {
                    ForEach(AppTheme.allCases) { theme in
                        let locked = theme.unlockLevel.map { xpRepo.level < $0 } ?? false
                        ThemePickerCard(
                            theme: theme,
                            isSelected: themeManager.theme == theme,
                            isLocked: locked,
                            unlockLevel: theme.unlockLevel
                        ) {
                            guard !locked else { return }
                            withAnimation(.easeInOut(duration: 0.2)) {
                                themeManager.theme = theme
                            }
                        }
                    }
                }
                .accessibilityLabel("テーマの選択")
            }
        }
    }

    // MARK: - Data

    private var dataSection: some View {
        SettingsCard(title: "データ管理", icon: "folder.fill", iconColor: OniTanTheme.accentWeak) {
            VStack(spacing: 12) {
                progressSummaryRow

                Divider().background(OniTanTheme.cardBorder)

                Button {
                    let hasData = !appState.clearedStages.isEmpty
                        || !statsRepo.stageStats.isEmpty
                        || streakRepo.currentStreak > 0
                        || xpRepo.totalXP > 0
                    if !hasData {
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
                .foregroundColor(OniTanTheme.textTertiary)
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
                .foregroundColor(OniTanTheme.textTertiary)
            Spacer()
            Text(value)
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.semibold)
                .foregroundColor(OniTanTheme.textSecondary)
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
                primaryButton: .destructive(Text("次へ")) {
                    activeAlert = .resetFinalConfirmation
                },
                secondaryButton: .cancel(Text("キャンセル"))
            )
        case .resetFinalConfirmation:
            return Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                primaryButton: .destructive(Text("初期化する")) {
                    appState.reset()
                    statsRepo.reset()
                    streakRepo.reset()
                    xpRepo.reset()
                    activeAlert = .resetComplete
                },
                secondaryButton: .cancel(Text("やめる"))
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

// MARK: - Theme Picker Card

private struct ThemePickerCard: View {
    let theme: AppTheme
    let isSelected: Bool
    let isLocked: Bool
    let unlockLevel: Int?
    let onTap: () -> Void

    private var palette: ThemePalette {
        switch theme {
        case .current: return .current
        case .cool:    return .cool
        case .cute:    return .cute
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                // Color swatch
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: palette.backgroundGradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 36)
                        .overlay(
                            Circle()
                                .fill(palette.accentPrimary)
                                .frame(width: 14, height: 14)
                        )
                        .opacity(isLocked ? 0.35 : 1.0)

                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                if isLocked, let level = unlockLevel {
                    Text("Lv.\(level)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(OniTanTheme.accentWeak)
                        .lineLimit(1)
                } else {
                    Text(theme.displayName)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(OniTanTheme.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(OniTanTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? OniTanTheme.accentPrimary : OniTanTheme.cardBorder,
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .scaleEffect(isSelected ? 1.0 : 0.96)
            .animation(.easeInOut(duration: 0.15), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
        .frame(maxWidth: .infinity)
        .accessibilityLabel(isLocked
            ? "\(theme.displayName)テーマ レベル\(unlockLevel ?? 0)で解放"
            : "\(theme.displayName)テーマ")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
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
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(iconColor)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(OniTanTheme.textTertiary)
                    .textCase(.uppercase)
            }

            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: OniTanTheme.radiusCard)
                .fill(OniTanTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: OniTanTheme.radiusCard)
                        .stroke(OniTanTheme.cardBorder, lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
    }
}
