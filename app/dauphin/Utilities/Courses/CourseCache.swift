import Foundation

private enum CourseCacheVersion { static let v2 = 2 }

struct CourseCachePayloadV2: Codable {
    let version: Int
    let generatedAt: Date
    let courses: [Course]
    let meetingsFlat: [CourseMeetingDigest]
}

struct CourseMeetingDigest: Codable, Hashable {
    let courseId: String
    let weekday: Int
    let startMinuteOfDay: Int
    let endMinuteOfDay: Int
    let sortKey: Int
}

func decodeCoursesFromCacheData(_ data: Data) -> [Course]? {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601

    if let payload = try? decoder.decode(CourseCachePayloadV2.self, from: data),
        payload.version == CourseCacheVersion.v2
    {
        return payload.courses
    }

    return try? decoder.decode([Course].self, from: data)
}

private func makeCachePayloadV2(courses: [Course]) -> CourseCachePayloadV2 {
    CourseCachePayloadV2(
        version: CourseCacheVersion.v2, generatedAt: Date(), courses: courses,
        meetingsFlat: courses.map {
            CourseMeetingDigest(
                courseId: $0.id, weekday: $0.weekday, startMinuteOfDay: $0.startMinuteOfDay,
                endMinuteOfDay: $0.endMinuteOfDay, sortKey: $0.sortKey)
        })
}

protocol CourseCache {
    func load() -> [Course]?
    func save(_ courses: [Course])
    func clear()
}

struct DefaultsCourseCache: CourseCache {
    private let defaults: UserDefaults
    private let key: String

    init(suiteName: String?, key: String) {
        self.defaults = UserDefaults(suiteName: suiteName) ?? .standard
        self.key = key
    }

    func load() -> [Course]? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return decodeCoursesFromCacheData(data)
    }

    func save(_ courses: [Course]) {
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        let payload = makeCachePayloadV2(courses: courses)
        if let data = try? enc.encode(payload) { defaults.set(data, forKey: key) }
    }

    func clear() { defaults.removeObject(forKey: key) }
}
