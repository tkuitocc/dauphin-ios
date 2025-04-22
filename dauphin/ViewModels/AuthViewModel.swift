import SwiftUI
import WebKit
import WidgetKit

class AuthViewModel: ObservableObject {
    private let appGroupDefaults = UserDefaults(suiteName: "group.cantpr09ram.dauphin")

    @Published var isLoggedIn: Bool {
        didSet {
            appGroupDefaults?.set(isLoggedIn, forKey: Constants.isLoggedInKey)
        }
    }
    @Published var ssoStuNo: String {
        didSet {
            appGroupDefaults?.set(ssoStuNo, forKey: Constants.ssoTokenKey)
        }
    }
    private var courseViewModel: CourseViewModel

    init(courseViewModel: CourseViewModel = CourseViewModel()) {
        self.isLoggedIn = appGroupDefaults?.bool(forKey: Constants.isLoggedInKey) ?? false
        self.ssoStuNo = appGroupDefaults?.string(forKey: Constants.ssoTokenKey) ?? ""
        self.courseViewModel = courseViewModel
    }

    func login(with token: String) {
        print("Logging in with token: \(token)")
        DispatchQueue.main.async {
            self.ssoStuNo = token
            self.isLoggedIn = true
            print("Updated login state")
            
            self.appGroupDefaults?.set(token, forKey: Constants.ssoTokenKey)
            self.appGroupDefaults?.synchronize()
            print("Saved ssoStuNo to App Group")
            // Update Widget timelines
            WidgetCenter.shared.reloadAllTimelines()
            print("Widget timelines reloaded.")

            // Fetch courses
            self.fetchCourses(token: token)

        }
    }

    // Fetch courses for the logged-in user
    private func fetchCourses(token: String) {
        Task {
            print("Fetching courses for token: \(token)")
            await courseViewModel.fetchCourses(with: token)
        }
    }

    func logout() {
        // Clear token and courses from App Group defaults
        appGroupDefaults?.removeObject(forKey: Constants.ssoTokenKey)
        appGroupDefaults?.removeObject(forKey: Constants.Courses)
        print("已清除 App Group 的使用者資料")

        // Clear website data
        clearWebsiteData()

        // Update authentication state
        DispatchQueue.main.async {
            self.isLoggedIn = false
            self.ssoStuNo = ""
            print("已登出，使用者狀態已重置")

            // Reload widget timelines after logout
            WidgetCenter.shared.reloadAllTimelines()
            print("Widget timelines reloaded after logout")
        }
    }

    // MARK: - Clear Website Data
    private func clearWebsiteData() {
        let dataStore = WKWebsiteDataStore.default()
        dataStore.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            records.forEach { record in
                dataStore.removeData(ofTypes: record.dataTypes, for: [record]) {
                    print("已清除紀錄: \(record.displayName)")
                }
            }
        }
    }
}
