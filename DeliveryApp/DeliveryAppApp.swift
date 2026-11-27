import SwiftUI

@main
struct DeliveryAppApp: App {
    @State private var session = AppSession.mock(signedInAs: Self.launchUser)

    /// Debug only: `-demoRole customer` or `-demoRole courier` starts signed in as that demo user,
    /// for screenshots and UI tests. Ignored in release builds.
    private static var launchUser: AppUser? {
        #if DEBUG
        switch UserDefaults.standard.string(forKey: "demoRole") {
        case "customer": MockData.customer
        case "courier": MockData.courier
        default: nil
        }
        #else
        nil
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
        }
    }
}
