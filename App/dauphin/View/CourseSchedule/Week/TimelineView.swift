//
//  TimelineView.swift
//  dauphin
//
//  Created by \u8b19 on 12/13/24.
//

import SwiftUI

struct TimelineView: View {
  @Binding var courses: [Course]
  var onCourseTap: ((Course) -> Void)?
  var overlapGap: CGFloat = 2
  var verticalGap: CGFloat = 2

  let start = Calendar.current.date(
    bySettingHour: 8, minute: 10, second: 0, of: Calendar.current.startOfDay(for: Date())
  )!
  let end = Calendar.current.date(
    bySettingHour: 22, minute: 0, second: 0, of: Calendar.current.startOfDay(for: Date())
  )!

  private let calendar = Calendar.current

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
    let start1 = normalized(course1.startTime)
    let end1 = normalized(course1.endTime)
    let start2 = normalized(course2.startTime)
    let end2 = normalized(course2.endTime)
    return start1 < end2 && end1 > start2
  }

  var body: some View {
    GeometryReader { _ in
      let totalHeight = ScheduleLayout.totalHeight
      let numberOfSlots = ScheduleLayout.slotCount

      ZStack(alignment: .top) {
        // Grid
        TimeSlotGrid(numberOfSlots: numberOfSlots, totalHeight: totalHeight)

        // Courses with overlap handling
        ForEach(positionedCourses, id: \.course.id) { position in
          let courseStart = normalized(position.course.startTime)
          let courseEnd = normalized(position.course.endTime)

          GeometryReader { geo in
            let totalWidth = geo.size.width

            if position.totalColumns == 1 {
              let courseWidth: CGFloat = totalWidth
              let xOffset: CGFloat = 0
              let vGap = max(0, verticalGap)
              let cardHeight = max(
                0, heightForEvent(courseStart, courseEnd, in: totalHeight) - vGap)
              let yBase = yPosition(for: courseStart, in: totalHeight) + vGap / 2

              CourseView(
                course: position.course,
                height: cardHeight,
                yOffset: yBase
              )
              .frame(width: courseWidth)
              .offset(x: xOffset)
              .onTapGesture {
                onCourseTap?(position.course)
              }
            } else {
              let gap = max(0, overlapGap)
              let totalGaps = gap * CGFloat(position.totalColumns - 1)
              let availableWidth = max(0, totalWidth - totalGaps)
              let courseWidth: CGFloat =
                position.totalColumns > 0
                ? availableWidth / CGFloat(position.totalColumns)
                : totalWidth
              let xOffset: CGFloat = (courseWidth + gap) * CGFloat(position.column)
              let vGap = max(0, verticalGap)
              let cardHeight = max(
                0, heightForEvent(courseStart, courseEnd, in: totalHeight) - vGap)
              let yBase = yPosition(for: courseStart, in: totalHeight) + vGap / 2

              CourseView(
                course: position.course,
                height: cardHeight,
                yOffset: yBase
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

  private func normalized(_ date: Date) -> Date {
    let components = calendar.dateComponents([.hour, .minute, .second], from: date)
    return calendar.date(
      bySettingHour: components.hour ?? 0,
      minute: components.minute ?? 0,
      second: components.second ?? 0,
      of: calendar.startOfDay(for: start)
    ) ?? date
  }

  // 計算課程的高度
  private func heightForEvent(_ startTime: Date, _ endTime: Date, in totalHeight: CGFloat)
    -> CGFloat
  {
    let totalDuration = end.timeIntervalSince(start)
    guard totalDuration > 0 else { return 0 }

    let clampedStart = max(start, min(end, startTime))
    let clampedEnd = max(clampedStart, min(end, endTime))
    let eventDuration = clampedEnd.timeIntervalSince(clampedStart)
    return CGFloat(eventDuration / totalDuration) * totalHeight
  }

  // 計算課程的垂直位置
  private func yPosition(for time: Date, in totalHeight: CGFloat) -> CGFloat {
    let totalDuration = end.timeIntervalSince(start)
    guard totalDuration > 0 else { return 0 }
    let clamped = max(start, min(end, time))
    let eventOffset = clamped.timeIntervalSince(start)
    let relativePosition = eventOffset / totalDuration
    return CGFloat(relativePosition) * totalHeight
  }
}

#Preview {
  let courseViewModel = CourseViewModel(mockData: mockData)
  ScrollView {
    TimelineView(
      courses: Binding(
        get: { courseViewModel.weekCourses.filter { $0.weekday == 1 } },
        set: { _ in
        }
      )
    )
  }
}
