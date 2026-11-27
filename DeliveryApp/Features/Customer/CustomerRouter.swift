import Observation

/// Customer-side navigation that more than one screen needs to drive:
/// the selected tab, the Orders stack, and the cart sheet.
@Observable
final class CustomerRouter {
    enum Tab: Hashable {
        case stores, orders, profile
    }

    var tab = Tab.stores
    var ordersPath: [String] = []
    var isCartPresented = false

    /// After checkout: close the cart and open the new order's tracking screen.
    func showOrder(_ orderID: String) {
        isCartPresented = false
        tab = .orders
        ordersPath = [orderID]
    }
}
