import OSLog
import SwiftUI
import WebKit

private let ssoLogger = Logger(
  subsystem: "group.cantpr09ram.dauphin",
  category: "LibSSOLoginView"
)

struct LibSSOLoginView: UIViewRepresentable {
  @ObservedObject var viewModel: AuthViewModel

  class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    var parent: LibSSOLoginView

    init(parent: LibSSOLoginView) {
      self.parent = parent
    }

    func webView(_ webView: WKWebView, didFinish _: WKNavigation!) {
      ssoLogger.info("網頁加載完成")
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        let javascript = """
              try {
                  var token = getSsoLoginToken();
                  window.webkit.messageHandlers.ExtObj.postMessage(token);
              } catch(e) {
                  console.error('Error:', e);
                  window.webkit.messageHandlers.ExtObj.postMessage('error:' + e.message);
              }
          """

        webView.evaluateJavaScript(javascript) { _, error in
          if let error = error {
            ssoLogger.error(
              "JavaScript 執行錯誤: \(error.localizedDescription, privacy: .public)"
            )
          } else {
            ssoLogger.info("JavaScript 執行成功")
          }
        }
      }
    }

    func userContentController(_: WKUserContentController, didReceive message: WKScriptMessage) {
      ssoLogger.debug(
        "收到 JavaScript 訊息: \(String(describing: message.body), privacy: .public)"
      )
      if message.name == "ExtObj" {
        if let token = message.body as? String {
          if token.starts(with: "error:") {
            ssoLogger.error("JavaScript 錯誤: \(token, privacy: .public)")
          } else {
            ssoLogger.info("成功獲取 token: \(token, privacy: .public)")
            parent.handleToken(token)
          }
        }
      }
    }
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(parent: self)
  }

  func makeUIView(context: Context) -> WKWebView {
    let contentController = WKUserContentController()
    contentController.add(context.coordinator, name: "ExtObj")

    let config = WKWebViewConfiguration()
    config.userContentController = contentController

    let webView = WKWebView(frame: .zero, configuration: config)
    webView.navigationDelegate = context.coordinator

    if let url = URL(string: "https://sso.tku.edu.tw/ilife/CoWork/AndroidSsoLogin.cshtml") {
      let request = URLRequest(url: url)
      webView.load(request)
    }

    return webView
  }

  func updateUIView(_: WKWebView, context _: Context) {}

  private func handleToken(_ token: String) {
    guard !token.isEmpty else {
      ssoLogger.error("Token 無效")
      return
    }

    ssoLogger.info("處理有效的 token")
    viewModel.login(with: token)
  }
}
