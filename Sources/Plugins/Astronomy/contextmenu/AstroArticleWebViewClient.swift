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

    init(sourceView: UIView, articleUrl: String?) {
        self.sourceView = sourceView
        self.articleUrl = articleUrl
        super.init()
    }

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void) {
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
        if url.hasPrefix("http://") || url.hasPrefix("https://") {
            OAWikiArticleHelper.warnAboutExternalLoad(url, sourceView: sourceView)
            return true
        }
        guard let parsed = URL(string: url) else {
            return true
        }
        UIApplication.shared.open(parsed)
        return true
    }

    private func isSamePageAnchor(_ url: String) -> Bool {
        guard url.contains("#"),
              let currentUrl = articleUrl.flatMap({ OAWikiArticleHelper.normalizeFileUrl($0) })?.components(separatedBy: "#").first else {
            return false
        }
        return url.components(separatedBy: "#").first == currentUrl
    }
}
