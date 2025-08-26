import Foundation
import Combine

class ProgressStore: ObservableObject {
    static let shared = ProgressStore()

    @Published public var clearedStages: Set<Int>
    @Published public var incorrectQuestions: Set<String>
    @Published public var bookmarkedQuestions: Set<String>

    private var cancellables = Set<AnyCancellable>()

    private init() {
        self.clearedStages = Self.loadClearedStages()
        self.incorrectQuestions = Self.loadIncorrectQuestions()
        self.bookmarkedQuestions = Self.loadBookmarkedQuestions()
        
        // 自動保存の設定
        setupAutoSave()
    }
    
    private func setupAutoSave() {
        // clearedStagesの変更を監視して自動保存
        $clearedStages
            .dropFirst() // 初期値をスキップ
            .sink { [weak self] stages in
                self?.saveClearedStages(stages)
                print("DEBUG: clearedStages auto-saved: \(stages)")
            }
            .store(in: &cancellables)
        
        // incorrectQuestionsの変更を監視して自動保存
        $incorrectQuestions
            .dropFirst()
            .sink { [weak self] questions in
                self?.saveIncorrectQuestions(questions)
            }
            .store(in: &cancellables)
        
        // bookmarkedQuestionsの変更を監視して自動保存
        $bookmarkedQuestions
            .dropFirst()
            .sink { [weak self] questions in
                self?.saveBookmarkedQuestions(questions)
            }
            .store(in: &cancellables)
    }

    // MARK: - Stage Management Methods
    func saveStageCleared(_ stage: Int) {
        print("DEBUG: saveStageCleared called with stage \(stage)")
        clearedStages.insert(stage)
        print("DEBUG: clearedStages after insert: \(clearedStages)")
        
        // 即座に保存を確実にする
        saveClearedStages(clearedStages)
        UserDefaults.standard.synchronize()
    }

    // MARK: - Question Management Methods
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
        print("DEBUG: ProgressStore.reset() called")
        
        // プロパティをクリアする（@Publishedなので自動的に保存される）
        clearedStages = []
        incorrectQuestions = []
        bookmarkedQuestions = []
        
        // 念のため明示的に保存
        saveClearedStages([])
        saveIncorrectQuestions([])
        saveBookmarkedQuestions([])
        
        UserDefaults.standard.synchronize()
        print("DEBUG: ProgressStore properties cleared")
    }

    // MARK: - Public Methods for immediate saving
    func saveAllDataImmediately() {
        saveClearedStages(clearedStages)
        saveIncorrectQuestions(incorrectQuestions)
        saveBookmarkedQuestions(bookmarkedQuestions)
        UserDefaults.standard.synchronize()
        print("DEBUG: All ProgressStore data saved immediately.")
    }

    // MARK: - Persistence (Private)
    private func saveClearedStages(_ stages: Set<Int>) {
        if let encoded = try? JSONEncoder().encode(stages) {
            UserDefaults.standard.set(encoded, forKey: "clearedStages")
            print("DEBUG: Saved clearedStages to UserDefaults: \(stages)")
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
            print("DEBUG: Loaded clearedStages from UserDefaults: \(decoded)")
            return decoded
        }
        print("DEBUG: No clearedStages found in UserDefaults. Returning empty set.")
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
