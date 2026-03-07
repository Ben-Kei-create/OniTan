import StoreKit
import Foundation

// MARK: - DonationManager
// StoreKit 2 を使った開発者への寄付（課金）管理
// App Store Connect で以下の製品IDを Non-Consumable として登録してください:
//   com.fumiakiMogi777.OniTan.donation

@MainActor
final class DonationManager: ObservableObject {

    static let productID = "com.fumiakiMogi777.OniTan.donation"
    private static let donatedKey = "hasDonated"

    @Published private(set) var hasDonated: Bool
    @Published private(set) var product: Product?
    @Published var isPurchasing: Bool = false
    @Published var isLoadingProduct: Bool = false
    @Published var purchaseError: String? = nil

    init() {
        self.hasDonated = UserDefaults.standard.bool(forKey: Self.donatedKey)
        Task { await loadProduct() }
    }

    // MARK: - Load Product

    func loadProduct() async {
        isLoadingProduct = true
        defer { isLoadingProduct = false }
        do {
            let products = try await Product.products(for: [Self.productID])
            self.product = products.first
            if product == nil {
                purchaseError = "商品情報を取得できませんでした。後でもう一度お試しください。"
            }
        } catch {
            purchaseError = "商品情報の読み込みに失敗しました: \(error.localizedDescription)"
        }
    }

    // MARK: - Purchase

    func purchase() async {
        guard let product else { return }
        isPurchasing = true
        purchaseError = nil
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                markDonated()
            case .userCancelled:
                break
            case .pending:
                break
            @unknown default:
                break
            }
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    // MARK: - Restore

    func restore() async {
        isPurchasing = true
        purchaseError = nil
        defer { isPurchasing = false }

        do {
            try await AppStore.sync()
            for await result in Transaction.currentEntitlements {
                if case .verified(let transaction) = result,
                   transaction.productID == Self.productID {
                    await transaction.finish()
                    markDonated()
                    break
                }
            }
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    // MARK: - Private

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    private func markDonated() {
        hasDonated = true
        UserDefaults.standard.set(true, forKey: Self.donatedKey)
    }

    enum StoreError: LocalizedError {
        case failedVerification
        var errorDescription: String? { "購入の確認に失敗しました" }
    }
}
