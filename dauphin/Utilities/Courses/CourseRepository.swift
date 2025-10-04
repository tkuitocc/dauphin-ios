import Foundation

protocol CourseRepository {
  func loadCache() -> [Course]?
  func saveCache(_ courses: [Course])
  func clearCache()
  func fetchRemote(stdNo: String, encrypt: (String) -> String?) async throws -> [Course]
}

struct DefaultCourseRepository: CourseRepository {
  let api: CourseAPIClient
  let cache: CourseCache
  let parser: CourseParser

  func loadCache() -> [Course]? { cache.load() }
  func saveCache(_ courses: [Course]) { cache.save(courses) }
  func clearCache() { cache.clear() }

  // CourseRepository.swift
  func fetchRemote(stdNo: String, encrypt: (String) -> String?) async throws -> [Course] {
    guard let enc = encrypt("20220901200540356," + stdNo) else {
      throw URLError(.cannotParseResponse)
    }
    let data = try await api.fetchCoursesData(encryptedQuery: enc)
    return try parser.parse(data)
  }
}
