import OSLog
import SwiftUI
import WebKit
import OSLog

struct LibSSOLoginView: UIViewRepresentable {
    private static let logger = Logger(subsystem: "com.dauphin.app", category: "LibSSOLogin")
    @ObservedObject var viewModel: AuthViewModel

  class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    var parent: LibSSOLoginView

    init(parent: LibSSOLoginView) {
      self.parent = parent
    }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Web page loaded
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

                webView.evaluateJavaScript(javascript) { (result, error) in
                    if let error = error {
                        LibSSOLoginView.logger.error("JavaScript execution error: \(error.localizedDescription)")
                    }
                }
            }
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            // Received JavaScript message
            if message.name == "ExtObj" {
                if let token = message.body as? String {
                    if token.starts(with: "error:") {
                        LibSSOLoginView.logger.error("JavaScript token retrieval failed: \(token)")
                    } else {
                        LibSSOLoginView.logger.info("Authentication token received successfully")
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
            Self.logger.error("Invalid authentication token received")
            return
        }

        // Processing valid authentication token
        viewModel.login(with: token)
    }
}
