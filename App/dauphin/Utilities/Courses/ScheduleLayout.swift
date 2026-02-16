import CoreGraphics

enum ScheduleLayout {
  static let startHour = 8
  static let endHour = 22
  static let slotHeight: CGFloat = 99

  static var slotCount: Int {
    endHour - startHour + 1
  }

  static var totalHeight: CGFloat {
    CGFloat(slotCount) * slotHeight
  }
}
