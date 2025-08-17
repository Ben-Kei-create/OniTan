import SwiftUI

struct SettingsView: View {
    @AppStorage("colorScheme") private var colorScheme: String = "system"
    @AppStorage("soundEnabled") private var soundEnabled: Bool = true
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    @AppStorage("shuffleQuestionsEnabled") private var shuffleQuestionsEnabled: Bool = false
    @AppStorage("kanjiFont") private var kanjiFont: String = "system"
    @EnvironmentObject var appState: AppState // Access AppState
    
    private enum ActiveAlert: Identifiable {
        case reset, cannotReset

        var id: Int {
            hashValue
        }
    }
    
    @State private var activeAlert: ActiveAlert?

    var body: some View {
        Form {
            Section(header: Text("表示設定")
                .font(.headline)
                .foregroundColor(.accentColor)
            ) {
                Picker("モード", selection: $colorScheme) {
                    Text("システム設定").tag("system")
                    Text("ライト").tag("light")
                    Text("ダーク").tag("dark")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.vertical, 5)
                .onChange(of: colorScheme) { oldValue, newValue in
                    UserDefaults.standard.synchronize()
                }
            }
            
            Section(header: Text("サウンドと触覚")
                .font(.headline)
                .foregroundColor(.accentColor))
            {
                Toggle("効果音", isOn: $soundEnabled)
                Toggle("バイブレーション", isOn: $hapticsEnabled)
            }
            
            Section(header: Text("クイズ設定")
                .font(.headline)
                .foregroundColor(.accentColor)
            ) {
                Toggle("問題をシャッフル", isOn: $shuffleQuestionsEnabled)
                
                Picker("漢字フォント", selection: $kanjiFont) {
                    Text("システム").tag("system")
                    Text("ヒラギノ角ゴ").tag("hiragino")
                    Text("游ゴシック").tag("yuGothic")
                    Text("明朝体").tag("mincho")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.vertical, 5)
            }
            
            Section {
                Button(action: {
                    if appState.clearedStages.isEmpty {
                        activeAlert = .cannotReset
                    } else {
                        activeAlert = .reset
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
        .alert(item: $activeAlert) { alertType in
            switch alertType {
            case .reset:
                return Alert(
                    title: Text("確認"),
                    message: Text("本当に進行状況を初期化しますか？\nすべてのクリア情報が失われます。"),
                    primaryButton: .destructive(Text("初期化")) {
                        appState.resetUserDefaults()
                    },
                    secondaryButton: .cancel()
                )
            case .cannotReset:
                return Alert(
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
}