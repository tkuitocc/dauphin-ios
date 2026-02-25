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

    @Test("displayName prefers English when enabled and available")
    func displayNamePrefersEnglishWhenEnabled() {
        let course = Course(
            name: "線性代數",
            enName: "LINEAR ALGEBRA",
            room: "B101",
            teacher: "Dr. Lin",
            teacherEn: "DR. LIN",
            time: "2, 3",
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600),
            stdNo: "001",
            weekday: 1
        )

        #expect(course.displayName(showEnglish: false) == "線性代數")
        #expect(course.displayName(showEnglish: true) == "LINEAR ALGEBRA")
        #expect(course.displayTeacher(showEnglish: false) == "Dr. Lin")
        #expect(course.displayTeacher(showEnglish: true) == "DR. LIN")

        let noEnglish = Course(
            name: "微積分",
            enName: "   ",
            room: "A101",
            teacher: "王老師",
            teacherEn: "",
            time: "3, 4",
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600),
            stdNo: "002",
            weekday: 2
        )

        #expect(noEnglish.displayName(showEnglish: true) == "微積分")
        #expect(noEnglish.displayTeacher(showEnglish: true) == "王老師")
    }

    @Test("default language rule only keeps Chinese for zh-Hant locales")
    func defaultLanguageRule() {
        #expect(Course.shouldShowEnglishCourseName(forPreferredLanguage: "en-US") == true)
        #expect(Course.shouldShowEnglishCourseName(forPreferredLanguage: "ja-JP") == true)
        #expect(Course.shouldShowEnglishCourseName(forPreferredLanguage: "zh-Hant-TW") == false)
        #expect(Course.shouldShowEnglishCourseName(forPreferredLanguage: "zh-TW") == false)
        #expect(Course.defaultShowEnglishTeacherName() == Course.defaultShowEnglishCourseName())
    }
}
