import SwiftUI

struct EnvEditorView: View {
  @EnvironmentObject private var appState: AppState
  @Environment(\.dismiss) private var dismiss
  let env: EnvItem?
  let onSave: () -> Void

  @State private var name: String
  @State private var value: String
  @State private var remarks: String
  @State private var isSaving = false
  @State private var errorMessage: String?

  init(env: EnvItem?, onSave: @escaping () -> Void) {
    self.env = env
    self.onSave = onSave
    _name = State(initialValue: env?.name ?? "")
    _value = State(initialValue: env?.value ?? "")
    _remarks = State(initialValue: env?.remarks ?? "")
  }

  var body: some View {
    NavigationView {
      Form {
        Section("变量") {
          TextField("名称", text: $name)
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
          TextField("值", text: $value)
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
          TextField("备注", text: $remarks)
        }

        if let errorMessage {
          Section {
            Text(errorMessage).foregroundColor(.red)
          }
        }
      }
      .navigationTitle(env == nil ? "新增变量" : "编辑变量")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("取消") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button(isSaving ? "保存中" : "保存") {
            Task { await save() }
          }
          .disabled(!canSave || isSaving)
        }
      }
    }
  }

  private var canSave: Bool {
    !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
      !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  private func save() async {
    guard let api = appState.api else { return }
    isSaving = true
    errorMessage = nil
    defer { isSaving = false }
    do {
      if let env {
        try await api.updateEnv(env, value: value, remarks: remarks)
      } else {
        try await api.createEnv(name: name, value: value, remarks: remarks)
      }
      onSave()
      dismiss()
    } catch {
      errorMessage = error.localizedDescription
    }
  }
}
