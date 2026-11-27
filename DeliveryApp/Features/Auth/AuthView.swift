import SwiftUI

struct AuthView: View {
    private enum Mode: String, CaseIterable {
        case signIn = "Sign in"
        case signUp = "Create account"
    }

    @Environment(AppSession.self) private var session
    @State private var mode = Mode.signIn
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var phone = ""
    @State private var role = UserRole.customer
    @State private var isWorking = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Picker("Mode", selection: $mode) {
                    ForEach(Mode.allCases, id: \.self) { Text($0.rawValue) }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)

                if mode == .signUp {
                    Section("I want to") {
                        Picker("Role", selection: $role) {
                            Text("Order food").tag(UserRole.customer)
                            Text("Deliver orders").tag(UserRole.courier)
                        }
                        .pickerStyle(.inline)
                        .labelsHidden()
                    }
                    Section("About you") {
                        TextField("Name", text: $name)
                            .textContentType(.name)
                        TextField("Phone", text: $phone)
                            .textContentType(.telephoneNumber)
                            .keyboardType(.phonePad)
                    }
                }

                Section("Account") {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("Password", text: $password)
                        .textContentType(mode == .signIn ? .password : .newPassword)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }

                Section {
                    Button(mode.rawValue, action: submit)
                        .frame(maxWidth: .infinity)
                        .disabled(isWorking)
                }

                #if DEBUG
                Section {
                    Button("Sign in as demo customer") { demoSignIn(MockData.accounts[0].email) }
                    Button("Sign in as demo courier") { demoSignIn(MockData.accounts[1].email) }
                } header: {
                    Text("Demo")
                } footer: {
                    Text("Sample accounts from the in-memory mock backend.")
                }
                #endif
            }
            .navigationTitle("DeliveryApp")
            .onChange(of: mode) { errorMessage = nil }
        }
    }

    private func submit() {
        run {
            switch mode {
            case .signIn:
                try await session.signIn(email: email, password: password)
            case .signUp:
                try await session.signUp(name: name, phone: phone, email: email, password: password, role: role)
            }
        }
    }

    #if DEBUG
    private func demoSignIn(_ demoEmail: String) {
        run { try await session.signIn(email: demoEmail, password: MockData.demoPassword) }
    }
    #endif

    private func run(_ action: @escaping () async throws -> Void) {
        isWorking = true
        errorMessage = nil
        Task {
            defer { isWorking = false }
            do { try await action() } catch { errorMessage = error.localizedDescription }
        }
    }
}

#Preview {
    AuthView().environment(AppSession.mock())
}
