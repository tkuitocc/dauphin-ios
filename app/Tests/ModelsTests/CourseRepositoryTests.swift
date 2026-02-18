import Foundation
import Testing

@testable import dauphin

private final class MockCourseAPIClient: CourseAPIClient {
    var receivedQuery: String?
    var nextData: Data = Data()
    var nextError: Error?

    @CourseDataActor func fetchCoursesData(encryptedQuery: String) async throws -> Data {
        if let nextError { throw nextError }
        receivedQuery = encryptedQuery
        return nextData
    }
}

private final class MockCourseCache: CourseCache {
    var stored: [dauphin.Course]?
    var didClear = false

    func load() -> [dauphin.Course]? { stored }
    func save(_ courses: [dauphin.Course]) { stored = courses }
    func clear() {
        didClear = true
        stored = nil
    }
}

private final class MockCourseParser: CourseParser {
    var receivedData: Data?
    var result: [dauphin.Course] = []

    func parse(_ data: Data) throws -> [dauphin.Course] {
        receivedData = data
        return result
    }
}

@MainActor @Suite("Course Repository") struct CourseRepositoryTests {
    @Test("propagates API errors") func propagatesAPIErrors() async {
        let api = MockCourseAPIClient()
        let cache = MockCourseCache()
        let parser = MockCourseParser()
        let repo = DefaultCourseRepository(api: api, cache: cache, parser: parser)
        api.nextError = URLError(.timedOut)

        await #expect(throws: URLError.self) {
            _ = try await repo.fetchRemote(encryptedQuery: "ENC")
        }
    }

    @Test("passes encrypted query to API and parser output")
    func passesEncryptedQueryAndParsesResponse() async throws {
        let api = MockCourseAPIClient()
        let cache = MockCourseCache()
        let parser = MockCourseParser()
        api.nextData = Data("raw-payload".utf8)

        let expected = [
            CourseTestSupport.makeCourse(
                name: "N", weekday: 1, startOffsetFromNow: 0, endOffsetFromNow: 50,
                reference: CourseTestSupport.referenceDate())
        ]
        parser.result = expected

        let repo = DefaultCourseRepository(api: api, cache: cache, parser: parser)
        let courses = try await repo.fetchRemote(encryptedQuery: "ENC")

        #expect(api.receivedQuery == "ENC")
        #expect(parser.receivedData == Data("raw-payload".utf8))
        #expect(courses == expected)
    }

    @Test("delegates load/save/clear to cache") func delegatesCacheOperations() {
        let api = MockCourseAPIClient()
        let cache = MockCourseCache()
        let parser = MockCourseParser()
        let repo = DefaultCourseRepository(api: api, cache: cache, parser: parser)

        let sample = [
            CourseTestSupport.makeCourse(
                name: "Cache", weekday: 2, startOffsetFromNow: 10, endOffsetFromNow: 70,
                reference: CourseTestSupport.referenceDate())
        ]

        repo.saveCache(sample)
        #expect(cache.stored == sample)
        #expect(repo.loadCache() == sample)

        repo.clearCache()
        #expect(cache.didClear)
        #expect(repo.loadCache() == nil)
    }
}
