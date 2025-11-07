// 太複雜，先不要弄
import SwiftUI

struct CourseCardView: View {
  let courseName: String
  let roomNumber: String
  let teacherName: String
  let StartTime: Date
  let EndTime: Date
  let stdNo: String
  let weekday: Int

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
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .clipShape(Capsule())

        Spacer()
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
              .foregroundColor(.purple)
            Text(roomNumber)
              .font(.system(size: 12, weight: .medium))
              .foregroundColor(.primary)
          }
          .padding(.horizontal, 8)
          .padding(.vertical, 6)
          .background(
            RoundedRectangle(cornerRadius: 8)
              .fill(Color.purple.opacity(0.15))
          )

          // Student Number Badge
          HStack(spacing: 4) {
            Image(systemName: "graduationcap.fill")
              .font(.system(size: 12))
              .foregroundColor(.orange)
            Text(stdNo)
              .font(.system(size: 12, weight: .medium))
              .foregroundColor(.primary)
          }
          .padding(.horizontal, 8)
          .padding(.vertical, 6)
          .background(
            RoundedRectangle(cornerRadius: 8)
              .fill(Color.orange.opacity(0.15))
          )

          Spacer()
          
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
    }
    .padding(15)
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
  }
}

#Preview {
  CourseCardView(
    courseName: "計算機組織",
    roomNumber: "E305",
    teacherName: "我",
    StartTime: stringToTime("8:10")!,
    EndTime: stringToTime("9:00")!,
    stdNo: "178",
    weekday: 1
  )
  .padding()
}
