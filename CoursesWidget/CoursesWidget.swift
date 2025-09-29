//
//  CoursesWidget.swift
//  CoursesWidget
//
//  Created by \u8b19 on 11/27/24.
//

import SwiftUI
import WidgetKit
import os

struct Provider: TimelineProvider {
  private static let logger = Logger(
    subsystem: "group.cantpr09ram.dauphin", category: "CoursesWidget")

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
        date: now, ssoStuNo: stdNo, courses: getUpcomingCourses(from: cached, currentDate: now), today: todayCount)
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
        date: now, ssoStuNo: stdNo, courses: getUpcomingCourses(from: cached, currentDate: now), today: todayCount)
    }

    let timeline = Timeline(entries: [entry], policy: .after(refresh))
    completion(timeline)
  }

  // MARK: - Helpers

  /// 嚴格：沒有就回傳 nil；不回傳「尚未登入」假字串避免誤判已登入
  private func getSsoStuNo() -> String? {
    guard let defaults = UserDefaults(suiteName: "group.cantpr09ram.dauphin") else {
      Provider.logger.error("App Group defaults unavailable.")
      return nil
    }
    guard let value = defaults.string(forKey: Constants.ssoTokenKey),
      !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    else {
      Provider.logger.info("ssoStuNo not found.")
      return nil
    }
    Provider.logger.info("Retrieved ssoStuNo.")
    return value
  }

  private func loadCoursesFromCache() -> [Course]? {
    guard let defaults = UserDefaults(suiteName: "group.cantpr09ram.dauphin") else {
      Provider.logger.error("App Group defaults unavailable.")
      return nil
    }
    guard let data = defaults.data(forKey: Constants.courses) else {
      return nil
    }
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    do {
      return try decoder.decode([Course].self, from: data)
    } catch {
      Provider.logger.error(
        "Failed to decode cached courses: \(String(describing: error), privacy: .public)")
      return nil
    }
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
