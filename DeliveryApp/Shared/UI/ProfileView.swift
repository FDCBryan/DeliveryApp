import SwiftUI

struct ProfileView: View {
    @Environment(AppSession.self) private var session

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
                Section {
                    Button("Sign out", role: .destructive) { session.signOut() }
                }
            }
            .navigationTitle("Profile")
        }
    }
}
