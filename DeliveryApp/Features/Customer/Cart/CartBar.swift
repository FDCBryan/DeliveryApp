import SwiftUI

/// Floating "View cart" button shown above the tab bar whenever the cart has items.
struct CartBar: View {
    @Environment(AppSession.self) private var session
    @Environment(CustomerRouter.self) private var router

    var body: some View {
        let cart = session.cart
        if !cart.isEmpty {
            Button {
                router.isCartPresented = true
            } label: {
                HStack(spacing: 12) {
                    Text("\(cart.itemCount)")
                        .font(.subheadline.weight(.heavy))
                        .monospacedDigit()
                        .foregroundStyle(Brand.red)
                        .frame(minWidth: 28, minHeight: 28)
                        .background(Brand.yellow, in: Circle())
                    VStack(alignment: .leading, spacing: 0) {
                        Text("View cart")
                            .font(.headline)
                        if let store = cart.store {
                            Text(store.name)
                                .font(.caption)
                                .opacity(0.85)
                        }
                    }
                    Spacer()
                    Text(Money.format(cart.subtotal))
                        .font(.headline)
                        .monospacedDigit()
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Brand.red, in: Capsule())
                .shadow(color: .black.opacity(0.2), radius: 6, y: 3)
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
            .padding(.bottom, 8)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .accessibilityLabel("View cart, \(cart.itemCount) items, \(Money.format(cart.subtotal))")
        }
    }
}
