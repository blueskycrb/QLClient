import SwiftUI

struct CronListView: View {
  @EnvironmentObject private var appState: AppState
  @State private var state: Loadable<[CronItem]> = .idle
  @State private var searchText = ""
  @State private var showingEditor = false

  var body: some View {
    Group {
      switch state {
      case .idle, .loading:
        ProgressView("正在加载任务")
      case .failed(let message):
        ErrorStateView(message: message) {
          Task { await load() }
        }
      case .loaded(let crons):
        if crons.isEmpty {
          EmptyStateView(title: "没有定时任务", systemImage: "clock.badge.questionmark")
        } else {
          List(crons) { cron in
            NavigationLink {
              CronDetailView(cron: cron) {
                Task { await load() }
              }
            } label: {
              CronRow(cron: cron)
            }
          }
          .listStyle(.insetGrouped)
        }
      }
    }
    .navigationTitle("定时任务")
    .searchable(text: $searchText, prompt: "搜索任务")
    .toolbar {
      ToolbarItemGroup(placement: .navigationBarTrailing) {
        Button {
          showingEditor = true
        } label: {
          Image(systemName: "plus")
        }

        Button {
          Task { await load() }
        } label: {
          Image(systemName: "arrow.clockwise")
        }
      }
    }
    .sheet(isPresented: $showingEditor) {
      CronEditorView(cron: nil) {
        Task { await load() }
      }
      .environmentObject(appState)
    }
    .task { await load() }
    .task(id: searchText) {
      try? await Task.sleep(nanoseconds: 300_000_000)
      guard !Task.isCancelled else { return }
      await load()
    }
    .refreshable { await load() }
  }

  private func load() async {
    guard let api = appState.api else { return }
    state = .loading
    do {
      state = .loaded(try await api.crons(searchText: searchText))
    } catch {
      state = .failed(error.localizedDescription)
    }
  }
}

private struct CronRow: View {
  let cron: CronItem

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Image(systemName: cron.isRunning ? "play.circle.fill" : "clock")
        .font(.system(size: 22, weight: .semibold))
        .foregroundColor(cron.isRunning ? QLStyle.secondary : QLStyle.primary)
        .frame(width: 38, height: 38)
        .background((cron.isRunning ? QLStyle.secondary : QLStyle.primary).opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

      VStack(alignment: .leading, spacing: 8) {
        HStack(alignment: .firstTextBaseline) {
          Text(cron.title)
            .font(.headline)
            .lineLimit(2)
          Spacer(minLength: 8)
          if cron.isRunning {
            StatusBadge(text: "运行中", color: .blue)
          } else {
            StatusBadge(text: cron.isEnabled ? "启用" : "禁用", color: cron.isEnabled ? .green : .gray)
          }
          if cron.isPinnedOnTop {
            StatusBadge(text: "置顶", color: .orange)
          }
        }
        Text(cron.command)
          .font(.caption)
          .foregroundColor(.secondary)
          .lineLimit(2)
        if let schedule = cron.schedule, !schedule.isEmpty {
          Label(schedule, systemImage: "calendar")
            .font(.caption2)
            .foregroundColor(.secondary)
            .lineLimit(1)
        }
      }
    }
    .padding(.vertical, 6)
  }
}
