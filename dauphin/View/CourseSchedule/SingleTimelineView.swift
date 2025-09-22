//
//  SingleTimelineView.swift
//  dauphin
//
//  Created by \u8b19 on 12/13/24.
//

import SwiftUI

struct SingleTimeline: View {
  @Binding var courses: [Course]
  var onCourseTap: ((Course) -> Void)? = nil
  var overlapGap: CGFloat = -4

  let start = Calendar.current.date(
    bySettingHour: 8, minute: 0, second: 0, of: Calendar.current.startOfDay(for: Date()))!
  let end = Calendar.current.date(
    bySettingHour: 22, minute: 0, second: 0, of: Calendar.current.startOfDay(for: Date()))!

  // Structure to hold course positioning information
  struct CoursePosition {
    let course: Course
    let column: Int
    let totalColumns: Int
  }

  // Calculate overlapping groups and assign columns
  private var positionedCourses: [CoursePosition] {
    var groups: [[Course]] = []
    let sortedCourses = courses.sorted { $0.startTime < $1.startTime }

    for course in sortedCourses {
      var added = false

      // Try to add to an existing group
      for i in 0..<groups.count {
        let group = groups[i]
        var hasOverlap = false

        for existingCourse in group {
          if coursesOverlap(course, existingCourse) {
            hasOverlap = true
            break
          }
        }

        if hasOverlap {
          // Add to this group
          groups[i].append(course)
          added = true
          break
        }
      }

      // Create new group if not added
      if !added {
        groups.append([course])
      }
    }

    // Now assign positions within each group
    var positions: [CoursePosition] = []

    for group in groups {
      // Find all courses that overlap with each other in this group
      var overlapSets: [[Course]] = []

      for course in group {
        var addedToSet = false

        for i in 0..<overlapSets.count {
          // Check if this course overlaps with any course in this set
          var overlapsWithAll = false
          for setCourse in overlapSets[i] {
            if coursesOverlap(course, setCourse) {
              overlapsWithAll = true
              break
            }
          }

          if overlapsWithAll {
            overlapSets[i].append(course)
            addedToSet = true
            break
          }
        }

        if !addedToSet {
          overlapSets.append([course])
        }
      }

      // Assign columns within each overlap set
      for overlapSet in overlapSets {
        let totalColumns = overlapSet.count
        for (index, course) in overlapSet.enumerated() {
          positions.append(
            CoursePosition(
              course: course,
              column: index,
              totalColumns: totalColumns
            ))
        }
      }
    }

    return positions
  }

  // Check if two courses overlap
  private func coursesOverlap(_ course1: Course, _ course2: Course) -> Bool {
    let start1 = adjustedTime(for: course1.startTime)
    let end1 = adjustedTime(for: course1.endTime)
    let start2 = adjustedTime(for: course2.startTime)
    let end2 = adjustedTime(for: course2.endTime)

    // Courses overlap if one starts before the other ends
    return (start1 < end2 && end1 > start2)
  }

  var body: some View {
    GeometryReader { geometry in
      let totalHeight = CGFloat(1400)
      let numberOfSlots = 14

      ZStack(alignment: .top) {
        // Grid
        TimeSlotGrid(numberOfSlots: numberOfSlots, totalHeight: totalHeight)

        // Courses with overlap handling
        ForEach(positionedCourses, id: \.course.id) { position in
          let adjustedStartTime = adjustedTime(for: position.course.startTime)
          let adjustedEndTime = adjustedTime(for: position.course.endTime)

          GeometryReader { geo in
            let totalWidth = geo.size.width

            if position.totalColumns == 1 {
              let courseWidth: CGFloat = totalWidth
              let xOffset: CGFloat = 0

              CourseView(
                course: position.course,
                height: heightForEvent(adjustedStartTime, adjustedEndTime, in: totalHeight),
                yOffset: yPosition(for: adjustedStartTime, in: totalHeight)
              )
              .frame(width: courseWidth)
              .offset(x: xOffset)
              .onTapGesture {
                onCourseTap?(position.course)
              }
            } else {
              let totalGaps = overlapGap * CGFloat(position.totalColumns - 1)
              let availableWidth = totalWidth - totalGaps
              let courseWidth: CGFloat = availableWidth / CGFloat(position.totalColumns)
              let xOffset: CGFloat = (courseWidth + overlapGap) * CGFloat(position.column)

              CourseView(
                course: position.course,
                height: heightForEvent(adjustedStartTime, adjustedEndTime, in: totalHeight),
                yOffset: yPosition(for: adjustedStartTime, in: totalHeight)
              )
              .frame(width: courseWidth)
              .offset(x: xOffset)
              .onTapGesture {
                onCourseTap?(position.course)
              }
            }

          }
          .frame(height: totalHeight)
        }
      }
    }
  }

