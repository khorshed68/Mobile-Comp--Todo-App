import Foundation

// Cloud Firestore CRUD — REST API
// Firestore path: users/{userId}/tasks/{taskId}
final class TaskViewModel: ObservableObject {
    @Published var tasks: [TodoTask] = []
    @Published var errorMessage: String?
    @Published var isLoading = false

    private let userId: String
    private let auth: AuthViewModel

    init(userId: String, auth: AuthViewModel) {
        self.userId = userId
        self.auth = auth
    }

    private var tasksURL: String {
        "https://firestore.googleapis.com/v1/projects/\(FirebaseConfig.projectId)"
            + "/databases/(default)/documents/users/\(userId)/tasks"
    }

    // READ: Firestore theke sob task ane (notun task upore)
    @MainActor
    func loadTasks() async {
        isLoading = true
        do {
            let token = try await auth.validToken()
            let result = try await FirebaseREST.send("GET", tasksURL + "?pageSize=300", token: token)
            let documents = result["documents"] as? [[String: Any]] ?? []
            tasks = documents
                .compactMap { TodoTask(json: $0) }
                .sorted { $0.createdAt > $1.createdAt }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // CREATE
    func addTask(title: String, description: String) {
        perform { token in
            _ = try await FirebaseREST.send("POST", self.tasksURL, token: token, json: [
                "fields": [
                    "title": ["stringValue": title],
                    "description": ["stringValue": description],
                    "isDone": ["booleanValue": false],
                    "createdAt": ["timestampValue": TodoTask.isoFormatter.string(from: Date())]
                ]
            ])
        }
    }

    // UPDATE (title + description)
    func updateTask(_ task: TodoTask, title: String, description: String) {
        perform { token in
            let url = "\(self.tasksURL)/\(task.id)"
                + "?updateMask.fieldPaths=title&updateMask.fieldPaths=description"
            _ = try await FirebaseREST.send("PATCH", url, token: token, json: [
                "fields": [
                    "title": ["stringValue": title],
                    "description": ["stringValue": description]
                ]
            ])
        }
    }

    // UPDATE (done / not done)
    func toggleDone(_ task: TodoTask) {
        perform { token in
            let url = "\(self.tasksURL)/\(task.id)?updateMask.fieldPaths=isDone"
            _ = try await FirebaseREST.send("PATCH", url, token: token, json: [
                "fields": [
                    "isDone": ["booleanValue": !task.isDone]
                ]
            ])
        }
    }

    // DELETE
    func deleteTask(_ task: TodoTask) {
        perform { token in
            _ = try await FirebaseREST.send("DELETE", "\(self.tasksURL)/\(task.id)", token: token)
        }
    }

    // Kaj ta kore, tarpor list abar load kore
    private func perform(_ operation: @escaping (String) async throws -> Void) {
        Task { @MainActor in
            do {
                let token = try await self.auth.validToken()
                try await operation(token)
            } catch {
                self.errorMessage = error.localizedDescription
            }
            await self.loadTasks()
        }
    }
}
