import SwiftUI
import Combine
import Reachability

// MARK: - ViewModel for Courses
class CourseViewModel: ObservableObject {
    private let appGroupDefaults = UserDefaults(suiteName: "group.cantpr09ram.dauphin")

    @Published var weekCourses: [Course] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    private var reachability: Reachability
    private var helper: CustomAES256Helper?
    private var timeoutWorkItem: DispatchWorkItem?
    private var cancellables = Set<AnyCancellable>()

    init() {
        reachability = try! Reachability()

        configureReachability()
        do {
            try reachability.startNotifier()
        } catch {
            print("Unable to start reachability notifier: \(error)")
        }
        Task {
            await initializeHelper()
        }
    }

    init(mockData: [Course]) {
        self.weekCourses = mockData
        self.reachability = try! Reachability()
    }

    // MARK: - Helper Initialization
    private func initializeHelper() async {
        if let key = KeychainManager.shared.get(forKey: "AES256KEY"),
           let iv = KeychainManager.shared.get(forKey: "AES256IV") {
            helper = CustomAES256Helper(key: key, iv: iv)
            print("✅ Successfully initialized helper with AES256 key and IV.")
        } else {
            await MainActor.run {
                self.errorMessage = "Failed to retrieve AES256 key or IV from Keychain."
            }
            print("❌ Error: \(errorMessage ?? "Unknown error")")
        }
    }

    // MARK: - Cache Management
    func loadCoursesFromCache() -> [Course]? {
        print("Load courses from cache")
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let data = appGroupDefaults?.data(forKey: Constants.Courses) else {
            print("❌ No cached data found for key: \(Constants.Courses)")
            return nil
        }

        do {
            let courses = try decoder.decode([Course].self, from: data)
            print("✅ Successfully loaded courses from cache.")
            return courses
        } catch {
            print("❌ Failed to decode cached courses: \(error)")
            return nil
        }
    }

    func saveCoursesToCache(courses: [Course]) {
        print("Save courses from cache")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        do {
            let data = try encoder.encode(courses)
            appGroupDefaults?.set(data, forKey: Constants.Courses)
            print("✅ Courses saved to cache successfully.")
        } catch {
            print("❌ Failed to encode and save courses: \(error)")
        }
    }

