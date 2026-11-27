import Foundation

/// Mock auth for M1. Keeps accounts in memory only; passwords here are fake demo values.
final class InMemoryAuthRepository: AuthRepository {
    private struct Account {
        let password: String
        let user: AppUser
    }

    private var accounts: [String: Account] = [:]
    private let makeID: () -> String
    private(set) var currentUser: AppUser?

    init(seed: [(email: String, password: String, user: AppUser)] = [], makeID: @escaping () -> String = { UUID().uuidString }) {
        self.makeID = makeID
        for entry in seed {
            accounts[Self.key(entry.email)] = Account(password: entry.password, user: entry.user)
        }
    }

    func signIn(email: String, password: String) async throws -> AppUser {
        guard let account = accounts[Self.key(email)], account.password == password else {
            throw AuthError.invalidCredentials
        }
        currentUser = account.user
        return account.user
    }

    func signUp(name: String, phone: String, email: String, password: String, role: UserRole) async throws -> AppUser {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let phone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        let key = Self.key(email)
        guard !name.isEmpty else { throw AuthError.missingField("name") }
        guard !phone.isEmpty else { throw AuthError.missingField("phone number") }
        guard key.contains("@") else { throw AuthError.missingField("email") }
        guard password.count >= 8 else { throw AuthError.weakPassword }
        guard accounts[key] == nil else { throw AuthError.emailInUse }

        let user = AppUser(id: makeID(), role: role, name: name, phone: phone)
        accounts[key] = Account(password: password, user: user)
        currentUser = user
        return user
    }

    func signOut() throws {
        currentUser = nil
    }

    private static func key(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
