import SwiftUI

struct SettingsView: View {
    @AppStorage("colorScheme") private var colorScheme: String = "system"
    @EnvironmentObject var appState: AppState // Access AppState

    var body: some View {
        Form {
            Section(header: Text("表示設定")
                        .font(.headline) // Slightly larger header font
                        .foregroundColor(.accentColor) // Accent color for header
            ) {
                Picker("モード", selection: $colorScheme) {
                    Text("システム設定").tag("system")
                    Text("ライト").tag("light")
                    Text("ダーク").tag("dark")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.vertical, 5) // Add vertical padding to picker
                .onChange(of: colorScheme) { newValue in
                    print("SettingsView: colorScheme changed to \(newValue)")
                    UserDefaults.standard.synchronize() // Force write to UserDefaults
                }
            }

            Section {
                Button(action: {
                    if appState.clearedStages.isEmpty {
                        appState.showingCannotResetAlert = true
                    } else {
                        appState.showingResetAlert = true
                    }
                }) {
                    HStack {
                        Spacer()
                        Text("進行状況を初期化")
                            .font(.body) // Standard body font
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.vertical, 10) // More vertical padding for button
                    .background(Color.red) // Red background for destructive action
                    .cornerRadius(10) // Rounded corners
                }
                .listRowInsets(EdgeInsets()) // Remove default list row insets
                .buttonStyle(PlainButtonStyle()) // Remove default button styling
            } header: {
                Text("データ管理")
                    .font(.headline) // Slightly larger header font
                    .foregroundColor(.accentColor) // Accent color for header
            }
        }
        .navigationTitle("設定")
        .navigationBarTitleDisplayMode(.inline) // Keep title inline for settings
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { // Wrap in NavigationView for preview
            SettingsView()
        }
        .environmentObject(AppState()) // Provide AppState for preview
    }
}
