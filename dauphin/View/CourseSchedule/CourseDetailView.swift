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

  // Get day of week string
  private var dayOfWeek: String {
    let days = ["", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    return days[min(max(course.weekday, 0), days.count - 1)]
  }

  // Format time for display
  private var timeRange: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    let start = formatter.string(from: course.startTime)
    let end = formatter.string(from: course.endTime)
    return "\(start) - \(end)"
  }

  // Color variations for different courses (same as CourseView)
  private var courseColor: Color {
    let colors: [Color] = [
      Color(red: 0.2, green: 0.6, blue: 1.0),  // Blue
      Color(red: 0.4, green: 0.8, blue: 0.6),  // Green
      Color(red: 1.0, green: 0.6, blue: 0.4),  // Orange
      Color(red: 0.8, green: 0.4, blue: 0.8),  // Purple
      Color(red: 0.95, green: 0.7, blue: 0.3),  // Yellow
      Color(red: 0.3, green: 0.7, blue: 0.8),  // Cyan
      Color(red: 0.9, green: 0.5, blue: 0.5),  // Red
    ]
    let index = abs(course.name.hashValue) % colors.count
    return colors[index]
  }

  var body: some View {
    NavigationView {
      ScrollView {
        VStack(spacing: 0) {
          // Header with color
          VStack(spacing: 12) {
            Text(course.name)
              .font(.title2)
              .fontWeight(.bold)
              .foregroundColor(.white)
              .multilineTextAlignment(.center)
              .padding(.horizontal)
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 32)
          .background(courseColor)

          // Course details
          VStack(alignment: .leading, spacing: 20) {
            // Time section
            HStack(spacing: 16) {
              Image(systemName: "clock.fill")
                .font(.system(size: 22))
                .foregroundColor(courseColor)
                .frame(width: 30)

              VStack(alignment: .leading, spacing: 4) {
                Text("Time")
                  .font(.caption)
                  .foregroundColor(Color(UIColor.secondaryLabel))
                Text(timeRange)
                  .font(.system(size: 16, weight: .medium))
                  .foregroundColor(Color(UIColor.label))
                Text(dayOfWeek)
                  .font(.system(size: 14))
                  .foregroundColor(Color(UIColor.secondaryLabel))
              }

              Spacer()
            }

            Divider()

            // Location section
            HStack(spacing: 16) {
              Image(systemName: "location.circle.fill")
                .font(.system(size: 22))
                .foregroundColor(courseColor)
                .frame(width: 30)

              VStack(alignment: .leading, spacing: 4) {
                Text("Location")
                  .font(.caption)
                  .foregroundColor(Color(UIColor.secondaryLabel))
                Text(course.room)
                  .font(.system(size: 16, weight: .medium))
                  .foregroundColor(Color(UIColor.label))
              }

              Spacer()
            }

            Divider()

            // Teacher section
            HStack(spacing: 16) {
              Image(systemName: "person.fill")
                .font(.system(size: 22))
                .foregroundColor(courseColor)
                .frame(width: 30)

              VStack(alignment: .leading, spacing: 4) {
                Text("Instructor")
                  .font(.caption)
                  .foregroundColor(Color(UIColor.secondaryLabel))
                Text(course.teacher)
                  .font(.system(size: 16, weight: .medium))
                  .foregroundColor(Color(UIColor.label))
              }

              Spacer()
            }

            Divider()

            // Seat number section
            HStack(spacing: 16) {
              Image(systemName: "number.circle.fill")
                .font(.system(size: 22))
                .foregroundColor(courseColor)
                .frame(width: 30)

              VStack(alignment: .leading, spacing: 4) {
                Text("Seat Number")
                  .font(.caption)
                  .foregroundColor(Color(UIColor.secondaryLabel))
                Text(course.stdNo)
                  .font(.system(size: 16, weight: .medium))
                  .foregroundColor(Color(UIColor.label))
              }

              Spacer()
            }

            // Note section (only show if note is not empty)
            if !course.note.isEmpty {
              Divider()

              HStack(alignment: .top, spacing: 16) {
                Image(systemName: "note.text")
                  .font(.system(size: 22))
                  .foregroundColor(courseColor)
                  .frame(width: 30)

                VStack(alignment: .leading, spacing: 4) {
                  Text("Note")
                    .font(.caption)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                  Text(course.note)
                    .font(.system(size: 14))
                    .foregroundColor(Color(UIColor.label))
                    .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
              }
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
