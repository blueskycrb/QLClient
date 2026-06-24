import SwiftUI

struct CronEditorView: View {
  @EnvironmentObject private var appState: AppState
  @Environment(\.dismiss) private var dismiss
  let cron: CronItem?
  let onSave: () -> Void

  @State private var name: String
  @State private var command: String
  @State private var schedule: String
  @State private var labelsText: String
  @State private var isSaving = false
  @State private var errorMessage: String?

  init(cron: CronItem?, onSave: @escaping () -> Void) {
    self.cron = cron
    self.onSave = onSave
    _name = State(initialValue: cron?.name ?? "")
    _command = State(initialValue: cron?.command ?? "")
    _schedule = State(initialValue: cron?.schedule ?? "")
    _labelsText = State(initialValue: (cron?.labels ?? []).joined(separator: ", "))
  }

  var body: some View {
    NavigationView {
      Form {
        Section("任务") {
          TextField("名称", text: $name)
          TextField("命令，例如 task demo.js", text: $command)
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
          TextField("定时，例如 0 0 * * *", text: $schedule)
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
          TextField("标签，多个用逗号分隔", text: $labelsText)
        } footer: {
          Text("支持普通 cron 表达式，也支持青龙服务端支持的特殊 schedule。")
        }

        if let errorMessage {
          Section {
            Text(errorMessage).foregroundColor(.red)
          }
        }
      }
      .navigationTitle(cron == nil ? "新增任务" : "编辑任务")
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
    !command.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
      !schedule.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  private var labels: [String] {
    labelsText
      .split(separator: ",")
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
  }

  private func save() async {
    guard let api = appState.api else { return }
    isSaving = true
    errorMessage = nil
    defer { isSaving = false }
    do {
      let payload = CronPayload(
        id: cron?.id,
        name: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : name,
        command: command,
        schedule: schedule,
        labels: labels,
        extraSchedules: nil,
        taskBefore: nil,
        taskAfter: nil,
        allowMultipleInstances: nil,
        workDir: nil
      )
      if cron == nil {
        try await api.createCron(payload)
      } else {
        try await api.updateCron(payload)
      }
      onSave()
      dismiss()
    } catch {
      errorMessage = error.localizedDescription
    }
  }
}
