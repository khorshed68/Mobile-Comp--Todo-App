import SwiftUI

// User login thakle Task list, na thakle Login screen
struct RootView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        if let user = authVM.user {
            TaskListView(userId: user.uid, authVM: authVM)
                .id(user.uid) // onno user login korle fresh list
        } else {
            LoginView()
        }
    }
}
