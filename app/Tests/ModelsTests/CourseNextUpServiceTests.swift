import Foundation
import Testing

@testable import dauphin

@Suite("Next Up Service Tests / 下堂課排序與過濾") struct CourseNextUpServiceTests {
    @Test("結束前 20 分鐘內的課程剔除 / Today courses ending within 20 minutes are filtered out")
    func filterTodayCoursesWithin20Minutes() {
        let reference = CourseTestSupport.referenceDate()
        let today = CourseTestSupport.weekdayOneBased(for: reference)

        let courseA = CourseTestSupport.makeCourse(
            name: "A", weekday: today, startOffsetFromNow: -40, endOffsetFromNow: 10,
            reference: reference)
        let courseB = CourseTestSupport.makeCourse(
            name: "B", weekday: today, startOffsetFromNow: -35, endOffsetFromNow: 25,
            reference: reference)

        let result = dauphin.DefaultNextUpService().nextUp(
            from: [courseA, courseB], now: reference)
        #expect(result.map { $0.name } == ["B"])
    }

    @Test("已過去星期剔除 / Past weekdays filtered out") func filterPastWeekdays() {
        let reference = CourseTestSupport.referenceDate()
        let today = CourseTestSupport.weekdayOneBased(for: reference)
        let past = today - 1
        let coursePast = CourseTestSupport.makeCourse(
            name: "Past", weekday: past, startOffsetFromNow: -120, endOffsetFromNow: -60,
            reference: reference)
        let courseToday = CourseTestSupport.makeCourse(
            name: "Today", weekday: today, startOffsetFromNow: 0, endOffsetFromNow: 30,
            reference: reference)
        let courseFuture = CourseTestSupport.makeCourse(
            name: "Future", weekday: CourseTestSupport.shiftWeekday(today, by: 1),
            startOffsetFromNow: 60, endOffsetFromNow: 120, reference: reference)

        let result = dauphin.DefaultNextUpService().nextUp(
            from: [coursePast, courseToday, courseFuture], now: reference)
        #expect(result.contains(where: { $0.name == "Past" }) == false)
        #expect(result.contains(where: { $0.name == "Today" }))
        #expect(result.contains(where: { $0.name == "Future" }))
    }

    @Test("未來星期保留且排序：先星期、再開始時間 / Future weekdays kept and ordered by weekday then start time")
    func orderByWeekdayThenStart() {
        let reference = CourseTestSupport.referenceDate()
        let today = CourseTestSupport.weekdayOneBased(for: reference)
        let future1 = CourseTestSupport.shiftWeekday(today, by: 1)
        let future2 = CourseTestSupport.shiftWeekday(today, by: 2)

        let f1a = CourseTestSupport.makeCourse(
            name: "F1-early", weekday: future1, startOffsetFromNow: 60, endOffsetFromNow: 120,
            reference: reference)
        let f1b = CourseTestSupport.makeCourse(
            name: "F1-late", weekday: future1, startOffsetFromNow: 90, endOffsetFromNow: 150,
            reference: reference)
        let f2 = CourseTestSupport.makeCourse(
            name: "F2", weekday: future2, startOffsetFromNow: 30, endOffsetFromNow: 60,
            reference: reference)

        let result = dauphin.DefaultNextUpService().nextUp(from: [f2, f1b, f1a], now: reference)
        #expect(result.map { $0.name } == ["F1-early", "F1-late", "F2"])
    }

    @Test("同日排序：以開始時間升冪 / Same-day order by start time ascending") func orderSameDayByStartTime() {
        let reference = CourseTestSupport.referenceDate()
        let today = CourseTestSupport.weekdayOneBased(for: reference)
        let c1 = CourseTestSupport.makeCourse(
            name: "C1", weekday: today, startOffsetFromNow: 10, endOffsetFromNow: 30,
            reference: reference)
        let c2 = CourseTestSupport.makeCourse(
            name: "C2", weekday: today, startOffsetFromNow: 5, endOffsetFromNow: 40,
            reference: reference)
        let c3 = CourseTestSupport.makeCourse(
            name: "C3", weekday: today, startOffsetFromNow: 0, endOffsetFromNow: 50,
            reference: reference)

        let result = dauphin.DefaultNextUpService().nextUp(from: [c2, c3, c1], now: reference)
        #expect(result.map { $0.name } == ["C3", "C2", "C1"])
    }

    @Test("星期日中午後若有課則保留本週日課程") func sundayNoonKeepsSundayCourse() {
        var comps = DateComponents()
        comps.year = 2025
        comps.month = 2
        comps.day = 9  // Sunday
        comps.hour = 13
        comps.minute = 0
        let calendar = Calendar.current
        let sundayAfterNoon = calendar.date(from: comps)!

        func course(name: String, weekday: Int, hour: Int, minute: Int) -> dauphin.Course {
            let start = calendar.date(
                from: DateComponents(year: 2025, month: 2, day: 9, hour: hour, minute: minute))!
            let end = calendar.date(byAdding: .minute, value: 50, to: start)!
            return dauphin.Course(
                name: name, room: "R", teacher: "T", time: "", startTime: start, endTime: end,
                stdNo: "S", weekday: weekday, note: "")
        }

        let sundayCourse = course(name: "Sun", weekday: 7, hour: 13, minute: 5)
        let mondayCourse = course(name: "Mon", weekday: 1, hour: 8, minute: 10)

        let result = dauphin.DefaultNextUpService().nextUp(
            from: [sundayCourse, mondayCourse], now: sundayAfterNoon)
        #expect(result.first?.name == "Sun")
    }
}
