import SwiftUI
import WidgetKit

struct CoursesNextUpViewLockScreenView: View {
    @Environment(\.colorScheme) var colorScheme

    var entry: Provider.Entry
    private func courseNameFontSize(for course: Course) -> CGFloat {
        course.isShowingEnglishName(showEnglish: entry.showEnglishCourseName) ? 13 : 15
    }

    var body: some View {
        if entry.ssoStuNo.isEmpty {
            HStack(spacing: 10) {
                Image(systemName: "person.text.rectangle.trianglebadge.exclamationmark.fill").font(
                    .system(size: 40, weight: .semibold))

                Text(String(localized: "widget.notLoggedIn")).font(.caption).fontWeight(.medium)
            }.frame(maxWidth: .infinity, maxHeight: .infinity).containerBackground(for: .widget) {
                Color(UIColor.systemBackground)
            }
        } else {
            if entry.courses.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "figure.wave").font(.system(size: 40, weight: .semibold))

                    Text(String(localized: "widget.seeYouNextWeek")).font(.caption).fontWeight(
                        .medium)
                }.frame(maxWidth: .infinity, maxHeight: .infinity).containerBackground(for: .widget)
                { Color(UIColor.systemBackground) }
            } else {
                HStack(alignment: .top) {
                    Rectangle().fill(Color.red).frame(width: 4).clipShape(
                        RoundedRectangle(cornerRadius: 2, style: .continuous))

                    Spacer()

                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.courses[0].displayName(showEnglish: entry.showEnglishCourseName))
                            .font(
                                .system(
                                    size: courseNameFontSize(for: entry.courses[0]), weight: .bold))

                        Text(
                            "\(formatTime(entry.courses[0].startTime)) - \(formatTime(entry.courses[0].endTime))"
                        ).font(.system(size: 12))

                        Text(
                            entry.courses[0].displayTeacher(
                                showEnglish: entry.showEnglishTeacherName)
                        ).font(.system(size: 11)).lineLimit(1)

                        HStack {
                            HStack(spacing: 0) {
                                Image(systemName: "location.circle").resizable().frame(
                                    width: 15, height: 15)
                                Text(entry.courses[0].room).font(.system(size: 12))
                            }

                            Spacer(minLength: 20)

                            HStack(spacing: 0) {
                                Image(systemName: "graduationcap").resizable().frame(
                                    width: 15, height: 15)
                                Text(entry.courses[0].stdNo).font(.system(size: 12))
                            }
                        }
                    }
                }.padding(.vertical, 16).containerBackground(for: .widget) {
                    Color(UIColor.systemBackground)
                }
            }
        }
    }

    func currentDate() -> String {
        let components = Calendar.autoupdatingCurrent.dateComponents([.month, .day], from: Date())
        let month = components.month ?? 0
        let day = components.day ?? 0
        return String(format: "%02d.%02d", month, day)
    }

    func currentDay() -> String {
        Date.now.formatted(.dateTime.weekday(.wide).locale(.autoupdatingCurrent))
    }
}

#Preview(as: .accessoryRectangular) { CoursesNextUpWidget() } timeline: {
    SimpleEntry(
        date: Date(), ssoStuNo: "123456789", courses: mockData, today: mockData.count,
        showEnglishCourseName: false, showEnglishTeacherName: false)

    SimpleEntry(
        date: Date(), ssoStuNo: "", courses: mockData, today: mockData.count,
        showEnglishCourseName: false, showEnglishTeacherName: false)

    SimpleEntry(
        date: Date(), ssoStuNo: "123456789",
        courses: getUpcomingCourses(
            from: mockData,
            currentDate: Calendar.current.date(
                from: DateComponents(year: 2025, month: 9, day: 27, hour: 22, minute: 0))!),
        today: mockData.count, showEnglishCourseName: false, showEnglishTeacherName: false)

}
