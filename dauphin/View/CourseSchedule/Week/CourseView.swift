import SwiftUI

struct CourseView: View {
  let course: Course
  let height: CGFloat
  let yOffset: CGFloat
  
  var body: some View {
    RoundedRectangle(cornerRadius: 8)
      .fill(Color(UIColor.secondarySystemBackground))
      .overlay(
        RoundedRectangle(cornerRadius: 8)
          .stroke(Color(UIColor.separator), lineWidth: 1)
      )
      .frame(height: height)
      .overlay(
        VStack(alignment: .leading, spacing: 3) {
          HStack(alignment: .top, spacing: 0) {
            Text(course.name)
              .font(.system(size: 11, weight: .semibold))
              .foregroundColor(Color(UIColor.label))
              .lineLimit(2)
          }
          
          HStack(spacing: 3) {
            Image(systemName: "location.circle.fill")
              .font(.system(size: 10))
              .foregroundColor(Color(UIColor.secondaryLabel))
            Text(course.room)
              .font(.system(size: 10))
              .foregroundColor(Color(UIColor.secondaryLabel))
          }
          HStack(spacing: 3) {
            Image(systemName: "graduationcap")
              .font(.system(size: 10))
              .foregroundColor(Color(UIColor.secondaryLabel))
            Text(course.stdNo)
              .font(.system(size: 10))
              .foregroundColor(Color(UIColor.secondaryLabel))
          }
        }
        .padding(8),
        alignment: .topLeading
      )
      .offset(y: yOffset)
      .padding(.horizontal, 2)
  }
}

#Preview {
  let course = Course(
    name: "Data Structures",
    room: "E201",
    teacher: "Prof. Lin",
    time: "3, 4",
    startTime: stringToTime("10:10") ?? Date(),
    endTime: stringToTime("12:00") ?? Date(),
    stdNo: "A12345",
    weekday: 2
  )

  CourseView(
    course: course,
    height: 160,
    yOffset: 80
  )
}
