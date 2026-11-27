import Foundation
import Testing
@testable import DeliveryApp

struct NextCourierStepTests {
    private func order(status: OrderStatus, courierID: String?) throws -> Order {
        var order = try Order.new(id: "o", customer: Fixture.customer, store: Fixture.store, items: Fixture.items,
                                  deliveryAddress: Fixture.address, now: Fixture.now)
        order.status = status
        order.courierID = courierID
        return order
    }

    @Test func unassignedPlacedOrderCanBeAccepted() throws {
        #expect(try order(status: .placed, courierID: nil).nextCourierStep(for: "me") == .accepted)
    }

    @Test func ownOrderAdvancesStepByStep() throws {
        #expect(try order(status: .accepted, courierID: "me").nextCourierStep(for: "me") == .pickedUp)
        #expect(try order(status: .pickedUp, courierID: "me").nextCourierStep(for: "me") == .delivered)
        #expect(try order(status: .delivered, courierID: "me").nextCourierStep(for: "me") == nil)
    }

    @Test func someoneElsesOrderHasNoStep() throws {
        #expect(try order(status: .accepted, courierID: "other").nextCourierStep(for: "me") == nil)
        #expect(try order(status: .pickedUp, courierID: "other").nextCourierStep(for: "me") == nil)
    }

    @Test func cancelledOrderHasNoStep() throws {
        #expect(try order(status: .cancelled, courierID: nil).nextCourierStep(for: "me") == nil)
    }

    /// The step shown in the UI must always be one the repository accepts.
    @Test(arguments: OrderStatus.allCases)
    func stepIsAlwaysAnAllowedTransition(status: OrderStatus) throws {
        for courierID in [nil, "me", "other"] {
            if let step = try order(status: status, courierID: courierID).nextCourierStep(for: "me") {
                #expect(status.canTransition(to: step, by: .courier))
            }
        }
    }
}

struct CourierSessionTests {
    private func account(_ role: UserRole) -> (email: String, password: String, user: AppUser) {
        MockData.accounts.first { $0.user.role == role }!
    }

    private func signIn(_ session: AppSession, as role: UserRole) async throws {
        session.signOut()
        let acct = account(role)
        try await session.signIn(email: acct.email, password: acct.password)
    }

    /// Customer orders, courier delivers, customer sees it — all in one app run (one session).
    @Test func customerOrderIsDeliveredByCourierInTheSameRun() async throws {
        let session = AppSession.mock()
        try await signIn(session, as: .customer)
        let store = MockData.stores.first { $0.id == "store-chicken" }!
        let wings = MockData.menuItems.first { $0.id == "chicken-wings" }!
        session.cart.add(wings, from: store)
        let placed = try await session.checkout(deliveryAddress: Address(line: "9 Home Rd"))

        try await signIn(session, as: .courier)
        var available = session.orders.availableOrders().makeAsyncIterator()
        #expect(await available.next()?.contains { $0.id == placed.id } == true)

        let accepted = try await session.acceptOrder(id: placed.id)
        #expect(accepted.courierID == MockData.courier.id)
        #expect(try await session.advanceDelivery(id: placed.id, to: .pickedUp).status == .pickedUp)
        #expect(try await session.advanceDelivery(id: placed.id, to: .delivered).status == .delivered)

        try await signIn(session, as: .customer)
        var mine = session.orders.order(id: placed.id).makeAsyncIterator()
        let seen = try #require(await mine.next() ?? nil)
        #expect(seen.status == .delivered)
        #expect(seen.courierName == MockData.courier.name)
    }

    @Test func customerCannotUseCourierActions() async throws {
        let session = AppSession.mock(signedInAs: MockData.customer)
        await #expect(throws: OrderError.notAllowed) {
            try await session.acceptOrder(id: "order-1001")
        }
        await #expect(throws: OrderError.notAllowed) {
            try await session.advanceDelivery(id: "order-1001", to: .pickedUp)
        }
    }

    @Test func courierCannotSkipPickup() async throws {
        let session = AppSession.mock(signedInAs: MockData.courier)
        _ = try await session.acceptOrder(id: "order-1001")
        await #expect(throws: OrderError.invalidTransition(from: .accepted, to: .delivered)) {
            try await session.advanceDelivery(id: "order-1001", to: .delivered)
        }
    }

    @Test func courierBusyWithOneDeliveryCannotAcceptAnother() async throws {
        let session = AppSession.mock(signedInAs: MockData.courier)
        _ = try await session.acceptOrder(id: "order-1001")
        await #expect(throws: OrderError.courierBusy) {
            try await session.acceptOrder(id: "order-1002")
        }
    }

    @Test func cancelledOrderLeavesAvailableList() async throws {
        let session = AppSession.mock()
        try await signIn(session, as: .customer)
        let store = MockData.stores.first { $0.id == "store-bakery" }!
        session.cart.add(MockData.menuItems.first { $0.id == "bakery-coffee" }!, from: store)
        let order = try await session.checkout(deliveryAddress: Address(line: "9 Home Rd"))
        try await session.cancelOrder(id: order.id)

        try await signIn(session, as: .courier)
        var available = session.orders.availableOrders().makeAsyncIterator()
        #expect(await available.next()?.contains { $0.id == order.id } == false)
        await #expect(throws: OrderError.noLongerAvailable) {
            try await session.acceptOrder(id: order.id)
        }
    }
}
