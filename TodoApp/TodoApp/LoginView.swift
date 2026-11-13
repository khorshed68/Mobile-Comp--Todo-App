import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel

    @State private var email = ""
    @State private var password = ""
    @State private var isSignUpMode = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Todo List")
                .font(.largeTitle)
                .bold()

            Text(isSignUpMode ? "Create a new account" : "Login to your account")
                .foregroundColor(.secondary)

            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .textFieldStyle(.roundedBorder)

            SecureField("Password (min 6 characters)", text: $password)
                .textFieldStyle(.roundedBorder)

            if let error = authVM.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
            }

            Button {
                let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
                if isSignUpMode {
                    authVM.signUp(email: trimmedEmail, password: password)
                } else {
                    authVM.signIn(email: trimmedEmail, password: password)
                }
            } label: {
                if authVM.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text(isSignUpMode ? "Sign Up" : "Login")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(email.isEmpty || password.isEmpty || authVM.isLoading)

            Button(isSignUpMode ? "Already have an account? Login" : "No account? Sign Up") {
                isSignUpMode.toggle()
                authVM.errorMessage = nil
            }
            .font(.footnote)
        }
        .padding(24)
    }
}
