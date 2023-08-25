//
//  TravelArticleDialogViewController.swift
//  OsmAnd Maps
//
//  Created by nnngrach on 22.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit
import WebKit

class TravelArticleDialogViewController : OABaseWebViewController, SFSafariViewControllerDelegate  {
    
    let rtlLanguages = ["ar", "dv", "he", "iw", "fa", "nqo", "ps", "sd", "ug", "ur", "yi"]
    static let EMPTY_URL = "https://upload.wikimedia.org/wikipedia/commons/thumb/d/d4//"
    let emptyUrl = "about:blank"
    
    let HEADER_INNER = """
    <html><head>\n
    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />\n
    <meta http-equiv=\"cleartype\" content=\"on\" />\n
    <style>\n
    {{css-file-content}}
    </style>\n
    </head>
    """
    
    let FOOTER_INNER = """
    <script>var coll = document.getElementsByTagName("H2");
    var i;
    for (i = 0; i < coll.length; i++) {
      coll[i].addEventListener(\"click\", function() {
        this.classList.toggle(\"active\");
        var content = this.nextElementSibling;
        if (content.style.display === \"block\") {
          content.style.display = \"none\";
        } else {
          content.style.display = \"block\";
        }
      });
    }
    document.addEventListener(\"DOMContentLoaded\", function(event) {\n
        document.querySelectorAll('img').forEach(function(img) {\n
            img.onerror = function() {\n
                this.style.display = 'none';\n
                var caption = img.parentElement.nextElementSibling;\n
                if (caption.className == \"thumbnailcaption\") {\n
                    caption.style.display = 'none';\n
                }\n
            };\n
        })\n
    });
    function scrollAnchor(id, title) {
    openContent(title);
    window.location.hash = id;}\n
    function openContent(id) {\n
        var doc = document.getElementById(id).parentElement;\n
        doc.classList.toggle(\"active\");\n
        var content = doc.nextElementSibling;\n
        content.style.display = \"block\";\n
        collapseActive(doc);
    }
    function collapseActive(doc) {
        var coll = document.getElementsByTagName(\"H2\");
        var i;
        for (i = 0; i < coll.length; i++) {
            var item = coll[i];
            if (item != doc && item.classList.contains(\"active\")) {
                item.classList.toggle(\"active\");
                var content = item.nextElementSibling;
                if (content.style.display === \"block\") {
                    content.style.display = \"none\";
                }
            }
        }
    }</script>
    </body></html>
    """
    
    var article: TravelArticle?
    var articleId: TravelArticleIdentifier?
    var selectedLang: String?
    var langs: [String]?
    var nightMode = false
    var isFirstLaunch = true
    
    var bottomView: UIView?
    var bottomStackView: UIStackView?
    var contentButton: UIButton?
    var pointsButton: UIButton?
    var bookmarkButton: UIButton?
    
    
    required init?(coder: NSCoder) {
        super.init()
    }
    
