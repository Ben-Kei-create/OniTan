import Foundation
import SwiftUI

#if canImport(GoogleMobileAds)
import GoogleMobileAds

@MainActor
final class AdInterstitialManager: NSObject, ObservableObject {

    private var interstitial: InterstitialAd?

    #if DEBUG
    private let adUnitID = "ca-app-pub-3940256099942544/4411468910"
    #else
    // TODO: AdMobコンソールでインタースティシャル広告ユニットを作成し、IDを差し替える
    private let adUnitID = "ca-app-pub-4859622277330192/REPLACE_WITH_INTERSTITIAL_ID"
    #endif

    override init() { super.init() }

    func loadIfNeeded(canRequestAds: Bool) {
        guard canRequestAds, interstitial == nil else { return }
        Task {
            do {
                let ad = try await InterstitialAd.load(
                    with: adUnitID,
                    request: Request()
                )
                ad.fullScreenContentDelegate = self
                self.interstitial = ad
            } catch {
                // 読み込み失敗は静かに無視
            }
        }
    }

    func showIfReady() {
        guard let ad = interstitial,
              let rootVC = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow })?
                .rootViewController
        else { return }

        interstitial = nil
        ad.present(from: rootVC)
    }
}

extension AdInterstitialManager: FullScreenContentDelegate {
    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        // 次のステージに備えて再ロード（consent状態は次回showIfReady前に確認済みのはず）
        Task { @MainActor in self.interstitial = nil }
    }

    nonisolated func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Task { @MainActor in self.interstitial = nil }
    }
}

#else

@MainActor
final class AdInterstitialManager: NSObject, ObservableObject {
    override init() {}
    func loadIfNeeded(canRequestAds: Bool) {}
    func showIfReady() {}
}

#endif
