import Foundation

@globalActor actor CourseDataActor { static let shared = CourseDataActor() }

protocol CourseRepository: Sendable {
    func loadCache() -> [Course]?
    func saveCache(_ courses: [Course])
    func clearCache()
    @CourseDataActor func fetchRemote(encryptedQuery: String) async throws -> [Course]
}

struct DefaultCourseRepository: CourseRepository, @unchecked Sendable {
    let api: CourseAPIClient
    let cache: CourseCache
    let parser: CourseParser

    func loadCache() -> [Course]? { cache.load() }
    func saveCache(_ courses: [Course]) { cache.save(courses) }
    func clearCache() { cache.clear() }

    @CourseDataActor func fetchRemote(encryptedQuery: String) async throws -> [Course] {
        let data = try await api.fetchCoursesData(encryptedQuery: encryptedQuery)
        return try parser.parse(data)
    }
}
