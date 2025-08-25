import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // アプリケーション起動時の追加設定（今回は不要）
        return true
    }

    // このメソッドでサポートする画面の向きを指定する
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        // .portrait を返すことで、縦画面のみをサポートするようにする
        return .portrait
    }
}
