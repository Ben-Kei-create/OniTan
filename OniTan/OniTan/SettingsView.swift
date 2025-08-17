import SwiftUI

struct SettingsView: View {
    @AppStorage("colorScheme") private var colorScheme: String = "system"
    @EnvironmentObject var appState: AppState // Access AppState

    var body: some View {
        Form {
            Section(header: Text("表示設定")) {
                Picker("モード", selection: $colorScheme) {
                    Text("システム設定").tag("system")
                    Text("ライト").tag("light")
                    Text("ダーク").tag("dark")
                }
                .pickerStyle(SegmentedPickerStyle())
            }

            Section {
                Button("進行状況を初期化") {
                    if appState.clearedStages.isEmpty {
                        appState.showingCannotResetAlert = true
                    } else {
                        appState.showingResetAlert = true
                    }
                }
                .foregroundColor(.red)
            } header: {
                Text("データ管理")
            }
        }
        .navigationTitle("設定")
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { // Wrap in NavigationView for preview
            SettingsView()
        }
    }
}