import SwiftUI

struct SettingsView: View {
    @AppStorage("colorScheme") private var colorScheme: String = "system"
    @State private var showingResetAlert = false // State for the reset confirmation dialog
    @State private var showResetConfirmation = false // State for the reset completion message
    @State private var showingCannotResetAlert = false // State for "cannot reset" message
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
                    print("SettingsView: Reset button tapped. clearedStages.isEmpty: \(clearedStages.isEmpty)")
                    if clearedStages.isEmpty {
                        showingCannotResetAlert = true
                    } else {
                        showingResetAlert = true
                    }
                }
                .foregroundColor(.red)
            } header: {
                Text("データ管理")
            }
        }
        .navigationTitle("設定")
        .alert(isPresented: $showingResetAlert) {
            // Fixed: Added 'return' before Alert
            Alert(
                title: Text("確認"),
                message: Text("本当に進行状況を初期化しますか？\nすべてのクリア情報が失われます。"),
                primaryButton: .destructive(Text("初期化")) {
                    // Reset action
                    clearedStages = [] // Clear all saved stages
                    UserDefaults.standard.removeObject(forKey: "clearedStages") // Explicitly remove the key
                    UserDefaults.standard.synchronize() // Force immediate write
                    showResetConfirmation = true // Show confirmation message
                },
                secondaryButton: .cancel(Text("キャンセル"))
            )
        }
        .alert(isPresented: $showResetConfirmation) { // New alert for confirmation
            Alert(
                title: Text("完了"),
                message: Text("進行状況が初期化されました。"),
                dismissButton: .default(Text("OK"))
            )
        }
        .alert(isPresented: $showingCannotResetAlert) { // New alert for "cannot reset"
            Alert(
                title: Text("初期化できません"),
                message: Text("ステージをクリアしていないため、初期化できません。"),
                dismissButton: .default(Text("OK"))
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
