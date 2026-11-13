import Foundation

struct TodoTask: Identifiable {
    var id: String
    var title: String
    var description: String
    var isDone: Bool
    var createdAt: Date

    static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let isoFormatterNoFraction = ISO8601DateFormatter()

    // Firestore REST document JSON -> TodoTask
    init?(json: [String: Any]) {
        guard let name = json["name"] as? String,
              let fields = json["fields"] as? [String: Any],
              let titleField = fields["title"] as? [String: Any],
              let title = titleField["stringValue"] as? String
        else { return nil }

        let descriptionField = fields["description"] as? [String: Any]
        let isDoneField = fields["isDone"] as? [String: Any]
        let createdField = fields["createdAt"] as? [String: Any]
        let createdText = createdField?["timestampValue"] as? String ?? ""

        // name = "projects/.../tasks/{taskId}" — sesh ongsho tai id
        self.id = String(name.split(separator: "/").last ?? "")
        self.title = title
        self.description = descriptionField?["stringValue"] as? String ?? ""
        self.isDone = isDoneField?["booleanValue"] as? Bool ?? false
        self.createdAt = TodoTask.isoFormatter.date(from: createdText)
            ?? TodoTask.isoFormatterNoFraction.date(from: createdText)
            ?? Date.distantPast
    }
}
