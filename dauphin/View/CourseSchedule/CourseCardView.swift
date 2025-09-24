//
//  CourseCardView.swift
//  campuspass_ios
//
//  Created by \u8b19 on 11/17/24.
//
import SwiftUI

struct CourseCardView: View {
  let courseName: String
  let roomNumber: String
  let teacherName: String
  let StartTime: Date
  let EndTime: Date
  let stdNo: String
  let weekday: Int

  @Environment(\.colorScheme) var colorScheme
  @State private var isOngoing = false
  @State private var currentTime = Date()
  let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

  private var timeColor: Color {
    if isOngoing {
      return .green
    } else {
      // Compare only time components for future courses
      let calendar = Calendar.current
      let currentHour = calendar.component(.hour, from: currentTime)
      let currentMinute = calendar.component(.minute, from: currentTime)
      let currentTimeInMinutes = currentHour * 60 + currentMinute

      let startHour = calendar.component(.hour, from: StartTime)
      let startMinute = calendar.component(.minute, from: StartTime)
      let startTimeInMinutes = startHour * 60 + startMinute

      if currentTimeInMinutes < startTimeInMinutes {
        return .accentColor
      } else {
        return .secondary
      }
    }
  }

  private var cardBackground: Color {
    colorScheme == .dark
      ? Color(UIColor.secondarySystemGroupedBackground)
      : Color(UIColor.systemBackground)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        // Time Badge
        HStack(spacing: 4) {
          Image(systemName: "clock.fill")
            .font(.system(size: 11))
          Text("\(formatTime(StartTime)) - \(formatTime(EndTime))")
            .font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(timeColor)
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(timeColor.opacity(0.15))
        .clipShape(Capsule())

        Spacer()

        // Status Indicator
        if isOngoing {
          HStack(spacing: 6) {
            ZStack {
              // Outer pulsing circle
              Circle()
                .fill(Color.green.opacity(0.3))
                .frame(width: 16, height: 16)
                .modifier(PulsingAnimation(finalScale: 1.5, finalOpacity: 0.3, duration: 1.0))

              // Middle pulsing circle
              Circle()
                .fill(Color.green.opacity(0.5))
                .frame(width: 12, height: 12)
                .modifier(PulsingAnimation(finalScale: 1.3, duration: 1.0))

              // Core dot that pulses
              Circle()
                .fill(Color.green)
                .frame(width: 8, height: 8)
                .modifier(PulsingAnimation(finalScale: 1.2, initialScale: 0.8, duration: 1.0))
            }

            Text("Ongoing")
              .font(.system(size: 12, weight: .semibold))
              .foregroundColor(.green)
          }
        }
      }

      // Course Name
      Text(courseName)
        .font(.system(size: 24, weight: .semibold))
        .foregroundColor(.primary)
        .lineLimit(2)
        .fixedSize(horizontal: false, vertical: true)

      VStack(alignment: .leading, spacing: 8) {
        // Course Details
        HStack(spacing: 8) {
          // Location Badge
          HStack(spacing: 4) {
            Image(systemName: "location.circle.fill")
              .font(.system(size: 12))
              .foregroundColor(.blue)
            Text(roomNumber)
              .font(.system(size: 12, weight: .medium))
              .foregroundColor(.primary)
          }
          .padding(.horizontal, 8)
          .padding(.vertical, 6)
          .background(
            RoundedRectangle(cornerRadius: 8)
              .fill(Color.blue.opacity(0.1))
              .overlay(
                RoundedRectangle(cornerRadius: 8)
                  .strokeBorder(Color.blue.opacity(0.3), lineWidth: 1)
              )
          )

          // Student Number Badge
          HStack(spacing: 4) {
            Image(systemName: "number.circle.fill")
              .font(.system(size: 12))
              .foregroundColor(.purple)
            Text(stdNo)
              .font(.system(size: 12, weight: .medium))
              .foregroundColor(.primary)
          }
          .padding(.horizontal, 8)
          .padding(.vertical, 6)
          .background(
            RoundedRectangle(cornerRadius: 8)
              .fill(Color.purple.opacity(0.1))
              .overlay(
                RoundedRectangle(cornerRadius: 8)
                  .strokeBorder(Color.purple.opacity(0.3), lineWidth: 1)
              )
          )

          Spacer()
        }

        // Teacher Info
        HStack(spacing: 4) {
          Image(systemName: "person.fill")
            .font(.system(size: 14))
            .foregroundColor(.secondary)
          Text(teacherName)
            .font(.system(size: 14, weight: .regular))
            .foregroundColor(.secondary)
            .lineLimit(1)
        }
      }
    }
    .padding(15)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(cardBackground)
        .shadow(
          color: colorScheme == .dark
            ? Color.black.opacity(0.3)
            : Color.black.opacity(0.08),
          radius: 12,
          x: 0,
          y: 4
        )
    )
    .overlay(
      RoundedRectangle(cornerRadius: 16)
        .strokeBorder(
          LinearGradient(
            colors: [
              Color.gray.opacity(0.1),
              Color.gray.opacity(0.05),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          ),
          lineWidth: 1
        )
    )
    .onAppear {
      updateOngoingStatus()
    }
    .onReceive(timer) { _ in
      updateOngoingStatus()
    }
  }

  private func updateOngoingStatus() {
    currentTime = Date()

    let calendar = Calendar.current
    let now = Date()

    let currentWeekday = calendar.component(.weekday, from: now)

    let courseWeekdayIOS = weekday == 7 ? 1 : weekday + 1

    // If not today, not ongoing
    if currentWeekday != courseWeekdayIOS {
      isOngoing = false
      return
    }

    // Check time if it's the right day
    let currentHour = calendar.component(.hour, from: now)
    let currentMinute = calendar.component(.minute, from: now)
    let currentTimeInMinutes = currentHour * 60 + currentMinute

    let startHour = calendar.component(.hour, from: StartTime)
    let startMinute = calendar.component(.minute, from: StartTime)
    let startTimeInMinutes = startHour * 60 + startMinute

    let endHour = calendar.component(.hour, from: EndTime)
    let endMinute = calendar.component(.minute, from: EndTime)
    let endTimeInMinutes = endHour * 60 + endMinute

    // Check if current time is between start and end times
    isOngoing =
      currentTimeInMinutes >= startTimeInMinutes && currentTimeInMinutes <= endTimeInMinutes
  }
}

// Custom ViewModifier for continuous pulsing animation
struct PulsingAnimation: ViewModifier {
  @State private var isAnimating = false
  let finalScale: CGFloat
  var initialScale: CGFloat = 1.0
  var finalOpacity: Double = 1.0
  var initialOpacity: Double = 0.6
  let duration: Double

  func body(content: Content) -> some View {
    content
      .scaleEffect(isAnimating ? finalScale : initialScale)
      .opacity(isAnimating ? finalOpacity : initialOpacity)
      .onAppear {
        withAnimation(
          Animation.easeInOut(duration: duration)
            .repeatForever(autoreverses: true)
        ) {
          isAnimating = true
        }
      }
  }
}

#Preview {
  CourseCardView(
    courseName: "計算機組織", roomNumber: "E305", teacherName: "我", StartTime: stringToTime("8:10")!,
    EndTime: stringToTime("9:00")!,
    stdNo: "178",
    weekday: 1
  )
  .padding()
}
