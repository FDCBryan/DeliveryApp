import SwiftUI

/// Orders from every store that no courier has taken yet, oldest first.
struct AvailableOrdersView: View {
    @Environment(AppSession.self) private var session
    @Environment(CourierRouter.self) private var router
    @State private var orders: [Order] = []
    @State private var hasActiveDelivery = false
    @State private var hasLoaded = false

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.availablePath) {
            List {
                if hasActiveDelivery {
                    Section {
                        Button {
                            router.tab = .active
                        } label: {
                            Label("Finish your current delivery before accepting another.", systemImage: "bicycle")
                                .font(.subheadline)
                        }
                    }
                }
                ForEach(orders) { order in
                    NavigationLink(value: order.id) {
                        OrderRow(order: order, perspective: .courier)
                    }
                }
            }
            .overlay {
                if hasLoaded && orders.isEmpty {
                    ContentUnavailableView("No orders waiting", systemImage: "tray", description: Text("New orders appear here as customers place them."))
                }
            }
            .navigationTitle("Available")
            .navigationDestination(for: String.self) { id in
                OrderDetailView(orderID: id, onAccepted: router.showActiveDelivery)
            }
            .task {
                for await value in session.orders.availableOrders() {
                    orders = value
                    hasLoaded = true
                }
            }
            .task(id: session.user?.id) {
                guard let user = session.user else { return }
                for await mine in session.orders.courierOrders(courierID: user.id) {
                    hasActiveDelivery = mine.contains(where: \.status.isActive)
                }
            }
        }
    }
}

#Preview {
    AvailableOrdersView()
        .environment(AppSession.mock(signedInAs: MockData.courier))
        .environment(CourierRouter())
}
