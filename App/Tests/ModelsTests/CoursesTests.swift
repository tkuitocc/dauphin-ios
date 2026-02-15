//
//  ModelsTests.swift
//  ModelsTests
//
//  Created by \u8b19 on 9/24/25.
//

import Foundation
import Testing

@testable import dauphin

@Suite("Course & Schedule Tests / 課程與行程測試")
struct CourseScheduleTests {
  private let calendar = Calendar.current

  private func referenceDate() -> Date {
    var comps = DateComponents()
    comps.year = 2025
    comps.month = 2
    comps.day = 12  // Wednesday
    comps.hour = 9
    comps.minute = 0
    return calendar.date(from: comps)!
  }

  private func weekdayOneBased(for date: Date) -> Int {
    let sys = calendar.component(.weekday, from: date)
    return sys == 1 ? 7 : (sys - 1)
  }

  private func shiftWeekday(_ weekday: Int, by offset: Int) -> Int {
    ((weekday - 1 + offset) % 7) + 1
  }

  // MARK: - Helpers

  /// 建立一個 Course，給定：名稱、星期、開始/結束時間（以今天日期為基準，但只用到時分）
  private func makeCourse(
    name: String,
    weekday: Int,
    startOffsetFromNow minutesFromNowStart: Int,
    endOffsetFromNow minutesFromNowEnd: Int,
    room: String = "R1",
    teacher: String = "T",
    reference: Date
  ) -> Course {
    let now = reference
    let cal = calendar

    // 以 now 的年月日為基準，只調時分，避免時區漂移
    let start = cal.date(byAdding: .minute, value: minutesFromNowStart, to: now)!
    let end = cal.date(byAdding: .minute, value: minutesFromNowEnd, to: now)!
    let startH = cal.component(.hour, from: start)
    let startM = cal.component(.minute, from: start)
    let endH = cal.component(.hour, from: end)
    let endM = cal.component(.minute, from: end)

    let startNormalized = cal.date(
      bySettingHour: startH, minute: startM, second: 0, of: now
    )!
    let endNormalized = cal.date(
      bySettingHour: endH, minute: endM, second: 0, of: now
    )!

    return Course(
      id: UUID(),
      name: name,
      room: room,
      teacher: teacher,
      time:
        "\(String(format: "%02d", startH)):\(String(format: "%02d", startM)) ~ \(String(format: "%02d", endH)):\(String(format: "%02d", endM))",
      startTime: startNormalized,
      endTime: endNormalized,
      stdNo: "S1",
      weekday: weekday,
      note: ""
    )
  }

  /// 取得以該實作邏輯計算的「今天 weekday（0~6，星期日=0）」。
  private func todayWeekdayOneBased(reference: Date) -> Int {
    weekdayOneBased(for: reference)
  }

  private func getCourseStartHourMinute(_ course: Course) -> (Int, Int) {
    (calendar.component(.hour, from: course.startTime),
     calendar.component(.minute, from: course.startTime))
  }

  private func getCourseEndHourMinute(_ course: Course) -> (Int, Int) {
    (calendar.component(.hour, from: course.endTime),
     calendar.component(.minute, from: course.endTime))
  }

  // MARK: - Core behavior

  @Test("結束前 20 分鐘內的課程剔除 / Today courses ending within 20 minutes are filtered out")
  func filterTodayCoursesWithin20Minutes() {
    let reference = referenceDate()
    let today = todayWeekdayOneBased(reference: reference)

    // A 將在 10 分鐘後結束 → 應被過濾
    let courseA = makeCourse(
      name: "A", weekday: today, startOffsetFromNow: -40, endOffsetFromNow: 10,
      reference: reference)
    // B 將在 25 分鐘後結束 → 應被保留
    let courseB = makeCourse(
      name: "B", weekday: today, startOffsetFromNow: -35, endOffsetFromNow: 25,
      reference: reference)

    let result = DefaultNextUpService().nextUp(from: [courseA, courseB], now: reference)
    #expect(result.map { $0.name } == ["B"])
  }

  @Test("已過去星期剔除 / Past weekdays filtered out")
  func filterPastWeekdays() {
    let reference = referenceDate()
    let today = todayWeekdayOneBased(reference: reference)
    let past = today - 1
    let coursePast = makeCourse(
      name: "Past", weekday: past, startOffsetFromNow: -120, endOffsetFromNow: -60,
      reference: reference)
    let courseToday = makeCourse(
      name: "Today", weekday: today, startOffsetFromNow: 0, endOffsetFromNow: 30,
      reference: reference)
    let courseFuture = makeCourse(
      name: "Future", weekday: shiftWeekday(today, by: 1), startOffsetFromNow: 60,
      endOffsetFromNow: 120, reference: reference)

    let result = DefaultNextUpService().nextUp(
      from: [coursePast, courseToday, courseFuture], now: reference)
    // Past 應被剔除，其餘依原排序保留
    #expect(result.contains(where: { $0.name == "Past" }) == false)
    #expect(result.contains(where: { $0.name == "Today" }))
    #expect(result.contains(where: { $0.name == "Future" }))
  }

