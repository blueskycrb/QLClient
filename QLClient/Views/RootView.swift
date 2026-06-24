import SwiftUI

struct RootView: View {
  @EnvironmentObject private var appState: AppState

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
  }
}

struct MainTabView: View {
  var body: some View {
    TabView {
      NavigationView {
        DashboardView()
      }
      .navigationViewStyle(.stack)
      .tabItem { Label("概览", systemImage: "gauge.medium") }

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
        SettingsView()
      }
      .navigationViewStyle(.stack)
      .tabItem { Label("设置", systemImage: "gearshape") }
    }
  }
}
