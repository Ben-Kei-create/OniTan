import SwiftUI

#if canImport(GoogleMobileAds)
import GoogleMobileAds

struct AdBannerView: View {
    @EnvironmentObject private var adConsentManager: AdConsentManager

    var body: some View {
        Group {
            if adConsentManager.canRequestAds {
                BannerViewContainer()
                    .frame(height: 50)
            }
        }
    }
}

private struct BannerViewContainer: UIViewRepresentable {
    typealias UIViewType = BannerView

    #if DEBUG
    private let adUnitID = "ca-app-pub-3940256099942544/2435281174"
    #else
    private let adUnitID = "ca-app-pub-4859622277330192/9892982365"
    #endif

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = adUnitID
        banner.rootViewController = context.coordinator.rootVC
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {
        uiView.rootViewController = context.coordinator.rootVC
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject {
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

struct AdBannerView: View {
    var body: some View {
        EmptyView()
    }
}

#endif
