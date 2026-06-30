import SwiftUI

struct EnvDetailView: View {
  @EnvironmentObject private var appState: AppState
  @State private var env: EnvItem
  @State private var showingEditor = false
  @State private var isWorking = false
  @State private var actionError: String?
  let onChange: () -> Void

  init(env: EnvItem, onChange: @escaping () -> Void) {
    _env = State(initialValue: env)
    self.onChange = onChange
  }

  var body: some View {
    List {
      Section("变量") {
        InfoRow(title: "名称", value: env.name)
        InfoRow(title: "值", value: env.value)
        InfoRow(title: "备注", value: env.remarks ?? "-")
        InfoRow(title: "状态", value: env.isEnabled ? "启用" : "禁用")
        InfoRow(title: "置顶", value: env.isPinnedOnTop ? "是" : "否")
      }

      if let actionError {
        Section {
          Text(actionError).foregroundColor(.red)
        }
      }

      Section {
        Button {
          showingEditor = true
        } label: {
          Label("编辑", systemImage: "square.and.pencil")
        }

        Button {
          Task { await setEnabled(!env.isEnabled) }
        } label: {
          Label(env.isEnabled ? "禁用变量" : "启用变量", systemImage: env.isEnabled ? "pause.circle" : "checkmark.circle")
        }
        .disabled(isWorking)

        Button {
          Task { await setPinned(!env.isPinnedOnTop) }
        } label: {
          Label(env.isPinnedOnTop ? "取消置顶" : "置顶变量", systemImage: env.isPinnedOnTop ? "pin.slash" : "pin")
        }
        .disabled(isWorking)
      }
    }
    .navigationTitle(env.name)
    .listStyle(.insetGrouped)
    .qlListBackground()
    .sheet(isPresented: $showingEditor) {
      EnvEditorView(env: env) {
        onChange()
      }
      .environmentObject(appState)
    }
  }

  private func setEnabled(_ enabled: Bool) async {
    guard let api = appState.api else { return }
    isWorking = true
    actionError = nil
    defer { isWorking = false }
    do {
      try await api.setEnvEnabled(id: env.id, enabled: enabled)
      env = EnvItem(
        id: env.id,
        name: env.name,
        value: env.value,
        remarks: env.remarks,
        status: enabled ? 0 : 1,
        isPinned: env.isPinned,
        position: env.position,
        labels: env.labels
      )
      onChange()
    } catch {
      actionError = error.localizedDescription
    }
  }

  private func setPinned(_ pinned: Bool) async {
    guard let api = appState.api else { return }
    isWorking = true
    actionError = nil
    defer { isWorking = false }
    do {
      try await api.setEnvPinned(id: env.id, pinned: pinned)
      env = EnvItem(
        id: env.id,
        name: env.name,
        value: env.value,
        remarks: env.remarks,
        status: env.status,
        isPinned: pinned ? 1 : 0,
        position: env.position,
        labels: env.labels
      )
      onChange()
    } catch {
      actionError = error.localizedDescription
    }
  }
}
