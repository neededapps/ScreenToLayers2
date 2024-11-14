
import StoreKit
import SwiftUI
import Observation

@MainActor
@Observable
public class CoffeePurchaser {
    
    // MARK: Enumerations
    
    public enum PurchaseState: String, Equatable, Identifiable {
        case purchased = "purchased"
        case purchasing = "purchasing"
        case notPurchased = "not_purchased"
        public var id: String { rawValue }
    }
    
    public enum PurchaserError: Error, LocalizedError {
        case productNotFound
        case purchaseFailed
        case verificationFailed
        
        public var errorDescription: String? {
            switch self {
            case .productNotFound:
                return String(localized: "The requested product could not be found.")
            case .purchaseFailed:
                return String(localized: "The purchase process failed. Please try again.")
            case .verificationFailed:
                return String(localized: "The purchase could not be verified.")
            }
        }
    }
    
    // MARK: Initializers
    
    public init() {
        Task {
            try? await reloadPurchaseState()
            try? await loadPurchaseUpdates()
        }
    }
    
    // MARK: Properties
    
    private let productIdentifier = "com.jeremyvizzini.screentolayers.osx.buycoffeeonce"
    
    public private(set) var state: PurchaseState = .notPurchased

    public private(set) var isRestoring: Bool = false
    
    // MARK: Purchase process
    
    private typealias Verification = VerificationResult<StoreKit.Transaction>
    
    private func isPurchased(productID id: String) async -> Bool {
        let result = await Transaction.currentEntitlement(for: id)
        guard case .verified(_) = result else { return false }
        return true
    }
    
    private func reloadPurchaseState() async throws {
        let isPurchased = await isPurchased(productID: productIdentifier)
        state = isPurchased ? .purchased : .notPurchased
    }
    
    private func finalizeVerification(_ verification: Verification) async throws {
        guard case .verified(let transaction) = verification else {
            throw PurchaserError.verificationFailed
        }
        await transaction.finish()
        try await reloadPurchaseState()
    }
    
    private func loadPurchaseUpdates() async throws {
        for await verification in Transaction.updates {
            try await finalizeVerification(verification)
        }
    }
    
    private func purchaseProduct() async throws {
        let products = try await Product.products(for: [productIdentifier])
        guard let foundProduct = products.first else {
            throw PurchaserError.productNotFound
        }
        
        let result = try await foundProduct.purchase()
        guard case .success(let verification) = result else {
            throw PurchaserError.purchaseFailed
        }
        try await finalizeVerification(verification)
    }

    // MARK: Actions
    
    public func canBuyCoffee() -> Bool {
        state == .notPurchased && !isRestoring
    }
    
    public func buyCoffee() async {
        guard canBuyCoffee() else { return }
        state = .purchasing
        
        do {
            try await purchaseProduct()
        } catch {
            state = .notPurchased
        }
    }
    
    public func canRestorePurchases() -> Bool {
        state != .purchasing && !isRestoring
    }
    
    public func restorePurchases() async {
        guard canRestorePurchases() else { return }
        isRestoring = true
        try? await AppStore.sync()
        isRestoring = false
    }
}
