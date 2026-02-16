import Combine
import Network
import OSLog
import SwiftUI

@MainActor final class CourseViewModel: ObservableObject {

    private static let logger = Logger(
        subsystem: "group.cantpr09ram.dauphin", category: "CourseViewModel")

    // 對外狀態：維持不變
    @Published var weekCourses: [Course] = []
    @Published var errorMessage: String? = nil
    @Published var isCacheEmpty = false
    @Published var isUpdatingCache = false
    @Published var cacheUpdateMessage: String? = nil
    @Published var isRefreshing = false

    // 內部依賴
    private let repo: CourseRepository
    private let nextUp: NextUpService
    private let encryptor: (String) -> String?

    // 網路狀態（維持原行為）
    private var monitor: NWPathMonitor
    private let monitorQueue = DispatchQueue(label: "CourseViewModel.Network")
    private var isNetworkAvailable = true
    private var cacheMessageTask: Task<Void, Never>?

    private var hasPerformedInitialLoad = false

    // 預設建構符合舊使用方式（不改外部）
    init(
        repository: CourseRepository? = nil, nextUpService: NextUpService = DefaultNextUpService(),
        encryptor: ((String) -> String?)? = nil
    ) {
        // Cache 與 Parser 預設注入
        let cache = DefaultsCourseCache(
            suiteName: "group.cantpr09ram.dauphin", key: Constants.courses)
        let parser = DefaultCourseParser(
            htmlStrip: { text in
                text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            }, sessionToStart: sessionToStartTime, sessionToEnd: sessionToEndTime)
        let api = DefaultCourseAPIClient()
        self.repo = repository ?? DefaultCourseRepository(api: api, cache: cache, parser: parser)
        self.nextUp = nextUpService

        if let enc = encryptor {
            self.encryptor = enc
        } else if let key = KeychainManager.shared.get(forKey: "AES256KEY"),
            let iv = KeychainManager.shared.get(forKey: "AES256IV")
        {
            let helper = CustomAES256Helper(key: key, iv: iv)
            self.encryptor = { helper.encrypt(data: $0) }
            Self.logger.debug("Successfully initialized AES256 helper")
        } else {
            self.encryptor = { _ in nil }
            self.errorMessage = "Failed to retrieve AES256 key or IV from Keychain."
            Self.logger.error("Failed to retrieve AES256 key or IV from Keychain")
        }

        self.monitor = NWPathMonitor()
        startNetworkMonitor()
    }

    deinit {
        cacheMessageTask?.cancel()
        monitor.cancel()
    }

    private func scheduleCacheMessageClear() {
        cacheMessageTask?.cancel()
        cacheMessageTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard !Task.isCancelled else { return }
            self?.cacheUpdateMessage = nil
        }
    }

    private func startNetworkMonitor() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.isNetworkAvailable = (path.status == .satisfied)
                if self.isNetworkAvailable {
                    Self.logger.debug("Network is available")
                    self.errorMessage = nil
                } else {
                    Self.logger.debug("Network is unavailable")
                    self.errorMessage = "No internet connection. Please check your network."
                }
            }
        }
        monitor.start(queue: monitorQueue)
    }

    // 與舊版相同的快取 API（對外行為不變）
    func loadCoursesFromCache() -> [Course]? {
        let courses = repo.loadCache()
        isCacheEmpty = courses?.isEmpty ?? true
        if courses == nil { Self.logger.debug("No cached data found for courses") }
        return courses
    }

    func clearCache() {
        repo.clearCache()
        weekCourses = []
        isCacheEmpty = true
        errorMessage = "Cache cleared. Please refresh to load courses."
    }

    func resetInitializationFlag() {
        hasPerformedInitialLoad = false
        Self.logger.debug("Reset initialization flag for fresh session")
    }

    func saveCoursesToCache(courses: [Course]) {
        repo.saveCache(courses)
        Self.logger.debug("Courses saved to cache successfully")
    }

    // 對外簽名不變
    func fetchCourses(with stdNo: String, forceRefresh: Bool = false, isFirstLogin: Bool = false)
        async
    {
        if forceRefresh { self.isRefreshing = true }
        cacheMessageTask?.cancel()

        // 先載入快取顯示
        if let cached = loadCoursesFromCache(), !cached.isEmpty {
            self.weekCourses = cached
            self.errorMessage = nil
        }

        // 同一 session 僅自動打一次，除非強制刷新或首次登入
        guard !hasPerformedInitialLoad || forceRefresh || isFirstLogin else {
            self.isRefreshing = false
            return
        }

        guard isNetworkAvailable else {
            if weekCourses.isEmpty {
                self.errorMessage = "No internet connection and no cached data available."
            }
            self.isRefreshing = false
            return
        }

        hasPerformedInitialLoad = true
        self.isUpdatingCache = true
        self.cacheUpdateMessage = "Updating course data..."

        do {
            let courses = try await repo.fetchRemote(stdNo: stdNo, encrypt: encryptor)
            saveCoursesToCache(courses: courses)
            self.weekCourses = courses
            self.isCacheEmpty = courses.isEmpty
            self.errorMessage = nil
            self.isUpdatingCache = false
            self.isRefreshing = false
            self.cacheUpdateMessage =
                forceRefresh ? "Refreshed successfully" : "Course data updated"
            scheduleCacheMessageClear()
        } catch {
            self.isUpdatingCache = false
            self.isRefreshing = false
            self.cacheUpdateMessage = nil
            if self.weekCourses.isEmpty {
                self.errorMessage = "Failed to fetch courses."
            } else if forceRefresh {
                self.cacheUpdateMessage = "Refresh failed"
                scheduleCacheMessageClear()
            }
            Self.logger.error("Fetch error: \(error.localizedDescription)")
        }
    }
}

extension CourseViewModel {
    convenience init(mockData: [Course]) {
        self.init()
        self.weekCourses = mockData
    }
}