    // MARK: - Fetch Courses
    func fetchCourses(with stdNo: String) async {
        print("Fetch courses")
        timeoutWorkItem?.cancel()

        if let cachedCourses = loadCoursesFromCache() {
            setCacheTimeoutFallback(using: cachedCourses)
        }

        guard let helper = helper else {
            await updateUI(error: "Encryption helper not initialized.")
            return
        }

        guard reachability.connection != .unavailable else {
            if let cachedCourses = loadCoursesFromCache() {
                await updateUI(error: "No internet connection. Showing cached data.", courses: cachedCourses)
            }
            return
        }

        do {
            let encryptedQuery = try await createEncryptedQuery(for: stdNo, helper: helper)
            let url = URL(string: "https://ilifeapi.az.tku.edu.tw/api/ilifeStuClassApi?q=\(encryptedQuery)")!

            // isLoading = true
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
                throw URLError(.badServerResponse)
            }

            // Use parseCourseData to process API response
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                let courses = parseCourseData(apiData: json)
                saveCoursesToCache(courses: courses)
                await updateUI(courses: courses)
            } else {
                throw URLError(.cannotParseResponse)
            }

        } catch {
            await updateUI(error: "Failed to fetch courses: \(error.localizedDescription)")
        }
    }

    private func createEncryptedQuery(for stdNo: String, helper: CustomAES256Helper) async throws -> String {
        guard let encrypted = helper.encrypt(data: "20220901200540356," + stdNo) else {
            throw EncryptionError.failed
        }
        guard let encoded = encrypted.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw URLError(.badServerResponse)
        }
        return encoded
    }

    // MARK: - Parse Course Data
    private func parseCourseData(apiData: [String: Any]) -> [Course] {
        var weekCourses = [Course]()

        guard let stuelelist = apiData["stuelelist"] as? [[String: Any]] else {
            print("❌ Failed to parse 'stuelelist' from API data.")
            return weekCourses
        }

        for courseData in stuelelist {
            guard let weekString = courseData["week"] as? String,
                  let weekIndex = Int(weekString),
                  (1...6).contains(weekIndex) else {
                print("❌ Invalid or missing 'week' in course data.")
                continue
            }

            // let name = (courseData["ch_cos_name"] as? String ?? "Unknown")
            //    .replacingOccurrences(of: "\\s*\\(.*\\)", with: "", options: .regularExpression)
            let name = (courseData["ch_cos_name"] as? String ?? "Unknown")

            let room = courseData["room"] as? String ?? (courseData["note"] as? String ?? "Unknown Room")
            let teacher = courseData["teach_name"] as? String ?? "Unknown Teacher"
            let seatNo = courseData["seat_no"] as? String ?? "Unknown Seat"

            guard let timeSessions = courseData["timePlase"] as? [String: Any],
                  let sesses = timeSessions["sesses"] as? [String],
                  let firstSession = sesses.first,
                  let lastSession = sesses.last,
                  let firstSessionInt = Int(firstSession),
                  let lastSessionInt = Int(lastSession),
                  let start = sessionToStartTime(session: firstSessionInt),
                  let end = sessionToEndTime(session: lastSessionInt) else {
                print("❌ Invalid or missing time information for course: \(name)")
                continue
            }

            let time = sesses.joined(separator: ", ")

            weekCourses.append(
                Course(
                    name: name,
                    room: room,
                    teacher: teacher,
                    time: time,
                    startTime: start,
                    endTime: end,
                    stdNo: seatNo,
                    weekday: weekIndex
                )
            )
        }

        print("✅ Successfully parsed \(weekCourses.count) courses.")
        return weekCourses
    }

    // MARK: - Time Helpers
    private func sessionToStartTime(session: Int) -> Date? {
        let sessionTimes = [
            1: 8, 2: 9, 3: 10, 4: 11, 5: 12, 6: 13,
            7: 14, 8: 15, 9: 16, 10: 17, 11: 18,
            12: 19, 13: 20, 14: 21
        ]

        guard let hour = sessionTimes[session] else { return nil }
        let components = DateComponents(year: 1989, month: 6, day: 4, hour: hour, minute: 10)
        return Calendar.current.date(from: components)
    }

    private func sessionToEndTime(session: Int) -> Date? {
        let sessionTimes = [
            1: 9, 2: 10, 3: 11, 4: 12, 5: 13, 6: 14,
            7: 15, 8: 16, 9: 17, 10: 18, 11: 19,
            12: 20, 13: 21, 14: 22
        ]

        guard let hour = sessionTimes[session] else { return nil }
        let components = DateComponents(year: 1989, month: 6, day: 4, hour: hour, minute: 0)
        return Calendar.current.date(from: components)
    }

    // MARK: - UI Updates
    private func setCacheTimeoutFallback(using cachedCourses: [Course]) {
        let workItem = DispatchWorkItem { [weak self] in
            Task {
                await self?.updateUI(error: "Fetching data took too long. Using cached data.", courses: cachedCourses)
            }
        }
        timeoutWorkItem = workItem
        DispatchQueue.global().asyncAfter(deadline: .now() + 2, execute: workItem)
    }

    private func updateUI(error: String, courses: [Course]? = nil) async {
        await MainActor.run {
            print(self.errorMessage ?? "Error in fetchCourses")
            self.errorMessage = error
            self.isLoading = false
            if let courses = courses {
                self.weekCourses = courses
            }
        }
    }

    private func updateUI(courses: [Course]) async {
        await MainActor.run {
            self.weekCourses = courses
            self.errorMessage = nil
            self.isLoading = false
        }
    }

    // MARK: - Reachability Configuration
    private func configureReachability() {
        reachability.whenReachable = { reachability in
            DispatchQueue.main.async {
                if reachability.connection == .wifi {
                    print("Network is reachable via WiFi.")
                } else {
                    print("Network is reachable via Cellular.")
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
}

// MARK: - Custom Errors
enum EncryptionError: Error {
    case failed
}
