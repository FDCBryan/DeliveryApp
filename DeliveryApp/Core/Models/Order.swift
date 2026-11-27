import Foundation

/// A copy of the menu item taken when the order is placed, so later menu edits don't change past orders.
nonisolated struct OrderItem: Codable, Hashable, Sendable {
    let menuItemID: String
    let name: String
    let unitPrice: Int
    var quantity: Int

    var lineTotal: Int { unitPrice * quantity }

    init(menuItemID: String, name: String, unitPrice: Int, quantity: Int) {
        self.menuItemID = menuItemID
        self.name = name
        self.unitPrice = unitPrice
        self.quantity = quantity
    }

    init(_ item: MenuItem, quantity: Int) {
        self.init(menuItemID: item.id, name: item.name, unitPrice: item.price, quantity: quantity)
    }
}

nonisolated struct Order: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let customerID: String
    let customerName: String
    let customerPhone: String
    let storeID: String
    let storeName: String
    let storeAddress: Address
    var courierID: String?
    var courierName: String?
    var courierPhone: String?
    let items: [OrderItem]
    let subtotal: Int
    let deliveryFee: Int
    let total: Int
    let deliveryAddress: Address
    var status: OrderStatus
    let createdAt: Date
    var updatedAt: Date

    var itemCount: Int { items.reduce(0) { $0 + $1.quantity } }

    /// Builds a new order, validating the input and computing the totals.
    static func new(
        id: String,
        customer: AppUser,
        store: Store,
        items: [OrderItem],
        deliveryAddress: Address,
        now: Date
    ) throws(OrderError) -> Order {
        guard customer.role == .customer else { throw .notAllowed }
        guard store.isOpen else { throw .storeClosed }
        guard !items.isEmpty, items.allSatisfy({ $0.quantity > 0 }) else { throw .emptyOrder }
        guard !deliveryAddress.line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw .missingAddress
        }
        let subtotal = items.reduce(0) { $0 + $1.lineTotal }
        return Order(
            id: id,
            customerID: customer.id,
            customerName: customer.name,
            customerPhone: customer.phone,
            storeID: store.id,
            storeName: store.name,
            storeAddress: store.address,
            courierID: nil,
            courierName: nil,
            courierPhone: nil,
            items: items,
            subtotal: subtotal,
            deliveryFee: store.deliveryFee,
            total: subtotal + store.deliveryFee,
            deliveryAddress: deliveryAddress,
            status: .placed,
            createdAt: now,
            updatedAt: now
        )
    }
}

nonisolated enum OrderError: Error, Equatable, LocalizedError {
    case notFound
    case notAllowed
    case storeClosed
    case emptyOrder
    case missingAddress
    case alreadyTaken
    case courierBusy
    case invalidTransition(from: OrderStatus, to: OrderStatus)

    var errorDescription: String? {
        switch self {
        case .notFound: "This order no longer exists."
        case .notAllowed: "You can't change this order."
        case .storeClosed: "This store is closed right now."
        case .emptyOrder: "Add at least one item."
        case .missingAddress: "Enter a delivery address."
        case .alreadyTaken: "Another courier already took this order."
        case .courierBusy: "Finish your current delivery first."
        case let .invalidTransition(from, to): "An order can't go from \(from.title) to \(to.title)."
        }
    }
}