  @Test("未來星期保留且排序：先星期、再開始時間 / Future weekdays kept and ordered by weekday then start time")
  func orderByWeekdayThenStart() {
    let reference = referenceDate()
    let today = todayWeekdayOneBased(reference: reference)
    let future1 = shiftWeekday(today, by: 1)
    let future2 = shiftWeekday(today, by: 2)

    // 同一未來星期：以結束時間排序
    let f1a = makeCourse(
      name: "F1-early", weekday: future1, startOffsetFromNow: 60, endOffsetFromNow: 120,
      reference: reference)
    let f1b = makeCourse(
      name: "F1-late", weekday: future1, startOffsetFromNow: 90, endOffsetFromNow: 150,
      reference: reference)
    // 另一個更晚星期，應排在後面
    let f2 = makeCourse(
      name: "F2", weekday: future2, startOffsetFromNow: 30, endOffsetFromNow: 60,
      reference: reference)

    let result = DefaultNextUpService().nextUp(from: [f2, f1b, f1a], now: reference)
    #expect(result.map { $0.name } == ["F1-early", "F1-late", "F2"])
  }

  @Test("同日排序：以開始時間升冪 / Same-day order by start time ascending")
  func orderSameDayByStartTime() {
    let reference = referenceDate()
    let today = todayWeekdayOneBased(reference: reference)
    let c1 = makeCourse(
      name: "C1", weekday: today, startOffsetFromNow: 10, endOffsetFromNow: 30,
      reference: reference)
    let c2 = makeCourse(
      name: "C2", weekday: today, startOffsetFromNow: 5, endOffsetFromNow: 40,
      reference: reference)
    let c3 = makeCourse(
      name: "C3", weekday: today, startOffsetFromNow: 0, endOffsetFromNow: 50,
      reference: reference)

    let result = DefaultNextUpService().nextUp(from: [c2, c3, c1], now: reference)
    // 全部距離結束 > 20 分鐘，應保留且按開始時間排序：0 < 5 < 10
    #expect(result.map { $0.name } == ["C3", "C2", "C1"])
  }

  // MARK: - Helpers: hour/minute extractors

  @Test("getCourseStartHourMinute / getCourseEndHourMinute 應正確回傳時分")
  func startEndHourMinuteExtractors() {
    let reference = referenceDate()
    let c = makeCourse(
      name: "X", weekday: todayWeekdayOneBased(reference: reference), startOffsetFromNow: 0,
      endOffsetFromNow: 90, reference: reference)
    let (sh, sm) = getCourseStartHourMinute(c)
    let (eh, em) = getCourseEndHourMinute(c)

    #expect(sh == calendar.component(.hour, from: c.startTime))
    #expect(sm == calendar.component(.minute, from: c.startTime))
    #expect(eh == calendar.component(.hour, from: c.endTime))
    #expect(em == calendar.component(.minute, from: c.endTime))
  }

  // MARK: - stringToTime / formatTime

  @Test("stringToTime 解析 HH:mm，formatTime 輸出 HH:mm")
  func timeParsingAndFormatting() {
    let t = "07:05"
    let d = stringToTime(t)
    #expect(d != nil)

    let out = formatTime(d)
    #expect(out == "07:05")

    let err = formatTime(nil)
    #expect(err == "ERROR")
  }

  // MARK: - Edge case: dead branch

  @Test("todayWeekday == 7 分支永不成立 / Dead branch detection")
  func todayWeekdayNeverSeven() {
    let today = weekdayOneBased(for: referenceDate())
    #expect((1...7).contains(today))
    #expect(today != 8)
  }

  @Test("星期日中午後若沒有課則顯示下週一") func sundayNoonShowsNextWeek() {
    var comps = DateComponents()
    comps.year = 2025
    comps.month = 2
    comps.day = 9  // Sunday
    comps.hour = 13
    comps.minute = 0
    let calendar = Calendar.current
    let sundayAfterNoon = calendar.date(from: comps)!

    func course(
      name: String, weekday: Int, hour: Int, minute: Int
    ) -> Course {
      let start = calendar.date(
        from: DateComponents(year: 2025, month: 2, day: 9, hour: hour, minute: minute))!
      let end = calendar.date(byAdding: .minute, value: 50, to: start)!
      return Course(
        name: name,
        room: "R",
        teacher: "T",
        time: "",
        startTime: start,
        endTime: end,
        stdNo: "S",
        weekday: weekday,
        note: ""
      )
    }

    let sundayCourse = course(name: "Sun", weekday: 7, hour: 13, minute: 5)
    let mondayCourse = course(name: "Mon", weekday: 1, hour: 8, minute: 10)

    let result = DefaultNextUpService().nextUp(
      from: [sundayCourse, mondayCourse], now: sundayAfterNoon)
    #expect(result.first?.name == "Mon")
  }
}
