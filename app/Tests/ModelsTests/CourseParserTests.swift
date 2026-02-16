import Foundation
import Testing

@testable import dauphin

@Suite("Course Parser") struct CourseParserTests {
    @Test("parses sorted sessions and strips html") func parsesSortedSessionsAndStripsHtml() throws
    {
        let json = """
            {
              "stuelelist": [
                {
                  "week": "1",
                  "ch_cos_name": "<b>Linear Algebra</b>,extra",
                  "teach_name": "<i>Dr. Lin</i>,x",
                  "room": "<span>B101</span>,foo",
                  "seat_no": "S123,foo",
                  "note": "<p>Important</p>",
                  "timePlase": { "sesses": ["4", "2"] }
                }
              ]
            }
            """

        let parser = DefaultCourseParser(
            htmlStrip: {
                $0.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            }, sessionToStart: { Date(timeIntervalSince1970: TimeInterval($0 * 60)) },
            sessionToEnd: { Date(timeIntervalSince1970: TimeInterval($0 * 60 + 30)) })

        let courses = try parser.parse(Data(json.utf8))
        #expect(courses.count == 1)

        let course = try #require(courses.first)
        #expect(course.name == "Linear Algebra")
        #expect(course.teacher == "Dr. Lin")
        #expect(course.room == "B101")
        #expect(course.stdNo == "S123")
        #expect(course.note == "Important")
        #expect(course.time == "2, 4")
        #expect(course.weekday == 1)
        #expect(course.startTime == Date(timeIntervalSince1970: 120))
        #expect(course.endTime == Date(timeIntervalSince1970: 270))
    }

    @Test("dedupes and merges teacher names") func dedupesAndMergesTeacherNames() throws {
        let json = """
            {
              "stuelelist": [
                {
                  "week": "2",
                  "ch_cos_name": "Physics",
                  "teach_name": "A",
                  "room": "R1",
                  "seat_no": "S1",
                  "note": "",
                  "timePlase": { "sesses": ["1", "2"] }
                },
                {
                  "week": "2",
                  "ch_cos_name": "Physics",
                  "teach_name": "B",
                  "room": "R1",
                  "seat_no": "S1",
                  "note": "",
                  "timePlase": { "sesses": ["1", "2"] }
                }
              ]
            }
            """

        let parser = DefaultCourseParser(
            htmlStrip: { $0 },
            sessionToStart: { Date(timeIntervalSince1970: TimeInterval($0 * 60)) },
            sessionToEnd: { Date(timeIntervalSince1970: TimeInterval($0 * 60 + 30)) })

        let courses = try parser.parse(Data(json.utf8))
        #expect(courses.count == 1)
        #expect(courses[0].teacher == "A, B")
    }

    @Test("filters invalid weekday or session rows") func filtersInvalidRows() throws {
        let json = """
            {
              "stuelelist": [
                {
                  "week": "8",
                  "ch_cos_name": "Ignored",
                  "teach_name": "T",
                  "room": "R",
                  "seat_no": "S",
                  "note": "",
                  "timePlase": { "sesses": ["1"] }
                },
                {
                  "week": "3",
                  "ch_cos_name": "AlsoIgnored",
                  "teach_name": "T",
                  "room": "R",
                  "seat_no": "S",
                  "note": "",
                  "timePlase": { "sesses": ["X"] }
                }
              ]
            }
            """

        let parser = DefaultCourseParser(
            htmlStrip: { $0 }, sessionToStart: { Date(timeIntervalSince1970: TimeInterval($0)) },
            sessionToEnd: { Date(timeIntervalSince1970: TimeInterval($0)) })

        let courses = try parser.parse(Data(json.utf8))
        #expect(courses.isEmpty)
    }
}
