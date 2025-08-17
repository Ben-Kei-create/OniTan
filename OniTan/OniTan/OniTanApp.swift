import SwiftUI

@main
struct OniTanApp: App {
    @AppStorage("colorScheme") private var colorScheme: String = "system"
    @StateObject var appState = AppState() // Create an instance of AppState

    init() {
        // Force clearedStages to be empty at app launch
        appState.clearedStages = []
        // Also clear UserDefaults for clearedStages and unlockedStage just in case
        UserDefaults.standard.removeObject(forKey: "clearedStages")
        UserDefaults.standard.removeObject(forKey: "unlockedStage")
        UserDefaults.standard.synchronize()
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(appState) // Inject appState into the environment
                .preferredColorScheme(colorScheme == "dark" ? .dark : (colorScheme == "light" ? .light : nil))
        }
    }
}