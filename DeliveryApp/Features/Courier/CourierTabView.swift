import SwiftUI

struct CourierTabView: View {
    @Environment(AppSession.self) private var session
    @State private var router = CourierRouter()
    @State private var availableCount = 0

    var body: some View {
        TabView(selection: $router.tab) {
            AvailableOrdersView()
                .tabItem { Label("Available", systemImage: "tray.full") }
                .badge(availableCount)
                .tag(CourierRouter.Tab.available)
            ActiveDeliveryView()
                .tabItem { Label("Active", systemImage: "bicycle") }
                .tag(CourierRouter.Tab.active)
            DeliveryHistoryView()
                .tabItem { Label("History", systemImage: "clock") }
                .tag(CourierRouter.Tab.history)
            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                .tag(CourierRouter.Tab.profile)
        }
        .environment(router)
        .task {
            for await orders in session.orders.availableOrders() {
                availableCount = orders.count
            }
        }
    }
}

#Preview {
    CourierTabView().environment(AppSession.mock(signedInAs: MockData.courier))
}
