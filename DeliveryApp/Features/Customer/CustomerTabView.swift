import SwiftUI

struct CustomerTabView: View {
    @State private var router = CustomerRouter()

    var body: some View {
        TabView(selection: $router.tab) {
            StoreListView()
                .tabItem { Label("Stores", systemImage: "storefront") }
                .tag(CustomerRouter.Tab.stores)
            MyOrdersView()
                .tabItem { Label("Orders", systemImage: "bag") }
                .tag(CustomerRouter.Tab.orders)
            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                .tag(CustomerRouter.Tab.profile)
        }
        .sheet(isPresented: $router.isCartPresented) {
            CartView()
                .environment(router)
        }
        .environment(router)
    }
}

#Preview {
    CustomerTabView().environment(AppSession.mock(signedInAs: MockData.customer))
}
