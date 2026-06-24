import SwiftUI

struct SettingsView: View {
  @EnvironmentObject private var appState: AppState
  @State private var refreshError: String?
  @State private var isRefreshingToken = false

  var body: some View {
    List {
      if let session = appState.session {
        Section("连接") {
          InfoRow(title: "服务器", value: session.baseURL.absoluteString)
          InfoRow(title: "Client ID", value: session.clientID)
          InfoRow(title: "Token 到期", value: expirationText(session.expiration))
        }
      }

      if let refreshError {
        Section {
          Text(refreshError).foregroundColor(.red)
        }
      }

      Section {
        Button {
          Task { await refreshToken() }
        } label: {
          Label(isRefreshingToken ? "刷新中" : "刷新 Token", systemImage: "key")
        }
        .disabled(isRefreshingToken)

        Button(role: .destructive) {
          appState.signOut()
        } label: {
          Label("退出登录", systemImage: "rectangle.portrait.and.arrow.right")
        }
      }

      Section("权限") {
        Text("建议 Open API 应用授予 system、dashboard、crons、envs 权限。缺少某项权限时，对应页面会返回 401 或权限错误。")
          .font(.footnote)
          .foregroundColor(.secondary)
      }
    }
    .navigationTitle("设置")
  }

  private func refreshToken() async {
    isRefreshingToken = true
    refreshError = nil
    defer { isRefreshingToken = false }
    do {
      try await appState.refreshToken()
    } catch {
      refreshError = error.localizedDescription
    }
  }

  private func expirationText(_ timestamp: Int) -> String {
    let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
    return date.formatted(date: .abbreviated, time: .shortened)
  }
}
