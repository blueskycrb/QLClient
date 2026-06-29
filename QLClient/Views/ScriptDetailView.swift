import Foundation
import SwiftUI

struct ScriptDetailView: View {
  @EnvironmentObject private var appState: AppState
  let file: ScriptFile

  @State private var state: Loadable<String> = .idle
  @State private var content = ""
  @State private var originalContent = ""
  @State private var isEditing = false
  @State private var isSaving = false
  @State private var isStartingRun = false
  @State private var isStoppingRun = false
  @State private var currentRunPID: Int?
  @State private var currentRunCommand: String?
  @State private var runLog = ""
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

          runControls

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

          Divider()
          runConsole
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

  private var runControls: some View {
    VStack(alignment: .leading, spacing: 8) {
      ViewThatFits(in: .horizontal) {
        HStack(spacing: 10) {
          runButtons
        }
        VStack(alignment: .leading, spacing: 10) {
          runButtons
        }
      }

      Text(runStatusText)
        .font(.caption)
        .foregroundColor(.secondary)
        .lineLimit(2)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal)
    .padding(.vertical, 10)
    .background(Color(.secondarySystemBackground))
  }

  private var runButtons: some View {
    Group {
      Button {
        Task { await runScript() }
      } label: {
        Label(runButtonTitle, systemImage: "play.fill")
      }
      .buttonStyle(.borderedProminent)
      .disabled(currentRunCommand != nil || isStartingRun || isStoppingRun)

      Button {
        Task { await stopScript() }
      } label: {
        Label(isStoppingRun ? "停止中" : "停止", systemImage: "stop.fill")
      }
      .buttonStyle(.bordered)
      .disabled((currentRunPID == nil && currentRunCommand == nil) || isStoppingRun)

      Button {
        runLog = ""
      } label: {
        Label("清空日志", systemImage: "trash")
      }
      .buttonStyle(.bordered)
      .disabled(runLog.isEmpty || isStoppingRun)
    }
  }

  private var runConsole: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Label("测试输出", systemImage: "terminal")
          .font(.caption.weight(.semibold))
        Spacer()
        if isStartingRun || isStoppingRun {
          ProgressView()
        }
      }

      ScrollView([.vertical, .horizontal]) {
        Text(runLog.isEmpty ? "暂无测试输出" : runLog)
          .font(.system(.caption, design: .monospaced))
          .foregroundColor(runLog.isEmpty ? .secondary : .primary)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.vertical, 2)
      }
      .frame(minHeight: 90, maxHeight: 180)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding()
    .background(Color(.systemBackground))
  }

  private var runStatusText: String {
    if let currentRunPID {
      return "正在测试运行，PID：\(currentRunPID)。可以继续查看实时输出，或点停止结束。"
    }
    if currentRunCommand != nil {
      return "正在测试运行，可以继续查看实时输出，或点停止结束。"
    }
    return "运行测试会把当前编辑内容作为临时脚本提交，不会先覆盖原文件。"
  }

  private var runButtonTitle: String {
    if currentRunCommand != nil { return "运行中" }
    if isStartingRun { return "提交中" }
    return "运行测试"
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

  private func runScript() async {
    guard let api = appState.api else { return }
    isStartingRun = true
    actionError = nil
    currentRunPID = nil
    currentRunCommand = nil
    runLog = "正在提交测试运行...\n"
    defer { isStartingRun = false }

    let tempFile = temporaryScriptFilename(for: file.title)
    let command = shellCommand(for: tempFile, path: file.parent)
    currentRunCommand = command

    do {
      let normalizedContent = content.replacingOccurrences(of: "\r\n", with: "\n")
      try await api.createScript(file: tempFile, path: file.parent, content: normalizedContent)
      appendRunLog("已创建临时测试脚本：\(tempFile)")
      appendRunLog("开始运行：\(file.title)")

      try await api.runCommand(
        command,
        onStart: { pid in
          await MainActor.run {
            currentRunPID = pid
            if let pid {
              appendRunLog("PID：\(pid)")
            }
          }
        },
        onOutput: { output in
          await MainActor.run {
            runLog += output
          }
        }
      )
      appendRunLog("测试运行结束。")
    } catch {
      actionError = error.localizedDescription
      appendRunLog("运行失败：\(error.localizedDescription)")
    }

    do {
      try await api.deleteScript(file: tempFile, path: file.parent)
    } catch {
      appendRunLog("临时脚本清理失败：\(error.localizedDescription)")
    }

    currentRunPID = nil
    currentRunCommand = nil
  }

  private func stopScript() async {
    guard let api = appState.api else { return }
    isStoppingRun = true
    actionError = nil
    defer { isStoppingRun = false }
    do {
      try await api.stopCommand(pid: currentRunPID, command: currentRunCommand)
      appendRunLog("已发送停止指令。")
      currentRunPID = nil
      currentRunCommand = nil
    } catch {
      actionError = error.localizedDescription
      appendRunLog("停止失败：\(error.localizedDescription)")
    }
  }

  private func appendRunLog(_ line: String) {
    if !runLog.isEmpty, !runLog.hasSuffix("\n") {
      runLog += "\n"
    }
    runLog += line + "\n"
  }

  private func temporaryScriptFilename(for filename: String) -> String {
    let nsFilename = filename as NSString
    let name = nsFilename.deletingPathExtension
    let ext = nsFilename.pathExtension
    let suffix = UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(8)
    if ext.isEmpty {
      return "\(name).qlclient-\(suffix).swap"
    }
    return "\(name).qlclient-\(suffix).swap.\(ext)"
  }

  private func shellCommand(for filename: String, path: String) -> String {
    let relativePath = [path, filename]
      .filter { !$0.isEmpty }
      .joined(separator: "/")
    return "\(shellQuoted(relativePath)) now"
  }

  private func shellQuoted(_ value: String) -> String {
    "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
  }
}
