import SwiftUI

import GoogleMobileAds

@main
struct OniTanApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var statsRepo = StudyStatsRepository()
    @StateObject private var streakRepo = StreakRepository()
    @StateObject private var xpRepo = GamificationRepository()
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var donationManager = DonationManager()

    init() {
        GADMobileAds.sharedInstance().start()
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
