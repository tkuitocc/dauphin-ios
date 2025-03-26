//
//  LibSSoLoginView.swift
//  campuspass_ios
//
//  Created by \u8b19 on 11/17/24.
//

import SwiftUI
import WebKit

struct LibSSOLoginView: UIViewRepresentable {
    @ObservedObject var viewModel: AuthViewModel

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: LibSSOLoginView

        init(parent: LibSSOLoginView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("網頁加載完成")
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
                        print("JavaScript 執行錯誤: \(error.localizedDescription)")
                    } else {
                        print("JavaScript 執行成功")
                    }
                }
            }
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            print("收到 JavaScript 訊息: \(message.body)")
            if message.name == "ExtObj" {
                if let token = message.body as? String {
                    if token.starts(with: "error:") {
                        print("JavaScript 錯誤: \(token)")
                    } else {
                        print("成功獲取 token: \(token)")
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

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    private func handleToken(_ token: String) {
        guard !token.isEmpty else {
            print("Token 無效")
            return
        }

        print("處理有效的 token")
        viewModel.login(with: token)
    }
}
