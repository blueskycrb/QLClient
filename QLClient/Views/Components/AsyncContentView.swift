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
      ZStack {
        Circle()
          .fill(QLStyle.primary.opacity(0.12))
          .frame(width: 76, height: 76)
        Image(systemName: systemImage)
          .font(.system(size: 32, weight: .semibold))
          .foregroundColor(QLStyle.primary)
      }
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
      ZStack {
        Circle()
          .fill(Color.orange.opacity(0.14))
          .frame(width: 76, height: 76)
        Image(systemName: "exclamationmark.triangle")
          .font(.system(size: 30, weight: .semibold))
          .foregroundColor(.orange)
      }
      Text(message)
        .multilineTextAlignment(.center)
        .foregroundColor(.secondary)
      Button("重试", action: retry)
        .buttonStyle(.borderedProminent)
        .tint(QLStyle.primary)
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
