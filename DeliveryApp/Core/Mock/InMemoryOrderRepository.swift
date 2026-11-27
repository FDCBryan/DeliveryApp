import Foundation

/// Mock order backend for M1–M3. Runs on the main actor, and no method suspends
/// between checking and writing, so `accept` is atomic the way a Firestore
/// transaction will be in M4.
final class InMemoryOrderRepository: OrderRepository {
    private var orders: [String: Order]
    private var observers: [UUID: () -> Void] = [:]
    private let now: () -> Date
    private let makeID: () -> String

    init(
        seed: [Order] = [],
        now: @escaping () -> Date = { Date() },
        makeID: @escaping () -> String = { UUID().uuidString }
    ) {
        self.orders = Dictionary(uniqueKeysWithValues: seed.map { ($0.id, $0) })
        self.now = now
        self.makeID = makeID
    }

    // MARK: Commands

    func placeOrder(customer: AppUser, store: Store, items: [OrderItem], deliveryAddress: Address) async throws -> Order {
        let order = try Order.new(
            id: makeID(), customer: customer, store: store, items: items,
            deliveryAddress: deliveryAddress, now: now()
        )
        save(order)
        return order
    }

    func accept(orderID: String, courier: AppUser) async throws -> Order {
        guard courier.role == .courier else { throw OrderError.notAllowed }
        guard var order = orders[orderID] else { throw OrderError.notFound }
        guard order.status == .placed, order.courierID == nil else { throw OrderError.alreadyTaken }
        let hasActiveDelivery = orders.values.contains { $0.courierID == courier.id && $0.status.isActive }
        guard !hasActiveDelivery else { throw OrderError.courierBusy }

        order.courierID = courier.id
        order.courierName = courier.name
        order.courierPhone = courier.phone
        order.status = .accepted
        order.updatedAt = now()
        save(order)
        return order
    }

    func updateStatus(orderID: String, to status: OrderStatus, by user: AppUser) async throws -> Order {
        guard var order = orders[orderID] else { throw OrderError.notFound }
        switch user.role {
        case .customer: guard order.customerID == user.id else { throw OrderError.notAllowed }
        case .courier: guard order.courierID == user.id else { throw OrderError.notAllowed }
        }
        guard status != .accepted, order.status.canTransition(to: status, by: user.role) else {
            throw OrderError.invalidTransition(from: order.status, to: status)
        }
        order.status = status
        order.updatedAt = now()
        save(order)
        return order
    }

    // MARK: Streams

    func customerOrders(customerID: String) -> AsyncStream<[Order]> {
        stream { repo in
            repo.orders.values.filter { $0.customerID == customerID }.sorted { $0.createdAt > $1.createdAt }
        }
    }

    func availableOrders() -> AsyncStream<[Order]> {
        stream { repo in
            repo.orders.values.filter { $0.status == .placed }.sorted { $0.createdAt < $1.createdAt }
        }
    }

    func courierOrders(courierID: String) -> AsyncStream<[Order]> {
        stream { repo in
            repo.orders.values.filter { $0.courierID == courierID }.sorted { $0.updatedAt > $1.updatedAt }
        }
    }

    func order(id: String) -> AsyncStream<Order?> {
        stream { repo in repo.orders[id] }
    }

    // MARK: Private

    private func save(_ order: Order) {
        orders[order.id] = order
        for notify in observers.values { notify() }
    }

    private func stream<Value: Sendable>(_ select: @escaping (InMemoryOrderRepository) -> Value) -> AsyncStream<Value> {
        AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            let id = UUID()
            observers[id] = { [weak self] in
                guard let self else { return }
                continuation.yield(select(self))
            }
            continuation.yield(select(self))
            continuation.onTermination = { [weak self] _ in
                guard let self else { return }
                Task { @MainActor in self.observers[id] = nil }
            }
        }
    }
}
