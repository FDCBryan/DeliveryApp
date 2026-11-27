import Foundation

nonisolated struct CartLine: Identifiable, Hashable, Sendable {
    let item: MenuItem
    var quantity: Int

    var id: String { item.id }
    var lineTotal: Int { item.price * quantity }
}

/// The customer's cart. Holds items from one store only (docs/PLAN.md §2);
/// adding from another store asks the customer to start a new cart.
nonisolated struct Cart: Hashable, Sendable {
    static let maxQuantity = 20

    enum AddResult: Equatable, Sendable {
        case added
        /// The cart already has items from `current`; nothing was changed.
        case needsNewCart(current: Store)
        /// Sold out, or the item doesn't belong to the given store.
        case unavailable
    }

    private(set) var store: Store?
    private(set) var lines: [CartLine] = []

    var isEmpty: Bool { lines.isEmpty }
    var itemCount: Int { lines.reduce(0) { $0 + $1.quantity } }
    var subtotal: Int { lines.reduce(0) { $0 + $1.lineTotal } }
    var deliveryFee: Int { isEmpty ? 0 : store?.deliveryFee ?? 0 }
    var total: Int { subtotal + deliveryFee }

    var orderItems: [OrderItem] {
        lines.map { OrderItem($0.item, quantity: $0.quantity) }
    }

    func quantity(of itemID: String) -> Int {
        lines.first { $0.id == itemID }?.quantity ?? 0
    }

    @discardableResult
    mutating func add(_ item: MenuItem, from store: Store) -> AddResult {
        guard item.isAvailable, item.storeID == store.id else { return .unavailable }
        if let current = self.store, current.id != store.id, !lines.isEmpty {
            return .needsNewCart(current: current)
        }
        self.store = store
        if let index = lines.firstIndex(where: { $0.id == item.id }) {
            lines[index].quantity = min(lines[index].quantity + 1, Self.maxQuantity)
        } else {
            lines.append(CartLine(item: item, quantity: 1))
        }
        return .added
    }

    /// Empties the cart and adds `item` from `store`; used after the customer
    /// confirms replacing a cart from another store.
    mutating func startNew(with item: MenuItem, from store: Store) {
        clear()
        add(item, from: store)
    }

    /// Sets a line's quantity; 0 or less removes the line.
    mutating func setQuantity(_ quantity: Int, for itemID: String) {
        guard let index = lines.firstIndex(where: { $0.id == itemID }) else { return }
        if quantity <= 0 {
            lines.remove(at: index)
            if lines.isEmpty { store = nil }
        } else {
            lines[index].quantity = min(quantity, Self.maxQuantity)
        }
    }

    mutating func clear() {
        lines = []
        store = nil
    }
}
