//
//  CoursesWidget.swift
//  CoursesWidget
//
//  Created by \u8b19 on 11/27/24.
//

import SwiftUI
import WidgetKit

struct Provider: TimelineProvider {
  let viewModel = CourseViewModel()

  func placeholder(in _: Context) -> SimpleEntry {
    SimpleEntry(date: Date(), ssoStuNo: "尚未登入", courses: [], today: 0)
  }

  func getSnapshot(in _: Context, completion: @escaping (SimpleEntry) -> Void) {
    let entry: SimpleEntry
    if let stdNo = getSsoStuNo(), !stdNo.isEmpty {
      entry = SimpleEntry(date: Date(), ssoStuNo: stdNo, courses: mockData, today: mockData.count)
    } else {
      entry = SimpleEntry(date: Date(), ssoStuNo: "尚未登入", courses: [], today: 0)
    }
    completion(entry)
  }

  func getTimeline(in _: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
    let currentDate = Date()
    if let stdNo = getSsoStuNo(), !stdNo.isEmpty {
      if let cachedCourses = viewModel.loadCoursesFromCache() {
        let courses = cachedCourses
        let currentWeekday = Calendar.current.component(.weekday, from: Date())
        let filteredCourses = courses.filter { $0.weekday == currentWeekday }
        let entry = SimpleEntry(
          date: currentDate, ssoStuNo: stdNo, courses: getNextUpCourses(from: courses),
          today: filteredCourses.count)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
      }

    } else {
      let entry = SimpleEntry(date: currentDate, ssoStuNo: "尚未登入", courses: [], today: 0)
      let timeline = Timeline(entries: [entry], policy: .atEnd)
      completion(timeline)
    }
  }

  private func getSsoStuNo() -> String? {
    let defaults = UserDefaults(suiteName: "group.cantpr09ram.dauphin")
    defaults?.synchronize()
    if let value = defaults?.string(forKey: Constants.ssoTokenKey) {
      print("Retrieved ssoStuNo: \(value)")
      return value
    } else {
      print("ssoStuNo not found, returning default value.")
      return "尚未登入"
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
