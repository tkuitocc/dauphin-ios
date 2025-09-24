import SwiftUI
import WebKit
import WidgetKit
import os

@MainActor
final class AuthViewModel: ObservableObject {
  // App Group defaults
  private let appGroupDefaults = UserDefaults(suiteName: "group.cantpr09ram.dauphin")

  private let logger = Logger(subsystem: "group.cantpr09ram.dauphin", category: "AuthViewModel")

  // 將寫入集中於 didSet，避免重複 set
  @Published var isLoggedIn: Bool {
    didSet { appGroupDefaults?.set(isLoggedIn, forKey: Constants.isLoggedInKey) }
  }

  @Published var ssoStuNo: String {
    didSet { appGroupDefaults?.set(ssoStuNo, forKey: Constants.ssoTokenKey) }
  }

  // 由外部注入，預設建置
  private var courseViewModel: CourseViewModel

  init(courseViewModel: CourseViewModel? = nil) {
    self.isLoggedIn = appGroupDefaults?.bool(forKey: Constants.isLoggedInKey) ?? false
    self.ssoStuNo = appGroupDefaults?.string(forKey: Constants.ssoTokenKey) ?? ""
    // 在 MainActor 隔離的 init 主體內建立預設實例，合法
    self.courseViewModel = courseViewModel ?? CourseViewModel()
  }

  // MARK: - Login

  func login(with token: String) {
    // 避免把敏感資訊寫入公開日誌
    logger.info("Login invoked with token length: \(token.count, privacy: .public)")

    // 更新狀態（didSet 會自動寫入 App Group）
    self.ssoStuNo = token
    self.isLoggedIn = true
    logger.info("Login state updated.")

    // 先刷新 Widget（讀取到剛寫入的值）
    WidgetCenter.shared.reloadAllTimelines()
    logger.info("Widget timelines reloaded after login.")

    // 取課表（與原邏輯相同）
    fetchCourses(token: token)
  }

  // MARK: - Fetch courses

  private func fetchCourses(token: String) {
    Task { [courseViewModel, logger] in
      logger.info("Fetching courses for token length: \(token.count, privacy: .public)")
      await courseViewModel.fetchCourses(with: token)
    }
  }

  // MARK: - Logout

  func logout() {
    // 清除 App Group 中的使用者資料與快取
    appGroupDefaults?.removeObject(forKey: Constants.ssoTokenKey)
    appGroupDefaults?.removeObject(forKey: Constants.Courses)
    appGroupDefaults?.set(false, forKey: Constants.isLoggedInKey)
    logger.info("Cleared App Group user data.")

    // 清除 Web 資料
    clearWebsiteData()

    // 更新本地狀態
    self.isLoggedIn = false
    self.ssoStuNo = ""
    logger.info("User logged out and state reset.")

    // 刷新 Widget
    WidgetCenter.shared.reloadAllTimelines()
    logger.info("Widget timelines reloaded after logout.")
  }

  // MARK: - Clear Website Data

  private func clearWebsiteData() {
    let store = WKWebsiteDataStore.default()
    let all = WKWebsiteDataStore.allWebsiteDataTypes()
    store.fetchDataRecords(ofTypes: all) { [logger] records in
      guard !records.isEmpty else { return }
      store.removeData(ofTypes: all, for: records) {
        records.forEach { rec in
          logger.info("Cleared web data: \(rec.displayName, privacy: .public)")
        }
      }
    }
  }
}
