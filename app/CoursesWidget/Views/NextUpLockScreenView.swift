import SwiftUI
import WidgetKit

struct CoursesNextUpViewLockScreenView: View {
    @Environment(\.colorScheme) var colorScheme

    var entry: Provider.Entry
    var body: some View {
        if entry.ssoStuNo.isEmpty {
            HStack(spacing: 10) {
                Image(systemName: "person.text.rectangle.trianglebadge.exclamationmark.fill").font(
                    .system(size: 40, weight: .semibold))

                Text("尚未登入").font(.caption).fontWeight(.medium)
            }.frame(maxWidth: .infinity, maxHeight: .infinity).containerBackground(for: .widget) {
                Color(UIColor.systemBackground)
            }
        } else {
            if entry.courses.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "figure.wave").font(.system(size: 40, weight: .semibold))

                    Text("下週見").font(.caption).fontWeight(.medium)
                }.frame(maxWidth: .infinity, maxHeight: .infinity).containerBackground(for: .widget)
                { Color(UIColor.systemBackground) }
            } else {
                HStack(alignment: .top) {
                    Rectangle().fill(Color.red).frame(width: 4).clipShape(
                        RoundedRectangle(cornerRadius: 2, style: .continuous))

                    Spacer()

                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(entry.courses[0].name)").font(.system(size: 15, weight: .bold))

                        Text(
                            "\(formatTime(entry.courses[0].startTime)) - \(formatTime(entry.courses[0].endTime))"
                        ).font(.system(size: 12))

                        HStack {
                            HStack(spacing: 0) {
                                Image(systemName: "location.circle").resizable().frame(
                                    width: 15, height: 15)
                                Text(" : \(entry.courses[0].room)").font(.system(size: 12))
                            }

                            Spacer(minLength: 20)

                            HStack(spacing: 0) {
                                Image(systemName: "graduationcap").resizable().frame(
                                    width: 15, height: 15)
                                Text(" : \(entry.courses[0].stdNo)").font(.system(size: 12))
                            }
                        }
                    }
                }.padding(.vertical, 16).containerBackground(for: .widget) {
                    Color(UIColor.systemBackground)
                }
            }
        }
    }

    func currentDate() -> String { Self.currentDateFormatter.string(from: Date()) }

    func currentDay() -> String { Self.currentDayFormatter.string(from: Date()) }

    private static let currentDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd"
        return formatter
    }()

    private static let currentDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()
}

#Preview(as: .accessoryRectangular) { CoursesNextUpWidget() } timeline: {
    SimpleEntry(date: Date(), ssoStuNo: "123456789", courses: mockData, today: mockData.count)

    SimpleEntry(date: Date(), ssoStuNo: "", courses: mockData, today: mockData.count)

    SimpleEntry(
        date: Date(), ssoStuNo: "123456789",
        courses: getUpcomingCourses(
            from: mockData,
            currentDate: Calendar.current.date(
                from: DateComponents(year: 2025, month: 9, day: 27, hour: 22, minute: 0))!),
        today: mockData.count)

}
