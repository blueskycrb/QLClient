import SwiftUI

struct CronDetailView: View {
  @EnvironmentObject private var appState: AppState
  @State private var cron: CronItem
  @State private var logState: Loadable<CronLog> = .idle
  @State private var isWorking = false
  @State private var actionError: String?

  init(cron: CronItem) {
    _cron = State(initialValue: cron)
  }

  var body: some View {
    List {
      Section("任务") {
        InfoRow(title: "名称", value: cron.title)
        InfoRow(title: "命令", value: cron.command)
        InfoRow(title: "定时", value: cron.schedule ?? "-")
        InfoRow(title: "状态", value: cron.isEnabled ? "启用" : "禁用")
      }

      if let actionError {
        Section {
          Text(actionError).foregroundColor(.red)
        }
      }

      Section {
        Button {
          Task { await run() }
        } label: {
          Label("运行一次", systemImage: "play.fill")
        }
        .disabled(isWorking)

        Button {
          Task { await stop() }
        } label: {
          Label("停止", systemImage: "stop.fill")
        }
        .disabled(isWorking)

        Button {
          Task { await setEnabled(!cron.isEnabled) }
        } label: {
          Label(cron.isEnabled ? "禁用任务" : "启用任务", systemImage: cron.isEnabled ? "pause.circle" : "checkmark.circle")
        }
        .disabled(isWorking)
      }

      Section("日志") {
        switch logState {
        case .idle, .loading:
          ProgressView()
        case .failed(let message):
          Text(message).foregroundColor(.red)
        case .loaded(let log):
          ScrollView(.horizontal) {
            Text(log.content.isEmpty ? "暂无日志" : log.content)
              .font(.system(.caption, design: .monospaced))
              .frame(maxWidth: .infinity, alignment: .leading)
          }
          if let status = log.status {
            InfoRow(title: "日志状态", value: "\(status)")
          }
        }
      }
    }
    .navigationTitle(cron.title)
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        Button {
          Task { await loadLog() }
        } label: {
          Image(systemName: "arrow.clockwise")
        }
      }
    }
    .task { await loadLog() }
  }

  private func run() async {
    await perform {
      try await appState.api?.runCron(id: cron.id)
      await loadLog()
    }
  }

  private func stop() async {
    await perform {
      try await appState.api?.stopCron(id: cron.id)
      await loadLog()
    }
  }

  private func setEnabled(_ enabled: Bool) async {
    await perform {
      try await appState.api?.setCronEnabled(id: cron.id, enabled: enabled)
      cron = CronItemValueUpdater.setEnabled(cron, enabled: enabled)
    }
  }

  private func loadLog() async {
    guard let api = appState.api else { return }
    logState = .loading
    do {
      logState = .loaded(try await api.cronLog(id: cron.id))
    } catch {
      logState = .failed(error.localizedDescription)
    }
  }

  private func perform(_ operation: () async throws -> Void) async {
    isWorking = true
    actionError = nil
    defer { isWorking = false }
    do {
      try await operation()
    } catch {
      actionError = error.localizedDescription
    }
  }
}

private enum CronItemValueUpdater {
  static func setEnabled(_ cron: CronItem, enabled: Bool) -> CronItem {
    CronItem(
      id: cron.id,
      name: cron.name,
      command: cron.command,
      schedule: cron.schedule,
      status: cron.status,
      isDisabled: enabled ? 0 : 1,
      isPinned: cron.isPinned,
      labels: cron.labels,
      lastRunningTime: cron.lastRunningTime,
      lastExecutionTime: cron.lastExecutionTime
    )
  }
}
