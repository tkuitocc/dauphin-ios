import OSLog
import SwiftUI
import WebKit

struct LibSSOLoginView: UIViewRepresentable {
    private static let logger = Logger(
        subsystem: "group.cantpr09ram.dauphin", category: "LibSSOLogin")
    @ObservedObject var viewModel: AuthViewModel

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: LibSSOLoginView
        private let allowedHosts: Set<String> = ["sso.tku.edu.tw"]
        private var evaluateTokenTask: Task<Void, Never>?

        init(parent: LibSSOLoginView) { self.parent = parent }

        deinit { evaluateTokenTask?.cancel() }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Web page loaded
            evaluateTokenTask?.cancel()
            evaluateTokenTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 500_000_000)
                guard !Task.isCancelled else { return }

                let javascript = """
                        try {
                            var token = getSsoLoginToken();
                            window.webkit.messageHandlers.ExtObj.postMessage(token);
                        } catch(e) {
                            console.error('Error:', e);
                            window.webkit.messageHandlers.ExtObj.postMessage('error:' + e.message);
                        }
                    """

                do { _ = try await webView.evaluateJavaScript(javascript) } catch {
                    LibSSOLoginView.logger.error(
                        "JavaScript execution error: \(error.localizedDescription)")
                }
            }
        }

        func userContentController(
            _ userContentController: WKUserContentController, didReceive message: WKScriptMessage
        ) {
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

        func webView(
            _ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.cancel)
                return
            }

            let isHttps = url.scheme?.lowercased() == "https"
            let hostAllowed = url.host.map { allowedHosts.contains($0.lowercased()) } ?? false

            if isHttps && hostAllowed {
                decisionHandler(.allow)
            } else {
                LibSSOLoginView.logger.error("Blocked navigation to \(url.absoluteString)")
                decisionHandler(.cancel)
            }
        }

        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            LibSSOLoginView.logger.error("Web content process terminated")
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIView(context: Context) -> WKWebView {
        let contentController = WKUserContentController()
        contentController.add(context.coordinator, name: "ExtObj")

        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        config.websiteDataStore = .nonPersistent()

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator

        if let url = URL(string: "https://sso.tku.edu.tw/ilife/CoWork/AndroidSsoLogin.cshtml") {
            let request = URLRequest(url: url)
            webView.load(request)
        }

        return webView
    }

    func updateUIView(_ webView: WKWebView, context _: Context) {}

    static func dismantleUIView(_ webView: WKWebView, coordinator _: Coordinator) {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "ExtObj")
    }

    private func handleToken(_ token: String) {
        guard !token.isEmpty else {
            LibSSOLoginView.logger.error("Invalid authentication token received")
            return
        }

        // Processing valid authentication token
        viewModel.login(with: token)
    }
}
