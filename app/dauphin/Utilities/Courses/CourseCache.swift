import Foundation

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
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        return try? dec.decode([Course].self, from: data)
    }

    func save(_ courses: [Course]) {
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        if let data = try? enc.encode(courses) { defaults.set(data, forKey: key) }
    }

    func clear() { defaults.removeObject(forKey: key) }
}
