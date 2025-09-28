import Combine
import OSLog
import Reachability
import SwiftUI
import os

// MARK: - ViewModel for Courses
@MainActor
class CourseViewModel: ObservableObject {
  private static let logger = Logger(subsystem: "com.dauphin.app", category: "CourseViewModel")
  private let appGroupDefaults = UserDefaults(suiteName: "group.cantpr09ram.dauphin")

  @Published var weekCourses: [Course] = []
  @Published var errorMessage: String? = nil
  @Published var isCacheEmpty = false
  @Published var isUpdatingCache = false
  @Published var cacheUpdateMessage: String? = nil
  @Published var isRefreshing = false

  // MARK: Private State

  private let appGroupDefaults = UserDefaults(suiteName: "group.cantpr09ram.dauphin")
  private let logger = Logger(subsystem: "group.cantpr09ram.dauphin", category: "CourseViewModel")

  private var monitor: NWPathMonitor?
  private let monitorQueue = DispatchQueue(label: "CourseViewModel.Network")
  private var helper: CustomAES256Helper?
  private var timeoutWorkItem: DispatchWorkItem?
  private var cancellables = Set<AnyCancellable>()
  static var hasPerformedInitialLoad = false

  init() {
    reachability = try! Reachability()

    configureReachability()
    do {
      try reachability.startNotifier()
    } catch {
      Self.logger.error("Unable to start reachability notifier: \(error.localizedDescription)")
    }
    initializeHelper()
  }

  // Testing initializer
  init(mockData: [Course]) {
    weekCourses = mockData
    startNetworkMonitor()
  }

  deinit { monitor?.cancel() }

