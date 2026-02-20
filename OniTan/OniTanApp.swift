import SwiftUI

@main
struct OniTanApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var statsRepo = StudyStatsRepository()
    @StateObject private var streakRepo = StreakRepository()
    @StateObject private var xpRepo = GamificationRepository()
    @AppStorage("colorScheme") private var colorSchemeString: String = "system"

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(appState)
                .environmentObject(statsRepo)
                .environmentObject(streakRepo)
                .environmentObject(xpRepo)
                .preferredColorScheme(appColorScheme)
        }
    }

    private var appColorScheme: ColorScheme? {
        switch colorSchemeString {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
}
