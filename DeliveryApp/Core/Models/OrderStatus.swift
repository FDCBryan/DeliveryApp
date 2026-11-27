import Foundation

/// placed → accepted → pickedUp → delivered, and placed → cancelled (customer only).
/// The Firestore security rules (M4) must enforce this same table.
nonisolated enum OrderStatus: String, Codable, CaseIterable, Sendable {
    case placed
    case accepted
    case pickedUp
    case delivered
    case cancelled

    var title: String {
        switch self {
        case .placed: "Placed"
        case .accepted: "Courier assigned"
        case .pickedUp: "Picked up"
        case .delivered: "Delivered"
        case .cancelled: "Cancelled"
        }
    }

    /// Still in progress: not delivered and not cancelled.
    var isActive: Bool {
        switch self {
        case .placed, .accepted, .pickedUp: true
        case .delivered, .cancelled: false
        }
    }

    /// The happy-path steps shown in a status timeline.
    static let progression: [OrderStatus] = [.placed, .accepted, .pickedUp, .delivered]

    func canTransition(to next: OrderStatus, by role: UserRole) -> Bool {
        switch (self, next, role) {
        case (.placed, .accepted, .courier),
             (.accepted, .pickedUp, .courier),
             (.pickedUp, .delivered, .courier),
             (.placed, .cancelled, .customer):
            true
        default:
            false
        }
    }
}
