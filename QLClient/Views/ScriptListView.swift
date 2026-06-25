import SwiftUI

struct ScriptListView: View {
  @EnvironmentObject private var appState: AppState
  let path: String
  let title: String

  @State private var state: Loadable<[ScriptFile]> = .idle
  @State private var searchText = ""

  init(path: String = "", title: String = "脚本管理") {
    self.path = path
    self.title = title
  }

  var body: some View {
    Group {
      switch state {
      case .idle, .loading:
        ProgressView("正在加载脚本")
      case .failed(let message):
        ErrorStateView(message: message) {
          Task { await load(showLoading: true) }
        }
      case .loaded(let files):
        let filtered = filteredFiles(files)
        if filtered.isEmpty {
          EmptyStateView(title: "没有脚本文件", systemImage: "doc.text.magnifyingglass")
        } else {
          List(filtered) { file in
            if file.isDirectory {
              NavigationLink {
                ScriptListView(path: file.key, title: file.title)
              } label: {
                ScriptFileRow(file: file)
              }
            } else {
              NavigationLink {
                ScriptDetailView(file: file)
              } label: {
                ScriptFileRow(file: file)
              }
            }
          }
          .listStyle(.insetGrouped)
        }
      }
    }
    .navigationTitle(title)
    .searchable(text: $searchText, prompt: "搜索脚本")
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        Button {
          Task { await load(showLoading: false) }
        } label: {
          Image(systemName: "arrow.clockwise")
        }
      }
    }
    .task { await loadIfNeeded() }
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
      state = .loaded(try await api.scripts(path: path))
    } catch {
      state = .failed(error.localizedDescription)
    }
  }

  private func filteredFiles(_ files: [ScriptFile]) -> [ScriptFile] {
    let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !query.isEmpty else { return files }
    return flatten(files).filter {
      $0.title.localizedCaseInsensitiveContains(query) ||
        $0.key.localizedCaseInsensitiveContains(query)
    }
  }

  private func flatten(_ files: [ScriptFile]) -> [ScriptFile] {
    files.flatMap { file in
      [file] + flatten(file.children ?? [])
    }
  }
}

private struct ScriptFileRow: View {
  let file: ScriptFile

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: file.isDirectory ? "folder" : "doc.text")
        .font(.system(size: 21, weight: .semibold))
        .foregroundColor(file.isDirectory ? QLStyle.amber : QLStyle.secondary)
        .frame(width: 38, height: 38)
        .background((file.isDirectory ? QLStyle.amber : QLStyle.secondary).opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
      VStack(alignment: .leading, spacing: 4) {
        Text(file.title)
          .font(.headline)
          .lineLimit(1)
        Text(file.isDirectory ? file.key : file.displaySize)
          .font(.caption)
          .foregroundColor(.secondary)
          .lineLimit(1)
      }
    }
    .padding(.vertical, 4)
  }
}
