import OSLog
import SwiftUI
import WebKit
import WidgetKit
import os

@MainActor
final class AuthViewModel: ObservableObject {
  private static let logger = Logger(
    subsystem: "group.cantpr09ram.dauphin", category: "AuthViewModel")
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
  let courseViewModel: CourseViewModel

  init(courseViewModel: CourseViewModel? = nil) {
    self.isLoggedIn = appGroupDefaults?.bool(forKey: Constants.isLoggedInKey) ?? false
    self.ssoStuNo = appGroupDefaults?.string(forKey: Constants.ssoTokenKey) ?? ""
    self.courseViewModel = courseViewModel ?? CourseViewModel()
  }

  func login(with token: String) {
    // Processing login with provided token
    self.ssoStuNo = token
    self.isLoggedIn = true
    // Login state updated

    self.appGroupDefaults?.set(token, forKey: Constants.ssoTokenKey)
    self.appGroupDefaults?.synchronize()
    AuthViewModel.logger.info("Saved ssoStuNo to App Group")
    // Update Widget timelines
    WidgetCenter.shared.reloadAllTimelines()
    AuthViewModel.logger.debug("Widget timelines reloaded")

    // Fetch courses
    self.fetchCourses(token: token)
  }

  // Fetch courses for the logged-in user
  private func fetchCourses(token: String) {
    Task {
      // Initiating course fetch for authenticated user - force fetch on login
      await courseViewModel.fetchCourses(with: token, forceRefresh: false, isFirstLogin: true)
    }
  }

  func logout() {
    // Clear token and courses from App Group defaults
    appGroupDefaults?.removeObject(forKey: Constants.ssoTokenKey)
    appGroupDefaults?.removeObject(forKey: Constants.courses)
    AuthViewModel.logger.info("Cleared user data from App Group")

    // Reset course view model initialization flag for fresh session
    courseViewModel.resetInitializationFlag()

    // Clear website data
    clearWebsiteData()

    // Update authentication state
    self.isLoggedIn = false
    self.ssoStuNo = ""
    AuthViewModel.logger.info("User logged out and state reset")

    // Reload widget timelines after logout
    WidgetCenter.shared.reloadAllTimelines()
    AuthViewModel.logger.debug("Widget timelines reloaded after logout")
  }

  // MARK: - Clear Website Data
  private func clearWebsiteData() {
    let dataStore = WKWebsiteDataStore.default()
    dataStore.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
      for record in records {
        dataStore.removeData(ofTypes: record.dataTypes, for: [record]) {
          AuthViewModel.logger.debug("Cleared website data record: \(record.displayName)")
        }
      }
    }
  }
}
