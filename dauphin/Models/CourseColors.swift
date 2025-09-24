import SwiftUI

class CourseColors {
  static let shared = CourseColors()

  private let palette: [Color] = [
    Color(red: 0.2, green: 0.6, blue: 1.0),  // Blue
    Color(red: 0.4, green: 0.8, blue: 0.6),  // Green
    Color(red: 1.0, green: 0.6, blue: 0.4),  // Orange
    Color(red: 0.8, green: 0.4, blue: 0.8),  // Purple
    Color(red: 0.95, green: 0.7, blue: 0.3),  // Yellow
    Color(red: 0.3, green: 0.7, blue: 0.8),  // Cyan
    Color(red: 0.9, green: 0.5, blue: 0.5),  // Red
    Color(red: 0.6, green: 0.5, blue: 0.9),  // Indigo
    Color(red: 0.9, green: 0.4, blue: 0.7),  // Pink
    Color(red: 0.5, green: 0.9, blue: 0.4),  // Lime
    Color(red: 0.4, green: 0.9, blue: 0.9),  // Aqua
    Color(red: 0.7, green: 0.4, blue: 0.5),  // Maroon
    Color(red: 0.5, green: 0.3, blue: 0.7),  // Violet
    Color(red: 0.9, green: 0.7, blue: 0.5),  // Peach
    Color(red: 0.3, green: 0.5, blue: 0.4),  // Forest Green
    Color(red: 0.8, green: 0.6, blue: 0.8),  // Lavender
    Color(red: 0.6, green: 0.8, blue: 0.5),  // Light Green
    Color(red: 0.9, green: 0.5, blue: 0.3),  // Coral
    Color(red: 0.4, green: 0.6, blue: 0.8),  // Sky Blue
    Color(red: 0.7, green: 0.5, blue: 0.6),  // Dusty Rose
  ]

  private var courseColorMap: [String: Color] = [:]
  private var usedColorIndices: Set<Int> = []
  private var nextColorIndex: Int = 0

  private init() {}

  static func color(for courseName: String) -> Color {
    return shared.getColor(for: courseName)
  }

  private func getColor(for courseName: String) -> Color {
    // If we already assigned a color to this course, return it
    if let existingColor = courseColorMap[courseName] {
      return existingColor
    }

    // If all colors are used, reset and start over
    if usedColorIndices.count >= palette.count {
      usedColorIndices.removeAll()
      nextColorIndex = 0
    }

    // Find the next unused color
    while usedColorIndices.contains(nextColorIndex) {
      nextColorIndex = (nextColorIndex + 1) % palette.count
    }

    // Assign the color
    let color = palette[nextColorIndex]
    courseColorMap[courseName] = color
    usedColorIndices.insert(nextColorIndex)

    // Move to next index for next course
    nextColorIndex = (nextColorIndex + 1) % palette.count

    return color
  }

  // Optional: Reset colors (useful when reloading courses)
  static func reset() {
    shared.courseColorMap.removeAll()
    shared.usedColorIndices.removeAll()
    shared.nextColorIndex = 0
  }
}
