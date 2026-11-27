import Testing
@testable import DeliveryApp

struct InMemoryAuthRepositoryTests {
    let auth = InMemoryAuthRepository(seed: [("demo@test.dev", "password-1", Fixture.customer)], makeID: { "new-user" })

    @Test func signInIsCaseInsensitiveOnEmail() async throws {
        let user = try await auth.signIn(email: "  Demo@Test.dev ", password: "password-1")
        #expect(user == Fixture.customer)
        #expect(auth.currentUser == Fixture.customer)
    }

    @Test func wrongPasswordFails() async {
        await #expect(throws: AuthError.invalidCredentials) {
            try await auth.signIn(email: "demo@test.dev", password: "nope")
        }
    }

    @Test func signUpCreatesUserWithChosenRole() async throws {
        let user = try await auth.signUp(name: " Dee ", phone: "555", email: "dee@test.dev", password: "password-2", role: .courier)
        #expect(user == AppUser(id: "new-user", role: .courier, name: "Dee", phone: "555"))
        let again = try await auth.signIn(email: "dee@test.dev", password: "password-2")
        #expect(again.role == .courier)
    }

    @Test func signUpRejectsDuplicateEmail() async {
        await #expect(throws: AuthError.emailInUse) {
            try await auth.signUp(name: "X", phone: "1", email: "DEMO@test.dev", password: "password-3", role: .customer)
        }
    }

    @Test func signUpRejectsShortPassword() async {
        await #expect(throws: AuthError.weakPassword) {
            try await auth.signUp(name: "X", phone: "1", email: "x@test.dev", password: "short", role: .customer)
        }
    }

    @Test func signOutClearsUser() async throws {
        _ = try await auth.signIn(email: "demo@test.dev", password: "password-1")
        try auth.signOut()
        #expect(auth.currentUser == nil)
    }
}
