import Foundation
@testable import DeliveryApp

enum Fixture {
    static let now = Date(timeIntervalSince1970: 1_800_000_000)

    static let customer = AppUser(id: "cust-1", role: .customer, name: "Test Customer", phone: "555-1000")
    static let otherCustomer = AppUser(id: "cust-2", role: .customer, name: "Other Customer", phone: "555-1001")
    static let courier = AppUser(id: "cour-1", role: .courier, name: "Test Courier", phone: "555-2000")
    static let otherCourier = AppUser(id: "cour-2", role: .courier, name: "Other Courier", phone: "555-2001")

    static let store = Store(id: "store-1", name: "Test Store", address: Address(line: "1 Store St"), isOpen: true, deliveryFee: 250)
    static let closedStore = Store(id: "store-2", name: "Closed Store", address: Address(line: "2 Store St"), isOpen: false, deliveryFee: 100)

    static let items = [
        OrderItem(menuItemID: "a", name: "Item A", unitPrice: 1000, quantity: 2),
        OrderItem(menuItemID: "b", name: "Item B", unitPrice: 350, quantity: 1),
    ]

    static let address = Address(line: "9 Home Rd")

    static func repository() -> InMemoryOrderRepository {
        var next = 0
        return InMemoryOrderRepository(now: { now }, makeID: {
            next += 1
            return "order-\(next)"
        })
    }
}
