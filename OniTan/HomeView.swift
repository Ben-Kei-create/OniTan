import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
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

                NavigationLink(destination: StatsView()) {
                    Text("統計")
                        .font(.title)
                        .padding()
                        .frame(maxWidth: 200)
                        .background(Color.purple)
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
    }
}
