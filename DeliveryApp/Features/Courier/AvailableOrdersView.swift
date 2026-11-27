import SwiftUI

/// Orders from every store that no courier has taken yet. Accepting comes in M3.
struct AvailableOrdersView: View {
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
                    ContentUnavailableView("No orders waiting", systemImage: "tray", description: Text("New orders appear here as customers place them."))
                }
            }
            .navigationTitle("Available")
            .navigationDestination(for: String.self) { OrderDetailView(orderID: $0) }
            .task {
                for await value in session.orders.availableOrders() {
                    orders = value
                    hasLoaded = true
                }
            }
        }
    }
}

#Preview {
    AvailableOrdersView().environment(AppSession.mock(signedInAs: MockData.courier))
}
