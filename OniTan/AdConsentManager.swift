import Foundation
import OSLog

#if canImport(AppTrackingTransparency)
import AppTrackingTransparency
#endif

#if canImport(GoogleMobileAds) && canImport(UserMessagingPlatform)
import GoogleMobileAds
import UIKit
import UserMessagingPlatform
#endif

private let adsLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "OniTan", category: "Ads")

@MainActor
final class AdConsentManager: ObservableObject {
    @Published private(set) var canRequestAds: Bool = false
    @Published private(set) var privacyOptionsRequired: Bool = false
    @Published private(set) var isPreparing: Bool = false
    @Published private(set) var lastErrorMessage: String?

    private var hasPrepared = false
    private var hasStartedMobileAds = false
    private let processInfo = ProcessInfo.processInfo

    func prepareIfNeeded() async {
        guard !isDisabledForCurrentProcess else {
            canRequestAds = false
            privacyOptionsRequired = false
            lastErrorMessage = nil
            return
        }

        guard !hasPrepared else {
            syncConsentState()
            startAdsIfPossible()
            return
        }

        hasPrepared = true
        await prepareConsentAndAds()
    }

    func presentPrivacyOptionsFormIfRequired() async {
#if canImport(GoogleMobileAds) && canImport(UserMessagingPlatform)
        guard privacyOptionsRequired else { return }
        do {
            try await ConsentForm.presentPrivacyOptionsForm(from: nil)
            syncConsentState()
        } catch {
            lastErrorMessage = "広告のプライバシー設定を開けませんでした。"
            adsLogger.error("Failed to present privacy options form: \(error.localizedDescription, privacy: .public)")
        }
#endif
    }

    private func prepareConsentAndAds() async {
        isPreparing = true
        defer { isPreparing = false }

#if canImport(GoogleMobileAds) && canImport(UserMessagingPlatform)
        let parameters = RequestParameters()
        parameters.isTaggedForUnderAgeOfConsent = false

        do {
            try await ConsentInformation.shared.requestConsentInfoUpdate(with: parameters)
            syncConsentState()

            if canRequestAds {
                startAdsIfPossible()
            }

            try await ConsentForm.loadAndPresentIfRequired(from: nil)
            syncConsentState()
            startAdsIfPossible()
            lastErrorMessage = nil
        } catch {
            syncConsentState()
            startAdsIfPossible()
            lastErrorMessage = "広告の準備中に一部設定を確認できませんでした。"
            adsLogger.error("Consent flow failed: \(error.localizedDescription, privacy: .public)")
        }
#else
        canRequestAds = false
        privacyOptionsRequired = false
#endif
    }

    private func syncConsentState() {
#if canImport(GoogleMobileAds) && canImport(UserMessagingPlatform)
        canRequestAds = ConsentInformation.shared.canRequestAds
        privacyOptionsRequired = ConsentInformation.shared.privacyOptionsRequirementStatus == .required
#else
        canRequestAds = false
        privacyOptionsRequired = false
#endif
    }

    private func startAdsIfPossible() {
#if canImport(GoogleMobileAds) && canImport(UserMessagingPlatform)
        guard canRequestAds, !hasStartedMobileAds else { return }
        hasStartedMobileAds = true
        MobileAds.shared.start()
        adsLogger.info("Google Mobile Ads SDK started")
#endif
    }

    private var isDisabledForCurrentProcess: Bool {
        processInfo.environment["XCTestConfigurationFilePath"] != nil
            || processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
}
