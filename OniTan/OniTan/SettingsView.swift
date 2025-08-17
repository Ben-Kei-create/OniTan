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
                .onChange(of: colorScheme) { oldValue, newValue in
                    print("SettingsView: colorScheme changed from \(oldValue) to \(newValue)")
                    UserDefaults.standard.synchronize() // Force write to UserDefaults
                }
            }
            
            Section {
                Button(action: {
                    print("SettingsView: '初期化' button tapped.")
                    if appState.clearedStages.isEmpty {
                        print("SettingsView: clearedStages is empty. Setting showingCannotResetAlert to true.")
                        appState.showingCannotResetAlert = true
                        print("SettingsView: showingCannotResetAlert is now \(appState.showingCannotResetAlert)")
                    } else {
                        print("SettingsView: clearedStages is NOT empty. Setting showingResetAlert to true.")
                        appState.showingResetAlert = true
                        print("SettingsView: showingResetAlert is now \(appState.showingResetAlert)")
                    }
                }) {
                    HStack {
                        Spacer()
                        Text("進行状況を初期化")
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.vertical, 10)
                    .background(Color.red)
                    .cornerRadius(10)
                }
                .listRowInsets(EdgeInsets())
                .buttonStyle(PlainButtonStyle())
            } header: {
                Text("データ管理")
                    .font(.headline)
                    .foregroundColor(.accentColor)
            }
        }
        .navigationTitle("設定")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            print("SettingsView: appState.clearedStages.isEmpty = \(appState.clearedStages.isEmpty)")
            print("SettingsView: appState.clearedStages = \(appState.clearedStages)")
        }
        .alert(isPresented: $appState.showingResetAlert) {
            Alert(
                title: Text("確認"),
                message: Text("本当に進行状況を初期化しますか？\nすべてのクリア情報が失われます。"),
                primaryButton: .destructive(Text("初期化")) {
                    print("SettingsView: '初期化' alert - Destructive button tapped.")
                    appState.resetUserDefaults() // Call the new reset method
                    appState.showResetConfirmation = true // Show confirmation message
                },
                secondaryButton: .cancel(Text("キャンセル"))
            )
        }
        .alert(isPresented: $appState.showResetConfirmation) {
            Alert(
                title: Text("完了"),
                message: Text("進行状況が初期化されました。"),
                dismissButton: .default(Text("OK"))
            )
        }
        .alert(isPresented: $appState.showingCannotResetAlert) {
            Alert(
                title: Text("初期化できません"),
                message: Text("ステージをクリアしていないため、初期化できません。ステージ1をクリアしてから初期化してください"), // Added more helpful message
                dismissButton: .default(Text("OK")) {
                    print("SettingsView: '初期化できません' alert - OK button tapped.")
                }
            )
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
}
