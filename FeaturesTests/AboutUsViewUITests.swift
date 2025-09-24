// AboutUsViewUITests.swift
import XCTest

final class AboutUsViewUITests: XCTestCase {
  var app: XCUIApplication!

  override func setUp() {
    continueAfterFailure = false
    app = XCUIApplication()
    app.launch()
  }

  func testVersionLabelMatchesBundle() {
    // 讀取被測 target 的 Info.plist
    let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
    let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
    let expected = "\(version) (\(build))"

    let versionLabel = app.staticTexts["about_version_value"]
    XCTAssertTrue(versionLabel.waitForExistence(timeout: 2))
    XCTAssertEqual(versionLabel.label, expected)
  }

  func testLinksExistAndAreHittable() {
    // 僅確認存在與可點，避免跨 App 驗證 Safari
    let ids = [
      "pkg_KeychainSwift",
      "pkg_Lottie",
      "link_淡江i生活",
      "link_Source Code"
    ]
    for id in ids {
      let el = app.buttons[id].firstMatch
      XCTAssertTrue(el.waitForExistence(timeout: 2))
      XCTAssertTrue(el.isHittable)
      el.tap() // 若 Link 轉出 App，之後可立即回到本 App
      app.activate() // 把焦點帶回被測 App，避免後續測試受影響
    }
  }
}
