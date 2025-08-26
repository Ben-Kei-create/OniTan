
import Foundation
import SwiftUI

class AppState: ObservableObject {
    // MARK: - Published Properties
    @Published var progressStore = ProgressStore.shared

    @Published var showReviewCompletion: Bool = false {
        didSet {
            if showReviewCompletion {
                // Auto-hide after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    self.showReviewCompletion = false
                }
            }
        }
    }

    // Note: These alert properties are only used in SettingsView and could be moved there.
    // For now, we keep them here as part of the global state.
    @Published var showingResetAlert: Bool = false
    @Published var showResetConfirmation: Bool = false
    @Published var showingCannotResetAlert: Bool = false

    // MARK: - Initialization
    init() {}

    // MARK: - Convenience Accessors
    var clearedStages: Set<Int> {
        progressStore.clearedStages
    }

    var incorrectQuestions: Set<String> {
        progressStore.incorrectQuestions
    }

    var bookmarkedQuestions: Set<String> {
        progressStore.bookmarkedQuestions
    }

    // MARK: - Public Methods
    func addIncorrectQuestion(_ kanji: String) {
        progressStore.addIncorrectQuestion(kanji)
    }

    func removeIncorrectQuestion(_ kanji: String) {
        progressStore.removeIncorrectQuestion(kanji)
    }

    func addBookmarkedQuestion(_ kanji: String) {
        progressStore.addBookmarkedQuestion(kanji)
    }

    func removeBookmarkedQuestion(_ kanji: String) {
        progressStore.removeBookmarkedQuestion(kanji)
    }

    func isBookmarked(_ kanji: String) -> Bool {
        progressStore.isBookmarked(kanji)
    }

    func resetProgress() {
        print("DEBUG: AppState.resetProgress() called")
        progressStore.reset()
        // Reset alert states
        self.showingResetAlert = false
        self.showResetConfirmation = false
        self.showingCannotResetAlert = false
    }
}
