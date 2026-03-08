import SwiftUI

// MARK: - Wrong Answer Note View

struct WrongAnswerNoteView: View {
    @EnvironmentObject var statsRepo: StudyStatsRepository
    @EnvironmentObject var themeManager: ThemeManager

    @State private var selectedEntry: WrongAnswerEntry? = nil

    private var filteredEntries: [WrongAnswerEntry] {
        statsRepo.recentWrongAnswers(limit: 200)
    }

    var body: some View {
        ZStack {
            OniTanTheme.backgroundGradientFallback
                .ignoresSafeArea()

            VStack(spacing: 0) {
                entryCountBar

                if filteredEntries.isEmpty {
                    emptyState
                } else {
                    entryList
                }
            }
        }
        .navigationTitle("誤答ノート")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(themeManager.preferredColorScheme == .dark ? .dark : .light, for: .navigationBar)
        .sheet(item: $selectedEntry) { entry in
            WrongAnswerDetailSheet(entry: entry)
        }
    }

    // MARK: Entry Count Bar

    private var entryCountBar: some View {
        HStack {
            Spacer()
            Text("\(filteredEntries.count) 件")
                .font(.system(.caption2, design: .rounded))
                .foregroundColor(OniTanTheme.textTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(OniTanTheme.cardBackground.opacity(0.5))
    }

    // MARK: Entry List

    private var entryList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(filteredEntries) { entry in
                    WrongAnswerRow(entry: entry)
                        .onTapGesture {
                            selectedEntry = entry
                        }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
    }

    // MARK: Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 56))
                .foregroundColor(OniTanTheme.accentCorrect.opacity(0.6))

            Text("誤答記録なし")
                .font(.system(.title3, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(OniTanTheme.textSecondary)

            Text("ステージに挑戦すると\n間違えた問題がここに記録されます")
                .font(.system(.caption, design: .rounded))
                .foregroundColor(OniTanTheme.textTertiary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("誤答記録がありません。ステージに挑戦すると記録されます。")
    }
}

// MARK: - Wrong Answer Row

private struct WrongAnswerRow: View {
    let entry: WrongAnswerEntry
    var showsXPBadge: Bool = true

    private var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: entry.date, relativeTo: Date())
    }

    private var stageBadgeText: String {
        entry.stageNumber < 0 ? "復習" : "S\(entry.stageNumber)"
    }

    var body: some View {
        HStack(spacing: 14) {
            Text(entry.kanji)
                .font(.system(size: 38, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(OniTanTheme.wrongGradient)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: OniTanTheme.accentWrong.opacity(0.35), radius: 6, y: 3)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(stageBadgeText)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(OniTanTheme.textTertiary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(OniTanTheme.cardBackground)
                        .cornerRadius(6)

                    Text(relativeDate)
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(OniTanTheme.textTertiary)
                }

                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(OniTanTheme.accentCorrect)
                    Text("正解: \(entry.correctAnswer)")
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(OniTanTheme.textPrimary)
                }

                if !entry.selectedAnswer.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(OniTanTheme.accentWrong)
                        Text("選択: \(entry.selectedAnswer)")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(OniTanTheme.textTertiary)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if showsXPBadge {
                    Text("+\(XPEvent.wrongNoteRetrieved.points) XP")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.2))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color(red: 0.35, green: 0.28, blue: 0.05).opacity(0.6))
                        )
                        .accessibilityHidden(true)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(OniTanTheme.textTertiary)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: OniTanTheme.radiusBadge)
                .fill(OniTanTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: OniTanTheme.radiusBadge)
                        .stroke(OniTanTheme.accentWrong.opacity(0.20), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("漢字: \(entry.kanji) 正解: \(entry.correctAnswer) \(stageBadgeText) \(relativeDate)")
    }
}

// MARK: - Wrong Answer Detail Sheet

struct WrongAnswerDetailSheet: View {
    let entry: WrongAnswerEntry
    @Environment(\.dismiss) private var dismiss

    private var fullQuestion: Question? {
        allQuestions.first { $0.kanji == entry.kanji }
    }

    var body: some View {
        ZStack {
            OniTanTheme.backgroundGradientFallback
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Capsule()
                    .fill(OniTanTheme.textTertiary)
                    .frame(width: 40, height: 4)
                    .padding(.top, 12)
                    .padding(.bottom, 20)

                ScrollView {
                    VStack(spacing: 20) {
                        Text(entry.kanji)
                            .font(.system(size: 100, weight: .black, design: .rounded))
                            .foregroundStyle(OniTanTheme.primaryGradient)
                            .shadow(color: OniTanTheme.shadowGlow.color, radius: 8)
                            .accessibilityLabel("漢字: \(entry.kanji)")

                        VStack(spacing: 10) {
                            infoRow(
                                icon: "checkmark.circle.fill",
                                iconColor: OniTanTheme.accentCorrect,
                                label: "正解",
                                value: entry.correctAnswer
                            )
                            if !entry.selectedAnswer.isEmpty {
                                infoRow(
                                    icon: "xmark.circle.fill",
                                    iconColor: OniTanTheme.accentWrong,
                                    label: "あなたの回答",
                                    value: entry.selectedAnswer
                                )
                            }
                            infoRow(
                                icon: "calendar",
                                iconColor: OniTanTheme.textTertiary,
                                label: "日時",
                                value: formattedDate
                            )
                        }
                        .padding(16)
                        .background(OniTanTheme.cardBackground)
                        .cornerRadius(OniTanTheme.radiusCard)
                        .padding(.horizontal, 20)

                        if let q = fullQuestion {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("解説")
                                    .font(.system(.headline, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundColor(OniTanTheme.textSecondary)

                                Text(q.displayExplanation)
                                    .font(.system(.body, design: .rounded))
                                    .foregroundColor(OniTanTheme.textSecondary)
                                    .lineSpacing(5)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(OniTanTheme.cardBackground)
                            .cornerRadius(OniTanTheme.radiusCard)
                            .padding(.horizontal, 20)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("解説: \(q.displayExplanation)")
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .presentationDetents([.fraction(0.75), .large])
        .presentationDragIndicator(.hidden)
        .onAppear {
            OniTanTheme.haptic(.light)
        }
    }

    private func infoRow(icon: String, iconColor: Color, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(.system(size: 16))
                .frame(width: 24)
            Text(label)
                .font(.system(.caption, design: .rounded))
                .foregroundColor(OniTanTheme.textTertiary)
                .frame(width: 80, alignment: .leading)
            Text(value)
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.semibold)
                .foregroundColor(OniTanTheme.textPrimary)
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private var formattedDate: String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "ja_JP")
        fmt.dateStyle = .medium
        fmt.timeStyle = .short
        return fmt.string(from: entry.date)
    }
}
