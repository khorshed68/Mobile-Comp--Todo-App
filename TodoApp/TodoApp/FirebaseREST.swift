import Foundation

// Firebase SDK chara, direct Firebase REST API diye kaj kori.
// (Xcode 14.1 beta te FirebaseAuth SDK build hoy na — GameKit bug)

struct FirebaseError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

// GoogleService-Info.plist theke API_KEY ar PROJECT_ID pori
enum FirebaseConfig {
    static let values: [String: Any] = {
        guard let url = Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil),
              let dict = plist as? [String: Any]
        else {
            fatalError("GoogleService-Info.plist pawa jay nai. File ta TodoApp target e add koro.")
        }
        return dict
    }()

    static var apiKey: String { values["API_KEY"] as? String ?? "" }
    static var projectId: String { values["PROJECT_ID"] as? String ?? "" }
}

enum FirebaseREST {
    // Ekta HTTP request pathay, JSON response dictionary hisebe ferot dey
    static func send(_ method: String,
                     _ urlString: String,
                     token: String? = nil,
                     json: [String: Any]? = nil,
                     form: String? = nil) async throws -> [String: Any] {
        guard let url = URL(string: urlString) else {
            throw FirebaseError(message: "Invalid URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        if let bundleId = Bundle.main.bundleIdentifier {
            request.setValue(bundleId, forHTTPHeaderField: "X-Ios-Bundle-Identifier")
        }
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let json = json {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: json)
        }
        if let form = form {
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.httpBody = form.data(using: .utf8)
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0

        if !(200...299).contains(status) {
            let error = object["error"] as? [String: Any]
            let message = error?["message"] as? String ?? "HTTP error \(status)"
            throw FirebaseError(message: friendly(message))
        }
        return object
    }

    // Firebase er error code ke shohoj message e convert kori
    static func friendly(_ code: String) -> String {
        if code.hasPrefix("EMAIL_EXISTS") { return "This email is already registered. Please login." }
        if code.hasPrefix("EMAIL_NOT_FOUND") { return "No account with this email. Please sign up." }
        if code.hasPrefix("INVALID_PASSWORD") { return "Wrong password." }
        if code.hasPrefix("INVALID_LOGIN_CREDENTIALS") { return "Wrong email or password." }
        if code.hasPrefix("INVALID_EMAIL") { return "Invalid email address." }
        if code.hasPrefix("WEAK_PASSWORD") { return "Password must be at least 6 characters." }
        if code.hasPrefix("OPERATION_NOT_ALLOWED") { return "Enable Email/Password in Firebase Authentication." }
        if code.hasPrefix("TOO_MANY_ATTEMPTS") { return "Too many attempts. Try again later." }
        return code
    }
}
