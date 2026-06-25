import SwiftUI
import UIKit

struct LoginView: View {
  @EnvironmentObject private var appState: AppState
  @State private var baseURL = ""
  @State private var clientID = ""
  @State private var clientSecret = ""
  @State private var isSigningIn = false
  var onSignedIn: (() -> Void)?

  var body: some View {
    NavigationView {
      ScrollView {
        VStack(alignment: .leading, spacing: 18) {
          VStack(alignment: .leading, spacing: 14) {
            BrandMark(size: 72)
            VStack(alignment: .leading, spacing: 6) {
              Text("青龙客户端")
                .font(.largeTitle)
                .fontWeight(.bold)
              Text("连接你的青龙面板，管理任务、变量和脚本。")
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.top, 18)

          VStack(alignment: .leading, spacing: 12) {
            Text("Open API")
              .font(.headline)

            InputRow(title: "服务器", placeholder: "http://192.168.1.2:5700", text: $baseURL, keyboardType: .URL)
            InputRow(title: "Client ID", placeholder: "Client ID", text: $clientID)
            InputRow(title: "Client Secret", placeholder: "Client Secret", text: $clientSecret)

            Text("在青龙 Web 面板创建 Open API 应用，并授予 system、crons、envs、scripts 权限。Client Secret 使用普通输入框，以支持微信输入法等第三方键盘。")
              .font(.footnote)
              .foregroundColor(.secondary)
              .fixedSize(horizontal: false, vertical: true)
          }
          .qlCard()

          if let signInError = appState.signInError {
            Text(signInError)
              .font(.footnote)
              .foregroundColor(.red)
              .padding(.horizontal, 4)
          }

          Button {
            Task { await signIn() }
          } label: {
            HStack(spacing: 8) {
              if isSigningIn { ProgressView().tint(.white) }
              Text(isSigningIn ? "连接中" : "登录")
                .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
          }
          .buttonStyle(.borderedProminent)
          .tint(QLStyle.primary)
          .disabled(!canSignIn || isSigningIn)
        }
        .padding()
      }
      .navigationTitle("连接青龙")
      .background(Color(.systemGroupedBackground))
    }
  }

  private var canSignIn: Bool {
    !baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
      !clientID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
      !clientSecret.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  private func signIn() async {
    isSigningIn = true
    let signedIn = await appState.signIn(baseURL: baseURL, clientID: clientID, clientSecret: clientSecret)
    isSigningIn = false
    if signedIn {
      onSignedIn?()
    }
  }
}

private struct InputRow: View {
  let title: String
  let placeholder: String
  @Binding var text: String
  var keyboardType: UIKeyboardType = .default

  var body: some View {
    VStack(alignment: .leading, spacing: 7) {
      Text(title)
        .font(.caption)
        .foregroundColor(.secondary)
      HStack(spacing: 8) {
        TextField(placeholder, text: $text)
          .keyboardType(keyboardType)
          .textInputAutocapitalization(.never)
          .disableAutocorrection(true)
          .padding(.vertical, 10)
        Button {
          if let pasted = UIPasteboard.general.string {
            text = pasted
          }
        } label: {
          Image(systemName: "doc.on.clipboard")
        }
        .buttonStyle(.borderless)
        .foregroundColor(QLStyle.primary)
        .accessibilityLabel("粘贴\(title)")
      }
      .padding(.horizontal, 12)
      .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
  }
}
