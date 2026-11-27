import SwiftUI

/// Cart and checkout in one sheet: adjust quantities, enter the delivery address,
/// review the total, and place the order (cash on delivery in v1).
struct CartView: View {
    @Environment(AppSession.self) private var session
    @Environment(CustomerRouter.self) private var router
    @Environment(\.dismiss) private var dismiss

    @State private var addressLine = ""
    @State private var note = ""
    @State private var isPlacing = false
    @State private var errorMessage: String?
    @State private var isConfirmingClear = false
    @FocusState private var focusedField: Field?

    private enum Field { case address, note }

    private var trimmedAddress: String {
        addressLine.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Group {
                if session.cart.isEmpty {
                    ContentUnavailableView(
                        "Your cart is empty",
                        systemImage: "cart",
                        description: Text("Add items from a store's menu.")
                    )
                } else {
                    form
                }
            }
            .navigationTitle("Your cart")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                if !session.cart.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Clear", role: .destructive) { isConfirmingClear = true }
                    }
                }
            }
            .confirmationDialog("Remove everything from your cart?", isPresented: $isConfirmingClear, titleVisibility: .visible) {
                Button("Clear cart", role: .destructive) { session.cart.clear() }
            }
            .onAppear {
                if addressLine.isEmpty, let last = session.lastDeliveryAddress {
                    addressLine = last.line
                    note = last.note ?? ""
                }
            }
        }
    }

    private var form: some View {
        let cart = session.cart
        return List {
            if let store = cart.store {
                Section {
                    HStack(spacing: 12) {
                        StoreLogo(store: store, size: 40)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(store.name).font(.headline)
                            // HStack rather than Label: inside a List row, Label pads its icon into a wide column.
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                Text(store.deliveryTimeText)
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Items") {
                ForEach(cart.lines) { line in
                    CartLineRow(line: line) { quantity in
                        withAnimation { session.cart.setQuantity(quantity, for: line.id) }
                    }
                }
            }

            Section {
                TextField("Street, building, unit", text: $addressLine, axis: .vertical)
                    .textContentType(.fullStreetAddress)
                    .lineLimit(1...3)
                    .focused($focusedField, equals: .address)
                TextField("Note for the courier (optional)", text: $note, axis: .vertical)
                    .lineLimit(1...3)
                    .focused($focusedField, equals: .note)
            } header: {
                Text("Deliver to")
            } footer: {
                if trimmedAddress.isEmpty {
                    Text("Enter where the courier should bring your order.")
                }
            }

            Section("Payment") {
                Label("Cash on delivery", systemImage: "banknote")
            }

            Section {
                LabeledContent("Subtotal", value: Money.format(cart.subtotal))
                LabeledContent("Delivery fee", value: cart.deliveryFee == 0 ? "Free" : Money.format(cart.deliveryFee))
                LabeledContent {
                    Text(Money.format(cart.total)).bold()
                } label: {
                    Text("Total").bold()
                }
            }
            .monospacedDigit()

            if let errorMessage {
                Section {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(Brand.red)
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) { placeOrderButton(total: cart.total) }
    }

    private func placeOrderButton(total: Int) -> some View {
        Button(action: placeOrder) {
            HStack {
                if isPlacing {
                    ProgressView().tint(.white)
                } else {
                    Text("Place order")
                }
                Spacer()
                Text(Money.format(total)).monospacedDigit()
            }
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Brand.red.opacity(canPlace ? 1 : 0.4), in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!canPlace)
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.bar)
    }

    private var canPlace: Bool {
        !isPlacing && !trimmedAddress.isEmpty && !session.cart.isEmpty
    }

    private func placeOrder() {
        guard canPlace else { return }
        focusedField = nil
        isPlacing = true
        errorMessage = nil
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let address = Address(line: trimmedAddress, note: trimmedNote.isEmpty ? nil : trimmedNote)
        Task {
            defer { isPlacing = false }
            do {
                let order = try await session.checkout(deliveryAddress: address)
                router.showOrder(order.id)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

private struct CartLineRow: View {
    let line: CartLine
    let setQuantity: (Int) -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(line.item.name)
                    .font(.subheadline.weight(.semibold))
                Text(Money.format(line.item.price))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Spacer()
            QuantityStepper(quantity: line.quantity, setQuantity: setQuantity)
            Text(Money.format(line.lineTotal))
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .frame(minWidth: 64, alignment: .trailing)
        }
    }
}

/// − quantity + control; at 1 the minus becomes a trash button that removes the line.
private struct QuantityStepper: View {
    let quantity: Int
    let setQuantity: (Int) -> Void

    var body: some View {
        HStack(spacing: 0) {
            button(systemImage: quantity == 1 ? "trash" : "minus",
                   label: quantity == 1 ? "Remove" : "Decrease") { setQuantity(quantity - 1) }
            Text("\(quantity)")
                .font(.subheadline.weight(.bold))
                .monospacedDigit()
                .frame(minWidth: 24)
                .accessibilityLabel("Quantity \(quantity)")
            button(systemImage: "plus", label: "Increase") { setQuantity(quantity + 1) }
                .disabled(quantity >= Cart.maxQuantity)
        }
        .padding(2)
        .background(Brand.yellow.opacity(0.2), in: Capsule())
    }

    private func button(systemImage: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(Brand.red)
                .frame(width: 30, height: 30)
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(label)
    }
}

#Preview {
    let session = AppSession.mock(signedInAs: MockData.customer)
    session.cart.add(MockData.menuItems[0], from: MockData.stores[0])
    session.cart.add(MockData.menuItems[3], from: MockData.stores[0])
    return CartView()
        .environment(session)
        .environment(CustomerRouter())
}
