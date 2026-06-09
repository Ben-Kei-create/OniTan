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
    /// Hard-coded fallbacks so the dojo screen never crashes due to a missing JSON file.
    static var fallbacks: [CategoryEntry] {
        [
            CategoryEntry(
                id: "reading",
                title: "読み道場",
                description: "音読み・訓読み・熟字訓を鍛える",
                questionKinds: [.reading, .jukujikun],
                stageIDs: Array(1...20),
                targetAccuracy: 0.90,
                iconName: "character.book.closed",
                colorHex: "#4A90D9"
            ),
            CategoryEntry(
                id: "writing",
                title: "書き取り道場",
                description: "かなを正しい漢字に変換する",
                questionKinds: [.writing],
                stageIDs: [],
                targetAccuracy: 0.90,
                iconName: "pencil",
                colorHex: "#E85D3A"
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
        ]
    }
}
