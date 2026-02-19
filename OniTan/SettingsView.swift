import SwiftUI

struct SettingsView: View {
    @AppStorage("colorScheme") private var colorScheme: String = "system"
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var statsRepo: StudyStatsRepository

    @State private var showingResetAlert = false
    @State private var showResetConfirmation = false
    @State private var showingCannotResetAlert = false

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

            Section(header: Text("データ管理")) {
                Button(action: {
                    if appState.clearedStages.isEmpty {
                        showingCannotResetAlert = true
                    } else {
                        showingResetAlert = true
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
            }
        }
        .navigationTitle("設定")
        .alert("確認", isPresented: $showingResetAlert) {
            Button("初期化", role: .destructive) {
                appState.reset()
                statsRepo.reset()
                showResetConfirmation = true
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("本当に進行状況を初期化しますか？\nすべてのクリア情報が失われます。")
        }
        .alert("完了", isPresented: $showResetConfirmation) {
            Button("OK") {}
        } message: {
            Text("進行状況が初期化されました。")
        }
        .alert("初期化できません", isPresented: $showingCannotResetAlert) {
            Button("OK") {}
        } message: {
            Text("ステージをクリアしていないため、初期化できません。")
        }
    }
}
