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
                  "ch_cos_name": "<b>線性代數</b>",
                  "en_cos_name": "LINEAR ALGEBRA",
                  "teach_name": "<i>Dr. Lin</i>,x",
                  "teach_name_en": "DR. LIN",
                  "room": "<span>B101</span>,foo",
                  "seat_no": "S123,foo",
                  "cos_no": "COS001",
                  "cos_ele_seq": "0743",
                  "remark": "&nbsp;",
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
        #expect(course.name == "線性代數")
        #expect(course.teacher == "Dr. Lin")
        #expect(course.teachers == ["Dr. Lin"])
        #expect(course.room == "B101")
        #expect(course.stdNo == "S123")
        #expect(course.seatNo == "S123")
        #expect(course.note == "Important")
        #expect(course.time == "2, 4")
        #expect(course.sessionNumbers == [2, 4])
        #expect(course.weekday == 1)
        #expect(course.enName == "LINEAR ALGEBRA")
        #expect(course.cosNo == "COS001")
        #expect(course.cosEleSeq == "0743")
        #expect(course.startTime == Date(timeIntervalSince1970: 120))
        #expect(course.endTime == Date(timeIntervalSince1970: 270))
        let calendar = Calendar.current
        let expectedStartMinute =
            calendar.component(.hour, from: course.startTime) * 60
            + calendar.component(.minute, from: course.startTime)
        let expectedEndMinute =
            calendar.component(.hour, from: course.endTime) * 60
            + calendar.component(.minute, from: course.endTime)
        #expect(course.startMinuteOfDay == expectedStartMinute)
        #expect(course.endMinuteOfDay == expectedEndMinute)
        #expect(course.durationMinutes == max(0, expectedEndMinute - expectedStartMinute))
        #expect(!course.id.isEmpty)
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
        #expect(courses[0].teachers == ["A", "B"])
    }

    @Test("falls back to sess fields when timePlase is missing") func fallsBackToSessFields() throws
    {
        let json = """
            {
              "stuelelist": [
                {
                  "week": "3",
                  "ch_cos_name": "Networks",
                  "teach_name": "T",
                  "room": "R",
                  "seat_no": "S",
                  "note": "",
                  "sess1": "06",
                  "sess2": "07",
                  "sess3": "  "
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
        #expect(courses[0].sessionNumbers == [6, 7])
        #expect(courses[0].time == "6, 7")
    }

    @Test("merges contiguous rows from cells fallback") func mergesContiguousRowsFromCellsFallback()
        throws
    {
        let json = """
            {
              "stuelelist": [],
              "cells": [
                {
                  "weekno": "2",
                  "sessno": "07",
                  "ch_cos_name": "Happiness",
                  "teach_name": "A",
                  "seatno": "003",
                  "room": "L302"
                },
                {
                  "weekno": "2",
                  "sessno": "08",
                  "ch_cos_name": "Happiness",
                  "teach_name": "A",
                  "seatno": "003",
                  "room": "L302"
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
        #expect(courses[0].sessionNumbers == [7, 8])
        #expect(courses[0].time == "7, 8")
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

    @Test("keeps full chinese course name without comma truncation")
    func keepsFullChineseCourseName() throws {
        let json = """
            {
              "stuelelist": [
                {
                  "week": "2",
                  "ch_cos_name": "幸福的理性與感性(本科目為通識教育跨領域微學程課程,大學部學生均可選修)",
                  "teach_name": "胡延薇",
                  "room": "L302",
                  "seat_no": "003",
                  "note": "",
                  "timePlase": { "sesses": ["07"] }
                }
              ]
            }
            """

        let parser = DefaultCourseParser(
            htmlStrip: { $0 },
            sessionToStart: { Date(timeIntervalSince1970: TimeInterval($0 * 60)) },
            sessionToEnd: { Date(timeIntervalSince1970: TimeInterval($0 * 60 + 30)) })

        let courses = try parser.parse(Data(json.utf8))
        let course = try #require(courses.first)
        #expect(course.name == "幸福的理性與感性(本科目為通識教育跨領域微學程課程,大學部學生均可選修)")
    }
}
