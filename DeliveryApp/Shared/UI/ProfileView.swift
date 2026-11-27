import SwiftUI

struct ProfileView: View {
    @Environment(AppSession.self) private var session
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                if let user = session.user {
                    Section {
                        LabeledContent("Name", value: user.name)
                        LabeledContent("Phone", value: user.phone)
                        LabeledContent("Role", value: user.role.title)
                    }
                }

                #if DEBUG
                if let user = session.user {
                    Section {
                        let other: UserRole = user.role == .customer ? .courier : .customer
                        Button("Switch to demo \(other.title.lowercased())") { switchDemo(to: other) }
                        if let errorMessage {
                            Text(errorMessage).foregroundStyle(Brand.red)
                        }
                    } header: {
                        Text("Demo")
                    } footer: {
                        Text("Signs in as the other sample account. Orders stay in memory while the app is running, so you can place an order as the customer and deliver it as the courier.")
                    }
                }
                #endif

                Section {
                    Button("Sign out", role: .destructive) { session.signOut() }
                }
            }
            .navigationTitle("Profile")
        }
    }

    #if DEBUG
    private func switchDemo(to role: UserRole) {
        guard let account = MockData.accounts.first(where: { $0.user.role == role }) else { return }
        session.signOut()
        Task {
            do {
                try await session.signIn(email: account.email, password: account.password)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    #endif
}
