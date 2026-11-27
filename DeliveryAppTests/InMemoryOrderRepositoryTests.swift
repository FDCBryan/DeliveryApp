import Foundation
import Testing
@testable import DeliveryApp

struct InMemoryOrderRepositoryTests {
    let repo = Fixture.repository()

    private func place(by customer: AppUser? = nil) async throws -> Order {
        try await repo.placeOrder(customer: customer ?? Fixture.customer, store: Fixture.store, items: Fixture.items, deliveryAddress: Fixture.address)
    }

    @Test func fullDeliveryLifecycle() async throws {
        let placed = try await place()
        let accepted = try await repo.accept(orderID: placed.id, courier: Fixture.courier)
        #expect(accepted.status == .accepted)
        #expect(accepted.courierID == Fixture.courier.id)
        #expect(accepted.courierName == Fixture.courier.name)

        let picked = try await repo.updateStatus(orderID: placed.id, to: .pickedUp, by: Fixture.courier)
        #expect(picked.status == .pickedUp)
        let delivered = try await repo.updateStatus(orderID: placed.id, to: .delivered, by: Fixture.courier)
        #expect(delivered.status == .delivered)
    }

    @Test func secondAcceptIsRejected() async throws {
        let order = try await place()
        _ = try await repo.accept(orderID: order.id, courier: Fixture.courier)
        await #expect(throws: OrderError.alreadyTaken) {
            try await repo.accept(orderID: order.id, courier: Fixture.otherCourier)
        }
    }

    @Test func concurrentAcceptsHaveExactlyOneWinner() async throws {
        let order = try await place()
        let repo = self.repo
        let winners = await withTaskGroup(of: String?.self) { group in
            for courier in [Fixture.courier, Fixture.otherCourier] {
                group.addTask { try? await repo.accept(orderID: order.id, courier: courier).courierID }
            }
            var results: [String] = []
            for await id in group { if let id { results.append(id) } }
            return results
        }
        #expect(winners.count == 1)
    }

    @Test func courierCanHoldOnlyOneActiveDelivery() async throws {
        let first = try await place()
        let second = try await place(by: Fixture.otherCustomer)
        _ = try await repo.accept(orderID: first.id, courier: Fixture.courier)
        await #expect(throws: OrderError.courierBusy) {
            try await repo.accept(orderID: second.id, courier: Fixture.courier)
        }
    }

    @Test func customersCannotAcceptOrders() async throws {
        let order = try await place()
        await #expect(throws: OrderError.notAllowed) {
            try await repo.accept(orderID: order.id, courier: Fixture.customer)
        }
    }

    @Test func acceptanceMustGoThroughAccept() async throws {
        let order = try await place()
        await #expect(throws: OrderError.self) {
            try await repo.updateStatus(orderID: order.id, to: .accepted, by: Fixture.courier)
        }
    }

    @Test func onlyTheAssignedCourierCanUpdate() async throws {
        let order = try await place()
        _ = try await repo.accept(orderID: order.id, courier: Fixture.courier)
        await #expect(throws: OrderError.notAllowed) {
            try await repo.updateStatus(orderID: order.id, to: .pickedUp, by: Fixture.otherCourier)
        }
    }

    @Test func customerCanCancelOnlyWhilePlaced() async throws {
        let order = try await place()
        let cancelled = try await repo.updateStatus(orderID: order.id, to: .cancelled, by: Fixture.customer)
        #expect(cancelled.status == .cancelled)

        let other = try await place()
        _ = try await repo.accept(orderID: other.id, courier: Fixture.courier)
        await #expect(throws: OrderError.invalidTransition(from: .accepted, to: .cancelled)) {
            try await repo.updateStatus(orderID: other.id, to: .cancelled, by: Fixture.customer)
        }
    }

    @Test func customerCannotCancelSomeoneElsesOrder() async throws {
        let order = try await place()
        await #expect(throws: OrderError.notAllowed) {
            try await repo.updateStatus(orderID: order.id, to: .cancelled, by: Fixture.otherCustomer)
        }
    }

    @Test func cannotSkipSteps() async throws {
        let order = try await place()
        _ = try await repo.accept(orderID: order.id, courier: Fixture.courier)
        await #expect(throws: OrderError.invalidTransition(from: .accepted, to: .delivered)) {
            try await repo.updateStatus(orderID: order.id, to: .delivered, by: Fixture.courier)
        }
    }

    @Test func unknownOrderIsNotFound() async {
        await #expect(throws: OrderError.notFound) {
            try await repo.accept(orderID: "missing", courier: Fixture.courier)
        }
    }

    @Test func availableStreamUpdatesLive() async throws {
        var updates = repo.availableOrders().makeAsyncIterator()
        #expect(await updates.next()?.isEmpty == true)

        let order = try await place()
        #expect(await updates.next()?.map(\.id) == [order.id])

        _ = try await repo.accept(orderID: order.id, courier: Fixture.courier)
        #expect(await updates.next()?.isEmpty == true)
    }

    @Test func customerAndCourierStreamsAreScoped() async throws {
        let mine = try await place()
        _ = try await place(by: Fixture.otherCustomer)
        _ = try await repo.accept(orderID: mine.id, courier: Fixture.courier)

        var customerUpdates = repo.customerOrders(customerID: Fixture.customer.id).makeAsyncIterator()
        #expect(await customerUpdates.next()?.map(\.id) == [mine.id])

        var courierUpdates = repo.courierOrders(courierID: Fixture.courier.id).makeAsyncIterator()
        #expect(await courierUpdates.next()?.map(\.id) == [mine.id])

        var otherCourierUpdates = repo.courierOrders(courierID: Fixture.otherCourier.id).makeAsyncIterator()
        #expect(await otherCourierUpdates.next()?.isEmpty == true)
    }
}
