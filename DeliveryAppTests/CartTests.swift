import Testing
@testable import DeliveryApp

struct CartTests {
    let burgerStore = MockData.stores.first { $0.id == "store-burger" }!
    let noodleStore = MockData.stores.first { $0.id == "store-noodle" }!
    var classic: MenuItem { MockData.menuItems.first { $0.id == "burger-classic" }! }
    var fries: MenuItem { MockData.menuItems.first { $0.id == "burger-fries" }! }
    var soldOutShake: MenuItem { MockData.menuItems.first { $0.id == "burger-shake" }! }
    var ramen: MenuItem { MockData.menuItems.first { $0.id == "noodle-ramen" }! }

    @Test func addingTheSameItemIncrementsQuantity() {
        var cart = Cart()
        #expect(cart.add(classic, from: burgerStore) == .added)
        #expect(cart.add(classic, from: burgerStore) == .added)
        #expect(cart.lines.count == 1)
        #expect(cart.quantity(of: classic.id) == 2)
        #expect(cart.store?.id == burgerStore.id)
    }

    @Test func totalsUseMinorUnitsAndStoreFee() {
        var cart = Cart()
        cart.add(classic, from: burgerStore)   // 899
        cart.add(classic, from: burgerStore)   // 899
        cart.add(fries, from: burgerStore)     // 349
        #expect(cart.itemCount == 3)
        #expect(cart.subtotal == 2147)
        #expect(cart.deliveryFee == burgerStore.deliveryFee)
        #expect(cart.total == 2147 + burgerStore.deliveryFee)
        #expect(cart.orderItems.map(\.quantity) == [2, 1])
    }

    @Test func otherStoreNeedsANewCartAndChangesNothing() {
        var cart = Cart()
        cart.add(classic, from: burgerStore)
        let before = cart
        #expect(cart.add(ramen, from: noodleStore) == .needsNewCart(current: burgerStore))
        #expect(cart == before)

        cart.startNew(with: ramen, from: noodleStore)
        #expect(cart.store?.id == noodleStore.id)
        #expect(cart.lines.map(\.id) == [ramen.id])
    }

    @Test func soldOutOrMismatchedItemsAreRejected() {
        var cart = Cart()
        #expect(cart.add(soldOutShake, from: burgerStore) == .unavailable)
        #expect(cart.add(ramen, from: burgerStore) == .unavailable)
        #expect(cart.isEmpty)
        #expect(cart.store == nil)
    }

    @Test func settingQuantityToZeroRemovesAndEmptiesStore() {
        var cart = Cart()
        cart.add(classic, from: burgerStore)
        cart.setQuantity(5, for: classic.id)
        #expect(cart.quantity(of: classic.id) == 5)
        cart.setQuantity(0, for: classic.id)
        #expect(cart.isEmpty)
        #expect(cart.store == nil)
        #expect(cart.deliveryFee == 0)
        #expect(cart.total == 0)
    }

    @Test func quantityIsCapped() {
        var cart = Cart()
        cart.add(classic, from: burgerStore)
        cart.setQuantity(99, for: classic.id)
        #expect(cart.quantity(of: classic.id) == Cart.maxQuantity)
        cart.add(classic, from: burgerStore)
        #expect(cart.quantity(of: classic.id) == Cart.maxQuantity)
    }

    @Test func emptyCartCanStartWithAnyStore() {
        var cart = Cart()
        cart.add(classic, from: burgerStore)
        cart.setQuantity(0, for: classic.id)
        #expect(cart.add(ramen, from: noodleStore) == .added)
    }
}

struct CheckoutTests {
    let burgerStore = MockData.stores.first { $0.id == "store-burger" }!
    var classic: MenuItem { MockData.menuItems.first { $0.id == "burger-classic" }! }

    @Test func checkoutPlacesOrderAndClearsCart() async throws {
        let session = AppSession.mock(signedInAs: MockData.customer)
        session.cart.add(classic, from: burgerStore)
        session.cart.add(classic, from: burgerStore)

        let order = try await session.checkout(deliveryAddress: Address(line: "9 Home Rd", note: "Gate code 12"))

        #expect(order.status == .placed)
        #expect(order.storeID == burgerStore.id)
        #expect(order.customerPhone == MockData.customer.phone)
        #expect(order.total == 2 * classic.price + burgerStore.deliveryFee)
        #expect(order.deliveryAddress.note == "Gate code 12")
        #expect(session.cart.isEmpty)
        #expect(session.lastDeliveryAddress?.line == "9 Home Rd")

        var updates = session.orders.customerOrders(customerID: MockData.customer.id).makeAsyncIterator()
        #expect(await updates.next()?.contains { $0.id == order.id } == true)
    }

    @Test func failedCheckoutKeepsCart() async {
        let session = AppSession.mock(signedInAs: MockData.customer)
        session.cart.add(classic, from: burgerStore)
        await #expect(throws: OrderError.missingAddress) {
            try await session.checkout(deliveryAddress: Address(line: "  "))
        }
        #expect(session.cart.itemCount == 1)
    }

    @Test func emptyCartCannotCheckOut() async {
        let session = AppSession.mock(signedInAs: MockData.customer)
        await #expect(throws: OrderError.emptyOrder) {
            try await session.checkout(deliveryAddress: Address(line: "9 Home Rd"))
        }
    }

    @Test func couriersCannotCheckOut() async {
        let session = AppSession.mock(signedInAs: MockData.courier)
        session.cart.add(classic, from: burgerStore)
        await #expect(throws: OrderError.notAllowed) {
            try await session.checkout(deliveryAddress: Address(line: "9 Home Rd"))
        }
    }

    @Test func customerCancelsWhilePlaced() async throws {
        let session = AppSession.mock(signedInAs: MockData.customer)
        session.cart.add(classic, from: burgerStore)
        let order = try await session.checkout(deliveryAddress: Address(line: "9 Home Rd"))

        try await session.cancelOrder(id: order.id)

        var updates = session.orders.order(id: order.id).makeAsyncIterator()
        #expect(await updates.next()??.status == .cancelled)
    }

    @Test func acceptedOrderShowsCourierContactAndCannotBeCancelled() async throws {
        let session = AppSession.mock(signedInAs: MockData.customer)
        session.cart.add(classic, from: burgerStore)
        let order = try await session.checkout(deliveryAddress: Address(line: "9 Home Rd"))

        let accepted = try await session.orders.accept(orderID: order.id, courier: MockData.courier)
        #expect(accepted.courierPhone == MockData.courier.phone)

        await #expect(throws: OrderError.invalidTransition(from: .accepted, to: .cancelled)) {
            try await session.cancelOrder(id: order.id)
        }
    }

    @Test func signOutClearsCart() {
        let session = AppSession.mock(signedInAs: MockData.customer)
        session.cart.add(classic, from: burgerStore)
        session.signOut()
        #expect(session.cart.isEmpty)
        #expect(session.user == nil)
    }
}
