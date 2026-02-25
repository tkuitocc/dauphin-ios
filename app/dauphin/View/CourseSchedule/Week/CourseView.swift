import SwiftUI

struct CourseView: View {
    let course: Course
    let height: CGFloat
    let yOffset: CGFloat
    @AppStorage(
        Constants.showEnglishCourseName, store: UserDefaults(suiteName: Constants.appGroupSuiteName)
    ) private var showEnglishCourseName = Course.defaultShowEnglishCourseName()
    private var courseNameFontSize: CGFloat {
        course.isShowingEnglishName(showEnglish: showEnglishCourseName) ? 13 : 15
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 8).fill(Color(UIColor.secondarySystemBackground)).overlay(
            RoundedRectangle(cornerRadius: 8).stroke(Color(UIColor.separator), lineWidth: 1)
        ).frame(height: height).overlay(
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .top, spacing: 0) {
                    Text(course.displayName(showEnglish: showEnglishCourseName)).font(
                        .system(size: courseNameFontSize, weight: .semibold)
                    ).foregroundColor(Color(UIColor.label)).lineLimit(2)
                }

                HStack(spacing: 2) {
                    Image(systemName: "location.circle.fill").font(.system(size: 10))
                        .foregroundColor(.purple)
                    Text(course.room).font(.system(size: 10, weight: .medium)).foregroundColor(
                        .primary)
                }.padding(.horizontal, 4).padding(.vertical, 2).background(
                    RoundedRectangle(cornerRadius: 8).fill(Color.purple.opacity(0.15)))

                // Student Number Badge
                HStack(spacing: 2) {
                    Image(systemName: "graduationcap.fill").font(.system(size: 10)).foregroundColor(
                        .orange)
                    Text(course.stdNo).font(.system(size: 10, weight: .medium)).foregroundColor(
                        .primary)
                }.padding(.horizontal, 4).padding(.vertical, 2).background(
                    RoundedRectangle(cornerRadius: 8).fill(Color.orange.opacity(0.15)))
            }.padding(8), alignment: .topLeading
        ).offset(y: yOffset).padding(.horizontal, 2)
    }
}

#Preview {
    let course = Course(
        name: "Data Structures", room: "E201", teacher: "Prof. Lin", time: "3, 4",
        startTime: stringToTime("10:10") ?? Date(), endTime: stringToTime("12:00") ?? Date(),
        stdNo: "067", weekday: 2)

    CourseView(course: course, height: 160, yOffset: 80)
}
