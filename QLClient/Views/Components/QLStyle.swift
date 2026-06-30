import SwiftUI

enum QLStyle {
  static let primary = Color(red: 0.00, green: 0.62, blue: 0.52)
  static let secondary = Color(red: 0.12, green: 0.44, blue: 0.88)
  static let amber = Color(red: 0.95, green: 0.58, blue: 0.18)
  static let success = Color(red: 0.10, green: 0.66, blue: 0.36)
  static let warning = Color(red: 0.94, green: 0.52, blue: 0.16)
  static let danger = Color(red: 0.88, green: 0.20, blue: 0.22)
  static let appBackground = Color(.systemGroupedBackground)
  static let surface = Color(.secondarySystemGroupedBackground)
  static let elevatedSurface = Color(.tertiarySystemGroupedBackground)
  static let cardCorner: CGFloat = 12
  static let rowCorner: CGFloat = 10
}

extension QLStyle {
  static func accentGradient(_ color: Color = QLStyle.primary) -> LinearGradient {
    LinearGradient(
      colors: [color, QLStyle.secondary.opacity(0.72)],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }
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
      .background(QLStyle.surface, in: RoundedRectangle(cornerRadius: QLStyle.cardCorner, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: QLStyle.cardCorner, style: .continuous)
          .stroke(Color.primary.opacity(0.05), lineWidth: 1)
      )
  }
}

struct QLIconTile: View {
  let systemImage: String
  let color: Color
  var filled = false
  var size: CGFloat = 34

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 9, style: .continuous)
        .fill(filled ? AnyShapeStyle(QLStyle.accentGradient(color)) : AnyShapeStyle(color.opacity(0.12)))
      Image(systemName: systemImage)
        .font(.system(size: size * 0.52, weight: .semibold))
        .foregroundColor(filled ? .white : color)
    }
    .frame(width: size, height: size)
    .shadow(color: color.opacity(filled ? 0.16 : 0), radius: 6, x: 0, y: 3)
  }
}

struct RowCardBackground: ViewModifier {
  func body(content: Content) -> some View {
    content
      .listRowInsets(EdgeInsets(top: 3, leading: 16, bottom: 3, trailing: 14))
      .listRowBackground(QLStyle.surface)
  }
}

struct ListSurfaceBackground: ViewModifier {
  func body(content: Content) -> some View {
    content
      .scrollContentBackground(.hidden)
      .background(QLStyle.appBackground)
  }
}

extension View {
  func qlCard() -> some View {
    modifier(CardBackground())
  }

  func qlRowCard() -> some View {
    modifier(RowCardBackground())
  }

  func qlListBackground() -> some View {
    modifier(ListSurfaceBackground())
  }
}
