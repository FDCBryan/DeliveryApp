import SwiftUI

/// Shows sign-in, or the tab set for the signed-in user's role.
struct RootView: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        Group {
            switch session.user?.role {
            case nil: AuthView()
            case .customer: CustomerTabView()
            case .courier: CourierTabView()
            }
        }
        .animation(.default, value: session.user?.id)
    }
}

#Preview("Signed out") {
    RootView().environment(AppSession.mock())
}
