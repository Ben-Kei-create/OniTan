import SwiftUI

// MARK: - Wrong Answer Note View
// Displays chronological log of all wrong answers grouped by stage.
// Users can tap any entry to see the full question detail.

struct WrongAnswerNoteView: View {
    @EnvironmentObject var statsRepo: StudyStatsRepository

    @State private var selectedFilter: FilterMode = .all
    @State private var selectedEntry: WrongAnswerEntry? = nil

    enum FilterMode: String, CaseIterable {
        case all    = "全て"
        case stage1 = "S1"
        case stage2 = "S2"
        case stage3 = "S3"
    }

    private var filteredEntries: [WrongAnswerEntry] {
        let recent = statsRepo.recentWrongAnswers(limit: 200)
        switch selectedFilter {
        case .all:    return recent
        case .stage1: return recent.filter { $0.stageNumber == 1 }
        case .stage2: return recent.filter { $0.stageNumber == 2 }
        case .stage3: return recent.filter { $0.stageNumber == 3 }
        }
    }

    var body: some View {
        ZStack {
            OniTanTheme.backgroundGradientFallback
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Filter bar
                filterBar

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
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(item: $selectedEntry) { entry in
            WrongAnswerDetailSheet(entry: entry)
        }
    }

    // MARK: Filter Bar

    private var filterBar: some View {
        HStack(spacing: 8) {
            ForEach(FilterMode.allCases, id: \.self) { filter in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedFilter = filter
                    }
                } label: {
                    Text(filter.rawValue)
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(selectedFilter == filter ? .bold : .regular)
                        .foregroundColor(selectedFilter == filter ? .white : .white.opacity(0.55))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(selectedFilter == filter
                                      ? OniTanTheme.accentWeak
                                      : Color.white.opacity(0.10))
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("\(filter.rawValue)フィルター")
                .accessibilityAddTraits(selectedFilter == filter ? .isSelected : [])
            }

            Spacer()

            Text("\(filteredEntries.count) 件")
                .font(.system(.caption2, design: .rounded))
                .foregroundColor(.white.opacity(0.45))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.05))
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
                .foregroundColor(.white.opacity(0.7))

            Text("ステージに挑戦すると\n間違えた問題がここに記録されます")
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.white.opacity(0.45))
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

    private var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: entry.date, relativeTo: Date())
    }

    var body: some View {
        HStack(spacing: 14) {
            // Kanji
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
                    Text("S\(entry.stageNumber)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(6)

                    Text(relativeDate)
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(.white.opacity(0.4))
                }

                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(OniTanTheme.accentCorrect)
                    Text("正解: \(entry.correctAnswer)")
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }

                if !entry.selectedAnswer.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(OniTanTheme.accentWrong)
                        Text("選択: \(entry.selectedAnswer)")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.white.opacity(0.55))
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.3))
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: OniTanTheme.radiusBadge)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: OniTanTheme.radiusBadge)
                        .stroke(OniTanTheme.accentWrong.opacity(0.20), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("漢字: \(entry.kanji) 正解: \(entry.correctAnswer) ステージ\(entry.stageNumber) \(relativeDate)")
    }
}

// MARK: - Wrong Answer Detail Sheet

struct WrongAnswerDetailSheet: View {
    let entry: WrongAnswerEntry
    @Environment(\.dismiss) private var dismiss

    // Look up the full question from quiz data
    private var fullQuestion: Question? {
        questions.first { $0.kanji == entry.kanji }
    }

    var body: some View {
        ZStack {
            OniTanTheme.backgroundGradientFallback
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Handle
                Capsule()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 40, height: 4)
                    .padding(.top, 12)
                    .padding(.bottom, 20)

                ScrollView {
                    VStack(spacing: 20) {
                        // Big kanji
                        Text(entry.kanji)
                            .font(.system(size: 100, weight: .black, design: .rounded))
                            .foregroundStyle(OniTanTheme.primaryGradient)
                            .shadow(color: .purple.opacity(0.3), radius: 8)
                            .accessibilityLabel("漢字: \(entry.kanji)")

                        // Answer info
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
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(OniTanTheme.radiusCard)
                        .padding(.horizontal, 20)

                        // Full explanation (if available)
                        if let q = fullQuestion {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("解説")
                                    .font(.system(.headline, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundColor(.white.opacity(0.85))

                                Text(q.explain)
                                    .font(.system(.body, design: .rounded))
                                    .foregroundColor(.white.opacity(0.75))
                                    .lineSpacing(5)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(OniTanTheme.radiusCard)
                            .padding(.horizontal, 20)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("解説: \(q.explain)")
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .presentationDetents([.fraction(0.75), .large])
        .presentationDragIndicator(.hidden)
    }

    private func infoRow(icon: String, iconColor: Color, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(.system(size: 16))
                .frame(width: 24)
            Text(label)
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
                .frame(width: 80, alignment: .leading)
            Text(value)
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.semibold)
                .foregroundColor(.white)
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
