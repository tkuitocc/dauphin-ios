import SwiftUI

class CourseColors {
  static let shared = CourseColors()

  private let palette: [Color] = [
    Color(red: 0.15, green: 0.45, blue: 0.85),  // Deep Blue
    Color(red: 0.25, green: 0.6, blue: 0.45),   // Forest Green
    Color(red: 0.85, green: 0.45, blue: 0.25),  // Burnt Orange
    Color(red: 0.55, green: 0.3, blue: 0.65),   // Deep Purple
    Color(red: 0.75, green: 0.55, blue: 0.15),  // Amber
    Color(red: 0.2, green: 0.55, blue: 0.65),   // Teal
    Color(red: 0.75, green: 0.35, blue: 0.35),  // Crimson
    Color(red: 0.45, green: 0.35, blue: 0.75),  // Indigo
    Color(red: 0.7, green: 0.3, blue: 0.55),    // Magenta
    Color(red: 0.4, green: 0.7, blue: 0.3),     // Grass Green
    Color(red: 0.25, green: 0.65, blue: 0.7),   // Cyan
    Color(red: 0.6, green: 0.3, blue: 0.35),    // Maroon
    Color(red: 0.4, green: 0.25, blue: 0.6),    // Violet
    Color(red: 0.7, green: 0.5, blue: 0.35),    // Bronze
    Color(red: 0.25, green: 0.4, blue: 0.3),    // Dark Green
    Color(red: 0.6, green: 0.45, blue: 0.65),   // Lavender
    Color(red: 0.45, green: 0.65, blue: 0.35),  // Olive
    Color(red: 0.75, green: 0.4, blue: 0.25),   // Sienna
    Color(red: 0.3, green: 0.45, blue: 0.65),   // Steel Blue
    Color(red: 0.55, green: 0.35, blue: 0.45),  // Plum
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
