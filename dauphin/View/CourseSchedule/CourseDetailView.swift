//
//  CourseDetailView.swift
//  dauphin
//
//  Created on 2025-09-19.
//

import SwiftUI

struct CourseDetailView: View {
  let course: Course
  @Environment(\.dismiss) var dismiss

  // Cache expensive computations
  private let dayOfWeek: String
  private let timeRange: String
  private let courseColor: Color
  private let hasNote: Bool

  init(course: Course) {
    self.course = course

    // Pre-compute day of week
    let days = ["", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    self.dayOfWeek = days[min(max(course.weekday, 0), days.count - 1)]

    // Pre-compute time range with cached formatter
    let formatter = CourseDetailView.timeFormatter
    let start = formatter.string(from: course.startTime)
    let end = formatter.string(from: course.endTime)
    self.timeRange = "\(start) - \(end)"

    // Pre-compute color
    self.courseColor = CourseColors.color(for: course.name)

    // Pre-compute note check
    self.hasNote = !course.note.isEmpty
  }

  // Shared formatter to avoid recreation
  private static let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    return formatter
  }()

  var body: some View {
    NavigationView {
      ScrollView {
        VStack(spacing: 0) {
          // Header with color
          headerView

          // Course details
          VStack(alignment: .leading, spacing: 20) {
            detailRow(icon: "clock.fill", title: "Time", content: timeRange, subcontent: dayOfWeek)
            Divider()
            detailRow(icon: "location.circle.fill", title: "Location", content: course.room)
            Divider()
            detailRow(icon: "person.fill", title: "Instructor", content: course.teacher)
            Divider()
            detailRow(icon: "number.circle.fill", title: "Seat Number", content: course.stdNo)

            // Note section (only show if note is not empty)
            if hasNote {
              Divider()
              detailRow(icon: "note.text", title: "Note", content: course.note, isNote: true)
            }
          }
          .padding(24)
          .background(Color(UIColor.systemBackground))
        }
      }
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Done") {
            dismiss()
          }
          .fontWeight(.medium)
        }
      }
    }
  }

  // Extract header as ViewBuilder for better performance
  @ViewBuilder
  private var headerView: some View {
    Text(course.name)
      .font(.title2)
      .fontWeight(.bold)
      .foregroundColor(.white)
      .multilineTextAlignment(.center)
      .padding(.horizontal)
      .frame(maxWidth: .infinity)
      .padding(.vertical, 32)
      .background(courseColor)
  }

  // Reusable detail row component to reduce code duplication
  @ViewBuilder
  private func detailRow(
    icon: String, title: String, content: String, subcontent: String? = nil, isNote: Bool = false
  ) -> some View {
    HStack(spacing: 16) {
      Image(systemName: icon)
        .font(.system(size: 22))
        .foregroundColor(courseColor)
        .frame(width: 30)

      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(.caption)
          .foregroundColor(Color(UIColor.secondaryLabel))
        Text(content)
          .font(.system(size: isNote ? 14 : 16, weight: isNote ? .regular : .medium))
          .foregroundColor(Color(UIColor.label))
          .fixedSize(horizontal: false, vertical: isNote)
        if let subcontent = subcontent {
          Text(subcontent)
            .font(.system(size: 14))
            .foregroundColor(Color(UIColor.secondaryLabel))
        }
      }

      Spacer()
    }
  }
}

#Preview {
  CourseDetailView(
    course: Course(
      name: "Programming",
      room: "E236",
      teacher: "Dr. Smith",
      time: "1, 2",
      startTime: Date(),
      endTime: Date().addingTimeInterval(3600),
      stdNo: "A12",
      weekday: 1,
      note: "This is a sample note for the course"
    )
  )
}
