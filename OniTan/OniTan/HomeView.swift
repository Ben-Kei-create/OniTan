import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState // Access AppState

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("鬼単")
                    .font(.system(size: 80, weight: .bold))
                    .padding(.bottom, 40)
                
                NavigationLink(destination: StageSelectView()) {
                    Text("スタート")
                        .font(.title)
                        .padding()
                        .frame(maxWidth: 200)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                NavigationLink(destination: SettingsView()) {
                    Text("設定")
                        .font(.title)
                        .padding()
                        .frame(maxWidth: 200)
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            // Removed print("HomeView: body appeared")
        }
        // Attach alerts to the NavigationView in HomeView
        .alert(isPresented: $appState.showingResetAlert) {
            Alert(
                title: Text("確認"),
                message: Text("本当に進行状況を初期化しますか？\nすべてのクリア情報が失われます。"),
                primaryButton: .destructive(Text("初期化")) {
                    // Reset action
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
                message: Text("ステージをクリアしていないため、初期化できません。"),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
