import SwiftUI

@main
struct OniTanApp: App {
    @AppStorage("colorScheme") private var colorScheme: String = "system"

    var body: some Scene {
        WindowGroup {
            MainView()
                .preferredColorScheme(colorScheme == "dark" ? .dark : (colorScheme == "light" ? .light : nil))
        }
    }
}
