import SwiftUI

struct SettingsView: View {
    @AppStorage("colorScheme") private var colorScheme: String = "system"
    @EnvironmentObject var appState: AppState

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: OniTheme.Spacing.sm) {
                    Text("テーマ")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.secondary)

                    Picker("モード", selection: $colorScheme) {
                        Text("システム").tag("system")
                        Text("ライト").tag("light")
                        Text("ダーク").tag("dark")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .padding(.vertical, OniTheme.Spacing.xs)
            } header: {
                Label("表示設定", systemImage: "paintbrush.fill")
                    .font(.headline)
                    .foregroundColor(.accentColor)
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
                        HStack(spacing: OniTheme.Spacing.sm) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("進行状況を初期化")
                        }
                        .font(.body.weight(.bold))
                        .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.vertical, OniTheme.Spacing.sm + 2)
                    .background(OniTheme.Colors.danger)
                    .cornerRadius(OniTheme.Radius.md)
                }
                .listRowInsets(EdgeInsets())
                .buttonStyle(PlainButtonStyle())
            } header: {
                Label("データ管理", systemImage: "folder.fill")
                    .font(.headline)
                    .foregroundColor(.accentColor)
            }

            Section {
                HStack {
                    Text("バージョン")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
            } header: {
                Label("アプリ情報", systemImage: "info.circle.fill")
                    .font(.headline)
                    .foregroundColor(.accentColor)
            }
        }
        .navigationTitle("設定")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $appState.showingResetAlert) {
            Alert(
                title: Text("確認"),
                message: Text("本当に進行状況を初期化しますか？\nすべてのクリア情報が失われます。"),
                primaryButton: .destructive(Text("初期化")) {
                    appState.resetUserDefaults()
                    appState.showResetConfirmation = true
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
                message: Text("ステージをクリアしていないため、初期化できません。ステージ1をクリアしてから初期化してください"),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView()
        }
        .environmentObject(AppState())
    }
}
