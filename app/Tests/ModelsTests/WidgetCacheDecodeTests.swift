import Foundation
import Testing

@testable import dauphin

@Suite("Widget Cache Decode") struct WidgetCacheDecodeTests {
    @Test("widget-style decoder reads cache payload") func widgetStyleDecoderReadsCachePayload()
        throws
    {
        let suiteName = "group.cantpr09ram.dauphin.tests.\(UUID().uuidString)"
        let key = "courses"

        let cache = DefaultsCourseCache(suiteName: suiteName, key: key)
        let sample: [dauphin.Course] = [
            CourseTestSupport.makeCourse(
                name: "Widget", weekday: 4, startOffsetFromNow: 10, endOffsetFromNow: 70,
                reference: CourseTestSupport.referenceDate())
        ]

        cache.save(sample)

        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let data = try #require(defaults.data(forKey: key))
        let decoded = widgetStyleDecodeCourses(data)
        let decodedCourses = try #require(decoded)
        #expect(decodedCourses == sample)
    }

    @Test("widget-style decoder returns nil for invalid payload")
    func widgetStyleDecoderRejectsInvalidPayload() throws {
        let invalid = Data("not-json".utf8)
        #expect(widgetStyleDecodeCourses(invalid) == nil)
    }

    private func widgetStyleDecodeCourses(_ data: Data) -> [dauphin.Course]? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode([dauphin.Course].self, from: data)
    }
}
