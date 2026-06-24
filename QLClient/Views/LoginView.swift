import SwiftUI

struct LoginView: View {
  @EnvironmentObject private var appState: AppState
  @State private var baseURL = ""
  @State private var clientID = ""
  @State private var clientSecret = ""
  @State private var isSigningIn = false

  var body: some View {
    NavigationView {
      Form {
        Section {
          TextField("http://192.168.1.2:5700", text: $baseURL)
            .keyboardType(.URL)
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
          TextField("Client ID", text: $clientID)
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
          SecureField("Client Secret", text: $clientSecret)
        } header: {
          Text("Open API")
        } footer: {
          Text("在青龙 Web 面板的系统设置或应用管理中创建 Open API 应用，并至少授予 system、dashboard、crons、envs 权限。")
        }

        if let signInError = appState.signInError {
          Section {
            Text(signInError)
              .foregroundColor(.red)
          }
        }

        Section {
          Button {
            Task { await signIn() }
          } label: {
            HStack {
              Spacer()
              if isSigningIn {
                ProgressView()
              } else {
                Text("登录")
                  .fontWeight(.semibold)
              }
              Spacer()
            }
          }
          .disabled(!canSignIn || isSigningIn)
        }
      }
      .navigationTitle("连接青龙")
    }
  }

  private var canSignIn: Bool {
    !baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
      !clientID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
      !clientSecret.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  private func signIn() async {
    isSigningIn = true
    await appState.signIn(baseURL: baseURL, clientID: clientID, clientSecret: clientSecret)
    isSigningIn = false
  }
}
