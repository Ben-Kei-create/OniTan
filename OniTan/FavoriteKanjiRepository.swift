import Foundation

final class FavoriteKanjiRepository: ObservableObject {
    @Published private(set) var favoriteKanji: Set<String> = []

    private let store: PersistenceStore
    private let key = "favoriteKanji_v1"

    convenience init() {
        self.init(
            store: UserDefaults.standard,
            availableKanji: Set(allQuestionsWithCatalog.flatMap(\.catalogKanjiCharacters))
        )
    }

    init(store: PersistenceStore, availableKanji: Set<String>) {
        self.store = store
        load()
        syncAvailableKanji(availableKanji)
    }

    var count: Int { favoriteKanji.count }

    func isFavorite(_ kanji: String) -> Bool {
        kanji.isSingleKanjiCharacter && favoriteKanji.contains(kanji)
    }

    func toggle(_ kanji: String) {
        guard kanji.isSingleKanjiCharacter else { return }
        if favoriteKanji.contains(kanji) {
            favoriteKanji.remove(kanji)
        } else {
            favoriteKanji.insert(kanji)
        }
        save()
    }

    func syncAvailableKanji(_ availableKanji: Set<String>) {
        let singleAvailableKanji = availableKanji.filter(\.isSingleKanjiCharacter)
        let filtered = favoriteKanji.filter { kanji in
            kanji.isSingleKanjiCharacter && singleAvailableKanji.contains(kanji)
        }
        guard filtered != favoriteKanji else { return }
        favoriteKanji = filtered
        save()
    }

    private func load() {
        guard let data = store.data(forKey: key),
              let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) else { return }
        favoriteKanji = decoded
    }

    private func save() {
        guard let encoded = try? JSONEncoder().encode(favoriteKanji) else { return }
        store.set(encoded, forKey: key)
    }
}
