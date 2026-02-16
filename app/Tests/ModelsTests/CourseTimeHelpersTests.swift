import Foundation
import Testing

@testable import dauphin

@Suite("Course Time Helpers / 時間擷取") struct CourseTimeHelpersTests {
    @Test("getCourseStartHourMinute / getCourseEndHourMinute 應正確回傳時分")
    func startEndHourMinuteExtractors() {
        let reference = CourseTestSupport.referenceDate()
        let c = CourseTestSupport.makeCourse(
            name: "X", weekday: CourseTestSupport.weekdayOneBased(for: reference),
            startOffsetFromNow: 0, endOffsetFromNow: 90, reference: reference)

        let (sh, sm) = CourseTestSupport.courseStartHourMinute(c)
        let (eh, em) = CourseTestSupport.courseEndHourMinute(c)

        #expect(sh == CourseTestSupport.calendar.component(.hour, from: c.startTime))
        #expect(sm == CourseTestSupport.calendar.component(.minute, from: c.startTime))
        #expect(eh == CourseTestSupport.calendar.component(.hour, from: c.endTime))
        #expect(em == CourseTestSupport.calendar.component(.minute, from: c.endTime))
    }
}