    init(article: TravelArticle, lang: String) {
        super.init()
        self.article = article
        self.selectedLang = lang
        self.isFirstLaunch = true
    }
    
    
    //MARK: Base UI
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBottomButtonsView()
        populateArticle()
    }
    
    func setupBottomButtonsView() {
        bottomView = UIView()
        bottomView!.addBlurEffect(true, cornerRadius: 0, padding: 0)
        view.addSubview(bottomView!)
        
        bottomStackView = UIStackView()
        bottomStackView!.axis = .horizontal
        bottomStackView!.alignment = .center
        bottomStackView!.distribution = .equalCentering
        bottomStackView!.spacing = 8
        bottomView!.addSubview(bottomStackView!)
        
        contentButton = UIButton()
        contentButton!.setTitle(localizedString("shared_string_contents"), for: .normal)
        contentButton!.setTitleColor(UIColor(rgb: color_primary_purple), for: .normal)
        contentButton!.titleLabel?.font = UIFont.preferredFont(forTextStyle: .footnote)
        contentButton!.setImage(UIImage.templateImageNamed("ic_action_route_first_intermediate"), for: .normal)
        contentButton!.tintColor = UIColor(rgb: color_primary_purple)
        contentButton!.contentHorizontalAlignment = .left
        contentButton!.addTarget(self, action: #selector(self.onContentsButtonClicked), for: .touchUpInside)
        bottomStackView!.addArrangedSubview(contentButton!)
        
        bottomStackView!.addArrangedSubview(UIView())
        
        pointsButton = UIButton()
        pointsButton!.setTitle(localizedString("shared_string_gpx_points"), for: .normal)
        pointsButton!.setTitleColor(UIColor(rgb: color_primary_purple), for: .normal)
        pointsButton!.titleLabel?.font = UIFont.preferredFont(forTextStyle: .footnote)
        pointsButton!.setImage(UIImage.templateImageNamed("ic_small_map_point"), for: .normal)
        pointsButton!.tintColor = UIColor(rgb: color_primary_purple)
        pointsButton!.addTarget(self, action: #selector(self.onPointsButtonClicked), for: .touchUpInside)
        bottomStackView!.addArrangedSubview(pointsButton!)
        
        bottomStackView!.addArrangedSubview(UIView())
        
        bookmarkButton = UIButton()
        bookmarkButton!.setTitle(localizedString("shared_string_bookmark"), for: .normal)
        bookmarkButton!.setTitleColor(UIColor(rgb: color_primary_purple), for: .normal)
        bookmarkButton!.titleLabel?.font = UIFont.preferredFont(forTextStyle: .footnote)
        bookmarkButton!.setImage(UIImage.templateImageNamed("ic_small_waypoints"), for: .normal)
        bookmarkButton!.tintColor = UIColor(rgb: color_primary_purple)
        contentButton!.contentHorizontalAlignment = .right
        bookmarkButton!.addTarget(self, action: #selector(self.onBookmarkButtonClicked), for: .touchUpInside)
        bottomStackView!.addArrangedSubview(bookmarkButton!)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        if (bottomView != nil && bottomStackView != nil) {
            let stackHeight = 30.0 + 16.0
            let bottomViewHeight = stackHeight + OAUtilities.getBottomMargin()
            let sideOffset = OAUtilities.getLeftMargin() + 16.0
            
            bottomView!.frame = CGRect(x: 0, y: webView.frame.height - bottomViewHeight, width: webView.frame.width, height: bottomViewHeight)
            
            bottomStackView!.frame = CGRect(x: sideOffset, y: 0, width: bottomView!.frame.width - 2 * sideOffset, height: stackHeight)
            
            // Place image on bookmarkButton after text
            bookmarkButton!.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
            bookmarkButton!.titleLabel?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        }
    }
    
    override func getRightNavbarButtons() -> [UIBarButtonItem]! {
        let languageButton = createRightNavbarButton(nil, iconName: "ic_navbar_languge", action: #selector(onLanguagesButtonClicked), menu: nil)
        let optionsButton = createRightNavbarButton(nil, iconName: "ic_navbar_overflow_menu_stroke", action: #selector(onOptionsButtonClicked), menu: nil)
        
        //TODO: add accessibilityLabels
        //optionsButton?.accessibilityLabel = "Label"
        //optionsButton?.accessibilityValue = "value"
        return [optionsButton!, languageButton!]

    }
    
    override func getTitle() -> String! {
        return article?.title ?? ""
    }
    
    override func getLeftNavbarButtonTitle() -> String! {
        return ""
    }
    
    
    //MARK: Actions
    
    @objc func onOptionsButtonClicked() {
        print("onOptionsButtonClicked")
    }
    
    @objc func onLanguagesButtonClicked() {
        print("onLanguagesButtonClicked")
    }
    
    @objc func onContentsButtonClicked() {
        print("onContentsButtonClicked")
        let vc = TravelGuidesContentsViewController(article: article!, selectedLang: selectedLang!)
        self.showModalViewController(vc)
    }
    
    @objc func onPointsButtonClicked() {
        print("onPointsButtonClicked")
    }
    
    @objc func onBookmarkButtonClicked() {
        print("onBookmarkButtonClicked")
    }
    
    @objc func showNavigation() {
        print("showNavigation")
    }
    
    
    //MARK: Data
    
    override func getContent() -> String! {
        return createHtmlContent()
    }
    
    func populateArticle() {
        if article != nil {
            articleId = article!.generateIdentifier()
            langs = TravelObfHelper.shared.getArticleLangs(articleId: articleId!)
        }
        guard (article != nil && articleId != nil && langs != nil && langs!.count > 0) else { return }
        
        if selectedLang == nil {
            selectedLang = langs![0]
        }
        
        //TODO: implement
        //TravelLocalDataHelper ldh = app.getTravelHelper().getBookmarksHelper();
        //ldh.addToHistory(article);
        
        updateSaveButton()
        
        //loadHtml()
        
    }
    
    func createHtmlContent() -> String? {
        
        var sb = HEADER_INNER
        
        if let cssFilePath = Bundle.main.path(forResource: "article_style", ofType: "css") {
            if var cssFileContent = try? String.init(contentsOfFile: cssFilePath) {
                cssFileContent = cssFileContent.replacingOccurrences(of: "\n", with: " ")
                sb = sb.replacingOccurrences(of:"{{css-file-content}}", with: cssFileContent)
            }
        }
        
        let bodyTag =  rtlLanguages.contains(article!.lang!) ? "<body dir=\"rtl\">\n" : "<body>\n"
        sb += bodyTag
        let nightModeClass = nightMode ? " nightmode" : ""
        let imageTitle = article!.imageTitle
        
        if article!.aggregatedPartOf != nil && article!.aggregatedPartOf!.count > 0 {
            let aggregatedPartOfArrayOrig = article!.aggregatedPartOf!.split(separator: ",")
            if aggregatedPartOfArrayOrig.count > 0 {
                let current = aggregatedPartOfArrayOrig[0]
                sb += "<a href=\"#showNavigation\" style=\"text-decoration: none\"> <div class=\"nav-bar" + nightModeClass + "\">"
                for i in 0..<aggregatedPartOfArrayOrig.count {
                    if i > 0 {
                        sb += "&nbsp;&nbsp;•&nbsp;&nbsp;" + aggregatedPartOfArrayOrig[i]
                    } else {
                        if String(current).length > 0 {
                            sb += "<span class=\"nav-bar-current\">" + current + "</span>"
                        }
                    }
                }
                sb += "</div> </a>"
            }
        }
        
        
        if imageTitle != nil && imageTitle!.length > 0 {
            let url = TravelArticle.getImageUrl(imageTitle: imageTitle!, thumbnail: false)
            
            //TODO: add menu for Image Downloading settings. And uncomment.
            //if OAAppSettings.sharedManager().wikivoyageShowImgs.get() != EOAWikiArticleShowConstant.off && !url.hasPrefix(TravelArticleDialogViewController.EMPTY_URL) {
                sb += "<div class=\"title-image" + nightModeClass + "\" style=\"background-image: url(" + url + ")\"></div>"
            //}
        }
        
        sb += "<div class=\"main" + nightModeClass + "\">\n"
        sb += "<h1>" +  (article!.title ?? "")  + "</h1>"
        sb += article!.content ?? ""
        sb += FOOTER_INNER
        
        printHtmlToDebugFileIfEnabled(sb)
        
        return sb
    }
    
    func printHtmlToDebugFileIfEnabled(_ content: String) {
        let developmentPlugin = OAPlugin.getPlugin(OAOsmandDevelopmentPlugin.self) as? OAOsmandDevelopmentPlugin
        if (developmentPlugin != nil && developmentPlugin!.isEnabled()) {
            let filepath = OsmAndApp.swiftInstance().documentsPath + "/TravelGuidesDebug.html"
            do {
                try content.write(toFile: filepath, atomically: true, encoding: String.Encoding.utf8)
            } catch {
            }
        }
    }
    
 
    
    func updateSaveButton() {
        //TODO implement
    }
    
    func updateTrackButton() {
        //TODO implement
    }
    
    override func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let a = navigationAction.request.url?.absoluteString
        let newUrl = OATravelGuidesHelper.normalizeFileUrl(navigationAction.request.url?.absoluteString) ?? ""
        var currentUrl = OATravelGuidesHelper.normalizeFileUrl(webView.url?.absoluteString) ?? ""
        let wikiUrlEndIndndex = Int(currentUrl.index(of: "#"))
        if wikiUrlEndIndndex > 0 {
            currentUrl = currentUrl.substring(to: wikiUrlEndIndndex)
        }
        
        if isFirstLaunch {
            isFirstLaunch = false
            decisionHandler(.allow)
            
        } else {
            
            if newUrl.hasPrefix(currentUrl) {
                
                if newUrl.hasSuffix("showNavigation") {
                    //Clicked on Breadcrumbs navigation pannel
                    showNavigation()
                    decisionHandler(.cancel)
                } else {
                    //Navigation inside one page by anchors
                    decisionHandler(.allow)
                }
                
            } else {
                
                //TODO: implement new urls opening
                decisionHandler(.cancel)
            }
        }
        
    }
    
}
