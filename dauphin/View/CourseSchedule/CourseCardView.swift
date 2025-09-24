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

  @Environment(\.colorScheme) var colorScheme
  @State private var isPressed = false
  @State private var isOngoing = false
  @State private var currentTime = Date()
  let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

  private var timeColor: Color {
    if isOngoing {
      return .green
    } else if currentTime < StartTime {
      return .accentColor
    } else {
      return .secondary
    }
  }

  private var cardBackground: Color {
    colorScheme == .dark
      ? Color(UIColor.secondarySystemGroupedBackground)
      : Color(UIColor.systemBackground)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
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
          HStack(spacing: 4) {
            Circle()
              .fill(Color.green)
              .frame(width: 8, height: 8)
              .overlay(
                Circle()
                  .fill(Color.green.opacity(0.5))
                  .frame(width: 16, height: 16)
                  .scaleEffect(isPressed ? 1.2 : 1.0)
              )
            Text("Ongoing")
              .font(.system(size: 12, weight: .semibold))
              .foregroundColor(.green)
          }
          .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isPressed)
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
        HStack(spacing: 12) {
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
        HStack(spacing: 8) {
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
    .padding(20)
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
    .scaleEffect(isPressed && !isOngoing ? 0.98 : 1.0)
    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
    .onAppear {
      updateOngoingStatus()
      if isOngoing {
        isPressed = true
      }
    }
    .onReceive(timer) { _ in
      updateOngoingStatus()
    }
  }

  private func updateOngoingStatus() {
    currentTime = Date()
    let wasOngoing = isOngoing
    isOngoing = currentTime >= StartTime && currentTime <= EndTime
    if isOngoing && !wasOngoing {
      isPressed = true
    }
  }
}

#Preview {
  CourseCardView(
    courseName: "計算機組織", roomNumber: "E305", teacherName: "我", StartTime: stringToTime("8:10")!,
    EndTime: stringToTime("9:00")!, stdNo: "178"
  )
  .padding()
}
