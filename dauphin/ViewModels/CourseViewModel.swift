import Foundation
import Network
import SwiftUI
import os

// MARK: - ViewModel for Courses (modernized, same logic)

@MainActor
final class CourseViewModel: ObservableObject {

  // MARK: Published State

  @Published var weekCourses: [Course] = []
  @Published var isLoading = false
  @Published var errorMessage: String?
  @Published var isCacheEmpty = false

  // MARK: Private State

  private let appGroupDefaults = UserDefaults(suiteName: "group.cantpr09ram.dauphin")
  private let logger = Logger(subsystem: "group.cantpr09ram.dauphin", category: "CourseViewModel")

  private var monitor: NWPathMonitor?
  private let monitorQueue = DispatchQueue(label: "CourseViewModel.Network")
  private var helper: CustomAES256Helper?
  private var helperReady = false
  private var timeoutTask: Task<Void, Never>?

  // MARK: Init

  init() {
    startNetworkMonitor()
    Task { await initializeHelper() }
  }

  // Testing initializer
  init(mockData: [Course]) {
    weekCourses = mockData
    startNetworkMonitor()
  }

  deinit { monitor?.cancel() }

  // MARK: - Helper Initialization

  private func initializeHelper() async {
    if let key = KeychainManager.shared.get(forKey: "AES256KEY"),
      let iv = KeychainManager.shared.get(forKey: "AES256IV")
    {
      helper = CustomAES256Helper(key: key, iv: iv)
      helperReady = true
      logger.info("Initialized AES256 helper.")
    } else {
      errorMessage = "Failed to retrieve AES256 key or IV from Keychain."
      logger.error("Key/IV retrieval failed.")
    }
  }

  // MARK: - Cache Management

  private var defaults: UserDefaults {
    guard let d = appGroupDefaults else {
      logger.error("App Group defaults unavailable. Falling back to .standard.")
      return .standard
    }
    return d
  }

  func loadCoursesFromCache() -> [Course]? {
    logger.info("Load courses from cache.")
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601

    guard let data = defaults.data(forKey: Constants.courses) else {
      logger.info("No cached data for key \(Constants.courses, privacy: .public).")
      isCacheEmpty = true
      return nil
    }

    do {
      let courses = try decoder.decode([Course].self, from: data)
      isCacheEmpty = courses.isEmpty
      return courses
    } catch {
      logger.error("Decode cached courses failed: \(String(describing: error), privacy: .public)")
      isCacheEmpty = true
      return nil
    }
  }

  func clearCache() {
    defaults.removeObject(forKey: Constants.courses)
    weekCourses = []
    isCacheEmpty = true
    errorMessage = "Cache cleared. Please refresh to load courses."
  }

  func saveCoursesToCache(courses: [Course]) {
    logger.info("Saving courses to cache.")
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    do {
      let data = try encoder.encode(courses)
      defaults.set(data, forKey: Constants.courses)
    } catch {
      logger.error("Encode+save courses failed: \(String(describing: error), privacy: .public)")
    }
  }

  // MARK: - Fetch Courses

