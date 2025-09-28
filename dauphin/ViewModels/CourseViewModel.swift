import Combine
import OSLog
import Reachability
import SwiftUI

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

  private var reachability: Reachability
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

  init(mockData: [Course]) {
    self.weekCourses = mockData
    self.reachability = try! Reachability()
  }

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
    appGroupDefaults?.removeObject(forKey: Constants.Courses)
    appGroupDefaults?.synchronize()
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
    return
      text
      .replacingOccurrences(of: "<br/>", with: "\n")
      .replacingOccurrences(of: "<br>", with: "\n")
      .replacingOccurrences(of: "</br>", with: "\n")
      .replacingOccurrences(of: "<BR/>", with: "\n")
      .replacingOccurrences(of: "<BR>", with: "\n")
      .replacingOccurrences(of: "\\r\\n", with: "\n")
      .replacingOccurrences(of: "\r\n", with: "\n")
  }

  // MARK: - Helper function to trim all string fields in JSON
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

  // MARK: - Parse Course Data
  private func parseCourseData(apiData: [String: Any]) -> [Course] {
    var weekCourses = [Course]()

    guard let stuelelist = apiData["stuelelist"] as? [[String: Any]] else {
      Self.logger.error("Failed to parse 'stuelelist' from API data")
      return weekCourses
    }

    for courseData in stuelelist {
      guard let weekString = courseData["week"] as? String,
        let weekIndex = Int(weekString),
        (1...6).contains(weekIndex)
      else {
        Self.logger.warning("Invalid or missing 'week' in course data")
        continue
      }

      // Clean HTML tags from all fields first (fields are already trimmed at JSON level)
      let rawCourseName = cleanHTMLTags(from: courseData["ch_cos_name"] as? String ?? "Unknown")
        // Remove all newline characters from the name field
        .replacingOccurrences(of: "\n", with: "")
        .replacingOccurrences(of: "\r", with: "")
      let noteText = courseData["note"] as? String ?? ""
      let cleanedNote = cleanHTMLTags(from: noteText)

      // STEP 1: Split the course if "name" contains "," - only keep the first part
      let courseName =
        rawCourseName.contains(",")
        ? rawCourseName.components(separatedBy: ",").first ?? rawCourseName
        : rawCourseName

      // Handle multiple rooms, teachers, and seat numbers - also only keep first
      let room =
        cleanHTMLTags(from: courseData["room"] as? String ?? "")
        .components(separatedBy: ",")
        .first ?? ""

      let teacher =
        cleanHTMLTags(from: courseData["teach_name"] as? String ?? "Unknown Teacher")
        .components(separatedBy: ",")
        .first ?? "Unknown Teacher"

      let seatNo =
        cleanHTMLTags(from: courseData["seat_no"] as? String ?? "Unknown Seat")
        .components(separatedBy: ",")
        .first ?? "Unknown Seat"

      guard let timeSessions = courseData["timePlase"] as? [String: Any],
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

      // Handle empty room
      let finalRoom =
        (room.isEmpty || room.replacingOccurrences(of: " ", with: "").isEmpty
          || room.range(of: "^[A-Z]", options: .regularExpression) == nil)
        ? "Unknown Room" : room

      // Create single course entry with first part of comma-separated values
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

    // STEP 2: Keep only one course if data is same (remove exact duplicates)
    // Using Set for O(n) performance instead of O(n²)
    var seenCourses = Set<Course>()
    var uniqueCourses: [Course] = []

    for course in weekCourses {
      if seenCourses.insert(course).inserted {
        uniqueCourses.append(course)
      }
    }

    // STEP 3: Replace the "(<note-content>)" inside "name"
    for i in 0..<uniqueCourses.count {
      var course = uniqueCourses[i]
      if !course.note.isEmpty {
        // Since we removed newlines from name but note still has them,
        // we need to compare with a cleaned version of the note
        let noteForComparison = course.note
          .replacingOccurrences(of: "\n", with: "")
          .replacingOccurrences(of: "\r", with: "")
        let notePattern = "(" + noteForComparison + ")"

        if course.name.contains(notePattern) {
          course.name = course.name.replacingOccurrences(of: notePattern, with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        uniqueCourses[i] = course
      }
    }

    // STEP 4: Merge course data if all fields except teacher are same
    var mergedCourses: [Course] = []
    for course in uniqueCourses {
      if let existingIndex = mergedCourses.firstIndex(where: { existingCourse in
        existingCourse.name == course.name && existingCourse.room == course.room
          && existingCourse.time == course.time && existingCourse.stdNo == course.stdNo
          && existingCourse.weekday == course.weekday
          && existingCourse.startTime == course.startTime
          && existingCourse.endTime == course.endTime && existingCourse.note == course.note
      }) {
        // Merge teachers if different
        var mergedCourse = mergedCourses[existingIndex]
        if !mergedCourse.teacher.contains(course.teacher) {
          mergedCourse.teacher += ", " + course.teacher
        }
        mergedCourses[existingIndex] = mergedCourse
      } else {
        mergedCourses.append(course)
      }
    }

    Self.logger.info("Successfully parsed \(mergedCourses.count) courses")
    return mergedCourses
  }

  // MARK: - Time Helpers
  private func sessionToStartTime(session: Int) -> Date? {
    let sessionTimes = [
      1: 8, 2: 9, 3: 10, 4: 11, 5: 12, 6: 13,
      7: 14, 8: 15, 9: 16, 10: 17, 11: 18,
      12: 19, 13: 20, 14: 21,
    ]

    guard let hour = sessionTimes[session] else { return nil }
    let components = DateComponents(year: 1989, month: 6, day: 4, hour: hour, minute: 10)
    return Calendar.current.date(from: components)
  }

  private func sessionToEndTime(session: Int) -> Date? {
    let sessionTimes = [
      1: 9, 2: 10, 3: 11, 4: 12, 5: 13, 6: 14,
      7: 15, 8: 16, 9: 17, 10: 18, 11: 19,
      12: 20, 13: 21, 14: 22,
    ]

    guard let hour = sessionTimes[session] else { return nil }
    let components = DateComponents(year: 1989, month: 6, day: 4, hour: hour, minute: 0)
    return Calendar.current.date(from: components)
  }
}

// MARK: - Custom Errors
enum EncryptionError: Error {
  case failed
}
