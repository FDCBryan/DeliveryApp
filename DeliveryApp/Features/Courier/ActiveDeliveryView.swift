import SwiftUI

/// The courier's current delivery (at most one in v1). Status buttons come in M3.
struct ActiveDeliveryView: View {
    @Environment(AppSession.self) private var session
    @State private var active: Order?
    @State private var hasLoaded = false

    var body: some View {
        NavigationStack {
            Group {
                if let active {
                    OrderDetailView(orderID: active.id)
                } else if hasLoaded {
                    ContentUnavailableView("No active delivery", systemImage: "bicycle", description: Text("Accept an order from the Available tab."))
                        .navigationTitle("Active")
                } else {
                    ProgressView()
                }
            }
            .task(id: session.user?.id) {
                guard let user = session.user else { return }
                for await orders in session.orders.courierOrders(courierID: user.id) {
                    active = orders.first(where: \.status.isActive)
                    hasLoaded = true
                }
            }
        }
    }
}

struct DeliveryHistoryView: View {
    @Environment(AppSession.self) private var session
    @State private var orders: [Order] = []
    @State private var hasLoaded = false

    var body: some View {
        NavigationStack {
            List(orders) { order in
                NavigationLink(value: order.id) {
                    OrderRow(order: order, perspective: .courier)
                }
            }
            .overlay {
                if hasLoaded && orders.isEmpty {
                    ContentUnavailableView("No deliveries yet", systemImage: "clock")
                }
            }
            .navigationTitle("History")
            .navigationDestination(for: String.self) { OrderDetailView(orderID: $0) }
            .task(id: session.user?.id) {
                guard let user = session.user else { return }
                for await value in session.orders.courierOrders(courierID: user.id) {
                    orders = value.filter { !$0.status.isActive }
                    hasLoaded = true
                }
            }
        }
    }
}

#Preview {
    DeliveryHistoryView().environment(AppSession.mock(signedInAs: MockData.courier))
}
