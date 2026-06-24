//
//  AstroArticleWebViewClient.swift
//  OsmAnd Maps
//
//  Ported from Android AstroArticleWebViewClient.kt.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import UIKit
import WebKit

final class AstroArticleWebViewClient: NSObject, WKNavigationDelegate {
    private let sourceView: UIView
    private let articleUrl: String?
    private weak var presenter: UIViewController?

    init(sourceView: UIView, articleUrl: String?, presenter: UIViewController) {
        self.sourceView = sourceView
        self.articleUrl = articleUrl
        self.presenter = presenter
        super.init()
    }

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void) {
        guard navigationAction.navigationType == .linkActivated else {
            decisionHandler(.allow)
            return
        }
        let rawUrl = navigationAction.request.url?.absoluteString
        decisionHandler(handleUrl(rawUrl) ? .cancel : .allow)
    }

    private func handleUrl(_ rawUrl: String?) -> Bool {
        guard let rawUrl,
              !rawUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }
        let url = OAWikiArticleHelper.normalizeFileUrl(rawUrl) ?? rawUrl
        if url.hasPrefix("#") || isSamePageAnchor(url) {
            return false
        }
        if shouldAllowInternalLoad(url) {
            return false
        }
        if url.hasPrefix("http://") || url.hasPrefix("https://") {
            warnAboutExternalLoad(url)
            return true
        }
        guard let parsed = URL(string: url) else {
            return true
        }
        UIApplication.shared.open(parsed)
        return true
    }

    private func warnAboutExternalLoad(_ url: String) {
        let alert = UIAlertController(title: url,
                                      message: localizedString("online_webpage_warning"),
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"),
                                      style: .cancel,
                                      handler: nil))
        alert.addAction(UIAlertAction(title: localizedString("shared_string_ok"),
                                      style: .default) { _ in
            guard let urlObject = URL(string: url) else {
                return
            }
            UIApplication.shared.open(urlObject)
        })

        if let popoverPresentationController = alert.popoverPresentationController {
            popoverPresentationController.sourceView = sourceView
            popoverPresentationController.permittedArrowDirections = .any
        }
        presenter?.present(alert, animated: true)
    }

    private func shouldAllowInternalLoad(_ url: String) -> Bool {
        if url == "about:blank" {
            return true
        }
        guard let scheme = URL(string: url)?.scheme?.lowercased() else {
            return false
        }
        return scheme == "file" || scheme == "data" || scheme == "applewebdata"
    }

    private func isSamePageAnchor(_ url: String) -> Bool {
        guard url.contains("#"),
              let currentUrl = articleUrl.flatMap({ OAWikiArticleHelper.normalizeFileUrl($0) })?.components(separatedBy: "#").first else {
            return false
        }
        return url.components(separatedBy: "#").first == currentUrl
    }
}
