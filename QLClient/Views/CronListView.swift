import SwiftUI

struct CronListView: View {
  @EnvironmentObject private var appState: AppState
  @State private var state: Loadable<[CronItem]> = .idle
  @State private var searchText = ""
  @State private var showingEditor = false
  @State private var searchTask: Task<Void, Never>?

  var body: some View {
    Group {
      switch state {
      case .idle, .loading:
        ProgressView("正在加载任务")
      case .failed(let message):
        ErrorStateView(message: message) {
          Task { await load(showLoading: true) }
        }
      case .loaded(let crons):
        if crons.isEmpty {
          EmptyStateView(title: "没有定时任务", systemImage: "clock.badge.questionmark")
        } else {
          List(crons) { cron in
            NavigationLink {
              CronDetailView(cron: cron) {
                Task { await load(showLoading: false) }
              }
            } label: {
              CronRow(cron: cron)
            }
            .qlRowCard()
          }
          .listStyle(.insetGrouped)
          .qlListBackground()
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
          Task { await load(showLoading: false) }
        } label: {
          Image(systemName: "arrow.clockwise")
        }
      }
    }
    .sheet(isPresented: $showingEditor) {
      CronEditorView(cron: nil) {
        Task { await load(showLoading: false) }
      }
      .environmentObject(appState)
    }
    .task { await loadIfNeeded() }
    .onChange(of: searchText) { _ in
      searchTask?.cancel()
      searchTask = Task {
        try? await Task.sleep(nanoseconds: 300_000_000)
        guard !Task.isCancelled else { return }
        await load(showLoading: false)
      }
    }
    .refreshable { await load(showLoading: false) }
  }

  private func loadIfNeeded() async {
    if case .idle = state {
      await load(showLoading: true)
    }
  }

  private func load(showLoading: Bool) async {
    guard let api = appState.api else { return }
    if showLoading {
      state = .loading
    }
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
      QLIconTile(
        systemImage: cron.isRunning ? "play.fill" : "clock",
        color: cron.isRunning ? QLStyle.secondary : QLStyle.primary,
        filled: cron.isRunning
      )

      VStack(alignment: .leading, spacing: 8) {
        HStack(alignment: .firstTextBaseline) {
          Text(cron.title)
            .font(.headline.weight(.semibold))
            .lineLimit(2)
          Spacer(minLength: 8)
          if cron.isRunning {
            StatusBadge(text: "运行中", color: QLStyle.secondary)
          } else {
            StatusBadge(text: cron.isEnabled ? "启用" : "禁用", color: cron.isEnabled ? QLStyle.success : .gray)
          }
          if cron.isPinnedOnTop {
            StatusBadge(text: "置顶", color: QLStyle.warning)
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
