
import Foundation
import Combine

class ProgressStore: ObservableObject {
    @Published var clearedStages: Set<Int> {
        didSet {
            clearedStagesSubject.send(clearedStages)
        }
    }

    @Published var incorrectQuestions: Set<String> {
        didSet {
            incorrectQuestionsSubject.send(incorrectQuestions)
        }
    }

    @Published var bookmarkedQuestions: Set<String> {
        didSet {
            bookmarkedQuestionsSubject.send(bookmarkedQuestions)
        }
    }

    private var cancellables = Set<AnyCancellable>()
    private let clearedStagesSubject = PassthroughSubject<Set<Int>, Never>()
    private let incorrectQuestionsSubject = PassthroughSubject<Set<String>, Never>()
    private let bookmarkedQuestionsSubject = PassthroughSubject<Set<String>, Never>()

    init() {
        self.clearedStages = Self.loadClearedStages()
        self.incorrectQuestions = Self.loadIncorrectQuestions()
        self.bookmarkedQuestions = Self.loadBookmarkedQuestions()

        clearedStagesSubject
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] stages in
                self?.saveClearedStages(stages)
            }
            .store(in: &cancellables)

        incorrectQuestionsSubject
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] questions in
                self?.saveIncorrectQuestions(questions)
            }
            .store(in: &cancellables)

        bookmarkedQuestionsSubject
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] questions in
                self?.saveBookmarkedQuestions(questions)
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods
    func addIncorrectQuestion(_ kanji: String) {
        incorrectQuestions.insert(kanji)
    }

    func removeIncorrectQuestion(_ kanji: String) {
        incorrectQuestions.remove(kanji)
    }

    func addBookmarkedQuestion(_ kanji: String) {
        bookmarkedQuestions.insert(kanji)
    }

    func removeBookmarkedQuestion(_ kanji: String) {
        bookmarkedQuestions.remove(kanji)
    }

    func isBookmarked(_ kanji: String) -> Bool {
        return bookmarkedQuestions.contains(kanji)
    }
    
    func reset() {
        clearedStages = []
        incorrectQuestions = []
        bookmarkedQuestions = []
        UserDefaults.standard.removeObject(forKey: "clearedStages")
        UserDefaults.standard.removeObject(forKey: "incorrectQuestions")
        UserDefaults.standard.removeObject(forKey: "bookmarkedQuestions")
    }

    // MARK: - Persistence (Private)
    private func saveClearedStages(_ stages: Set<Int>) {
        if let encoded = try? JSONEncoder().encode(stages) {
            UserDefaults.standard.set(encoded, forKey: "clearedStages")
        }
    }

    private func saveIncorrectQuestions(_ questions: Set<String>) {
        if let encoded = try? JSONEncoder().encode(questions) {
            UserDefaults.standard.set(encoded, forKey: "incorrectQuestions")
        }
    }

    private func saveBookmarkedQuestions(_ questions: Set<String>) {
        if let encoded = try? JSONEncoder().encode(questions) {
            UserDefaults.standard.set(encoded, forKey: "bookmarkedQuestions")
        }
    }
    
    private static func loadClearedStages() -> Set<Int> {
        if let data = UserDefaults.standard.data(forKey: "clearedStages"),
           let decoded = try? JSONDecoder().decode(Set<Int>.self, from: data) {
            return decoded
        }
        return []
    }

    private static func loadIncorrectQuestions() -> Set<String> {
        if let data = UserDefaults.standard.data(forKey: "incorrectQuestions"),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            return decoded
        }
        return []
    }

    private static func loadBookmarkedQuestions() -> Set<String> {
        if let data = UserDefaults.standard.data(forKey: "bookmarkedQuestions"),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            return decoded
        }
        return []
    }
}
