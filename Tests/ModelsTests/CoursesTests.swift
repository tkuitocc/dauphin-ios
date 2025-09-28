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

  // MARK: - Helpers

  /// 建立一個 Course，給定：名稱、星期、開始/結束時間（以今天日期為基準，但只用到時分）
  private func makeCourse(
    name: String,
    weekday: Int,
    startOffsetFromNow minutesFromNowStart: Int,
    endOffsetFromNow minutesFromNowEnd: Int,
    room: String = "R1",
    teacher: String = "T"
  ) -> Course {
    let now = Date()
    let cal = Calendar.current

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
  private func todayWeekdayZeroBased() -> Int {
    let cal = Calendar.current
    return cal.component(.weekday, from: Date()) - 1
  }

  // MARK: - Core behavior

  @Test("同日課程：結束時間 <= 20 分鐘內者剔除 / Today courses ending ≤ 20min from now are filtered out")
  func filterTodayCoursesWithin20Minutes() {
    let today = todayWeekdayZeroBased()

    // A 將在 10 分鐘後結束 → 應被過濾
    let courseA = makeCourse(
      name: "A", weekday: today, startOffsetFromNow: -50, endOffsetFromNow: 10)
    // B 將在 25 分鐘後結束 → 應被保留
    let courseB = makeCourse(
      name: "B", weekday: today, startOffsetFromNow: -10, endOffsetFromNow: 25)

    let result = getNextUpCourses(from: [courseA, courseB])
    #expect(result.map { $0.name } == ["B"])
  }

  @Test("已過去星期剔除 / Past weekdays filtered out")
  func filterPastWeekdays() {
    let today = todayWeekdayZeroBased()
    let past = max(0, today - 1)
    // past < today 才有意義；若 today=0（週日），past=0 會等於 today，不影響測試邏輯
    let coursePast = makeCourse(
      name: "Past", weekday: past, startOffsetFromNow: -120, endOffsetFromNow: -60)
    let courseToday = makeCourse(
      name: "Today", weekday: today, startOffsetFromNow: 0, endOffsetFromNow: 30)
    let courseFuture = makeCourse(
      name: "Future", weekday: (today + 1) % 7, startOffsetFromNow: 60, endOffsetFromNow: 120)

    let result = getNextUpCourses(from: [coursePast, courseToday, courseFuture])
    // Past 應被剔除，其餘依原排序保留
    #expect(result.contains(where: { $0.name == "Past" }) == false)
    #expect(result.contains(where: { $0.name == "Today" }))
    #expect(result.contains(where: { $0.name == "Future" }))
  }

  @Test("未來星期保留且排序：先星期、再結束時間 / Future weekdays kept and ordered by weekday then end time")
  func orderByWeekdayThenEnd() {
    let today = todayWeekdayZeroBased()
    let future1 = (today + 1) % 7
    let future2 = (today + 2) % 7

    // 同一未來星期：以結束時間排序
    let f1a = makeCourse(
      name: "F1-early", weekday: future1, startOffsetFromNow: 60, endOffsetFromNow: 120)
    let f1b = makeCourse(
      name: "F1-late", weekday: future1, startOffsetFromNow: 90, endOffsetFromNow: 150)
    // 另一個更晚星期，應排在後面
    let f2 = makeCourse(name: "F2", weekday: future2, startOffsetFromNow: 30, endOffsetFromNow: 60)

    let result = getNextUpCourses(from: [f2, f1b, f1a])  // 打亂輸入順序
    #expect(result.map { $0.name } == ["F1-early", "F1-late", "F2"])
  }

  @Test("同日排序：以結束時間升冪 / Same-day order by end time ascending")
  func orderSameDayByEndTime() {
    let today = todayWeekdayZeroBased()
    let c1 = makeCourse(name: "C1", weekday: today, startOffsetFromNow: 10, endOffsetFromNow: 30)
    let c2 = makeCourse(name: "C2", weekday: today, startOffsetFromNow: 5, endOffsetFromNow: 40)
    let c3 = makeCourse(name: "C3", weekday: today, startOffsetFromNow: 0, endOffsetFromNow: 50)

    let result = getNextUpCourses(from: [c2, c3, c1])
    // 全部距離結束 > 20 分鐘，應保留且按結束時間排序：30 < 40 < 50
    #expect(result.map { $0.name } == ["C1", "C2", "C3"])
  }

  // MARK: - Helpers: hour/minute extractors

  @Test("getCourseStartHourMinute / getCourseEndHourMinute 應正確回傳時分")
  func startEndHourMinuteExtractors() {
    let c = makeCourse(
      name: "X", weekday: todayWeekdayZeroBased(), startOffsetFromNow: 0, endOffsetFromNow: 90)
    let (sh, sm) = getCourseStartHourMinute(c)
    let (eh, em) = getCourseEndHourMinute(c)

    let cal = Calendar.current
    #expect(sh == cal.component(.hour, from: c.startTime))
    #expect(sm == cal.component(.minute, from: c.startTime))
    #expect(eh == cal.component(.hour, from: c.endTime))
    #expect(em == cal.component(.minute, from: c.endTime))
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
    let cal = Calendar.current
    let today = cal.component(.weekday, from: Date()) - 1
    #expect((0...6).contains(today))
    #expect(today != 7)  // 驗證既有實作中的 if todayWeekday == 7 分支為死分支
  }
}
