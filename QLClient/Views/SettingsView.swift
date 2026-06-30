import SwiftUI

struct SettingsView: View {
  @EnvironmentObject private var appState: AppState
  @AppStorage("appearanceMode") private var appearanceMode = AppearanceMode.system.rawValue
  @State private var systemState: Loadable<SystemInfo> = .idle
  @State private var refreshError: String?
  @State private var isRefreshingToken = false
  @State private var showingAddAccount = false

  var body: some View {
    List {
      if let session = appState.session {
        Section("连接") {
          InfoRow(title: "服务器", value: session.baseURL.absoluteString)
          InfoRow(title: "Client ID", value: session.clientID)
          InfoRow(title: "Token 到期", value: expirationText(session.expiration))
        }
      }

      Section("账号") {
        ForEach(appState.accounts) { account in
          Button {
            appState.switchAccount(id: account.id)
          } label: {
            HStack(spacing: 12) {
              Image(systemName: appState.session?.accountID == account.id ? "checkmark.circle.fill" : "server.rack")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(appState.session?.accountID == account.id ? QLStyle.primary : .secondary)
                .frame(width: 34, height: 34)
                .background((appState.session?.accountID == account.id ? QLStyle.primary : Color.secondary).opacity(0.10), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

              VStack(alignment: .leading, spacing: 3) {
                Text(account.displayName)
                  .font(.subheadline.weight(.semibold))
                  .foregroundColor(.primary)
                Text(account.detailText)
                  .font(.caption)
                  .foregroundColor(.secondary)
              }

              Spacer()
            }
          }
          .swipeActions {
            Button(role: .destructive) {
              appState.deleteAccount(id: account.id)
            } label: {
              Label("删除", systemImage: "trash")
            }
          }
        }

        Button {
          showingAddAccount = true
        } label: {
          Label("添加账号", systemImage: "plus.circle")
        }
      }

      Section("服务端") {
        switch systemState {
        case .idle, .loading:
          ProgressView()
        case .failed(let message):
          Text(message).foregroundColor(.red)
        case .loaded(let info):
          InfoRow(title: "版本", value: info.version ?? "-")
          InfoRow(title: "分支", value: info.branch ?? "-")
          if let isInitialized = info.isInitialized {
            InfoRow(title: "初始化", value: isInitialized ? "已完成" : "未初始化")
          }
        }
      }

      Section("外观") {
        Picker("显示模式", selection: $appearanceMode) {
          ForEach(AppearanceMode.allCases) { mode in
            Text(mode.title).tag(mode.rawValue)
          }
        }
        .pickerStyle(.segmented)
      }

      Section("客户端") {
        InfoRow(title: "版本", value: appVersionText)
        InfoRow(title: "构建", value: buildCommit)
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
          Label("移除当前账号", systemImage: "rectangle.portrait.and.arrow.right")
        }
      }

      Section("权限") {
        Text("建议 Open API 应用授予 system、crons、envs、scripts 权限。缺少某项权限时，对应页面会返回 401 或权限错误。")
          .font(.footnote)
          .foregroundColor(.secondary)
      }
    }
    .navigationTitle("设置")
    .listStyle(.insetGrouped)
    .qlListBackground()
    .sheet(isPresented: $showingAddAccount) {
      LoginView {
        showingAddAccount = false
      }
      .environmentObject(appState)
    }
    .task { await loadSystemInfo() }
    .refreshable { await loadSystemInfo() }
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

  private func loadSystemInfo() async {
    guard let api = appState.api else { return }
    systemState = .loading
    do {
      systemState = .loaded(try await api.systemInfo())
    } catch {
      systemState = .failed(error.localizedDescription)
    }
  }

  private var appVersionText: String {
    let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "-"
    let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "-"
    return "\(version) (\(build))"
  }

  private var buildCommit: String {
    Bundle.main.object(forInfoDictionaryKey: "QLBuildCommit") as? String ?? "-"
  }
}
