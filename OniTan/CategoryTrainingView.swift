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
                LazyVStack(spacing: 14) {
                    header

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
                .padding(.top, 16)
                .padding(.bottom, 36)
            }
        }
        .navigationTitle("道場選択")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("分野別に鍛える")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundColor(OniTanTheme.textPrimary)

            Text("弱点を一つずつ削るための、準1級専用道場。")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(OniTanTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Rectangle()
                .fill(OniTanTheme.goldGradient)
                .frame(width: 44, height: 2)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 4)
    }
}

// MARK: - Category Row Card

private struct CategoryRowCard: View {
    let entry: CategoryEntry
    @State private var isPressed = false

    private var accentColor: Color {
        entry.id == "exam" ? OniTanTheme.accentPrimary : OniTanTheme.accentWeak
    }

    private var dojoMark: String {
        entry.sealMark
    }

    private var displayTitle: String {
        entry.title.replacingOccurrences(of: "道場", with: "")
    }

    private var questionCount: Int {
        if !entry.stageIDs.isEmpty {
            let stageSet = Set(entry.stageIDs)
            return quizData.stages
                .filter { stageSet.contains($0.stage) }
                .flatMap(\.questions)
                .filter { $0.kind.isExamEligible }
                .count
        }
        let kindSet = Set(entry.questionKinds)
        return allQuestions.filter { kindSet.contains($0.kind) }.count
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(accentColor.opacity(entry.id == "exam" ? 0.18 : 0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(accentColor.opacity(0.35), lineWidth: 1)
                    )
                    .frame(width: 48, height: 48)

                Text(dojoMark)
                    .font(.system(size: 23, weight: .black, design: .serif))
                    .foregroundColor(accentColor)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 8) {
                    Text(displayTitle)
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundColor(OniTanTheme.textPrimary)

                    if entry.id == "exam" {
                        Text("本番形式")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(OniTanTheme.accentPrimary)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(OniTanTheme.accentPrimary.opacity(0.12))
                                    .overlay(Capsule().stroke(OniTanTheme.accentPrimary.opacity(0.25), lineWidth: 1))
                            )
                    }
                }

                Text(entry.description)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(OniTanTheme.textSecondary)
                    .lineLimit(1)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 10) {
                    metadataPill(text: "\(questionCount) 問")
                    metadataPill(text: "目標 \(Int(entry.targetAccuracy * 100))%")
                }
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(OniTanTheme.textTertiary)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: OniTanTheme.radiusCard)
                .fill(
                    LinearGradient(
                        colors: [
                            OniTanTheme.cardBackgroundPressed.opacity(entry.id == "exam" ? 0.96 : 0.82),
                            OniTanTheme.cardBackground.opacity(0.92)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: OniTanTheme.radiusCard)
                        .stroke(accentColor.opacity(entry.id == "exam" ? 0.34 : 0.18), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.24), radius: 10, y: 5)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
    }

    private func metadataPill(text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundColor(OniTanTheme.textTertiary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.18))
                    .overlay(Capsule().stroke(OniTanTheme.cardBorder, lineWidth: 1))
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
                description: "例文中の傍線部の読みを鍛える",
                questionKinds: [.sentenceReading],
                stageIDs: [97, 98, 99],
                targetAccuracy: 0.90,
                iconName: "character.book.closed",
                colorHex: "#D8B45A"
            ),
            CategoryEntry(
                id: "commonKanji",
                title: "共通漢字道場",
                description: "複数の語に共通する一字を選ぶ",
                questionKinds: [.commonKanji],
                stageIDs: [],
                targetAccuracy: 0.90,
                iconName: "square.on.square",
                colorHex: "#D8B45A"
            ),
            CategoryEntry(
                id: "errorCorrection",
                title: "誤字訂正道場",
                description: "文中の誤った漢字を見つける",
                questionKinds: [.errorCorrection],
                stageIDs: [],
                targetAccuracy: 0.90,
                iconName: "checkmark.circle",
                colorHex: "#B91C2B"
            ),
            CategoryEntry(
                id: "yojijukugo",
                title: "四字熟語道場",
                description: "四字熟語の意味と欠けた文字を覚える",
                questionKinds: [.yojijukugo],
                stageIDs: [],
                targetAccuracy: 0.90,
                iconName: "square.grid.2x2",
                colorHex: "#D8B45A"
            ),
            CategoryEntry(
                id: "synonym_antonym",
                title: "類義語・対義語道場",
                description: "意味が近い・反対の語を覚える",
                questionKinds: [.synonym, .antonym],
                stageIDs: [],
                targetAccuracy: 0.90,
                iconName: "arrow.left.arrow.right",
                colorHex: "#D8B45A"
            ),
            CategoryEntry(
                id: "proverb",
                title: "故事・ことわざ道場",
                description: "故事成語・ことわざの意味と用法",
                questionKinds: [.proverb],
                stageIDs: [],
                targetAccuracy: 0.90,
                iconName: "quote.bubble",
                colorHex: "#D8B45A"
            ),
            CategoryEntry(
                id: "passage",
                title: "文章題道場",
                description: "文章中の読みや語彙・文脈を問う",
                questionKinds: [.passageReading, .passageVocabulary],
                stageIDs: [],
                targetAccuracy: 0.90,
                iconName: "doc.text.below.ecg",
                colorHex: "#D8B45A"
            ),
        ]
    }
}
