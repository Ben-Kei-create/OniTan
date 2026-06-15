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
    @StateObject private var appNavState = AppNavigationState()
    @StateObject private var masteryRepo = MasteryRepository()
    @StateObject private var examResultRepo = ExamResultRepository()
    @StateObject private var reviewPromptManager = ReviewPromptManager()

    @AppStorage("onboarding_v1_complete") private var onboardingComplete = false
    @State private var showOnboarding = false
    @State private var showSplash = true
    @State private var showDailySummary = false
    @AppStorage("dailySummary_lastShownDayKey") private var dailySummaryLastShownDayKey = ""

    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
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
                    .environmentObject(appNavState)
                    .environmentObject(masteryRepo)
                    .environmentObject(examResultRepo)
                    .environmentObject(reviewPromptManager)
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
                        notificationManager.scheduleWeeklySummary(weakCount: statsRepo.weakPointCount)
                        if !onboardingComplete {
                            onboardingComplete = true
                            showOnboarding = true
                        }
                    }
                    .onChange(of: streakRepo.todayCompleted) { completed in
                        if completed {
                            notificationManager.handleTodayCompleted()
                            notificationManager.scheduleWeeklySummary(weakCount: statsRepo.weakPointCount)
                            let todayKey = StreakRepository.dayKey(for: Date())
                            if !showOnboarding && dailySummaryLastShownDayKey != todayKey {
                                dailySummaryLastShownDayKey = todayKey
                                showDailySummary = true
                            }
                        }
                    }
                    .onChange(of: showDailySummary) { presented in
                        appState.isDailySummaryPresented = presented
                    }
                    .fullScreenCover(isPresented: $showDailySummary) {
                        DailySummaryView(
                            streak: streakRepo.currentStreak,
                            isNewLongestStreak: streakRepo.lastCompletionWasNewRecord,
                            answeredToday: streakRepo.todayAnswerCount,
                            xpEarnedToday: xpRepo.todayXP,
                            weakKanjiCount: statsRepo.weakPointCount,
                            onDismiss: { showDailySummary = false }
                        )
                    }
                    .onChange(of: showOnboarding) { showing in
                        if !showing {
                            notificationManager.ensureScheduledIfNeeded(
                                todayCompleted: streakRepo.todayCompleted
                            )
                        }
                    }

                if showSplash {
                    SplashView {
                        withAnimation(.easeOut(duration: 0.35)) {
                            showSplash = false
                        }
                    }
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
        }
    }
}
