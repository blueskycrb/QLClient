import SwiftUI

struct EnvListView: View {
  @EnvironmentObject private var appState: AppState
  @State private var state: Loadable<[EnvItem]> = .idle
  @State private var searchText = ""
  @State private var showingEditor = false
  @State private var searchTask: Task<Void, Never>?

  var body: some View {
    Group {
      switch state {
      case .idle, .loading:
        ProgressView("正在加载变量")
      case .failed(let message):
        ErrorStateView(message: message) {
          Task { await load(showLoading: true) }
        }
      case .loaded(let envs):
        if envs.isEmpty {
          EmptyStateView(title: "没有环境变量", systemImage: "list.bullet.rectangle")
        } else {
          List(envs) { env in
            NavigationLink {
              EnvDetailView(env: env) {
                Task { await load(showLoading: false) }
              }
            } label: {
              EnvRow(env: env)
            }
            .qlRowCard()
          }
          .listStyle(.insetGrouped)
          .qlListBackground()
        }
      }
    }
    .navigationTitle("环境变量")
    .navigationBarTitleDisplayMode(.inline)
    .searchable(text: $searchText, prompt: "搜索变量")
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
      EnvEditorView(env: nil) {
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
      state = .loaded(try await api.envs(searchText: searchText))
    } catch {
      state = .failed(error.localizedDescription)
    }
  }
}

private struct EnvRow: View {
  let env: EnvItem

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      QLIconTile(systemImage: "curlybraces.square", color: env.isEnabled ? QLStyle.primary : .secondary, size: 34)

      VStack(alignment: .leading, spacing: 5) {
        HStack(alignment: .firstTextBaseline) {
          Text(env.name)
            .font(.subheadline.weight(.semibold))
            .lineLimit(1)
          Spacer(minLength: 8)
          StatusBadge(text: env.isEnabled ? "启用" : "禁用", color: env.isEnabled ? QLStyle.success : .gray)
          if env.isPinnedOnTop {
            StatusBadge(text: "置顶", color: QLStyle.warning)
          }
        }
        Text(env.value)
          .font(.caption)
          .foregroundColor(.secondary)
          .lineLimit(1)
        if let remarks = env.remarks, !remarks.isEmpty {
          Text(remarks)
            .font(.caption2)
            .foregroundColor(.secondary)
            .lineLimit(2)
        }
      }
    }
    .padding(.vertical, 4)
  }
}
