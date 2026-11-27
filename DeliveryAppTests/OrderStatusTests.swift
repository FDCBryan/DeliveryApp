import Testing
@testable import DeliveryApp

struct OrderStatusTests {
    /// Every allowed (from, to, role) triple. Anything not listed must be rejected.
    static let allowed: Set<String> = [
        "placed>accepted>courier",
        "accepted>pickedUp>courier",
        "pickedUp>delivered>courier",
        "placed>cancelled>customer",
    ]

    @Test(arguments: OrderStatus.allCases, OrderStatus.allCases)
    func transitionTable(from: OrderStatus, to: OrderStatus) {
        for role in UserRole.allCases {
            let key = "\(from.rawValue)>\(to.rawValue)>\(role.rawValue)"
            #expect(from.canTransition(to: to, by: role) == Self.allowed.contains(key), "\(key)")
        }
    }

    @Test func activeStatuses() {
        #expect(OrderStatus.allCases.filter(\.isActive) == [.placed, .accepted, .pickedUp])
    }
}
