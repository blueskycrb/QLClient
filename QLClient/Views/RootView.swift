import SwiftUI

struct RootView: View {
  @EnvironmentObject private var appState: AppState
  @AppStorage("appearanceMode") private var appearanceMode = AppearanceMode.system.rawValue

  var body: some View {
    Group {
      if appState.isRestoringSession {
        ProgressView("正在读取登录状态")
      } else if appState.session == nil {
        LoginView()
      } else {
        MainTabView()
      }
    }
    .preferredColorScheme(selectedColorScheme)
    .tint(QLStyle.primary)
  }

  private var selectedColorScheme: ColorScheme? {
    (AppearanceMode(rawValue: appearanceMode) ?? .system).colorScheme
  }
}

struct MainTabView: View {
  var body: some View {
    TabView {
      NavigationView {
        CronListView()
      }
      .navigationViewStyle(.stack)
      .tabItem { Label("任务", systemImage: "clock.arrow.circlepath") }

      NavigationView {
        EnvListView()
      }
      .navigationViewStyle(.stack)
      .tabItem { Label("变量", systemImage: "list.bullet.rectangle") }

      NavigationView {
        ScriptListView()
      }
      .navigationViewStyle(.stack)
      .tabItem { Label("脚本", systemImage: "doc.text") }

      NavigationView {
        SettingsView()
      }
      .navigationViewStyle(.stack)
      .tabItem { Label("设置", systemImage: "gearshape") }
    }
  }
}
