import SwiftUI

@main
struct OniTanApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var statsRepo = StudyStatsRepository()
    @StateObject private var streakRepo = StreakRepository()
    @StateObject private var xpRepo = GamificationRepository()
    @StateObject private var adConsentManager = AdConsentManager()
    @StateObject private var favoriteRepo = FavoriteKanjiRepository()
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var playFontManager = PlayFontManager.shared
    @StateObject private var donationManager = DonationManager()

    init() {
        // NavigationStack のナビゲーションバー背景を透明にしてグラデーション背景を全画面に表示する
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(appState)
                .environmentObject(statsRepo)
                .environmentObject(streakRepo)
                .environmentObject(xpRepo)
                .environmentObject(adConsentManager)
                .environmentObject(favoriteRepo)
                .environmentObject(themeManager)
                .environmentObject(playFontManager)
                .environmentObject(donationManager)
                .preferredColorScheme(themeManager.preferredColorScheme)
                .task {
                    await adConsentManager.prepareIfNeeded()
                }
        }
    }
}
