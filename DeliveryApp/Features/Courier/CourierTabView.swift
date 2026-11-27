import SwiftUI

struct CourierTabView: View {
    var body: some View {
        TabView {
            AvailableOrdersView()
                .tabItem { Label("Available", systemImage: "tray.full") }
            ActiveDeliveryView()
                .tabItem { Label("Active", systemImage: "bicycle") }
            DeliveryHistoryView()
                .tabItem { Label("History", systemImage: "clock") }
            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
        }
    }
}

#Preview {
    CourierTabView().environment(AppSession.mock(signedInAs: MockData.courier))
}
