//
//  CourseView.swift
//  dauphin
//
//  Course card component for timeline view
//

import SwiftUI

struct CourseView: View {
  let course: Course
  let height: CGFloat
  let yOffset: CGFloat

  @State private var isOngoing = false
  @State private var currentTime = Date()
  let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

  // MARK: - Mock Date for Testing
  // October 3, 2025 at 1:30 PM (Friday)
  private let useMockDate = false
  private var mockDate: Date {
    let calendar = Calendar.current
    var components = DateComponents()
    components.year = 2025
    components.month = 10
    components.day = 3
    components.hour = 13
    components.minute = 30
    components.second = 0
    return calendar.date(from: components) ?? Date()
  }

  private func getCurrentDate() -> Date {
    return useMockDate ? mockDate : Date()
  }

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
          HStack(alignment: .top, spacing: 0) {
            Text(course.name)
              .font(.system(size: 11, weight: .semibold))
              .foregroundColor(.white)
              .lineLimit(2)
            Spacer()
            if isOngoing {
              OngoingStatusIndicator(
                fontSize: 10,
                showDotOnly: true
              )
              .shadow(
                color: .black.opacity(0.3),
                radius: 2,
                x: 0,
                y: 0
              )
            }
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
            Image(systemName: "number.circle.fill")
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
      .onAppear {
        updateOngoingStatus()
      }
      .onReceive(timer) { _ in
        updateOngoingStatus()
      }
  }

  private func updateOngoingStatus() {
    currentTime = getCurrentDate()

    let calendar = Calendar.current
    let now = getCurrentDate()

    let currentWeekday = calendar.component(.weekday, from: now)

    // Convert course weekday to iOS format (iOS: Sunday = 1, our format: Monday = 1)
    let courseWeekdayIOS = course.weekday == 7 ? 1 : course.weekday + 1

    // If not today, not ongoing
    if currentWeekday != courseWeekdayIOS {
      isOngoing = false
      return
    }

    // Check time if it's the right day
    let currentHour = calendar.component(.hour, from: now)
    let currentMinute = calendar.component(.minute, from: now)
    let currentTimeInMinutes = currentHour * 60 + currentMinute

    let startHour = calendar.component(.hour, from: course.startTime)
    let startMinute = calendar.component(.minute, from: course.startTime)
    let startTimeInMinutes = startHour * 60 + startMinute

    let endHour = calendar.component(.hour, from: course.endTime)
    let endMinute = calendar.component(.minute, from: course.endTime)
    let endTimeInMinutes = endHour * 60 + endMinute

    // Check if current time is between start and end times
    isOngoing =
      currentTimeInMinutes >= startTimeInMinutes && currentTimeInMinutes <= endTimeInMinutes
  }
}
