import SwiftUI

// MARK: - AdBannerView
//
// 【実際の広告を表示するには】
// 1. Xcode → File → Add Package Dependencies
//    URL: https://github.com/googleads/swift-package-manager-google-mobile-ads
// 2. AdMob コンソール (https://admob.google.com) でアプリを登録し、
//    App ID と Ad Unit ID を取得
// 3. Info.plist に追加:
//    Key: GADApplicationIdentifier
//    Value: ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX  (あなたのApp ID)
// 4. OniTanApp.swift の GADMobileAds.sharedInstance().start() を有効化
// 5. 下記 adUnitID を本番の Ad Unit ID に変更
//
// SDK が未インストールの場合はプレースホルダーが表示されます。

#if canImport(GoogleMobileAds)
import GoogleMobileAds

struct AdBannerView: UIViewRepresentable {

    // テスト用ID（Google公式テストバナー）
    // 本番用: ca-app-pub-4859622277330192/9892982365
    private let adUnitID = "ca-app-pub-3940256099942544/2934735716"

    func makeUIView(context: Context) -> GADBannerView {
        let banner = GADBannerView(adSize: GADAdSizeBanner)
        banner.adUnitID = adUnitID
        banner.rootViewController = context.coordinator.rootVC
        banner.load(GADRequest())
        return banner
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator: NSObject {
        var rootVC: UIViewController? {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }?
                .rootViewController
        }
    }
}

#else

// MARK: - Placeholder（SDK未インストール時）

struct AdBannerView: View {
    var body: some View {
        HStack(spacing: 8) {
            Text("AD")
                .font(.system(size: 8, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.35))
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
                )

            Spacer()

            Text("広告スペース")
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundColor(.white.opacity(0.4))

            Spacer()
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(Color.black.opacity(0.18))
        .overlay(
            Rectangle()
                .stroke(Color.white.opacity(0.07), lineWidth: 0.5)
        )
    }
}

#endif
