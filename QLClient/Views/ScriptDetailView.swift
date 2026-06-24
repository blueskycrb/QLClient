import SwiftUI

struct ScriptDetailView: View {
  @EnvironmentObject private var appState: AppState
  let file: ScriptFile

  @State private var state: Loadable<String> = .idle

  var body: some View {
    Group {
      switch state {
      case .idle, .loading:
        ProgressView("正在加载文件")
      case .failed(let message):
        ErrorStateView(message: message) {
          Task { await load() }
        }
      case .loaded(let content):
        ScrollView([.vertical, .horizontal]) {
          Text(content.isEmpty ? "文件为空" : content)
            .font(.system(.caption, design: .monospaced))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .background(Color(.systemBackground))
      }
    }
    .navigationTitle(file.title)
    .navigationBarTitleDisplayMode(.inline)
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
  }

  private func load() async {
    guard let api = appState.api else { return }
    state = .loading
    do {
      state = .loaded(try await api.scriptDetail(file: file.title, path: file.parent))
    } catch {
      state = .failed(error.localizedDescription)
    }
  }
}
