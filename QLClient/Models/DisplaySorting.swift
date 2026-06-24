import Foundation

extension Array where Element == CronItem {
  func sortedForDisplay() -> [CronItem] {
    sorted { left, right in
      if left.isPinnedOnTop != right.isPinnedOnTop {
        return left.isPinnedOnTop
      }
      if left.isEnabled != right.isEnabled {
        return left.isEnabled
      }
      if (left.status ?? 1) != (right.status ?? 1) {
        return (left.status ?? 1) < (right.status ?? 1)
      }
      return (left.createdAt ?? "") > (right.createdAt ?? "")
    }
  }
}

extension Array where Element == EnvItem {
  func sortedForDisplay() -> [EnvItem] {
    sorted { left, right in
      if left.isPinnedOnTop != right.isPinnedOnTop {
        return left.isPinnedOnTop
      }
      if (left.position ?? 0) != (right.position ?? 0) {
        return (left.position ?? 0) > (right.position ?? 0)
      }
      return left.id < right.id
    }
  }
}
