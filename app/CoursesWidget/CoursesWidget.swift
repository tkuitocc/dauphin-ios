//
//  CoursesWidget.swift
//  CoursesWidget
//
//  Created by \u8b19 on 11/27/24.
//

import SwiftUI
import WidgetKit
import os

private struct WidgetCourseCachePayloadV2: Decodable {
    let version: Int
    let courses: [Course]
}

struct Provider: TimelineProvider {
    private static let logger = Logger(
        subsystem: Constants.loggerSubsystem, category: "CoursesWidget")

    // MARK: - Placeholder

    func placeholder(in _: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), ssoStuNo: "", courses: [], today: 0, showEnglishCourseName: false)
    }

    // MARK: - Snapshot
    func getSnapshot(in _: Context, completion: @escaping (SimpleEntry) -> Void) {
        let now = Date()
        let showEnglishCourseName = loadShowEnglishCourseNamePreference()
        guard let stdNo = getSsoStuNo() else {
            return completion(
                SimpleEntry(
                    date: now,
                    ssoStuNo: "",
                    courses: [],
                    today: 0,
                    showEnglishCourseName: showEnglishCourseName
                )
            )
        }

        let cached = loadCoursesFromCache() ?? []
        let service = DefaultNextUpService()
        let calendar = Calendar.current
        let today = ((calendar.component(.weekday, from: now) + 5) % 7) + 1  // 快速轉成 1=Mon…7=Sun

        completion(
            SimpleEntry(
                date: now, ssoStuNo: stdNo, courses: service.nextUp(from: cached, now: now),
                today: cached.filter { $0.weekday == today }.count,
                showEnglishCourseName: showEnglishCourseName
            )
        )
    }

    // MARK: - Timeline
    func getTimeline(in _: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let now = Date()
        let showEnglishCourseName = loadShowEnglishCourseNamePreference()
        let refresh =
            Calendar.current.date(byAdding: .minute, value: 15, to: now)
            ?? now.addingTimeInterval(900)

        guard let stdNo = getSsoStuNo() else {
            return completion(
                Timeline(
                    entries: [
                        SimpleEntry(
                            date: now,
                            ssoStuNo: "",
                            courses: [],
                            today: 0,
                            showEnglishCourseName: showEnglishCourseName
                        )
                    ],
                    policy: .after(refresh)))
        }

        let cached = loadCoursesFromCache() ?? []
        let svc = DefaultNextUpService()
        let today = ((Calendar.current.component(.weekday, from: now) + 5) % 7) + 1  // 1=Mon…7=Sun
        let entry = SimpleEntry(
            date: now, ssoStuNo: stdNo, courses: svc.nextUp(from: cached, now: now),
            today: cached.lazy.filter { $0.weekday == today }.count,
            showEnglishCourseName: showEnglishCourseName)

        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }

    // MARK: - Helpers

    private func getSsoStuNo() -> String? {
        guard let defaults = UserDefaults(suiteName: Constants.appGroupSuiteName) else {
            Provider.logger.error("App Group defaults unavailable.")
            return nil
        }
        guard let value = defaults.string(forKey: Constants.ssoTokenKey),
            !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            Provider.logger.info("ssoStuNo not found.")
            return nil
        }
        Provider.logger.info("Retrieved ssoStuNo")
        return value
    }

    private func loadCoursesFromCache() -> [Course]? {
        guard let defaults = UserDefaults(suiteName: Constants.appGroupSuiteName) else {
            Provider.logger.error("App Group defaults unavailable.")
            return nil
        }
        guard let data = defaults.data(forKey: Constants.courses) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let payload = try? decoder.decode(WidgetCourseCachePayloadV2.self, from: data),
            payload.version == 2
        {
            return payload.courses
        }
        do { return try decoder.decode([Course].self, from: data) } catch {
            Provider.logger.error(
                "Failed to decode cached courses: \(String(describing: error), privacy: .private)")
            return nil
        }
    }

    private func loadShowEnglishCourseNamePreference() -> Bool {
        guard let defaults = UserDefaults(suiteName: Constants.appGroupSuiteName) else {
            return Course.defaultShowEnglishCourseName()
        }
        guard defaults.object(forKey: Constants.showEnglishCourseName) != nil else {
            return Course.defaultShowEnglishCourseName()
        }
        return defaults.bool(forKey: Constants.showEnglishCourseName)
    }
}
struct CoursesNextUpWidgetEntryView: View {
    @Environment(\.colorScheme) var colorScheme

    var entry: Provider.Entry
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        switch widgetFamily {
        case .systemSmall: CoursesNextUpSmallView(entry: entry)
        case .accessoryRectangular: CoursesNextUpViewLockScreenView(entry: entry)
        default: EmptyView()
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let ssoStuNo: String
    let courses: [Course]
    let today: Int
    let showEnglishCourseName: Bool
}

struct CoursesNextUpWidget: Widget {
    let kind: String = "CoursesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            CoursesNextUpWidgetEntryView(entry: entry)
        }.configurationDisplayName("Next Up").description("顯示下一堂課").supportedFamilies([
            .systemSmall, .accessoryRectangular,
        ])
    }
}
