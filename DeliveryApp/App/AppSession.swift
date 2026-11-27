import Foundation
import Observation

/// Holds the repositories and the signed-in user. Injected into the view tree with `.environment`.
@Observable
final class AppSession {
    let auth: any AuthRepository
    let stores: any StoreRepository
    let orders: any OrderRepository
    private(set) var user: AppUser?
    /// The customer's cart; kept for the session, cleared on sign-out and after checkout.
    var cart = Cart()
    /// Pre-fills the next checkout.
    private(set) var lastDeliveryAddress: Address?

    init(auth: any AuthRepository, stores: any StoreRepository, orders: any OrderRepository) {
        self.auth = auth
        self.stores = stores
        self.orders = orders
        self.user = auth.currentUser
    }

    func signIn(email: String, password: String) async throws {
        user = try await auth.signIn(email: email, password: password)
    }

    func signUp(name: String, phone: String, email: String, password: String, role: UserRole) async throws {
        user = try await auth.signUp(name: name, phone: phone, email: email, password: password, role: role)
    }

    func signOut() {
        try? auth.signOut()
        user = nil
        cart.clear()
        lastDeliveryAddress = nil
    }

    /// Places the cart as an order. The cart is cleared only if the order went through.
    func checkout(deliveryAddress: Address) async throws -> Order {
        guard let user, user.role == .customer else { throw OrderError.notAllowed }
        guard let store = cart.store, !cart.isEmpty else { throw OrderError.emptyOrder }
        let order = try await orders.placeOrder(
            customer: user, store: store, items: cart.orderItems, deliveryAddress: deliveryAddress
        )
        cart.clear()
        lastDeliveryAddress = deliveryAddress
        return order
    }

    /// Customer cancels their own order; only allowed while it's still `placed`.
    func cancelOrder(id: String) async throws {
        guard let user else { throw OrderError.notAllowed }
        _ = try await orders.updateStatus(orderID: id, to: .cancelled, by: user)
    }

    /// In-memory backend with sample stores, menus, accounts and orders.
    static func mock(signedInAs user: AppUser? = nil) -> AppSession {
        let auth = InMemoryAuthRepository(seed: MockData.accounts)
        let session = AppSession(
            auth: auth,
            stores: InMemoryStoreRepository(stores: MockData.stores, menuItems: MockData.menuItems),
            orders: InMemoryOrderRepository(seed: MockData.orders())
        )
        session.user = user
        return session
    }
}
