import SwiftUI

struct DashboardView: View {
  @EnvironmentObject private var appState: AppState
  @State private var systemState: Loadable<SystemInfo> = .idle
  @State private var overviewState: Loadable<DashboardOverview> = .idle

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        heroSection
        overviewSection
        systemSection
      }
      .padding()
    }
    .background(Color(.systemGroupedBackground))
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
  private var heroSection: some View {
    HStack(spacing: 14) {
      BrandMark(size: 58)
      VStack(alignment: .leading, spacing: 5) {
        Text("青龙面板")
          .font(.title2)
          .fontWeight(.bold)
        Text(appState.session?.baseURL.host ?? "已连接")
          .font(.subheadline)
          .foregroundColor(.secondary)
      }
      Spacer()
    }
    .qlCard()
  }

  @ViewBuilder
  private var systemSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("系统")
        .font(.headline)
      VStack(spacing: 10) {
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
      .qlCard()
    }
  }

  @ViewBuilder
  private var overviewSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("任务统计")
        .font(.headline)
      switch overviewState {
      case .idle, .loading:
        ProgressView()
          .frame(maxWidth: .infinity)
          .qlCard()
      case .failed(let message):
        Text(message)
          .foregroundColor(.red)
          .qlCard()
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
      MetricTile(title: "总任务", value: "\(overview.total ?? 0)", systemImage: "tray.full", color: QLStyle.primary)
      MetricTile(title: "启用", value: "\(overview.enabled ?? 0)", systemImage: "checkmark.circle", color: .green)
      MetricTile(title: "今日运行", value: "\(overview.todayRuns ?? 0)", systemImage: "bolt.circle", color: QLStyle.secondary)
      MetricTile(title: "成功率", value: "\(overview.successRate ?? "0")%", systemImage: "chart.line.uptrend.xyaxis", color: QLStyle.amber)
    }
  }
}

private struct MetricTile: View {
  let title: String
  let value: String
  let systemImage: String
  let color: Color

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Image(systemName: systemImage)
        .font(.system(size: 18, weight: .semibold))
        .foregroundColor(color)
        .frame(width: 34, height: 34)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
      Text(title)
        .font(.caption)
        .foregroundColor(.secondary)
      Text(value)
        .font(.title2)
        .fontWeight(.semibold)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .qlCard()
  }
}
