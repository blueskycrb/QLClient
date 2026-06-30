import SwiftUI

struct CronLogHistoryView: View {
  @EnvironmentObject private var appState: AppState
  @Environment(\.dismiss) private var dismiss
  let cron: CronItem

  @State private var logsState: Loadable<[CronLogFile]> = .idle
  @State private var selectedLog: CronLogFile?
  @State private var contentState: Loadable<CronLog> = .idle

  var body: some View {
    NavigationView {
      ZStack {
        QLStyle.appBackground.ignoresSafeArea()
        VStack(spacing: 12) {
          header
          content
        }
        .padding(.horizontal)
        .padding(.top, 10)
      }
      .navigationTitle("历史日志")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("关闭") { dismiss() }
        }

        ToolbarItem(placement: .navigationBarTrailing) {
          Button {
            Task { await loadLogs(showLoading: true) }
          } label: {
            Image(systemName: "arrow.clockwise")
          }
        }
      }
      .task { await loadLogsIfNeeded() }
    }
  }

  private var header: some View {
    HStack(spacing: 10) {
      QLIconTile(systemImage: "doc.text.magnifyingglass", color: QLStyle.secondary, size: 34)
      VStack(alignment: .leading, spacing: 2) {
        Text(cron.title)
          .font(.subheadline.weight(.semibold))
          .lineLimit(1)
        Text("查看该任务所有运行日志")
          .font(.caption)
          .foregroundColor(.secondary)
      }
      Spacer(minLength: 0)
    }
    .padding(12)
    .qlGlassPanel(cornerRadius: 16)
  }

  @ViewBuilder
  private var content: some View {
    switch logsState {
    case .idle, .loading:
      Spacer()
      ProgressView("正在加载日志")
      Spacer()
    case .failed(let message):
      ErrorStateView(message: message) {
        Task { await loadLogs(showLoading: true) }
      }
    case .loaded(let logs):
      if logs.isEmpty {
        EmptyStateView(title: "暂无历史日志", systemImage: "doc.text.magnifyingglass")
      } else {
        VStack(spacing: 12) {
          logList(logs)
          logContent
        }
      }
    }
  }

  private func logList(_ logs: [CronLogFile]) -> some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        ForEach(logs) { log in
          Button {
            selectLog(log)
          } label: {
            VStack(alignment: .leading, spacing: 4) {
              Text(log.filename)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
              Text(log.displayTime)
                .font(.caption2)
                .foregroundColor(.secondary)
            }
            .frame(width: 150, alignment: .leading)
            .padding(.horizontal, 11)
            .padding(.vertical, 9)
            .background(selectedLog?.id == log.id ? QLStyle.primary.opacity(0.14) : Color.clear, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
          }
          .buttonStyle(.plain)
        }
      }
      .padding(10)
    }
    .qlGlassPanel(cornerRadius: 16)
  }

  private var logContent: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Label(selectedLog?.filename ?? "日志内容", systemImage: "terminal")
          .font(.caption.weight(.semibold))
        Spacer()
        if case .loading = contentState {
          ProgressView()
        }
      }

      ScrollView([.vertical, .horizontal]) {
        switch contentState {
        case .idle:
          Text("请选择一条日志")
            .foregroundColor(Color.white.opacity(0.45))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
        case .loading:
          Text("正在加载...")
            .foregroundColor(Color.white.opacity(0.45))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
        case .failed(let message):
          Text(message)
            .foregroundColor(.red)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
        case .loaded(let log):
          Text(log.content.isEmpty ? "暂无日志" : log.content)
            .foregroundColor(Color.white.opacity(0.92))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
        }
      }
      .font(.system(.caption, design: .monospaced))
      .background(Color(red: 0.07, green: 0.09, blue: 0.11), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 12, style: .continuous)
          .stroke(Color.white.opacity(0.07), lineWidth: 1)
      )
    }
    .padding(12)
    .qlGlassPanel(cornerRadius: 16)
  }

  private func loadLogsIfNeeded() async {
    if case .idle = logsState {
      await loadLogs(showLoading: true)
    }
  }

  private func loadLogs(showLoading: Bool) async {
    guard let api = appState.api else { return }
    if showLoading {
      logsState = .loading
    }
    do {
      let logs = try await api.cronLogs(id: cron.id)
      logsState = .loaded(logs)
      if selectedLog == nil, let first = logs.first {
        selectLog(first)
      }
    } catch {
      logsState = .failed(error.localizedDescription)
    }
  }

  private func selectLog(_ log: CronLogFile) {
    selectedLog = log
    Task { await loadContent(log) }
  }

  private func loadContent(_ log: CronLogFile) async {
    guard let api = appState.api else { return }
    contentState = .loading
    do {
      contentState = .loaded(try await api.logDetail(file: log.filename, path: log.directory))
    } catch {
      contentState = .failed(error.localizedDescription)
    }
  }
}

private struct GlassPanelModifier: ViewModifier {
  let cornerRadius: CGFloat

  func body(content: Content) -> some View {
    content
      .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
          .stroke(Color.white.opacity(0.18), lineWidth: 1)
      )
      .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 6)
  }
}

private extension View {
  func qlGlassPanel(cornerRadius: CGFloat) -> some View {
    modifier(GlassPanelModifier(cornerRadius: cornerRadius))
  }
}
