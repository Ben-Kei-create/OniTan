import SwiftUI

private struct KanjiCatalogEntry: Identifiable {
    let question: Question
    let stageNumber: Int

    var id: String { question.kanji }
}

struct KanjiCatalogView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var favoriteRepo: FavoriteKanjiRepository

    @State private var selectedEntry: KanjiCatalogEntry?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)

    private var favoriteEntryCount: Int {
        entries.filter { favoriteRepo.isFavorite($0.question.kanji) }.count
    }

    private var entries: [KanjiCatalogEntry] {
        var seen = Set<String>()
        var result: [KanjiCatalogEntry] = []

        for stage in quizData.stages.sorted(by: { $0.stage < $1.stage }) {
            for question in stage.questions where seen.insert(question.kanji).inserted {
                result.append(KanjiCatalogEntry(question: question, stageNumber: stage.stage))
            }
        }

        let favorites = result.filter { favoriteRepo.isFavorite($0.question.kanji) }
        let others = result.filter { !favoriteRepo.isFavorite($0.question.kanji) }
        return favorites + others
    }

    var body: some View {
        ZStack {
            OniTanTheme.backgroundGradientFallback
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    summaryCard

                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(entries) { entry in
                            Button {
                                selectedEntry = entry
                            } label: {
                                KanjiCatalogCell(entry: entry)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(entry.question.kanji) の詳細")
                            .accessibilityHint("タップして読みと解説を見る")
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
        }
        .navigationTitle("漢字一覧")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(themeManager.preferredColorScheme == .dark ? .dark : .light, for: .navigationBar)
        .sheet(item: $selectedEntry) { entry in
            KanjiCatalogDetailView(entry: entry)
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("収録漢字 \(entries.count) 字")
                .font(.system(.title3, design: .rounded))
                .fontWeight(.black)
                .foregroundColor(OniTanTheme.textPrimary)

            if favoriteEntryCount > 0 {
                Text("お気に入り \(favoriteEntryCount) 字")
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(OniTanTheme.accentWeak)
            }

            Text("5列の一覧から漢字を選ぶと、読みと解説を確認できます。お気に入りはホームからまとめて学習できます。")
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(OniTanTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .oniCard()
    }
}

private struct KanjiCatalogCell: View {
    let entry: KanjiCatalogEntry

    @EnvironmentObject var favoriteRepo: FavoriteKanjiRepository

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 16)
                .fill(OniTanTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(OniTanTheme.cardBorder, lineWidth: 1)
                )

            if favoriteRepo.isFavorite(entry.question.kanji) {
                HStack {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.28))
                        .padding(7)
                        .background(Color.black.opacity(0.16))
                        .clipShape(Circle())
                    Spacer()
                }
                .padding(6)
            }

            Text("S\(entry.stageNumber)")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundColor(OniTanTheme.textTertiary)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.16))
                .clipShape(Capsule())
                .padding(6)

            Text(entry.question.kanji)
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundColor(OniTanTheme.textPrimary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .padding(.top, 4)
        }
        .frame(height: 68)
        .shadow(color: OniTanTheme.shadowCard.color.opacity(0.6), radius: 8, y: 4)
    }
}

private struct KanjiCatalogDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager

    let entry: KanjiCatalogEntry

    private var explanationLines: [String] {
        entry.question.displayExplanation
            .split(separator: "\n")
            .map(String.init)
            .filter { !$0.isEmpty }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                OniTanTheme.backgroundGradientFallback
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        heroCard
                        answerCard
                        explanationCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("漢字詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(themeManager.preferredColorScheme == .dark ? .dark : .light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var heroCard: some View {
        VStack(spacing: 14) {
            Text(entry.question.kanji)
                .font(.system(size: 96, weight: .black, design: .rounded))
                .foregroundColor(OniTanTheme.textPrimary)
                .minimumScaleFactor(0.4)
                .lineLimit(1)

            HStack(spacing: 8) {
                detailPill(title: "正解", value: entry.question.answer)
                detailPill(title: "収録", value: "Stage \(entry.stageNumber)")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .oniCard()
    }

    private var answerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            cardTitle("読み")

            Text(entry.question.answer)
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundColor(OniTanTheme.accentPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .oniCard()
    }

    private var explanationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            cardTitle("解説")

            ForEach(explanationLines, id: \.self) { line in
                Text(line)
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(OniTanTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .oniCard()
    }

    private func cardTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(.headline, design: .rounded))
            .fontWeight(.bold)
            .foregroundColor(OniTanTheme.textPrimary)
    }

    private func detailPill(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(OniTanTheme.textTertiary)
            Text(value)
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(OniTanTheme.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(OniTanTheme.cardBackgroundPressed)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
