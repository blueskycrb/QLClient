import SwiftUI

enum QLStyle {
  static let primary = Color(red: 0.00, green: 0.62, blue: 0.52)
  static let secondary = Color(red: 0.12, green: 0.44, blue: 0.88)
  static let amber = Color(red: 0.95, green: 0.58, blue: 0.18)
  static let cardCorner: CGFloat = 14
}

struct BrandMark: View {
  let size: CGFloat

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
        .fill(
          LinearGradient(
            colors: [QLStyle.primary, QLStyle.secondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
      Image(systemName: "terminal.fill")
        .font(.system(size: size * 0.42, weight: .semibold))
        .foregroundColor(.white)
    }
    .frame(width: size, height: size)
    .shadow(color: QLStyle.primary.opacity(0.24), radius: 10, x: 0, y: 6)
  }
}

struct CardBackground: ViewModifier {
  func body(content: Content) -> some View {
    content
      .padding(14)
      .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: QLStyle.cardCorner, style: .continuous))
  }
}

extension View {
  func qlCard() -> some View {
    modifier(CardBackground())
  }
}
