import SwiftUI

// MARK: - Category Training View

/// Full-screen list of all training categories sourced from categories.json.
/// Falls back to hard-coded entries if the file is absent.
struct CategoryTrainingView: View {
    @EnvironmentObject var themeManager: ThemeManager

    private var categories: [CategoryEntry] {
        categoryManifest?.categories ?? CategoryEntry.fallbacks
    }

    var body: some View {
        ZStack {
            OniTanTheme.backgroundGradientFallback.ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(categories) { entry in
                        NavigationLink(destination: TrainingModePickerView(category: entry)) {
                            CategoryRowCard(entry: entry)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityLabel("\(entry.title) — \(entry.description)")
                        .accessibilityHint("タップして\(entry.title)のモードを選択")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("道場選択")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

// MARK: - Category Row Card

private struct CategoryRowCard: View {
    let entry: CategoryEntry
    @State private var isPressed = false

    private var accentColor: Color { Color(hex: entry.colorHex) }

    private var questionCount: Int {
        if !entry.stageIDs.isEmpty {
            let stageSet = Set(entry.stageIDs)
            return quizData.stages
                .filter { stageSet.contains($0.stage) }
                .flatMap(\.questions).count
        }
        let kindSet = Set(entry.questionKinds)
        return allQuestions.filter { kindSet.contains($0.kind) }.count
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.18))
                    .frame(width: 52, height: 52)
                Image(systemName: entry.iconName)
                    .font(.system(size: 23, weight: .semibold))
                    .foregroundColor(accentColor)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title)
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(OniTanTheme.textPrimary)

                Text(entry.description)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(OniTanTheme.textTertiary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if questionCount > 0 {
                        Text("\(questionCount) 問")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(accentColor)
                    }
                    Text("目標 \(Int(entry.targetAccuracy * 100))%")
                        .font(.system(size: 11))
                        .foregroundColor(OniTanTheme.textTertiary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13))
                .foregroundColor(OniTanTheme.textTertiary)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: OniTanTheme.radiusCard)
                .fill(OniTanTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: OniTanTheme.radiusCard)
                        .stroke(accentColor.opacity(0.25), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
    }
}

// MARK: - Fallback categories (used if categories.json fails to load)

extension CategoryEntry {
    /// Hard-coded fallbacks matching the real Kanken Pre-1 exam structure.
    /// Used when categories.json is absent or fails to load.
    static var fallbacks: [CategoryEntry] {
        [
            CategoryEntry(
                id: "reading",
                title: "読み道場",
                description: "読み・表外の読み・熟語の読みを鍛える",
                questionKinds: [.reading, .hyogaiReading, .compoundReadingKun],
                stageIDs: Array(1...20),
                targetAccuracy: 0.90,
                iconName: "character.book.closed",
                colorHex: "#4A90D9"
            ),
            CategoryEntry(
                id: "commonKanji",
                title: "共通漢字道場",
                description: "複数の語に共通する一字を選ぶ",
                questionKinds: [.commonKanji],
                stageIDs: [],
                targetAccuracy: 0.90,
                iconName: "square.on.square",
                colorHex: "#E67E22"
            ),
            CategoryEntry(
                id: "errorCorrection",
                title: "誤字訂正道場",
                description: "文中の誤った漢字を見つける",
                questionKinds: [.errorCorrection],
                stageIDs: [],
                targetAccuracy: 0.90,
                iconName: "checkmark.circle",
                colorHex: "#E74C3C"
            ),
            CategoryEntry(
                id: "yojijukugo",
                title: "四字熟語道場",
                description: "四字熟語の意味と欠けた文字を覚える",
                questionKinds: [.yojijukugo],
                stageIDs: [],
                targetAccuracy: 0.90,
                iconName: "square.grid.2x2",
                colorHex: "#9B59B6"
            ),
            CategoryEntry(
                id: "synonym_antonym",
                title: "類義語・対義語道場",
                description: "意味が近い・反対の語を覚える",
                questionKinds: [.synonym, .antonym],
                stageIDs: [],
                targetAccuracy: 0.90,
                iconName: "arrow.left.arrow.right",
                colorHex: "#27AE60"
            ),
            CategoryEntry(
                id: "proverb",
                title: "故事・ことわざ道場",
                description: "故事成語・ことわざの意味と用法",
                questionKinds: [.proverb],
                stageIDs: [],
                targetAccuracy: 0.90,
                iconName: "quote.bubble",
                colorHex: "#D4AC0D"
            ),
            CategoryEntry(
                id: "passage",
                title: "文章題道場",
                description: "文章中の読みや語彙・文脈を問う",
                questionKinds: [.passageReading, .passageVocabulary],
                stageIDs: [],
                targetAccuracy: 0.90,
                iconName: "doc.text.below.ecg",
                colorHex: "#2980B9"
            ),
        ]
    }
}
