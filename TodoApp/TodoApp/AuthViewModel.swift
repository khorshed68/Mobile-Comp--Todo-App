import Foundation

// Login kora user er info (app bondho korleo save thake)
struct AuthUser: Codable {
    let uid: String
    let email: String
    var idToken: String
    var refreshToken: String
    var expiresAt: Date
}

// Firebase Authentication (Email + Password) — REST API
final class AuthViewModel: ObservableObject {
    @Published var user: AuthUser?
    @Published var errorMessage: String?
    @Published var isLoading = false

    private let storageKey = "savedAuthUser"

    init() {
        // Age login kora thakle abar login korte hobe na
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode(AuthUser.self, from: data) {
            user = saved
        }
    }

    func signUp(email: String, password: String) {
        Task { await authenticate(endpoint: "signUp", email: email, password: password) }
    }

    func signIn(email: String, password: String) {
        Task { await authenticate(endpoint: "signInWithPassword", email: email, password: password) }
    }

    func signOut() {
        setUser(nil)
    }

    @MainActor
    private func authenticate(endpoint: String, email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let url = "https://identitytoolkit.googleapis.com/v1/accounts:\(endpoint)?key=\(FirebaseConfig.apiKey)"
            let result = try await FirebaseREST.send("POST", url, json: [
                "email": email,
                "password": password,
                "returnSecureToken": true
            ])
            let expiresIn = Double(result["expiresIn"] as? String ?? "3600") ?? 3600
            setUser(AuthUser(
                uid: result["localId"] as? String ?? "",
                email: result["email"] as? String ?? email,
                idToken: result["idToken"] as? String ?? "",
                refreshToken: result["refreshToken"] as? String ?? "",
                expiresAt: Date().addingTimeInterval(expiresIn - 60)
            ))
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // Firestore er jonno valid ID token. 1 ghonta por expire hoy, tokhon refresh kori.
    @MainActor
    func validToken() async throws -> String {
        guard var current = user else {
            throw FirebaseError(message: "Not logged in")
        }
        if Date() < current.expiresAt {
            return current.idToken
        }
        let url = "https://securetoken.googleapis.com/v1/token?key=\(FirebaseConfig.apiKey)"
        let result = try await FirebaseREST.send(
            "POST", url,
            form: "grant_type=refresh_token&refresh_token=\(current.refreshToken)"
        )
        let expiresIn = Double(result["expires_in"] as? String ?? "3600") ?? 3600
        current.idToken = result["id_token"] as? String ?? ""
        current.refreshToken = result["refresh_token"] as? String ?? current.refreshToken
        current.expiresAt = Date().addingTimeInterval(expiresIn - 60)
        setUser(current)
        return current.idToken
    }

    private func setUser(_ newUser: AuthUser?) {
        user = newUser
        if let newUser = newUser, let data = try? JSONEncoder().encode(newUser) {
            UserDefaults.standard.set(data, forKey: storageKey)
        } else {
            UserDefaults.standard.removeObject(forKey: storageKey)
        }
    }
}
