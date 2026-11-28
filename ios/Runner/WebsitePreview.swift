import Flutter
import UIKit
import WebKit

@MainActor
final class WebsitePreview: NSObject, WKNavigationDelegate {
  private var browser: WKWebView?
  private var pending: FlutterResult?
  private var timeout: DispatchWorkItem?
  private var snapshot: DispatchWorkItem?

  func register(with messenger: FlutterBinaryMessenger) {
    FlutterMethodChannel(name: "checklist/website_previews", binaryMessenger: messenger)
      .setMethodCallHandler { [self] call, result in
        guard call.method == "capture" else {
          result(FlutterMethodNotImplemented)
          return
        }
        guard let address = call.arguments as? String, let url = URL(string: address),
          isWebsite(url)
        else {
          result(nil)
          return
        }
        capture(url, result: result)
      }
  }

  private func capture(_ url: URL, result: @escaping FlutterResult) {
    guard pending == nil,
      let window = UIApplication.shared.connectedScenes
        .compactMap({ $0 as? UIWindowScene })
        .flatMap(\.windows).first(where: \.isKeyWindow)
    else {
      result(nil)
      return
    }
    let configuration = WKWebViewConfiguration()
    configuration.websiteDataStore = .nonPersistent()
    let view = WKWebView(frame: CGRect(x: 0, y: 0, width: 600, height: 390),
                         configuration: configuration)
    view.isUserInteractionEnabled = false
    view.accessibilityElementsHidden = true
    view.navigationDelegate = self
    // WebKit needs a window to render the snapshot. Keep it below Flutter.
    window.insertSubview(view, at: 0)
    browser = view
    pending = result
    let expiry = DispatchWorkItem { [weak self, weak view] in
      if let view { self?.finish(view, data: nil) }
    }
    timeout = expiry
    DispatchQueue.main.asyncAfter(deadline: .now() + 10, execute: expiry)
    if view.load(URLRequest(url: url)) == nil { finish(view, data: nil) }
  }

  func webView(
    _ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
    decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
  ) {
    let allowed = navigationAction.targetFrame != nil &&
      navigationAction.request.url.map(isWebsite) == true
    decisionHandler(allowed ? .allow : .cancel)
  }

  func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
    snapshot?.cancel()
  }

  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    guard webView === browser else { return }
    snapshot?.cancel()
    let capture = DispatchWorkItem { [weak self, weak webView] in
      guard let self, let webView, webView === self.browser else { return }
      let configuration = WKSnapshotConfiguration()
      configuration.snapshotWidth = 600
      webView.takeSnapshot(with: configuration) { [weak self, weak webView] image, _ in
        guard let webView else { return }
        self?.finish(webView, data: image?.jpegData(compressionQuality: 0.80))
      }
    }
    snapshot = capture
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: capture)
  }

  func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
    finish(webView, data: nil)
  }

  func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!,
               withError error: Error) {
    finish(webView, data: nil)
  }

  func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
    finish(webView, data: nil)
  }

  private func finish(_ view: WKWebView, data: Data?) {
    guard view === browser, let result = pending else { return }
    pending = nil
    browser = nil
    timeout?.cancel()
    snapshot?.cancel()
    timeout = nil
    snapshot = nil
    view.navigationDelegate = nil
    view.stopLoading()
    view.removeFromSuperview()
    result(data.map { FlutterStandardTypedData(bytes: $0) })
  }

  private func isWebsite(_ url: URL) -> Bool {
    guard let host = url.host, !host.isEmpty, url.user == nil, url.password == nil else {
      return false
    }
    return url.scheme == "https" || url.scheme == "http"
  }
}
