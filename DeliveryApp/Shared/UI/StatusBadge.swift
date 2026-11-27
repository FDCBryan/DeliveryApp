import SwiftUI

struct StatusBadge: View {
    let status: OrderStatus

    var body: some View {
        Text(status.title)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }

    private var color: Color {
        switch status {
        case .placed: .orange
        case .accepted, .pickedUp: .blue
        case .delivered: .green
        case .cancelled: .secondary
        }
    }
}
