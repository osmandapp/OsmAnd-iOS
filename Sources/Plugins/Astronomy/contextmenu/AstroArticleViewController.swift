//
//  AstroArticleViewController.swift
//  OsmAnd Maps
//
//  Ported from the Android astronomy article dialog.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import UIKit
import WebKit

final class AstroArticleViewController: UIViewController {
    static let tag = "AstroArticleViewController"
    private static let bodyContentRegex = try? NSRegularExpression(pattern: "<body[^>]*>([\\s\\S]*?)</body>",
                                                                   options: [.caseInsensitive])

    private let article: AstroArticle
    private let articleHtml: String
    private let webView = WKWebView(frame: .zero)
    private let titleLabel = UILabel()
    private let readFullArticleButton = UIButton(type: .system)
    private var webViewClient: AstroArticleWebViewClient?

    init(article: AstroArticle) {
        self.article = article
        self.articleHtml = article.getMobileHtmlString() ?? ""
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
        if let sheetPresentationController {
            sheetPresentationController.detents = [.large()]
            sheetPresentationController.prefersGrabberVisible = true
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static func showInstance(from viewController: UIViewController, article: AstroArticle) -> Bool {
        let viewControllerToPresent = AstroArticleViewController(article: article)
        viewController.present(viewControllerToPresent, animated: true)
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        applyTheme()
        setupToolbar()
        setupWebView()
        populateArticle()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.hasDifferentColorAppearance(comparedTo: traitCollection) == true {
            applyTheme()
            if !articleHtml.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                webView.loadHTMLString(createHtmlContent(), baseURL: nil)
            }
        }
    }

    private func applyTheme() {
        view.backgroundColor = AstroContextMenuTheme.pageBackground
        titleLabel.textColor = AstroContextMenuTheme.primaryText
        readFullArticleButton.tintColor = .white
        readFullArticleButton.backgroundColor = AstroContextMenuTheme.primaryButton
        webView.backgroundColor = AstroContextMenuTheme.pageBackground
    }

    private func setupToolbar() {
        let toolbar = UIView()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toolbar)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = AstroContextMenuTheme.primaryText
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.numberOfLines = 2
        toolbar.addSubview(titleLabel)

        let closeButton = UIButton(type: .system)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setImage(AstroIcon.template("ic_action_close"), for: .normal)
        closeButton.tintColor = AstroContextMenuTheme.secondaryIcon
        closeButton.addAction(UIAction { [weak self] _ in
            self?.dismiss(animated: true)
        }, for: .touchUpInside)
        toolbar.addSubview(closeButton)

        readFullArticleButton.translatesAutoresizingMaskIntoConstraints = false
        readFullArticleButton.setTitle(localizedString("context_menu_read_full_article"), for: .normal)
        readFullArticleButton.setImage(AstroIcon.template("ic_world_globe_dark"), for: .normal)
        readFullArticleButton.tintColor = .white
        readFullArticleButton.backgroundColor = AstroContextMenuTheme.primaryButton
        readFullArticleButton.layer.cornerRadius = 10
        readFullArticleButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 14, bottom: 10, right: 14)
        readFullArticleButton.addAction(UIAction { [weak self] _ in
            self?.openFullArticle()
        }, for: .touchUpInside)
        view.addSubview(readFullArticleButton)

        NSLayoutConstraint.activate([
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 60),

            titleLabel.leadingAnchor.constraint(equalTo: toolbar.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -12),
            titleLabel.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),

            closeButton.trailingAnchor.constraint(equalTo: toolbar.trailingAnchor, constant: -12),
            closeButton.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),

            readFullArticleButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            readFullArticleButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            readFullArticleButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            readFullArticleButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
    }

    private func setupWebView() {
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.backgroundColor = AstroContextMenuTheme.pageBackground
        webView.isOpaque = false
        webView.configuration.preferences.javaScriptEnabled = true
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            webView.bottomAnchor.constraint(equalTo: readFullArticleButton.topAnchor, constant: -12)
        ])
    }

    private func populateArticle() {
        titleLabel.text = article.title
        let onlineArticleUrl = article.getOnlineArticleUrl()
        webViewClient = AstroArticleWebViewClient(sourceView: webView, articleUrl: onlineArticleUrl)
        webView.navigationDelegate = webViewClient

        readFullArticleButton.isHidden = onlineArticleUrl?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false
        guard !articleHtml.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        webView.loadHTMLString(createHtmlContent(), baseURL: nil)
    }

    private func createHtmlContent() -> String {
        let isRtl = Locale.characterDirection(forLanguage: article.lang) == .rightToLeft
        let bodyTag = isRtl ? "<body dir=\"rtl\">\n" : "<body>\n"
        let bodyContent = extractBodyContent(articleHtml)
        let background = cssColor(AstroContextMenuTheme.pageBackground.currentMapThemeColor)
        let text = cssColor(AstroContextMenuTheme.primaryText.currentMapThemeColor)
        let link = cssColor(AstroContextMenuTheme.activeText.currentMapThemeColor)
        return """
        <!doctype html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
        body { margin: 0; padding: 18px; background: \(background); color: \(text); font: -apple-system-body; }
        a { color: \(link); }
        img { max-width: 100%; height: auto; }
        .main { overflow-wrap: anywhere; }
        </style>
        </head>
        \(bodyTag)
        <div class="main">
        \(bodyContent)
        </div>
        </body>
        </html>
        """
    }

    private func extractBodyContent(_ html: String) -> String {
        guard let regex = Self.bodyContentRegex else {
            return html
        }
        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        guard let match = regex.firstMatch(in: html, options: [], range: range),
              match.numberOfRanges > 1,
              let bodyRange = Range(match.range(at: 1), in: html) else {
            return html
        }
        return String(html[bodyRange])
    }

    private func cssColor(_ color: UIColor) -> String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return String(format: "rgba(%d, %d, %d, %.3f)",
                      Int(red * 255.0),
                      Int(green * 255.0),
                      Int(blue * 255.0),
                      alpha)
    }

    private func openFullArticle() {
        guard let string = article.getOnlineArticleUrl(),
              let url = URL(string: string) else {
            return
        }
        UIApplication.shared.open(url)
    }
}
