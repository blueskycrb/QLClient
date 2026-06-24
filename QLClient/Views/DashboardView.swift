import SwiftUI

struct DashboardView: View {
  @EnvironmentObject private var appState: AppState
  @State private var systemState: Loadable<SystemInfo> = .idle
  @State private var overviewState: Loadable<DashboardOverview> = .idle

  var body: some View {
    List {
      systemSection
      overviewSection
    }
    .navigationTitle("概览")
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        Button {
          Task { await load() }
        } label: {
          Image(systemName: "arrow.clockwise")
        }
      }
    }
    .task { await load() }
    .refreshable { await load() }
  }

  @ViewBuilder
  private var systemSection: some View {
    Section("系统") {
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
  }

  @ViewBuilder
  private var overviewSection: some View {
    Section("任务统计") {
      switch overviewState {
      case .idle, .loading:
        ProgressView()
      case .failed(let message):
        Text(message).foregroundColor(.red)
      case .loaded(let overview):
        MetricGrid(overview: overview)
      }
    }
  }

  private func load() async {
    guard let api = appState.api else { return }
    systemState = .loading
    overviewState = .loading
    async let system = api.systemInfo()
    async let overview = api.dashboardOverview()

    do {
      systemState = .loaded(try await system)
    } catch {
      systemState = .failed(error.localizedDescription)
    }

    do {
      overviewState = .loaded(try await overview)
    } catch {
      overviewState = .failed(error.localizedDescription)
    }
  }
}

private struct MetricGrid: View {
  let overview: DashboardOverview

  var body: some View {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
      MetricTile(title: "总任务", value: "\(overview.total ?? 0)")
      MetricTile(title: "启用", value: "\(overview.enabled ?? 0)")
      MetricTile(title: "今日运行", value: "\(overview.todayRuns ?? 0)")
        MetricTile(title: "成功率", value: "\(overview.successRate ?? "0")%")
    }
    .padding(.vertical, 4)
  }
}

private struct MetricTile: View {
  let title: String
  let value: String

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(title)
        .font(.caption)
        .foregroundColor(.secondary)
      Text(value)
        .font(.title2)
        .fontWeight(.semibold)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(12)
    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
  }
}
