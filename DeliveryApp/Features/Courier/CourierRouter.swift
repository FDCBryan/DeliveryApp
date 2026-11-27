import Observation

/// Courier-side navigation shared across tabs.
@Observable
final class CourierRouter {
    enum Tab: Hashable {
        case available, active, history, profile
    }

    var tab = Tab.available
    var availablePath: [String] = []

    /// After accepting: leave the Available list and show the delivery.
    func showActiveDelivery() {
        availablePath = []
        tab = .active
    }
}
