import SwiftUI

@main
struct MyApp: App {
  @State private var isLoaded = false
  @State private var errorMessage: String?

  var body: some Scene {
    WindowGroup {
      if isLoaded {
        ContentView()  // API 金鑰載入成功後顯示主畫面
      } else {
        LaunchScreenView()  // 顯示啟動畫面
          .task {
            do {
              try await KeyConstants.loadAPIKeys()
              isLoaded = true  // 立即切換到 ContentView
            } catch {
              errorMessage = error.localizedDescription
            }
          }
      }
    }
  }
}
