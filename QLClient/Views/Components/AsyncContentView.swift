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
    VStack(spacing: 12) {
      Image(systemName: systemImage)
        .font(.largeTitle)
        .foregroundColor(.secondary)
      Text(title)
        .font(.headline)
        .foregroundColor(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding()
  }
}

struct ErrorStateView: View {
  let message: String
  let retry: () -> Void

  var body: some View {
    VStack(spacing: 12) {
      Image(systemName: "exclamationmark.triangle")
        .font(.largeTitle)
        .foregroundColor(.orange)
      Text(message)
        .multilineTextAlignment(.center)
        .foregroundColor(.secondary)
      Button("重试", action: retry)
        .buttonStyle(.borderedProminent)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding()
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
        .foregroundColor(.secondary)
      Spacer(minLength: 16)
      Text(value)
        .multilineTextAlignment(.trailing)
    }
  }
}
