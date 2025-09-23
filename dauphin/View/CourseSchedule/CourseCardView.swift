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

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("\(formatTime(StartTime)) ~ \(formatTime(EndTime))")
        .font(.subheadline)
        .foregroundColor(.gray)

      Text("\(courseName)")
        .font(.headline)
        .foregroundColor(.primary)

      HStack {
        VStack {
          HStack(spacing: 8) {
            Image(systemName: "location.circle")
            Text("\(roomNumber)")
              .font(.caption)
              .bold()
              .foregroundColor(.primary)
          }
          .padding(.vertical, 4)
          .padding(.horizontal, 10)
          .background(Color.blue)
          .cornerRadius(8)
        }

        VStack {
          HStack(spacing: 8) {
            Image(systemName: "graduationcap")
            Text("\(stdNo)")
              .font(.caption)
              .bold()
              .foregroundColor(.primary)
          }
          .padding(.vertical, 4)
          .padding(.horizontal, 10)
          .background(Color.blue.opacity(0.8))
          .cornerRadius(8)
        }

        Spacer()

        VStack(alignment: .center, spacing: 5) {
          HStack {
            Image(systemName: "inset.filled.rectangle.and.person.filled")
            VStack {
              Text("\(teacherName)")
                .font(.caption)
                .foregroundColor(.primary)
            }
          }
        }
      }
    }
    .padding()
    .background(
      colorScheme == .dark
        ? Color(UIColor(red: 28 / 255, green: 28 / 255, blue: 30 / 255, alpha: 1)) : Color.white
    )
    .cornerRadius(12)
    .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 4)
    .padding(.horizontal)
  }
}

#Preview {
  CourseCardView(
    courseName: "計算機組織", roomNumber: "E305", teacherName: "我", StartTime: stringToTime("8:10")!,
    EndTime: stringToTime("9:00")!, stdNo: "178")
}
