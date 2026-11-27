import Testing
@testable import DeliveryApp

struct MockDataTests {
    @Test func seedOrdersAreConsistent() {
        let orders = MockData.orders(now: Fixture.now)
        #expect(orders.filter { $0.status == .placed }.count == 2)
        #expect(Set(orders.map(\.id)).count == orders.count)
        for order in orders {
            #expect(MockData.stores.contains { $0.id == order.storeID })
            #expect(order.total == order.subtotal + order.deliveryFee)
        }
    }

    @Test func everyMenuItemBelongsToAStore() {
        let storeIDs = Set(MockData.stores.map(\.id))
        #expect(MockData.menuItems.allSatisfy { storeIDs.contains($0.storeID) })
    }
}

struct MockMenuTests {
    @Test func everyOpenStoreHasAnAvailableItemAndACuisine() {
        for store in MockData.stores where store.isOpen {
            #expect(!store.cuisine.isEmpty, "\(store.name)")
            #expect(MockData.menuItems.contains { $0.storeID == store.id && $0.isAvailable }, "\(store.name)")
        }
    }

    @Test func menuItemIDsAreUnique() {
        #expect(Set(MockData.menuItems.map(\.id)).count == MockData.menuItems.count)
    }
}
