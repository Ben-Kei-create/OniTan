import SwiftUI

@main
struct OniTanApp: App {
    @StateObject private var appState = AppState() // Create an instance of AppState

    @AppStorage("colorScheme") private var colorSchemeString: String = "system"

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(appState) // Inject appState into the environment
                .preferredColorScheme(appColorScheme) // Apply reactive color scheme
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