  func fetchCourses(with stdNo: String) async {
    isLoading = true
    timeoutTask?.cancel()

    if let cached = loadCoursesFromCache() {
      setCacheTimeoutFallback(using: cached)
    }

    if !helperReady { await initializeHelper() }
    guard let helper else {
      endWith(error: "Encryption helper not initialized.")
      return
    }

    // network check
    let hasNetwork = monitor?.currentPath.status == .satisfied
    if !hasNetwork {
      if let cached = loadCoursesFromCache(), !cached.isEmpty {
        weekCourses = cached
        endWith(error: "No internet connection. Showing cached data.", loading: false)
      } else {
        endWith(error: "No internet connection and no cached data available.", loading: false)
      }
      return
    }

    do {
      let encryptedQuery = try await createEncryptedQuery(for: stdNo, helper: helper)

      var comps = URLComponents(string: "https://ilifeapi.az.tku.edu.tw/api/ilifeStuClassApi")!
      comps.queryItems = [URLQueryItem(name: "q", value: encryptedQuery)]
      guard let url = comps.url else { throw URLError(.badURL) }

      let (data, response) = try await URLSession.shared.data(from: url)
      guard let http = response as? HTTPURLResponse, 200...299 ~= http.statusCode else {
        throw URLError(.badServerResponse)
      }

      // Prefer Decodable; fall back to JSONSerialization if needed
      let courses: [Course]
      if let decoded = try? JSONDecoder().decode(APIResponse.self, from: data) {
        courses = parseCourseData(from: decoded)
      } else if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
        let trimmed = trimAllStringFields(json) as? [String: Any] ?? json
        courses = parseCourseDataFromDictionary(apiData: trimmed)
      } else {
        throw URLError(.cannotParseResponse)
      }

      timeoutTask?.cancel()
      saveCoursesToCache(courses: courses)
      weekCourses = courses
      isCacheEmpty = courses.isEmpty
      errorMessage = nil
      isLoading = false
    } catch {
      timeoutTask?.cancel()
      endWith(error: "Failed to fetch courses: \(error.localizedDescription)")
    }
  }

  private func createEncryptedQuery(for stdNo: String, helper: CustomAES256Helper) async throws
    -> String
  {
    guard let encrypted = helper.encrypt(data: "20220901200540356," + stdNo) else {
      throw EncryptionError.failed
    }
    guard let encoded = encrypted.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    else {
      throw URLError(.badServerResponse)
    }
    return encoded
  }

  // MARK: - HTML / Trimming Helpers

  private func stripHTML(_ text: String) -> String {
    guard let data = text.data(using: .utf8) else { return text }
    if let attr = try? NSAttributedString(
      data: data,
      options: [
        .documentType: NSAttributedString.DocumentType.html,
        .characterEncoding: String.Encoding.utf8.rawValue,
      ],
      documentAttributes: nil
    ) {
      return attr.string
        .replacingOccurrences(of: "\r\n", with: "\n")
        .replacingOccurrences(of: "\\r\\n", with: "\n")
        .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    return text
  }

  private func cleanHTMLTags(from text: String) -> String {
    // kept for backward-compat usage; now calls stripHTML
    stripHTML(text)
  }

  private func trimAllStringFields(_ object: Any) -> Any {
    if let dict = object as? [String: Any] {
      var trimmedDict = [String: Any]()
      for (key, value) in dict {
        trimmedDict[key] = trimAllStringFields(value)
      }
      return trimmedDict
    } else if let array = object as? [Any] {
      return array.map { trimAllStringFields($0) }
    } else if let string = object as? String {
      return string.trimmingCharacters(in: .whitespacesAndNewlines)
    } else {
      return object
    }
  }

  // MARK: - Parse Course Data (Decodable path)

  struct APIResponse: Decodable {
    let stuelelist: [CourseDTO]
  }

  struct CourseDTO: Decodable {
    let week: String
    let chCosName: String?
    let note: String?
    let room: String?
    let teachName: String?
    let timePlace: TimePlace?

    enum CodingKeys: String, CodingKey {
      case week
      case chCosName = "ch_cos_name"
      case note
      case room
      case teachName = "teach_name"
      case timePlace = "timePlase"
    }

    struct TimePlace: Decodable {
      let sesses: [String]
    }
  }

  private func parseCourseData(from api: APIResponse) -> [Course] {
    var weekCourses: [Course] = []

    for courseData in api.stuelelist {
      guard
        let weekIndex = Int(courseData.week),
        (1...7).contains(weekIndex)
      else { continue }

      let rawCourseName = cleanHTMLTags(from: courseData.chCosName ?? "Unknown")
        .replacingOccurrences(of: "\n", with: "")
        .replacingOccurrences(of: "\r", with: "")

      let courseName =
        rawCourseName.contains(",")
        ? (rawCourseName.components(separatedBy: ",").first ?? rawCourseName)
        : rawCourseName

      let room =
        cleanHTMLTags(from: courseData.room ?? "")
        .components(separatedBy: ",")
        .first ?? ""

      let teacher =
        cleanHTMLTags(from: courseData.teachName ?? "Unknown Teacher")
        .components(separatedBy: ",")
        .first ?? "Unknown Teacher"

      // original code called this seat_no; API lacks here in Decodable path
      let seatNo =
        cleanHTMLTags(from: "")
        .components(separatedBy: ",")
        .first ?? "Unknown Seat"

      guard
        let sesses = courseData.timePlace?.sesses,
        let firstSession = sesses.first,
        let lastSession = sesses.last,
        let firstSessionInt = Int(firstSession),
        let lastSessionInt = Int(lastSession),
        let start = sessionToStartTime(session: firstSessionInt),
        let end = sessionToEndTime(session: lastSessionInt)
      else { continue }

      let time = sesses.joined(separator: ", ")
      let finalRoom =
        room.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Unknown Room" : room
      let cleanedNote = cleanHTMLTags(from: courseData.note ?? "")

      weekCourses.append(
        Course(
          name: courseName,
          room: finalRoom,
          teacher: teacher,
          time: time,
          startTime: start,
          endTime: end,
          stdNo: seatNo,
          weekday: weekIndex,
          note: cleanedNote
        )
      )
    }

    return dedupeAndMerge(weekCourses)
  }

  // MARK: - Parse Course Data (Dictionary fallback path, keeps original keys)

  private func parseCourseDataFromDictionary(apiData: [String: Any]) -> [Course] {
    var weekCourses: [Course] = []

    guard let stuelelist = apiData["stuelelist"] as? [[String: Any]] else {
      logger.error("Failed to parse 'stuelelist'.")
      return weekCourses
    }

    for courseData in stuelelist {
      guard
        let weekString = courseData["week"] as? String,
        let weekIndex = Int(weekString),
        (1...7).contains(weekIndex)
      else { continue }

      let rawCourseName = cleanHTMLTags(from: (courseData["ch_cos_name"] as? String) ?? "Unknown")
        .replacingOccurrences(of: "\n", with: "")
        .replacingOccurrences(of: "\r", with: "")

      let courseName =
        rawCourseName.contains(",")
        ? (rawCourseName.components(separatedBy: ",").first ?? rawCourseName)
        : rawCourseName

      let room =
        cleanHTMLTags(from: (courseData["room"] as? String) ?? "")
        .components(separatedBy: ",")
        .first ?? ""

      let teacher =
        cleanHTMLTags(from: (courseData["teach_name"] as? String) ?? "Unknown Teacher")
        .components(separatedBy: ",")
        .first ?? "Unknown Teacher"

      let seatNo =
        cleanHTMLTags(from: (courseData["seat_no"] as? String) ?? "Unknown Seat")
        .components(separatedBy: ",")
        .first ?? "Unknown Seat"

      guard
        let timeSessions = courseData["timePlase"] as? [String: Any],
        let sesses = timeSessions["sesses"] as? [String],
        let firstSession = sesses.first,
        let lastSession = sesses.last,
        let firstSessionInt = Int(firstSession),
        let lastSessionInt = Int(lastSession),
        let start = sessionToStartTime(session: firstSessionInt),
        let end = sessionToEndTime(session: lastSessionInt)
      else {
        continue
      }

      let time = sesses.joined(separator: ", ")
      let finalRoom =
        room.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Unknown Room" : room
      let cleanedNote = cleanHTMLTags(from: (courseData["note"] as? String) ?? "")

      weekCourses.append(
        Course(
          name: courseName,
          room: finalRoom,
          teacher: teacher,
          time: time,
          startTime: start,
          endTime: end,
          stdNo: seatNo,
          weekday: weekIndex,
          note: cleanedNote
        )
      )
    }

    return dedupeAndMerge(weekCourses)
  }

  // MARK: - De-duplication and Merge

  private func dedupeAndMerge(_ input: [Course]) -> [Course] {
    // STEP 2: remove exact duplicates (assumes Course: Hashable)
    var seen = Set<Course>()
    var unique: [Course] = []
    for c in input {
      if seen.insert(c).inserted { unique.append(c) }
    }

    // STEP 3: strip "(note)" from name if present
    for i in 0..<unique.count {
      var course = unique[i]
      if !course.note.isEmpty {
        let cleaned = course.note.replacingOccurrences(of: "\n", with: "")
          .replacingOccurrences(of: "\r", with: "")
        let notePattern = "(" + cleaned + ")"
        if course.name.contains(notePattern) {
          course.name = course.name.replacingOccurrences(of: notePattern, with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        }
      }
      unique[i] = course
    }

    // STEP 4: merge when all except teacher are same; teacher去重
    var merged: [Course] = []
    for course in unique {
      if let idx = merged.firstIndex(where: { e in
        e.name == course.name && e.room == course.room && e.time == course.time
          && e.stdNo == course.stdNo && e.weekday == course.weekday
          && e.startTime == course.startTime && e.endTime == course.endTime && e.note == course.note
      }) {
        var m = merged[idx]
        var teachers = Set(
          m.teacher.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) })
        teachers.insert(course.teacher)
        m.teacher = teachers.sorted().joined(separator: ", ")
        merged[idx] = m
      } else {
        merged.append(course)
      }
    }

    logger.info("Parsed \(merged.count) courses.")
    return merged
  }

  // MARK: - Time Helpers (reference hour/minute only; no hardcoded date)

  private func sessionToStartTime(session: Int) -> Date? {
    let startHour = [
      1: 8, 2: 9, 3: 10, 4: 11, 5: 12, 6: 13, 7: 14, 8: 15, 9: 16, 10: 17, 11: 18, 12: 19, 13: 20,
      14: 21,
    ][session]
    guard let hour = startHour else { return nil }
    var comps = DateComponents()
    comps.hour = hour
    comps.minute = 10
    return Calendar.current.date(from: comps)
  }

  private func sessionToEndTime(session: Int) -> Date? {
    let endHour = [
      1: 9, 2: 10, 3: 11, 4: 12, 5: 13, 6: 14, 7: 15, 8: 16, 9: 17, 10: 18, 11: 19, 12: 20, 13: 21,
      14: 22,
    ][session]
    guard let hour = endHour else { return nil }
    var comps = DateComponents()
    comps.hour = hour
    comps.minute = 0
    return Calendar.current.date(from: comps)
  }

  // MARK: - UI Updates

  private func setCacheTimeoutFallback(using cached: [Course]) {
    timeoutTask?.cancel()
    timeoutTask = Task { [weak self] in
      try? await Task.sleep(nanoseconds: 2_000_000_000)
      guard let self, !Task.isCancelled else { return }
      self.weekCourses = cached
      self.errorMessage = "Fetching data took too long. Using cached data."
      self.isLoading = false
    }
  }

  private func endWith(error: String, loading: Bool = false) {
    logger.debug("Error: \(error, privacy: .public)")
    errorMessage = error
    isLoading = loading
  }

  // MARK: - Network

  private func startNetworkMonitor() {
    let m = NWPathMonitor()
    m.pathUpdateHandler = { [weak self] path in
      Task { @MainActor in
        if path.status == .satisfied {
          self?.logger.info("Network reachable.")
          self?.errorMessage = nil
        } else {
          self?.logger.info("Network unreachable.")
          self?.errorMessage = "No internet connection. Please check your network."
        }
      }
    }
    monitor = m
    m.start(queue: monitorQueue)
  }
}

// MARK: - Custom Errors

enum EncryptionError: Error { case failed }
