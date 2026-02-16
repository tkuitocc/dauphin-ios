import Foundation
import Testing

@testable import dauphin

@Suite("Course Formatting / 字串格式") struct CourseFormattingTests {
    @Test("stringToTime 解析 HH:mm，formatTime 輸出 HH:mm") func timeParsingAndFormatting() {
        let t = "07:05"
        let d = stringToTime(t)
        #expect(d != nil)

        let out = formatTime(d)
        #expect(out == "07:05")

        let err = formatTime(nil)
        #expect(err == "ERROR")
    }
}
