//
//  CoursesWidget.swift
//  CoursesWidget
//
//  Created by \u8b19 on 11/27/24.
//

import SwiftUI
import WidgetKit
import os

// 假定外部型別
// struct SimpleEntry: TimelineEntry { let date: Date; let ssoStuNo: String; let courses: [Course]; let today: Int }
// struct Course: Codable, Hashable { let name: String; let room: String; let teacher: String; let time: String; let startTime: Date; let endTime: Date; let stdNo: String; let weekday: Int; let note: String }
// enum Constants { static let Courses = "Courses"; static let ssoTokenKey = "SSO_STU_NO" }

private let coursesWidgetLogger = Logger(
  subsystem: "group.cantpr09ram.dauphin", category: "CoursesWidget")

struct Provider: TimelineProvider {

  // MARK: - Placeholder

  func placeholder(in _: Context) -> SimpleEntry {
    SimpleEntry(date: Date(), ssoStuNo: "尚未登入", courses: [], today: 0)
  }

  // MARK: - Snapshot

  func getSnapshot(in _: Context, completion: @escaping (SimpleEntry) -> Void) {
    let now = Date()
    if let stdNo = getSsoStuNo() {
      // 若有快取，用快取；否則以空集合回傳
      let cached = loadCoursesFromCache() ?? []
      let todayCount = countCoursesToday(cached, date: now)
      let entry = SimpleEntry(
        date: now, ssoStuNo: stdNo, courses: nextUp(from: cached, date: now), today: todayCount)
      completion(entry)
    } else {
      completion(SimpleEntry(date: now, ssoStuNo: "尚未登入", courses: [], today: 0))
    }
  }

  // MARK: - Timeline

  func getTimeline(in _: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
    let now = Date()
    let refresh =
      Calendar.current.date(byAdding: .minute, value: 15, to: now) ?? now.addingTimeInterval(900)

    // 預設值，確保一定會 completion
    var entry = SimpleEntry(date: now, ssoStuNo: "尚未登入", courses: [], today: 0)

    if let stdNo = getSsoStuNo() {
      let cached = loadCoursesFromCache() ?? []
      let todayCount = countCoursesToday(cached, date: now)
      entry = SimpleEntry(
        date: now, ssoStuNo: stdNo, courses: nextUp(from: cached, date: now), today: todayCount)
    }

    let timeline = Timeline(entries: [entry], policy: .after(refresh))
    completion(timeline)
  }

  // MARK: - Helpers

  /// 嚴格：沒有就回傳 nil；不回傳「尚未登入」假字串避免誤判已登入
  private func getSsoStuNo() -> String? {
    guard let defaults = UserDefaults(suiteName: "group.cantpr09ram.dauphin") else {
      coursesWidgetLogger.error("App Group defaults unavailable.")
      return nil
    }
    guard let value = defaults.string(forKey: Constants.ssoTokenKey),
      !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    else {
      coursesWidgetLogger.info("ssoStuNo not found.")
      return nil
    }
    coursesWidgetLogger.info("Retrieved ssoStuNo.")
    return value
  }

  private func loadCoursesFromCache() -> [Course]? {
    guard let defaults = UserDefaults(suiteName: "group.cantpr09ram.dauphin") else {
      coursesWidgetLogger.error("App Group defaults unavailable.")
      return nil
    }
    guard let data = defaults.data(forKey: Constants.Courses) else {
      return nil
    }
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    do {
      return try decoder.decode([Course].self, from: data)
    } catch {
      coursesWidgetLogger.error(
        "Failed to decode cached courses: \(String(describing: error), privacy: .public)")
      return nil
    }
  }

  /// 取今天課程數；支援 Sunday=1 轉為 7 的校務週次常見格式
  private func countCoursesToday(_ courses: [Course], date: Date) -> Int {
    let sysWeekday = Calendar.current.component(.weekday, from: date)  // 1=Sun...7=Sat
    let schoolWeekday = mapSystemWeekdayToSchool(sysWeekday)
    return courses.filter { $0.weekday == schoolWeekday }.count
  }

  /// 取接下來要上的 N 筆課程；若無 `getNextUpCourses`，提供最簡降序邏輯
  private func nextUp(from courses: [Course], date: Date, limit: Int = 3) -> [Course] {
    // 先篩選今天，依 startTime 升冪，過去時間剔除
    let sysWeekday = Calendar.current.component(.weekday, from: date)
    let schoolWeekday = mapSystemWeekdayToSchool(sysWeekday)
    let todayCourses = courses.filter { $0.weekday == schoolWeekday }
      .sorted { $0.startTime < $1.startTime }
      .filter { $0.endTime > date }  // 尚未結束
    if todayCourses.isEmpty {
      // 若今天無，回傳最近未來一天的前幾筆
      return courses.sorted { ($0.weekday, $0.startTime) < ($1.weekday, $1.startTime) }.prefix(
        limit
      ).map { $0 }
    }
    return Array(todayCourses.prefix(limit))
  }

  /// 轉換 Apple 週次到學校常見格式：Sun(1)->7, Mon(2)->1, ... Sat(7)->6
  private func mapSystemWeekdayToSchool(_ w: Int) -> Int {
    // 學校週次若已採用 Sun=1 的話，請直接 `return w`
    // 常見「Mon=1...Sun=7」則：
    return w == 1 ? 7 : (w - 1)
  }
}
struct CoursesNextUpWidgetEntryView: View {
  @Environment(\.colorScheme) var colorScheme

  var entry: Provider.Entry
  @Environment(\.widgetFamily) var widgetFamily

  var body: some View {
    switch widgetFamily {
    case .systemSmall:
      CoursesNextUpSmallView(entry: entry)
    case .accessoryRectangular:
      CoursesNextUpViewLockScreenView(entry: entry)
    default:
      EmptyView()
    }
  }
}

struct SimpleEntry: TimelineEntry {
  let date: Date
  let ssoStuNo: String
  let courses: [Course]
  let today: Int
}

struct CoursesNextUpWidget: Widget {
  let kind: String = "CoursesWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: Provider()) { entry in
      CoursesNextUpWidgetEntryView(entry: entry)
    }
    .configurationDisplayName("Next Up")
    .description("顯示下一堂課")
    .supportedFamilies([.systemSmall, .accessoryRectangular])
  }
}