  // 調整時間到整點
  private func adjustedTime(for time: Date) -> Date {
    let baseDate = Calendar.current.startOfDay(for: Date())
    let calendar = Calendar.current
    return calendar.date(
      bySettingHour: calendar.component(.hour, from: time), minute: 0, second: 0, of: baseDate)!
  }

  // 計算課程的高度
  private func heightForEvent(_ startTime: Date, _ endTime: Date, in totalHeight: CGFloat)
    -> CGFloat
  {
    let totalDuration = end.timeIntervalSince(start)
    let eventDuration = endTime.timeIntervalSince(startTime)
    return CGFloat(eventDuration / totalDuration) * totalHeight
  }

  // 計算課程的垂直位置
  private func yPosition(for time: Date, in totalHeight: CGFloat) -> CGFloat {
    let totalDuration = end.timeIntervalSince(start)
    let eventOffset = time.timeIntervalSince(start)
    let relativePosition = eventOffset / totalDuration
    return CGFloat(relativePosition) * totalHeight
  }
}

struct TimeSlotGrid: View {
  let numberOfSlots: Int
  let totalHeight: CGFloat

  var body: some View {
    VStack(spacing: 0) {
      ForEach(0..<numberOfSlots, id: \.self) { index in
        Rectangle()
          .stroke(Color.gray.opacity(0.4), lineWidth: 0.3)
          .frame(height: totalHeight / CGFloat(numberOfSlots))
      }
    }
  }
}

struct CourseView: View {
  let course: Course
  let height: CGFloat
  let yOffset: CGFloat

  private var courseColor: Color {
    CourseColors.color(for: course.name)
  }

  var body: some View {
    RoundedRectangle(cornerRadius: 8)
      .fill(courseColor.opacity(0.85))
      .frame(height: max(height - 4, 20))  // Fixed 4pt gap for even spacing
      .overlay(
        RoundedRectangle(cornerRadius: 8)
          .strokeBorder(courseColor, lineWidth: 1.5)
      )
      .overlay(
        VStack(alignment: .leading, spacing: 3) {
          HStack {
            Text(course.name)
              .font(.system(size: 11, weight: .semibold))
              .foregroundColor(.white)
              .lineLimit(2)
            Spacer()
          }
          HStack(spacing: 3) {
            Image(systemName: "location.circle.fill")
              .font(.system(size: 9))
              .foregroundColor(.white.opacity(0.9))
            Text(course.room)
              .font(.system(size: 10))
              .foregroundColor(.white.opacity(0.95))
          }
          HStack(spacing: 3) {
            Image(systemName: "person.fill")
              .font(.system(size: 9))
              .foregroundColor(.white.opacity(0.9))
            Text(course.stdNo)
              .font(.system(size: 10))
              .foregroundColor(.white.opacity(0.95))
          }
        }
        .padding(8),
        alignment: .topLeading
      )
      .shadow(color: courseColor.opacity(0.3), radius: 2, x: 0, y: 1)
      .offset(y: yOffset)
      .padding(.horizontal, 4)
  }
}

#Preview {
  let courseViewModel = CourseViewModel(mockData: mockData)
  ScrollView {
    SingleTimeline(
      courses: Binding(
        get: { courseViewModel.weekCourses.filter { $0.weekday == 1 } },
        set: { newValue in
          // Update courseViewModel.weekCourses with the changes from newValue
          // This may require additional logic to ensure filtered courses are updated correctly
        }
      ),
      overlapGap: 4)
  }
}
