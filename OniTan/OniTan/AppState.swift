import Foundation
import SwiftUI

class AppState: ObservableObject {
    // MARK: - Published Properties
    @Published var clearedStages: Set<Int> {
        didSet {
            saveClearedStages()
        }
    }

    @Published var incorrectQuestions: Set<String> {
        didSet {
            saveIncorrectQuestions()
        }
    }

    // Note: These alert properties are only used in SettingsView and could be moved there.
    // For now, we keep them here as part of the global state.
    @Published var showingResetAlert: Bool = false
    @Published var showResetConfirmation: Bool = false
    @Published var showingCannotResetAlert: Bool = false

    // MARK: - Initialization
    init() {
        // Load cleared stages
        if let data = UserDefaults.standard.data(forKey: "clearedStages"),
           let decoded = try? JSONDecoder().decode(Set<Int>.self, from: data) {
            self.clearedStages = decoded
        } else {
            self.clearedStages = []
        }

        // Load incorrect questions
        if let data = UserDefaults.standard.data(forKey: "incorrectQuestions"),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            self.incorrectQuestions = decoded
        } else {
            self.incorrectQuestions = []
        }
    }

    // MARK: - Public Methods for Incorrect Questions
    func addIncorrectQuestion(_ kanji: String) {
        incorrectQuestions.insert(kanji)
    }

    func removeIncorrectQuestion(_ kanji: String) {
        incorrectQuestions.remove(kanji)
    }

    // MARK: - Persistence
    private func saveClearedStages() {
        if let encoded = try? JSONEncoder().encode(clearedStages) {
            UserDefaults.standard.set(encoded, forKey: "clearedStages")
        }
    }

    private func saveIncorrectQuestions() {
        if let encoded = try? JSONEncoder().encode(incorrectQuestions) {
            UserDefaults.standard.set(encoded, forKey: "incorrectQuestions")
        }
    }
    
    // MARK: - Reset
    func resetUserDefaults() {
        // Clear persistent data
        UserDefaults.standard.removeObject(forKey: "clearedStages")
        UserDefaults.standard.removeObject(forKey: "incorrectQuestions")
        
        // Reset in-memory state
        self.clearedStages = []
        self.incorrectQuestions = []
        
        // Reset alert states
        self.showingResetAlert = false
        self.showResetConfirmation = false
        self.showingCannotResetAlert = false
        
        // Force UI update
        objectWillChange.send()
    }
}