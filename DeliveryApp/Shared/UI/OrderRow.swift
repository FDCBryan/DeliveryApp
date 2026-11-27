import SwiftUI

struct OrderRow: View {
    enum Perspective { case customer, courier }

    let order: Order
    let perspective: Perspective

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(order.storeName).font(.headline)
                Spacer()
                StatusBadge(status: order.status)
            }
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            HStack {
                Text("\(order.itemCount) item\(order.itemCount == 1 ? "" : "s") · \(Money.format(order.total))")
                Spacer()
                Text(order.createdAt, format: .relative(presentation: .named))
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    private var detail: String {
        switch perspective {
        case .customer: order.items.map { "\($0.quantity)× \($0.name)" }.joined(separator: ", ")
        case .courier: "Drop-off: \(order.deliveryAddress.line)"
        }
    }
}
