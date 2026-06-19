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
    private static let headerInner = """
    <html><head>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta http-equiv="cleartype" content="on" />
    <style>
    {{css-file-content}}
    </style>
    </head>
    """
    private static let footerInner = """
    <script>var coll = document.getElementsByTagName("H2");
    var i;
    for (i = 0; i < coll.length; i++) {
      coll[i].addEventListener("click", function() {
        this.classList.toggle("active");
        var content = this.nextElementSibling;
        if (content.style.display === "block") {
          content.style.display = "none";
        } else {
          content.style.display = "block";
        }
      });
    }
    document.addEventListener("DOMContentLoaded", function(event) {
        document.querySelectorAll('img').forEach(function(img) {
            img.onerror = function() {
                this.style.display = 'none';
                var caption = img.parentElement.nextElementSibling;
                if (caption.className == "thumbnailcaption") {
                    caption.style.display = 'none';
                }
            };
        })
    });
    function scrollAnchor(id, title) {
    openContent(title);
    window.location.hash = id;}
    function openContent(id) {
        var doc = document.getElementById(id).parentElement;
        doc.classList.toggle("active");
        var content = doc.nextElementSibling;
        content.style.display = "block";
        collapseActive(doc);
    }
    function collapseActive(doc) {
        var coll = document.getElementsByTagName("H2");
        var i;
        for (i = 0; i < coll.length; i++) {
            var item = coll[i];
            if (item != doc && item.classList.contains("active")) {
                item.classList.toggle("active");
                var content = item.nextElementSibling;
                if (content.style.display === "block") {
                    content.style.display = "none";
                }
            }
        }
    }</script>
    </body></html>
    """
    private static let bodyContentRegex = try? NSRegularExpression(pattern: "<body[^>]*>([\\s\\S]*?)</body>",
                                                                   options: [.caseInsensitive])

    private let article: AstroArticle
    private var articleHtml: String?
    private let webView = WKWebView(frame: .zero)
    private let titleLabel = UILabel()
    private let emptyStateLabel = UILabel()
    private let readFullArticleButton = UIButton(type: .system)
    private var webViewClient: AstroArticleWebViewClient?
    private var htmlLoadToken: UUID?

    init(article: AstroArticle) {
        self.article = article
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

    deinit {
        htmlLoadToken = nil
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
            if let articleHtml = articleHtml, !articleHtml.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                webView.loadHTMLString(createHtmlContent(articleHtml: articleHtml), baseURL: articleBaseURL())
            }
        }
    }

    private func applyTheme() {
        view.backgroundColor = AstroContextMenuTheme.pageBackground
        titleLabel.textColor = AstroContextMenuTheme.primaryText
        readFullArticleButton.tintColor = .white
        readFullArticleButton.backgroundColor = AstroContextMenuTheme.primaryButton
        webView.backgroundColor = AstroContextMenuTheme.pageBackground
        emptyStateLabel.textColor = AstroContextMenuTheme.secondaryText
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
        closeButton.setImage(.icCustomClose, for: .normal)
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

        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyStateLabel.text = localizedString("shared_string_unavailable")
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.font = .systemFont(ofSize: 16)
        emptyStateLabel.numberOfLines = 0
        emptyStateLabel.isHidden = true
        view.addSubview(emptyStateLabel)

        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            webView.bottomAnchor.constraint(equalTo: readFullArticleButton.topAnchor, constant: -12),

            emptyStateLabel.leadingAnchor.constraint(equalTo: webView.leadingAnchor, constant: 24),
            emptyStateLabel.trailingAnchor.constraint(equalTo: webView.trailingAnchor, constant: -24),
            emptyStateLabel.centerYAnchor.constraint(equalTo: webView.centerYAnchor)
        ])
    }

    private func populateArticle() {
        titleLabel.text = article.title
        let onlineArticleUrl = article.getOnlineArticleUrl()
        webViewClient = AstroArticleWebViewClient(sourceView: webView, articleUrl: onlineArticleUrl, presenter: self)
        webView.navigationDelegate = webViewClient

        readFullArticleButton.isHidden = onlineArticleUrl?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false
        loadArticleHtml()
    }

    private func loadArticleHtml() {
        let token = UUID()
        htmlLoadToken = token
        webView.isHidden = false
        emptyStateLabel.isHidden = true

        DispatchQueue.global(qos: .userInitiated).async { [article] in
            let html = article.getMobileHtmlString()
            DispatchQueue.main.async { [weak self] in
                guard let self = self, self.htmlLoadToken == token else {
                    return
                }
                self.htmlLoadToken = nil
                guard let html = html, !html.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    self.showEmptyState()
                    return
                }
                self.articleHtml = html
                self.webView.isHidden = false
                self.emptyStateLabel.isHidden = true
                self.webView.loadHTMLString(self.createHtmlContent(articleHtml: html), baseURL: self.articleBaseURL())
            }
        }
    }

    private func showEmptyState() {
        webView.isHidden = true
        emptyStateLabel.isHidden = false
    }

    private func createHtmlContent(articleHtml: String) -> String {
        let isRtl = Locale.characterDirection(forLanguage: article.lang) == .rightToLeft
        let bodyTag = isRtl ? "<body dir=\"rtl\">\n" : "<body>\n"
        let bodyContent = extractBodyContent(articleHtml)
        let nightModeClass = ThemeManager.shared.isLightTheme() ? "" : " nightmode"
        var header = Self.headerInner
        let css = articleStyleCss()
        header = header.replacingOccurrences(of: "{{css-file-content}}", with: css)
        return """
        \(header)
        \(bodyTag)
        <div class="main\(nightModeClass)">
        \(bodyContent)
        \(Self.footerInner)
        """
    }

    private func articleStyleCss() -> String {
        guard let cssURL = Bundle.main.url(forResource: "article_style", withExtension: "css"),
              let css = try? String(contentsOf: cssURL, encoding: .utf8) else {
            return ""
        }
        return css.replacingOccurrences(of: "\n", with: " ")
    }

    private func articleBaseURL() -> URL? {
        article.getOnlineArticleUrl().flatMap(URL.init(string:))
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

    private func openFullArticle() {
        guard let string = article.getOnlineArticleUrl(),
              let url = URL(string: string) else {
            return
        }
        UIApplication.shared.open(url)
    }
}
