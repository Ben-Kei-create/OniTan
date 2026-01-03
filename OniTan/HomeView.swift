import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState // Access AppState

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
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
