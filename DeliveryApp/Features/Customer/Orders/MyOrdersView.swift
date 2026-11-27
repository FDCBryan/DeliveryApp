import SwiftUI

struct MyOrdersView: View {
    @Environment(AppSession.self) private var session
    @Environment(CustomerRouter.self) private var router
    @State private var orders: [Order] = []
    @State private var hasLoaded = false

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.ordersPath) {
            List {
                let active = orders.filter(\.status.isActive)
                let past = orders.filter { !$0.status.isActive }
                if !active.isEmpty {
                    Section("Active") { rows(active) }
                }
                if !past.isEmpty {
                    Section("Past") { rows(past) }
                }
            }
            .overlay {
                if hasLoaded && orders.isEmpty {
                    ContentUnavailableView {
                        Label("No orders yet", systemImage: "bag")
                    } description: {
                        Text("Your orders will show up here.")
                    } actions: {
                        Button("Browse stores") { router.tab = .stores }
                            .buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle("My orders")
            .navigationDestination(for: String.self) { OrderDetailView(orderID: $0) }
            .task(id: session.user?.id) {
                guard let user = session.user else { return }
                for await value in session.orders.customerOrders(customerID: user.id) {
                    orders = value
                    hasLoaded = true
                }
            }
        }
    }

    private func rows(_ orders: [Order]) -> some View {
        ForEach(orders) { order in
            NavigationLink(value: order.id) {
                OrderRow(order: order, perspective: .customer)
            }
        }
    }
}

#Preview {
    MyOrdersView()
        .environment(AppSession.mock(signedInAs: MockData.customer))
        .environment(CustomerRouter())
}
