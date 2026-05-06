import SwiftUI
import WebKit

struct EBookWebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        // Adding universal support for any URL parameter: Google Drive links or generic websites.
        let request = URLRequest(url: url)
        webView.load(request)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // Safe reloading mechanism
    }
}
