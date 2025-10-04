//
//  NextUpSmallView.swift
//  CoursesWidgetExtension
//
//  Created by \u8b19 on 11/29/24.
//

import SwiftUI
import WidgetKit

struct CoursesNextUpSmallView: View {
  @Environment(\.colorScheme) var colorScheme
  var entry: Provider.Entry
  let currentWeekday = Calendar.current.component(.weekday, from: Date())

  var todayNotDoneCount: Int {
    entry.courses.filter { $0.weekday == currentWeekday }.count
  }

  // Helper function to convert weekday index to name
  func weekdayName(for weekday: Int) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US")
    formatter.dateFormat = "EEEE"
    let date = Calendar.current.date(bySetting: .weekday, value: weekday + 1, of: Date())!
    return formatter.string(from: date)
  }

  var body: some View {
    if entry.ssoStuNo.isEmpty {
      VStack(spacing: 8) {
        Image(systemName: "person.text.rectangle.trianglebadge.exclamationmark.fill")
          .font(.system(size: 60, weight: .semibold))

        Text("尚未登入")
          .font(.caption)
          .fontWeight(.medium)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .containerBackground(for: .widget) {
          Color(UIColor.systemBackground)
      }
    } else {
      if entry.courses.isEmpty {
        VStack(spacing: 8) {
          Image(systemName: "figure.wave")
            .font(.system(size: 60, weight: .semibold))

          Text("下週見")
            .font(.caption)
            .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) {
            Color(UIColor.systemBackground)
        }
      } else {
          VStack(alignment: .leading, spacing: 6) {
          // First Event
          VStack(alignment: .leading, spacing: 2) {
            VStack(alignment: .leading, spacing: 0) {
              Text("\(entry.courses[0].name)")
                .lineLimit(1)
                .font(.subheadline)
                .foregroundColor(.primary)
              Text(
                "\(formatTime(entry.courses[0].startTime)) - \(formatTime(entry.courses[0].endTime))"
              )
              .font(.footnote)
              .foregroundColor(.secondary)
            }

            HStack(spacing: 3) {
              HStack(spacing: 2) {
                Image(systemName: "location.circle.fill")
                  .font(.system(size: 8))
                Text("\(entry.courses[0].room)")
                  .font(.system(size: 10))
              }
              .lineLimit(1)
              .padding(.vertical, 2)
              .padding(.horizontal, 5)
              .background(Color.blue.opacity(0.6))
              .cornerRadius(4)

              HStack(spacing: 0) {
                Image(systemName: "graduationcap")
                  .font(.system(size: 8))
                Text("\(entry.courses[0].stdNo)")
                  .font(.system(size: 10))
              }
              .lineLimit(1)
              .padding(.vertical, 2)
              .padding(.horizontal, 5)
              .background(Color.blue.opacity(0.6))
              .cornerRadius(4)
            }
          }
          .padding(.bottom, 3)
          .overlay(
            Capsule()
              .fill(Color.blue)
              .frame(width: 4)
              .padding(.leading, -8),
            alignment: .leading
          )

          Divider().padding(.leading, -8)

          // Second Event
          if entry.courses.count > 1 {
            let isSameDay = entry.courses[0].weekday == entry.courses[1].weekday
            let secondCourseWeekday = weekdayName(for: entry.courses[1].weekday)

            VStack(alignment: .leading, spacing: 2) {
              if !isSameDay {
                Text(secondCourseWeekday)
                  .font(.caption)
                  .foregroundColor(.secondary)
                  .padding(.leading, -10)
              } else {
                Color.clear.frame(height: 14)
              }
              VStack(alignment: .leading, spacing: 0) {
                Text("\(entry.courses[1].name)")
                  .font(.subheadline)
                  .foregroundColor(.primary)
                  .lineLimit(1)
                Text(
                  "\(formatTime(entry.courses[1].startTime)) - \(formatTime(entry.courses[1].endTime))"
                )
                .font(.caption)
                .foregroundColor(.secondary)
              }
              .padding(.bottom, 2)
              .overlay(
                Capsule()
                  .fill(isSameDay ? Color.blue : Color.orange)
                  .frame(width: 4)
                  .padding(.leading, -8),
                alignment: .leading
              )
            }
          } else {
            Color.clear.frame(height: 50)
          }
        }
        .padding([.leading], 6)
        .containerBackground(for: .widget) {
          Color(UIColor.systemBackground)
        }
      }
    }
  }
}

#Preview(as: .systemSmall) {
  CoursesNextUpWidget()
} timeline: {
  SimpleEntry(date: Date(), ssoStuNo: "123456789", courses: mockData, today: mockData.count)

  SimpleEntry(
    date: Date(),
    ssoStuNo: "123456789",
    courses: getUpcomingCourses(
      from: mockData,
      currentDate: Calendar.current.date(from: DateComponents(year: 2025, month: 9, day: 29, hour: 21, minute: 0))!
    ),
    today: mockData.count
  )

  SimpleEntry(date: Date(), ssoStuNo: "123456789", courses: [mockData[0]], today: mockData.count)
    
  SimpleEntry(date: Date(), ssoStuNo: "", courses: mockData, today: mockData.count)
    
  SimpleEntry(
  date: Date(), 
  ssoStuNo: "123456789", 
  courses: getUpcomingCourses(
    from: mockData,
    currentDate: Calendar.current.date(from: DateComponents(year: 2025, month: 9, day: 27, hour: 22, minute: 0))!
  ),
  today: mockData.count
  )
}
