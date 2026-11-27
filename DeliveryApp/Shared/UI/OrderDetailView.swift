import SwiftUI

/// Live view of one order, shared by both roles. Customers can cancel while it's
/// still placed; courier actions (accept, picked up, delivered) arrive in M3.
struct OrderDetailView: View {
    let orderID: String

    @Environment(AppSession.self) private var session
    @State private var order: Order?
    @State private var hasLoaded = false
    @State private var isConfirmingCancel = false
    @State private var isCancelling = false
    @State private var actionError: String?

    var body: some View {
        Group {
            if let order {
                content(order)
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
        .alert("Couldn't cancel", isPresented: Binding(get: { actionError != nil }, set: { if !$0 { actionError = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(actionError ?? "")
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
                LabeledContent("Pick up", value: "\(order.storeName), \(order.storeAddress.line)")
                LabeledContent("Drop off", value: order.deliveryAddress.line)
                if let note = order.deliveryAddress.note {
                    LabeledContent("Note", value: note)
                }
                LabeledContent("Payment", value: "Cash on delivery")
            }

            Section("Contact") {
                if isCustomerView {
                    if let courierName = order.courierName {
                        contactRow(title: "Courier", name: courierName, phone: order.courierPhone)
                    } else {
                        LabeledContent("Courier", value: order.status == .cancelled ? "None" : "Waiting for a courier…")
                    }
                } else {
                    contactRow(title: "Customer", name: order.customerName, phone: order.customerPhone)
                }
            }

            if canCancel(order) {
                Section {
                    Button(role: .destructive) {
                        isConfirmingCancel = true
                    } label: {
                        HStack {
                            Text("Cancel order")
                            if isCancelling {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isCancelling)
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

extension OrderDetailView {
    private var isCustomerView: Bool { session.user?.role != .courier }

    private func canCancel(_ order: Order) -> Bool {
        guard let user = session.user, user.id == order.customerID else { return false }
        return order.status.canTransition(to: .cancelled, by: user.role)
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

    private func cancel() {
        isCancelling = true
        Task {
            defer { isCancelling = false }
            do {
                try await session.cancelOrder(id: orderID)
            } catch {
                actionError = error.localizedDescription
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

#Preview {
    NavigationStack {
        OrderDetailView(orderID: "order-1001")
    }
    .environment(AppSession.mock(signedInAs: MockData.customer))
}