  // MARK: - Helper Initialization
  private func initializeHelper() {
    if let key = KeychainManager.shared.get(forKey: "AES256KEY"),
      let iv = KeychainManager.shared.get(forKey: "AES256IV")
    {
      helper = CustomAES256Helper(key: key, iv: iv)
      Self.logger.debug("Successfully initialized AES256 helper")
    } else {
      self.errorMessage = "Failed to retrieve AES256 key or IV from Keychain."
      Self.logger.error("Failed to retrieve AES256 key or IV from Keychain")
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
    // Loading courses from cache
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601

    guard let data = appGroupDefaults?.data(forKey: Constants.Courses) else {
      Self.logger.debug("No cached data found for courses")
      isCacheEmpty = true
      return nil
    }

    do {
      let courses = try decoder.decode([Course].self, from: data)
      Self.logger.debug("Successfully loaded courses from cache")
      isCacheEmpty = courses.isEmpty
      return courses
    } catch {
      Self.logger.error("Failed to decode cached courses: \(error.localizedDescription)")
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

  func resetInitializationFlag() {
    // Reset the initialization flag on logout
    Self.hasPerformedInitialLoad = false
    Self.logger.debug("Reset initialization flag for fresh session")
  }

  func saveCoursesToCache(courses: [Course]) {
    // Saving courses to cache
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    do {
      let data = try encoder.encode(courses)
      appGroupDefaults?.set(data, forKey: Constants.Courses)
      Self.logger.debug("Courses saved to cache successfully")
    } catch {
      Self.logger.error("Failed to encode and save courses: \(error.localizedDescription)")
    }
  }

  // MARK: - Fetch Courses
  func fetchCourses(with stdNo: String, forceRefresh: Bool = false, isFirstLogin: Bool = false) async {
    // Fetching courses from API
    timeoutWorkItem?.cancel()

    // Set refreshing state for pull-to-refresh
    if forceRefresh {
      self.isRefreshing = true
    }

    // Load and display cached data immediately
    if let cachedCourses = loadCoursesFromCache(), !cachedCourses.isEmpty {
      self.weekCourses = cachedCourses
      self.isCacheEmpty = false
      self.errorMessage = nil
    }

    // Only fetch from network on app launch, manual refresh, or first login
    guard !Self.hasPerformedInitialLoad || forceRefresh || isFirstLogin else {
      // Already loaded once this session, just show cached data
      self.isRefreshing = false
      return
    }

    guard let helper = helper else {
      self.errorMessage = "Encryption helper not initialized."
      self.isRefreshing = false
      return
    }

    // Check network availability
    guard reachability.connection != .unavailable else {
      if weekCourses.isEmpty {
        self.errorMessage = "No internet connection and no cached data available."
      }
      self.isRefreshing = false
      // If we have cached data, it's already displayed
      return
    }

    // Network is available - update cache in background (only on first load)
    Self.hasPerformedInitialLoad = true

    self.isUpdatingCache = true
    self.cacheUpdateMessage = "Updating course data..."

    do {
      let encryptedQuery = try await createEncryptedQuery(for: stdNo, helper: helper)
      let url = URL(
        string: "https://ilifeapi.az.tku.edu.tw/api/ilifeStuClassApi?q=\(encryptedQuery)")!

      let (data, response) = try await URLSession.shared.data(from: url)
      guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode
      else {
        if let httpResponse = response as? HTTPURLResponse {
          Self.logger.error("Network request failed with status code: \(httpResponse.statusCode)")
        }
        throw URLError(.badServerResponse)
      }

      // Use parseCourseData to process API response
      if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
        // Trim all string fields in the JSON response
        let trimmedJson = trimAllStringFields(json) as? [String: Any] ?? json
        let courses = parseCourseData(apiData: trimmedJson)
        saveCoursesToCache(courses: courses)

        self.weekCourses = courses
        self.isCacheEmpty = courses.isEmpty
        self.errorMessage = nil
        self.isUpdatingCache = false
        self.isRefreshing = false
        self.cacheUpdateMessage = forceRefresh ? "Refreshed successfully" : "Course data updated"

        // Hide the message after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
          self.cacheUpdateMessage = nil
        }
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
      self.isUpdatingCache = false
      self.isRefreshing = false
      self.cacheUpdateMessage = nil
      // Only show error if we don't have cached data
      if self.weekCourses.isEmpty {
        self.errorMessage = "Failed to fetch courses: \(error.localizedDescription)"
      } else if forceRefresh {
        // Show brief error notification for refresh failures
        self.cacheUpdateMessage = "Refresh failed"
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
          self.cacheUpdateMessage = nil
        }
      }
    }
  }

  private func createEncryptedQuery(for stdNo: String, helper: CustomAES256Helper) async throws
    -> String
  {
    guard let encrypted = helper.encrypt(data: "20220901200540356," + stdNo) else {
      Self.logger.fault(
        "Failed to encrypt authentication data for student: \(stdNo, privacy: .private)")
      throw EncryptionError.failed
    }
    guard let encoded = encrypted.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    else {
      throw URLError(.badServerResponse)
    }
    return encoded
  }


  // MARK: - UI Updates
  private func setCacheTimeoutFallback(using cachedCourses: [Course]) {
    let workItem = DispatchWorkItem { [weak self] in
      Task { @MainActor in
        Self.logger.notice("Network timeout: Falling back to cached data")
        self?.errorMessage = "Fetching data took too long. Using cached data."
        if let courses = cachedCourses as [Course]? {
          self?.weekCourses = courses
        }
      }
    }
    timeoutWorkItem = workItem
    DispatchQueue.global().asyncAfter(deadline: .now() + 2, execute: workItem)
  }

  private func updateUI(error: String, courses: [Course]? = nil) {
    // Error already captured in errorMessage
    self.errorMessage = error
    if let courses = courses {
      self.weekCourses = courses
    }
  }

  private func updateUI(courses: [Course]) {
    self.weekCourses = courses
    self.errorMessage = nil
  }

  // MARK: - Reachability Configuration
  private func configureReachability() {
    reachability.whenReachable = { reachability in
      DispatchQueue.main.async {
        if reachability.connection == .wifi {
          // Network reachable via WiFi
        } else {
          // Network reachable via Cellular
        }
        self.errorMessage = nil
      }
    }

    reachability.whenUnreachable = { _ in
      DispatchQueue.main.async {
        self.errorMessage = "No internet connection. Please check your network."
      }
    }
  }

  // MARK: - Helper function to clean HTML tags
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
      Self.logger.error("Failed to parse 'stuelelist' from API data")
      return weekCourses
    }

    for courseData in stuelelist {
      guard
        let weekString = courseData["week"] as? String,
        let weekIndex = Int(weekString),
        (1...6).contains(weekIndex)
      else {
        Self.logger.warning("Invalid or missing 'week' in course data")
        continue
      }

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
        Self.logger.warning("Invalid or missing time information for course data")
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

    Self.logger.info("Successfully parsed \(mergedCourses.count) courses")
    return mergedCourses
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
}

// MARK: - Custom Errors

enum EncryptionError: Error { case failed }
