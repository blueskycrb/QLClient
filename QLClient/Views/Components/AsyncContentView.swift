import SwiftUI

enum Loadable<Value> {
  case idle
  case loading
  case loaded(Value)
  case failed(String)
}

struct EmptyStateView: View {
  let title: String
  let systemImage: String

  var body: some View {
    VStack(spacing: 14) {
      QLIconTile(systemImage: systemImage, color: QLStyle.primary, filled: true)
        .scaleEffect(1.2)
      Text(title)
        .font(.headline.weight(.semibold))
      Text("下拉刷新或点右上角按钮同步最新数据")
        .font(.footnote)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding()
    .background(QLStyle.appBackground)
  }
}

struct ErrorStateView: View {
  let message: String
  let retry: () -> Void

  var body: some View {
    VStack(spacing: 14) {
      QLIconTile(systemImage: "exclamationmark.triangle", color: QLStyle.warning, filled: true)
        .scaleEffect(1.2)
      Text("加载失败")
        .font(.headline.weight(.semibold))
      Text(message)
        .font(.footnote)
        .multilineTextAlignment(.center)
        .foregroundColor(.secondary)
      Button("重试", action: retry)
        .buttonStyle(.borderedProminent)
        .tint(QLStyle.primary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding()
    .background(QLStyle.appBackground)
  }
}

struct StatusBadge: View {
  let text: String
  let color: Color

  var body: some View {
    Text(text)
      .font(.caption2)
      .fontWeight(.semibold)
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .foregroundColor(color)
      .background(color.opacity(0.12), in: Capsule())
  }
}

struct InfoRow: View {
  let title: String
  let value: String

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Text(title)
        .font(.subheadline)
        .foregroundColor(.secondary)
      Spacer(minLength: 16)
      Text(value)
        .font(.subheadline.weight(.medium))
        .multilineTextAlignment(.trailing)
        .textSelection(.enabled)
    }
    .padding(.vertical, 2)
  }
}
