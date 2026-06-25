import SwiftUI

struct AccountSwitchButton: View {
  @EnvironmentObject private var appState: AppState
  @State private var showingAddAccount = false

  var body: some View {
    Menu {
      if appState.accounts.isEmpty {
        Text("没有已保存账号")
      } else {
        ForEach(appState.accounts) { account in
          Button {
            appState.switchAccount(id: account.id)
          } label: {
            Label(account.displayName, systemImage: isCurrent(account) ? "checkmark.circle.fill" : "server.rack")
          }
        }
      }

      Divider()

      Button {
        showingAddAccount = true
      } label: {
        Label("添加账号", systemImage: "plus.circle")
      }
    } label: {
      Label(currentTitle, systemImage: "person.crop.circle")
        .labelStyle(.iconOnly)
    }
    .accessibilityLabel("切换账号")
    .sheet(isPresented: $showingAddAccount) {
      LoginView {
        showingAddAccount = false
      }
      .environmentObject(appState)
    }
  }

  private var currentTitle: String {
    guard let session = appState.session else { return "账号" }
    return session.baseURL.host ?? session.baseURL.absoluteString
  }

  private func isCurrent(_ account: StoredCredentials) -> Bool {
    appState.session?.accountID == account.id
  }
}
