//
//  CoursesWidget.swift
//  CoursesWidget
//
//  Created by \u8b19 on 11/27/24.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), ssoStuNo: "尚未登入", courses: [], today: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        let entry: SimpleEntry
        if let stdNo = getSsoStuNo(), !stdNo.isEmpty {
            entry = SimpleEntry(date: Date(), ssoStuNo: stdNo, courses: mockData, today: mockData.count)
        } else {
            entry = SimpleEntry(date: Date(), ssoStuNo: "尚未登入", courses: [], today: 0)
        }
        completion(entry)
    }


    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let currentDate = Date()
        if let stdNo = getSsoStuNo(), !stdNo.isEmpty {
            if let cachedCourses = loadCoursesFromCache() {
                let courses = cachedCourses
                let currentWeekday = Calendar.current.component(.weekday, from: Date())
                    let filteredCourses = courses.filter { $0.weekday == currentWeekday }
                let entry = SimpleEntry(date: currentDate, ssoStuNo: stdNo, courses: getNextUpCourses(from: courses), today: filteredCourses.count)
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
            // Retrieved student number from storage
            return value
        } else {
            // No student number found in storage
            return "尚未登入"
        }
    }

    private func loadCoursesFromCache() -> [Course]? {
        let appGroupDefaults = UserDefaults(suiteName: "group.cantpr09ram.dauphin")
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let data = appGroupDefaults?.data(forKey: Constants.Courses) else {
            return nil
        }

        do {
            let courses = try decoder.decode([Course].self, from: data)
            return courses
        } catch {
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
