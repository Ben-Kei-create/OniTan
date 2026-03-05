import SwiftUI

@main
struct OniTanApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var statsRepo = StudyStatsRepository()
    @StateObject private var streakRepo = StreakRepository()
    @StateObject private var xpRepo = GamificationRepository()
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var donationManager = DonationManager()

    init() {
        // Google Mobile Ads SDK は iOS 14+ で自動初期化される
        // 明示的な初期化は不要
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(appState)
                .environmentObject(statsRepo)
                .environmentObject(streakRepo)
                .environmentObject(xpRepo)
                .environmentObject(themeManager)
                .environmentObject(donationManager)
                .preferredColorScheme(themeManager.preferredColorScheme)
        }
    }
}
