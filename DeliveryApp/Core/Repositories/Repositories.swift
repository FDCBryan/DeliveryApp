import Foundation

/// The app talks to the backend only through these protocols. M1 uses the in-memory
/// versions in Core/Mock; M4 adds Firebase versions with the same behaviour.

protocol AuthRepository: AnyObject {
    var currentUser: AppUser? { get }
    func signIn(email: String, password: String) async throws -> AppUser
    func signUp(name: String, phone: String, email: String, password: String, role: UserRole) async throws -> AppUser
    func signOut() throws
}

protocol StoreRepository: AnyObject {
    func openStores() async throws -> [Store]
    func menu(storeID: String) async throws -> [MenuItem]
}

protocol OrderRepository: AnyObject {
    func placeOrder(customer: AppUser, store: Store, items: [OrderItem], deliveryAddress: Address) async throws -> Order

    /// Claims a placed order for a courier. Must be atomic: when two couriers accept
    /// the same order, exactly one succeeds and the other gets `OrderError.alreadyTaken`.
    func accept(orderID: String, courier: AppUser) async throws -> Order

    /// Moves an order along `OrderStatus`; acceptance must go through `accept` instead.
    func updateStatus(orderID: String, to status: OrderStatus, by user: AppUser) async throws -> Order

    /// Live streams: each emits the current value right away, then again on every change.
    func customerOrders(customerID: String) -> AsyncStream<[Order]>
    func availableOrders() -> AsyncStream<[Order]>
    func courierOrders(courierID: String) -> AsyncStream<[Order]>
    func order(id: String) -> AsyncStream<Order?>
}

nonisolated enum AuthError: Error, Equatable, LocalizedError {
    case invalidCredentials
    case emailInUse
    case missingField(String)
    case weakPassword

    var errorDescription: String? {
        switch self {
        case .invalidCredentials: "Wrong email or password."
        case .emailInUse: "An account with this email already exists."
        case let .missingField(name): "Enter your \(name)."
        case .weakPassword: "Use a password of at least 8 characters."
        }
    }
}
