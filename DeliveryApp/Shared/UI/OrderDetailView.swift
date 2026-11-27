import SwiftUI

/// Live view of one order, shared by both roles.
/// Customers can cancel while it's still placed. Couriers get one action button at the
/// bottom for their next step: accept, then picked up, then delivered.
struct OrderDetailView: View {
    let orderID: String
    /// Called after this courier accepts the order (e.g. to switch to the Active tab).
    var onAccepted: (() -> Void)?

    @Environment(AppSession.self) private var session
    @State private var order: Order?
    @State private var hasLoaded = false
    @State private var isConfirmingCancel = false
    @State private var isConfirmingDelivery = false
    @State private var isWorking = false
    @State private var actionAlert: ActionAlert?

    private struct ActionAlert: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }

    var body: some View {
        Group {
            if let order {
                content(order)
                    .safeAreaInset(edge: .bottom) { courierActionBar(order) }
            } else if hasLoaded {
                ContentUnavailableView("Order not found", systemImage: "questionmark.folder")
            } else {
                ProgressView()
            }
        }
        .navigationTitle(order?.storeName ?? "Order")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: orderID) {
            for await value in session.orders.order(id: orderID) {
                order = value
                hasLoaded = true
            }
        }
        .confirmationDialog("Cancel this order?", isPresented: $isConfirmingCancel, titleVisibility: .visible) {
            Button("Cancel order", role: .destructive, action: cancel)
            Button("Keep order", role: .cancel) {}
        } message: {
            Text("You can cancel until a courier accepts it.")
        }
        .confirmationDialog("Complete delivery?", isPresented: $isConfirmingDelivery, titleVisibility: .visible) {
            Button("Cash collected, mark delivered") { advance(to: .delivered) }
            Button("Not yet", role: .cancel) {}
        } message: {
            if let order {
                Text("Collect \(Money.format(order.total)) in cash from \(order.customerName) before confirming.")
            }
        }
        .alert(
            actionAlert?.title ?? "",
            isPresented: Binding(get: { actionAlert != nil }, set: { if !$0 { actionAlert = nil } }),
            presenting: actionAlert
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { alert in
            Text(alert.message)
        }
    }

    private func content(_ order: Order) -> some View {
        List {
            Section("Status") {
                StatusTimeline(status: order.status)
            }

            Section("Items") {
                ForEach(order.items, id: \.menuItemID) { item in
                    HStack {
                        Text("\(item.quantity)×")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                        Text(item.name)
                        Spacer()
                        Text(Money.format(item.lineTotal)).monospacedDigit()
                    }
                }
                LabeledContent("Subtotal", value: Money.format(order.subtotal))
                LabeledContent("Delivery fee", value: Money.format(order.deliveryFee))
                LabeledContent("Total") {
                    Text(Money.format(order.total)).bold()
                }
            }

            Section("Delivery") {
                addressRow(title: "Pick up", detail: "\(order.storeName), \(order.storeAddress.line)", mapsQuery: order.storeAddress.line)
                addressRow(title: "Drop off", detail: order.deliveryAddress.line, mapsQuery: order.deliveryAddress.line)
                if let note = order.deliveryAddress.note {
                    LabeledContent("Note", value: note)
                }
                LabeledContent("Payment", value: "Cash on delivery")
            }

            Section("Contact") {
                if isCourierView {
                    if order.courierID == session.user?.id {
                        contactRow(title: "Customer", name: order.customerName, phone: order.customerPhone)
                    } else {
                        LabeledContent("Customer", value: "Shown after you accept")
                    }
                } else if let courierName = order.courierName {
                    contactRow(title: "Courier", name: courierName, phone: order.courierPhone)
                } else {
                    LabeledContent("Courier", value: order.status == .cancelled ? "None" : "Waiting for a courier…")
                }
            }

            if canCancel(order) {
                Section {
                    Button(role: .destructive) {
                        isConfirmingCancel = true
                    } label: {
                        HStack {
                            Text("Cancel order")
                            if isWorking {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isWorking)
                } footer: {
                    Text("You can cancel until a courier accepts the order.")
                }
            }

            Section {
                LabeledContent("Order", value: order.id)
                LabeledContent("Placed") {
                    Text(order.createdAt, format: .dateTime.month().day().hour().minute())
                }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Courier actions

extension OrderDetailView {
    private var isCourierView: Bool { session.user?.role == .courier }

    private func nextStep(for order: Order) -> OrderStatus? {
        guard let user = session.user, user.role == .courier else { return nil }
        return order.nextCourierStep(for: user.id)
    }

    @ViewBuilder
    private func courierActionBar(_ order: Order) -> some View {
        if let step = nextStep(for: order) {
            Button {
                switch step {
                case .accepted: accept()
                case .delivered: isConfirmingDelivery = true
                default: advance(to: step)
                }
            } label: {
                HStack {
                    if isWorking {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: Self.symbol(for: step))
                    }
                    Text(Self.title(for: step))
                    Spacer()
                    if step == .delivered {
                        Text(Money.format(order.total)).monospacedDigit()
                    }
                }
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(Brand.red, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(isWorking)
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(.bar)
        }
    }

    private static func title(for step: OrderStatus) -> String {
        switch step {
        case .accepted: "Accept order"
        case .pickedUp: "Picked up from store"
        case .delivered: "Delivered"
        default: step.title
        }
    }

    private static func symbol(for step: OrderStatus) -> String {
        switch step {
        case .accepted: "hand.raised.fill"
        case .pickedUp: "bag.fill"
        case .delivered: "checkmark.seal.fill"
        default: "arrow.right"
        }
    }

    private func accept() {
        run(failureTitle: "Couldn't accept") {
            _ = try await session.acceptOrder(id: orderID)
            onAccepted?()
        }
    }

    private func advance(to status: OrderStatus) {
        run(failureTitle: "Couldn't update the order") {
            _ = try await session.advanceDelivery(id: orderID, to: status)
        }
    }
}

// MARK: - Customer actions and shared helpers

extension OrderDetailView {
    private func canCancel(_ order: Order) -> Bool {
        guard let user = session.user, user.id == order.customerID else { return false }
        return order.status.canTransition(to: .cancelled, by: user.role)
    }

    private func cancel() {
        run(failureTitle: "Couldn't cancel") {
            try await session.cancelOrder(id: orderID)
        }
    }

    private func run(failureTitle: String, _ action: @escaping () async throws -> Void) {
        guard !isWorking else { return }
        isWorking = true
        Task {
            defer { isWorking = false }
            do {
                try await action()
            } catch {
                actionAlert = ActionAlert(title: failureTitle, message: error.localizedDescription)
            }
        }
    }

    private func addressRow(title: String, detail: String, mapsQuery: String) -> some View {
        LabeledContent(title) {
            VStack(alignment: .trailing, spacing: 4) {
                Text(detail)
                    .multilineTextAlignment(.trailing)
                if isCourierView, let url = Self.mapsURL(for: mapsQuery) {
                    Link(destination: url) {
                        Label("Directions", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Brand.red)
                    }
                }
            }
        }
    }

    private static func mapsURL(for address: String) -> URL? {
        var components = URLComponents(string: "https://maps.apple.com/")
        components?.queryItems = [URLQueryItem(name: "daddr", value: address)]
        return components?.url
    }

    private func contactRow(title: String, name: String, phone: String?) -> some View {
        LabeledContent(title) {
            HStack(spacing: 12) {
                Text(name)
                if let phone, let url = URL(string: "tel:\(phone.filter { $0.isNumber || $0 == "+" })") {
                    Link(destination: url) {
                        Image(systemName: "phone.fill")
                            .foregroundStyle(.white)
                            .frame(width: 30, height: 30)
                            .background(Brand.red, in: Circle())
                    }
                    .accessibilityLabel("Call \(name)")
                }
            }
        }
    }
}

struct StatusTimeline: View {
    let status: OrderStatus

    var body: some View {
        if status == .cancelled {
            Label("This order was cancelled", systemImage: "xmark.circle")
                .foregroundStyle(.secondary)
        } else {
            let current = OrderStatus.progression.firstIndex(of: status) ?? 0
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(OrderStatus.progression.enumerated()), id: \.element) { index, step in
                    Label(step.title, systemImage: index <= current ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(index <= current ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                        .fontWeight(index == current ? .semibold : .regular)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

#Preview("Customer") {
    NavigationStack {
        OrderDetailView(orderID: "order-1001")
    }
    .environment(AppSession.mock(signedInAs: MockData.customer))
}

#Preview("Courier") {
    NavigationStack {
        OrderDetailView(orderID: "order-1002")
    }
    .environment(AppSession.mock(signedInAs: MockData.courier))
}
