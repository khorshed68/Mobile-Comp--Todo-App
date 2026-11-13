import SwiftUI

struct TaskListView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var taskVM: TaskViewModel

    @State private var showAddSheet = false
    @State private var editingTask: TodoTask?

    init(userId: String, authVM: AuthViewModel) {
        _taskVM = StateObject(wrappedValue: TaskViewModel(userId: userId, auth: authVM))
    }

    var body: some View {
        NavigationView {
            List {
                if taskVM.tasks.isEmpty && !taskVM.isLoading {
                    Text("No tasks yet. Tap + to add one.")
                        .foregroundColor(.secondary)
                }

                ForEach(taskVM.tasks) { task in
                    HStack(alignment: .top, spacing: 12) {
                        // Tap korle done / not done
                        Button {
                            taskVM.toggleDone(task)
                        } label: {
                            Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                                .font(.title2)
                                .foregroundColor(task.isDone ? .green : .gray)
                        }
                        .buttonStyle(.plain)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.title)
                                .font(.headline)
                                .strikethrough(task.isDone)
                            if !task.description.isEmpty {
                                Text(task.description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { editingTask = task }   // tap = edit
                    .swipeActions {                         // swipe = delete
                        Button(role: .destructive) {
                            taskVM.deleteTask(task)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .refreshable { await taskVM.loadTasks() }   // niche tene refresh
            .navigationTitle("My Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Logout") { authVM.signOut() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            // Add new task
            .sheet(isPresented: $showAddSheet) {
                TaskFormView(screenTitle: "New Task") { title, description in
                    taskVM.addTask(title: title, description: description)
                }
            }
            // Edit existing task
            .sheet(item: $editingTask) { task in
                TaskFormView(screenTitle: "Edit Task",
                             initialTitle: task.title,
                             initialDescription: task.description) { title, description in
                    taskVM.updateTask(task, title: title, description: description)
                }
            }
            .alert("Error", isPresented: Binding(
                get: { taskVM.errorMessage != nil },
                set: { if !$0 { taskVM.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(taskVM.errorMessage ?? "")
            }
        }
        .navigationViewStyle(.stack)
        .task { await taskVM.loadTasks() }
    }
}
