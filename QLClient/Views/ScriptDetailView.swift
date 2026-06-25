import SwiftUI

struct ScriptDetailView: View {
  @EnvironmentObject private var appState: AppState
  let file: ScriptFile

  @State private var state: Loadable<String> = .idle
  @State private var content = ""
  @State private var originalContent = ""
  @State private var isEditing = false
  @State private var isSaving = false
  @State private var actionError: String?

  var body: some View {
    Group {
      switch state {
      case .idle, .loading:
        ProgressView("正在加载文件")
      case .failed(let message):
        ErrorStateView(message: message) {
          Task { await load() }
        }
      case .loaded:
        VStack(spacing: 0) {
          if let actionError {
            Text(actionError)
              .font(.footnote)
              .foregroundColor(.red)
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(.horizontal)
              .padding(.vertical, 8)
              .background(Color.red.opacity(0.08))
          }

          if isEditing {
            TextEditor(text: $content)
              .font(.system(.caption, design: .monospaced))
              .textInputAutocapitalization(.never)
              .disableAutocorrection(true)
              .padding(8)
          } else {
            ScrollView([.vertical, .horizontal]) {
              Text(content.isEmpty ? "文件为空" : content)
                .font(.system(.caption, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
          }
        }
        .background(Color(.systemBackground))
      }
    }
    .navigationTitle(file.title)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItemGroup(placement: .navigationBarTrailing) {
        if isEditing {
          Button("取消") {
            content = originalContent
            actionError = nil
            isEditing = false
          }

          Button(isSaving ? "保存中" : "保存") {
            Task { await save() }
          }
          .disabled(isSaving || content == originalContent)
        } else {
          Button {
            isEditing = true
          } label: {
            Image(systemName: "square.and.pencil")
          }

          Button {
            Task { await load() }
          } label: {
            Image(systemName: "arrow.clockwise")
          }
        }
      }
    }
    .task { await loadIfNeeded() }
  }

  private func loadIfNeeded() async {
    if case .idle = state {
      await load()
    }
  }

  private func load() async {
    guard let api = appState.api else { return }
    isEditing = false
    actionError = nil
    state = .loading
    do {
      let loadedContent = try await api.scriptDetail(file: file.title, path: file.parent)
      content = loadedContent
      originalContent = loadedContent
      state = .loaded(loadedContent)
    } catch {
      state = .failed(error.localizedDescription)
    }
  }

  private func save() async {
    guard let api = appState.api else { return }
    isSaving = true
    actionError = nil
    defer { isSaving = false }
    do {
      try await api.updateScript(file: file.title, path: file.parent, content: content)
      originalContent = content
      state = .loaded(content)
      isEditing = false
    } catch {
      actionError = error.localizedDescription
    }
  }
}
