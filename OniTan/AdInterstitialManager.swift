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
    private let adUnitID = "ca-app-pub-4859622277330192/3670335626"
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

    func showIfReady(canRequestAds: Bool) {
        guard canRequestAds,
              let ad = interstitial,
              let rootVC = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow })?
                .rootViewController
        else {
            if !canRequestAds { interstitial = nil }
            return
        }

        interstitial = nil
        ad.present(from: rootVC)
    }
}

extension AdInterstitialManager: FullScreenContentDelegate {
    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        // 次のステージに備えて再ロード（consent状態はshowIfReady呼び出し時に再確認される）
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
    func showIfReady(canRequestAds: Bool) {}
}

#endif
