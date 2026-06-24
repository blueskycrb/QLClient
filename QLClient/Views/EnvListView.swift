import SwiftUI

struct EnvListView: View {
  @EnvironmentObject private var appState: AppState
  @State private var state: Loadable<[EnvItem]> = .idle
  @State private var searchText = ""
  @State private var showingEditor = false

  var body: some View {
    Group {
      switch state {
      case .idle, .loading:
        ProgressView("正在加载变量")
      case .failed(let message):
        ErrorStateView(message: message) {
          Task { await load() }
        }
      case .loaded(let envs):
        if envs.isEmpty {
          EmptyStateView(title: "没有环境变量", systemImage: "list.bullet.rectangle")
        } else {
          List(envs) { env in
            NavigationLink {
              EnvDetailView(env: env) {
                Task { await load() }
              }
            } label: {
              EnvRow(env: env)
            }
          }
          .listStyle(.insetGrouped)
        }
      }
    }
    .navigationTitle("环境变量")
    .searchable(text: $searchText, prompt: "搜索变量")
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
      EnvEditorView(env: nil) {
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
      Image(systemName: "curlybraces.square")
        .font(.system(size: 22, weight: .semibold))
        .foregroundColor(env.isEnabled ? QLStyle.primary : .secondary)
        .frame(width: 38, height: 38)
        .background((env.isEnabled ? QLStyle.primary : Color.secondary).opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

      VStack(alignment: .leading, spacing: 8) {
        HStack(alignment: .firstTextBaseline) {
          Text(env.name)
            .font(.headline)
            .lineLimit(1)
          Spacer(minLength: 8)
          StatusBadge(text: env.isEnabled ? "启用" : "禁用", color: env.isEnabled ? .green : .gray)
          if env.isPinnedOnTop {
            StatusBadge(text: "置顶", color: .orange)
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
    .padding(.vertical, 6)
  }
}
