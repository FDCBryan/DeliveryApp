import Foundation
import Testing
@testable import DeliveryApp

struct OrderTests {
    @Test func newOrderComputesTotalsInMinorUnits() throws {
        let order = try Order.new(id: "o1", customer: Fixture.customer, store: Fixture.store,
                                  items: Fixture.items, deliveryAddress: Fixture.address, now: Fixture.now)
        #expect(order.subtotal == 2350)
        #expect(order.deliveryFee == 250)
        #expect(order.total == 2600)
        #expect(order.itemCount == 3)
        #expect(order.status == .placed)
        #expect(order.courierID == nil)
        #expect(order.storeName == "Test Store")
    }

    @Test func rejectsEmptyOrder() {
        #expect(throws: OrderError.emptyOrder) {
            try Order.new(id: "o", customer: Fixture.customer, store: Fixture.store, items: [],
                          deliveryAddress: Fixture.address, now: Fixture.now)
        }
    }

    @Test func rejectsZeroQuantity() {
        let items = [OrderItem(menuItemID: "a", name: "A", unitPrice: 100, quantity: 0)]
        #expect(throws: OrderError.emptyOrder) {
            try Order.new(id: "o", customer: Fixture.customer, store: Fixture.store, items: items,
                          deliveryAddress: Fixture.address, now: Fixture.now)
        }
    }

    @Test func rejectsClosedStore() {
        #expect(throws: OrderError.storeClosed) {
            try Order.new(id: "o", customer: Fixture.customer, store: Fixture.closedStore, items: Fixture.items,
                          deliveryAddress: Fixture.address, now: Fixture.now)
        }
    }

    @Test func rejectsBlankAddress() {
        #expect(throws: OrderError.missingAddress) {
            try Order.new(id: "o", customer: Fixture.customer, store: Fixture.store, items: Fixture.items,
                          deliveryAddress: Address(line: "   "), now: Fixture.now)
        }
    }

    @Test func couriersCannotPlaceOrders() {
        #expect(throws: OrderError.notAllowed) {
            try Order.new(id: "o", customer: Fixture.courier, store: Fixture.store, items: Fixture.items,
                          deliveryAddress: Fixture.address, now: Fixture.now)
        }
    }

    @Test func formatsMoneyFromMinorUnits() {
        #expect(Money.format(1299, currencyCode: "USD").contains("12.99"))
    }
}
