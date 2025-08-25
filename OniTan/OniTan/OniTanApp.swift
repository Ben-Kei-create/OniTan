
import SwiftUI

@main
struct OniTanApp: App {
    // AppDelegateを登録する
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var appState = AppState()
    @StateObject private var progressStore = ProgressStore()
    private let quizData = QuizDataLoader().load()

    @AppStorage("colorScheme") private var colorSchemeString: String = "system"

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(appState)
                .environmentObject(progressStore)
                .environment(\.quizData, quizData)
                .preferredColorScheme(appColorScheme)
        }
    }
    
    // Convert colorSchemeString to ColorScheme?
    private var appColorScheme: ColorScheme? {
        switch colorSchemeString {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil // Use system setting
        }
    }
}

private struct QuizDataKey: EnvironmentKey {
    static let defaultValue: QuizData = QuizDataLoader().load()
}

extension EnvironmentValues {
    var quizData: QuizData {
        get { self[QuizDataKey.self] }
        set { self[QuizDataKey.self] = newValue }
    }
}
