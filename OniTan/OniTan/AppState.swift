import Foundation
import SwiftUI

class AppState: ObservableObject {
    @Published var clearedStages: Set<Int> {
        didSet {
            saveClearedStages() // Save whenever clearedStages changes
        }
    }
    
    @Published var showingResetAlert: Bool = false
    @Published var showResetConfirmation: Bool = false
    @Published var showingCannotResetAlert: Bool = false

    // Initialize from UserDefaults
    init() {
        if let data = UserDefaults.standard.data(forKey: "clearedStages"),
           let decoded = try? JSONDecoder().decode(Set<Int>.self, from: data) {
            self.clearedStages = decoded
        } else {
            self.clearedStages = []
        }
    }

    // Save clearedStages to UserDefaults
    private func saveClearedStages() {
        if let encoded = try? JSONEncoder().encode(clearedStages) {
            UserDefaults.standard.set(encoded, forKey: "clearedStages")
            UserDefaults.standard.synchronize() // Force immediate write
        } else {
            // No print here
        }
    }
    
    // New method to aggressively reset UserDefaults
    func resetUserDefaults() {
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
            UserDefaults.standard.synchronize() // Ensure immediate write
        }
        // After clearing UserDefaults, reset the in-memory state
        self.clearedStages = []
        // Also reset alert states
        self.showingResetAlert = false
        self.showResetConfirmation = false
        self.showingCannotResetAlert = false
        
        // Force UI update
        objectWillChange.send()
    }
}
