import Foundation

final class AppState: ObservableObject {
    @Published var clearedStages: Set<Int> {
        didSet { saveClearedStages() }
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: "clearedStages"),
           let decoded = try? JSONDecoder().decode(Set<Int>.self, from: data) {
            self.clearedStages = decoded
        } else {
            self.clearedStages = []
        }
    }

    func markStageCleared(_ stage: Int) {
        clearedStages.insert(stage)
    }

    func isCleared(_ stage: Int) -> Bool {
        clearedStages.contains(stage)
    }

    func isUnlocked(_ stage: Int) -> Bool {
        stage == 1 || clearedStages.contains(stage - 1)
    }

    func reset() {
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        clearedStages = []
    }

    private func saveClearedStages() {
        if let encoded = try? JSONEncoder().encode(clearedStages) {
            UserDefaults.standard.set(encoded, forKey: "clearedStages")
        }
    }
}
