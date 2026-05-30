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
    @StateObject private var interstitialManager = AdInterstitialManager()
    @StateObject private var notificationManager = NotificationManager.shared

    @AppStorage("onboarding_v1_complete") private var onboardingComplete = false
    @State private var showOnboarding = false

    init() {
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
                .environmentObject(interstitialManager)
                .environmentObject(notificationManager)
                .preferredColorScheme(themeManager.preferredColorScheme)
                .fullScreenCover(isPresented: $showOnboarding) {
                    OnboardingView(isPresented: $showOnboarding)
                        .environmentObject(notificationManager)
                        .preferredColorScheme(.dark)
                }
                .task {
                    await adConsentManager.prepareIfNeeded()
                    await notificationManager.refresh()
                    notificationManager.ensureScheduledIfNeeded(
                        todayCompleted: streakRepo.todayCompleted
                    )
                    if !onboardingComplete {
                        onboardingComplete = true
                        showOnboarding = true
                    }
                }
                .onChange(of: streakRepo.todayCompleted) { completed in
                    if completed {
                        notificationManager.handleTodayCompleted()
                    }
                }
                .onChange(of: showOnboarding) { showing in
                    if !showing {
                        // Ensure reminder is scheduled after onboarding completes
                        notificationManager.ensureScheduledIfNeeded(
                            todayCompleted: streakRepo.todayCompleted
                        )
                    }
                }
        }
    }
}
