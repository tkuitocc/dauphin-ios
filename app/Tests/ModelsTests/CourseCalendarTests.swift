import Foundation
import Testing

@testable import dauphin

@Suite("Course Calendar Helpers / 星期相關") struct CourseCalendarTests {
    @Test("todayWeekday 範圍為 1...7") func todayWeekdayInRange() {
        let today = CourseTestSupport.weekdayOneBased(for: CourseTestSupport.referenceDate())
        #expect((1 ... 7).contains(today))
        #expect(today != 8)
    }
}
