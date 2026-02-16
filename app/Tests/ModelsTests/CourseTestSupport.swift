import Foundation

@testable import dauphin

enum CourseTestSupport {
    static let calendar = Calendar.current

    static func referenceDate() -> Date {
        var comps = DateComponents()
        comps.year = 2025
        comps.month = 2
        comps.day = 12  // Wednesday
        comps.hour = 9
        comps.minute = 0
        return calendar.date(from: comps)!
    }

    static func weekdayOneBased(for date: Date) -> Int {
        let sys = calendar.component(.weekday, from: date)
        return sys == 1 ? 7 : (sys - 1)
    }

    static func shiftWeekday(_ weekday: Int, by offset: Int) -> Int {
        ((weekday - 1 + offset) % 7) + 1
    }

    static func makeCourse(
        name: String, weekday: Int, startOffsetFromNow minutesFromNowStart: Int,
        endOffsetFromNow minutesFromNowEnd: Int, room: String = "R1", teacher: String = "T",
        reference: Date
    ) -> dauphin.Course {
        let now = reference

        // 以 now 的年月日為基準，只調時分，避免時區漂移
        let start = calendar.date(byAdding: .minute, value: minutesFromNowStart, to: now)!
        let end = calendar.date(byAdding: .minute, value: minutesFromNowEnd, to: now)!
        let startH = calendar.component(.hour, from: start)
        let startM = calendar.component(.minute, from: start)
        let endH = calendar.component(.hour, from: end)
        let endM = calendar.component(.minute, from: end)

        let startNormalized = calendar.date(
            bySettingHour: startH, minute: startM, second: 0, of: now)!
        let endNormalized = calendar.date(bySettingHour: endH, minute: endM, second: 0, of: now)!

        let startText = String(format: "%02d:%02d", startH, startM)
        let endText = String(format: "%02d:%02d", endH, endM)

        return dauphin.Course(
            name: name, room: room, teacher: teacher, time: "\(startText) ~ \(endText)",
            startTime: startNormalized, endTime: endNormalized, stdNo: "S1", weekday: weekday,
            note: "")
    }

    static func courseStartHourMinute(_ course: dauphin.Course) -> (Int, Int) {
        (
            calendar.component(.hour, from: course.startTime),
            calendar.component(.minute, from: course.startTime)
        )
    }

    static func courseEndHourMinute(_ course: dauphin.Course) -> (Int, Int) {
        (
            calendar.component(.hour, from: course.endTime),
            calendar.component(.minute, from: course.endTime)
        )
    }
}
