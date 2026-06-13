import SwiftUI

private struct KanjiCatalogEntry: Identifiable {
    let question: Question

    var id: String { question.kanji }
}

struct KanjiCatalogView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var favoriteRepo: FavoriteKanjiRepository
    @State private var selectedEntry: KanjiCatalogEntry?
    @State private var searchText = ""
    @State private var favoritesOnly = false

    private let columns = [GridItem(.adaptive(minimum: 58), spacing: 10)]

    private var favoriteEntryCount: Int {
        baseEntries.filter { favoriteRepo.isFavorite($0.question.kanji) }.count
    }

    private var baseEntries: [KanjiCatalogEntry] {
        var seen = Set<String>()
        var result: [KanjiCatalogEntry] = []

        for question in questions where seen.insert(question.kanji).inserted {
            result.append(KanjiCatalogEntry(question: question))
        }

        return result
    }

    private var entries: [KanjiCatalogEntry] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let filtered = baseEntries.filter { entry in
            let question = entry.question
            let matchesFavorite = !favoritesOnly || favoriteRepo.isFavorite(question.kanji)
            let matchesQuery = query.isEmpty
                || question.kanji.localizedStandardContains(query)
                || question.answer.localizedStandardContains(query)
                || question.displayPrompt.localizedStandardContains(query)
                || question.displayExplanation.localizedStandardContains(query)
            return matchesFavorite && matchesQuery
        }

        let result = filtered
        let favorites = result.filter { favoriteRepo.isFavorite($0.question.kanji) }
        let others = result.filter { !favoriteRepo.isFavorite($0.question.kanji) }
        return favorites + others
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                OniTanTheme.backgroundGradientFallback
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        summaryCard
                        catalogControls

                        if entries.isEmpty {
                            emptyResultCard
                        } else {
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
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                }
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
            Text("収録漢字 \(baseEntries.count) 字")
                .font(.system(.title3, design: .rounded))
                .fontWeight(.black)
                .foregroundColor(OniTanTheme.textPrimary)

            if favoriteEntryCount > 0 {
                Text("お気に入り \(favoriteEntryCount) 字")
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(OniTanTheme.accentWeak)
            }

            Text("一覧から漢字を選ぶと、読みと解説を確認できます。お気に入りはホームからまとめて学習できます。")
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(OniTanTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .oniCard()
    }

    private var catalogControls: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(OniTanTheme.accentWeak)
                    .frame(width: 34, height: 34)
                    .background(
                        RoundedRectangle(cornerRadius: 9)
                            .fill(OniTanTheme.cardBackgroundPressed)
                    )
                    .accessibilityHidden(true)

                TextField("漢字・読み・解説で検索", text: $searchText)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(OniTanTheme.textPrimary)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(OniTanTheme.textTertiary)
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("検索語を消去")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(OniTanTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(OniTanTheme.cardBorder, lineWidth: 1)
                    )
            )

            Button {
                favoritesOnly.toggle()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: favoritesOnly ? "star.fill" : "star")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(favoritesOnly ? OniTanTheme.cardBackground : OniTanTheme.accentWeak)
                    Text(favoritesOnly ? "お気に入りのみ表示中" : "お気に入りのみ")
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.bold)
                    Spacer()
                    Text("\(favoriteEntryCount) 字")
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.semibold)
                }
                .foregroundColor(favoritesOnly ? OniTanTheme.cardBackground : OniTanTheme.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(favoritesOnly ? OniTanTheme.accentWeak : OniTanTheme.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(OniTanTheme.cardBorder, lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(favoritesOnly ? "お気に入りのみ表示中" : "お気に入りのみ表示")
        }
    }

    private var emptyResultCard: some View {
        VStack(spacing: 12) {
            if favoritesOnly && searchText.isEmpty {
                Text("お気に入りに登録された漢字がありません")
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(OniTanTheme.textSecondary)
                Text("漢字をタップして詳細を開き、星マークでお気に入りに追加できます")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(OniTanTheme.textTertiary)
                    .multilineTextAlignment(.center)
            } else {
                Text("該当する漢字がありません")
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(OniTanTheme.textSecondary)
                Text("検索語を変えるか、条件をクリアしてみてください")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(OniTanTheme.textTertiary)
            }

            Button {
                searchText = ""
                favoritesOnly = false
            } label: {
                Text("検索条件をクリア")
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(OniTanTheme.accentWeak)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(OniTanTheme.cardBackgroundPressed)
                            .overlay(Capsule().stroke(OniTanTheme.cardBorder, lineWidth: 1))
                    )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, minHeight: 72)
        .padding(.vertical, 8)
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
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(OniTanTheme.textSecondary)
                            .frame(width: 34, height: 34)
                            .background(Color.black.opacity(0.16))
                            .overlay(Circle().stroke(OniTanTheme.cardBorder, lineWidth: 1))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("閉じる")
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
