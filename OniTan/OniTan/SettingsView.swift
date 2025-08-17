import SwiftUI

struct SettingsView: View {
    @AppStorage("colorScheme") private var colorScheme: String = "system"
    @State private var showingResetAlert = false // State for the reset confirmation dialog
    @AppStorageCodable(wrappedValue: [], "clearedStages") var clearedStages: Set<Int> // Access cleared stages

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
                    showingResetAlert = true
                }
                .foregroundColor(.red)
            } header: {
                Text("データ管理")
            }
        }
        .navigationTitle("設定")
        .alert(isPresented: $showingResetAlert) {
            Alert(
                title: Text("確認"),
                message: Text("本当に進行状況を初期化しますか？\nすべてのクリア情報が失われます。"),
                primaryButton: .destructive(Text("初期化")) {
                    // Reset action
                    clearedStages = [] // Clear all saved stages
                },
                secondaryButton: .cancel(Text("キャンセル")
            )
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { // Wrap in NavigationView for preview
            SettingsView()
        }
    }
}
