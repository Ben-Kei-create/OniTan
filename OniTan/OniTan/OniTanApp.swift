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
        print("OniTanApp: appColorScheme computed. colorSchemeString: \(colorSchemeString)")
        switch colorSchemeString {
        case "light":
            print("OniTanApp: Applying light color scheme.")
            return .light
        case "dark":
            print("OniTanApp: Applying dark color scheme.")
            return .dark
        default:
            print("OniTanApp: Applying system color scheme.")
            return nil // Use system setting
        }
    }
}