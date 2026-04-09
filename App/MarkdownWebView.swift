import AppKit
import SwiftUI
import WebKit

struct MarkdownWebView: NSViewRepresentable {
    let document: MarkdownPreviewDocument
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
        webView.loadHTMLString(document.html, baseURL: baseURL)
        context.coordinator.lastTitle = document.title
        context.coordinator.lastBodyHTML = document.bodyHTML
        context.coordinator.lastShellSignature = document.shellSignature
        context.coordinator.lastBaseURL = baseURL
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let coordinator = context.coordinator
        guard coordinator.lastTitle != document.title
            || coordinator.lastBodyHTML != document.bodyHTML
            || coordinator.lastShellSignature != document.shellSignature
            || coordinator.lastBaseURL != baseURL else {
            return
        }

        guard coordinator.isPageReady,
              coordinator.lastShellSignature == document.shellSignature,
              coordinator.lastBaseURL == baseURL else {
            coordinator.isPageReady = false
            webView.loadHTMLString(document.html, baseURL: baseURL)
            coordinator.lastTitle = document.title
            coordinator.lastBodyHTML = document.bodyHTML
            coordinator.lastShellSignature = document.shellSignature
            coordinator.lastBaseURL = baseURL
            return
        }

        let updateScript = """
        window.updatePreview(\(document.title.javaScriptLiteral()), \(document.bodyHTML.javaScriptLiteral()));
        """
        webView.evaluateJavaScript(updateScript)
        coordinator.lastTitle = document.title
        coordinator.lastBodyHTML = document.bodyHTML
        coordinator.lastShellSignature = document.shellSignature
        coordinator.lastBaseURL = baseURL
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var isPageReady = false
        var lastTitle = ""
        var lastBodyHTML = ""
        var lastShellSignature = ""
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

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isPageReady = true
        }
    }
}

private extension String {
    func javaScriptLiteral() -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: [self]),
              let encoded = String(data: data, encoding: .utf8) else {
            return "\"\""
        }

        return String(encoded.dropFirst().dropLast())
    }
}
