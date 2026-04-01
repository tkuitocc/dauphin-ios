import OSLog
import SwiftUI

@main struct MyApp: App {
    private static let logger = Logger(subsystem: Constants.loggerSubsystem, category: "App")
    @AppStorage(
        Constants.userInterfaceStyle
    )
    var userInterfaceStyle = UIUserInterfaceStyle.unspecified
    @State private var isLoaded = false
    @State private var errorMessage: String?

    var body: some Scene {
        WindowGroup {
            if isLoaded {
                ContentView()  // API 金鑰載入成功後顯示主畫面
                    .preferredColorScheme(.init(userInterfaceStyle))
            } else {
                LaunchScreenView(
                    errorMessage: errorMessage, onRetry: { Task { await attemptLoadKeys() } }
                ).task { if errorMessage == nil { await attemptLoadKeys() } }
            }
        }
    }

    private func attemptLoadKeys() async {
        do {
            try await KeyConstants.loadAPIKeys()
            isLoaded = true  // 立即切換到 ContentView
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            MyApp.logger.fault(
                "Failed to load API keys at app launch: \(error.localizedDescription)")
        }
    }
}
