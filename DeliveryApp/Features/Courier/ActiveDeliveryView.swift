import SwiftUI

/// The courier's current delivery (at most one in v1), with its action button.
/// When it's delivered, shows a short completion screen.
struct ActiveDeliveryView: View {
    @Environment(AppSession.self) private var session
    @Environment(CourierRouter.self) private var router
    @State private var active: Order?
    @State private var justCompleted: Order?
    @State private var hasLoaded = false

    var body: some View {
        NavigationStack {
            Group {
                if let active {
                    OrderDetailView(orderID: active.id)
                } else if let justCompleted {
                    completion(justCompleted)
                } else if hasLoaded {
                    ContentUnavailableView {
                        Label("No active delivery", systemImage: "bicycle")
                    } description: {
                        Text("Accept an order from the Available tab.")
                    } actions: {
                        Button("See available orders") { router.tab = .available }
                            .buttonStyle(.borderedProminent)
                    }
                    .navigationTitle("Active")
                } else {
                    ProgressView()
                }
            }
            .task(id: session.user?.id) {
                guard let user = session.user else { return }
                for await orders in session.orders.courierOrders(courierID: user.id) {
                    let current = orders.first(where: \.status.isActive)
                    if let previous = active, current?.id != previous.id,
                       let finished = orders.first(where: { $0.id == previous.id }), finished.status == .delivered {
                        justCompleted = finished
                    }
                    if current != nil { justCompleted = nil }
                    active = current
                    hasLoaded = true
                }
            }
        }
    }

    private func completion(_ order: Order) -> some View {
        ContentUnavailableView {
            Label("Delivery complete", systemImage: "checkmark.seal.fill")
                .foregroundStyle(Brand.red)
        } description: {
            Text("Delivered \(order.storeName) order to \(order.customerName). Cash collected: \(Money.format(order.total)).")
        } actions: {
            Button("Find next order") {
                justCompleted = nil
                router.tab = .available
            }
            .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Active")
    }
}

/// Finished deliveries (delivered or cancelled), newest first, with a short summary.
struct DeliveryHistoryView: View {
    @Environment(AppSession.self) private var session
    @State private var orders: [Order] = []
    @State private var hasLoaded = false

    private var delivered: [Order] { orders.filter { $0.status == .delivered } }

    var body: some View {
        NavigationStack {
            List {
                if !delivered.isEmpty {
                    Section {
                        LabeledContent("Deliveries", value: "\(delivered.count)")
                        LabeledContent("Cash collected", value: Money.format(delivered.reduce(0) { $0 + $1.total }))
                        LabeledContent("Delivery fees", value: Money.format(delivered.reduce(0) { $0 + $1.deliveryFee }))
                    }
                    .monospacedDigit()
                }
                Section {
                    ForEach(orders) { order in
                        NavigationLink(value: order.id) {
                            OrderRow(order: order, perspective: .courier)
                        }
                    }
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
