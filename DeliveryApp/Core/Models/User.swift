import Foundation

nonisolated enum UserRole: String, Codable, CaseIterable, Sendable {
    case customer
    case courier

    var title: String {
        switch self {
        case .customer: "Customer"
        case .courier: "Courier"
        }
    }
}

nonisolated struct AppUser: Identifiable, Codable, Hashable, Sendable {
    let id: String
    /// Fixed at sign-up; the backend rules must reject later changes.
    let role: UserRole
    var name: String
    var phone: String
}
