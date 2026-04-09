import AppKit
import SwiftUI
import WebKit

struct MarkdownWebView: NSViewRepresentable {
    let html: String
    let baseURL: URL?

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.setValue(false, forKey: "drawsBackground")
        webView.allowsMagnification = true
        webView.loadHTMLString(html, baseURL: baseURL)
        context.coordinator.lastHTML = html
        context.coordinator.lastBaseURL = baseURL
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        guard context.coordinator.lastHTML != html || context.coordinator.lastBaseURL != baseURL else {
            return
        }

        webView.loadHTMLString(html, baseURL: baseURL)
        context.coordinator.lastHTML = html
        context.coordinator.lastBaseURL = baseURL
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var lastHTML = ""
        var lastBaseURL: URL?

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void
        ) {
            if navigationAction.navigationType == .linkActivated,
               let url = navigationAction.request.url,
               !url.isFileURL {
                NSWorkspace.shared.open(url)
                decisionHandler(.cancel)
                return
            }

            decisionHandler(.allow)
        }
    }
}
