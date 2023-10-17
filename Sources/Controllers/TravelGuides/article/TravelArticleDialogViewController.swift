//
//  TravelArticleDialogViewController.swift
//  OsmAnd Maps
//
//  Created by nnngrach on 22.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit
import WebKit
import JavaScriptCore

protocol TravelArticleDialogProtocol : AnyObject {
    func getWebView() -> WKWebView
    func moveToAnchor(link: String, title: String)
    func openArticleByTitle(title: String, selectedLang: String)
    func openArticleById(articleId: TravelArticleIdentifier, selectedLang: String)
}


class TravelArticleDialogViewController : OABaseWebViewController, TravelArticleDialogProtocol, OAWikiLanguagesWebDelegate, GpxReadDelegate, SFSafariViewControllerDelegate {
    
    let rtlLanguages = ["ar", "dv", "he", "iw", "fa", "nqo", "ps", "sd", "ug", "ur", "yi"]
    static let EMPTY_URL = "https://upload.wikimedia.org/wikipedia/commons/thumb/d/d4//"
    let PREFIX_GEO = "geo:"
    let PAGE_PREFIX_HTTP = "http://"
    let PAGE_PREFIX_HTTPS = "https://"
    let WIKIVOYAGE_DOMAIN = ".wikivoyage.org/wiki/"
    let WIKI_DOMAIN = ".wikipedia.org/wiki/"
    let PAGE_PREFIX_FILE = "file://"
    let blankUrl = "about:blank"
    
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
    
    var delegate: TravelExploreViewControllerDelegate?
    
    var article: TravelArticle?
    var articleId: TravelArticleIdentifier?
    var selectedLang: String?
    var langs: [String]?
    var nightMode = false
    
    var historyArticleIds: [TravelArticleIdentifier] = []
    var historyLangs: [String] = []
    
    var gpxFile: OAGPXDocumentAdapter?
    var gpx: OAGPX?
    var isGpxReading = false
    
    var bottomView: UIView?
    var bottomStackView: UIStackView?
    var contentButton: UIButton?
    var pointsButton: UIButton?
    var bookmarkButton: UIButton?
    
    var contentItems: TravelContentItem? = nil
    
    
    required init?(coder: NSCoder) {
        super.init()
    }
    
    override init() {
        super.init()
    }
    
    init(articleId: TravelArticleIdentifier, lang: String) {
        super.init()
        self.articleId = articleId
        self.selectedLang = lang
    }

    
    //MARK: Base UI
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBottomButtonsView()
        if OAAppSettings.sharedManager().travelGuidesState.wasWatchingGpx {
            restoreState()
        } else {
            populateArticle()
        }
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
        contentButton!.setImage(UIImage.templateImageNamed("ic_custom_list"), for: .normal)
        contentButton!.tintColor = UIColor(rgb: color_primary_purple)
        contentButton!.contentHorizontalAlignment = .left
        contentButton!.addTarget(self, action: #selector(self.onContentsButtonClicked), for: .touchUpInside)
        bottomStackView!.addArrangedSubview(contentButton!)
        
        bottomStackView!.addArrangedSubview(UIView())
        
        pointsButton = UIButton()
        pointsButton!.setTitle(localizedString("shared_string_gpx_points"), for: .normal)
        pointsButton!.setTitleColor(UIColor(rgb: color_primary_purple), for: .normal)
        pointsButton!.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        pointsButton!.addTarget(self, action: #selector(self.onPointsButtonClicked), for: .touchUpInside)
        bottomStackView!.addArrangedSubview(pointsButton!)
        
        bottomStackView!.addArrangedSubview(UIView())
        
        bookmarkButton = UIButton()
        bookmarkButton!.setImage(UIImage.templateImageNamed("ic_navbar_bookmark_outlined"), for: .normal)
        bookmarkButton!.tintColor = UIColor(rgb: color_primary_purple)
        contentButton!.contentHorizontalAlignment = .right
        bookmarkButton!.addTarget(self, action: #selector(self.onBookmarkButtonClicked), for: .touchUpInside)
        bottomStackView!.addArrangedSubview(bookmarkButton!)
        updateBookmarkButton()
    }
    
    func updateBookmarkButton() {
        if let article {
            let isSaved = TravelObfHelper.shared.getBookmarksHelper().isArticleSaved(article: article)
            let iconName = isSaved ? "ic_navbar_bookmark" : "ic_navbar_bookmark_outlined"
            bookmarkButton!.setImage(UIImage.templateImageNamed(iconName), for: .normal)
        }
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
        let menu = OAWikiArticleHelper.createLanguagesMenu(langs, selectedLocale: selectedLang, delegate: self)
        let languageButton = createRightNavbarButton(nil, iconName: "ic_navbar_languge", action: #selector(onLanguagesButtonClicked), menu: menu)
        
        let optionsButton = createRightNavbarButton(nil, iconName: "ic_navbar_overflow_menu_stroke", action: #selector(onOptionsButtonClicked), menu: nil)
        
        //TODO: add accessibilityLabels
        //optionsButton?.accessibilityLabel = "Label"
        //optionsButton?.accessibilityValue = "value"
        return [optionsButton!, languageButton!]
    }
    
    override func getTitle() -> String! {
        return article?.title ?? ""
    }
    
    override func getNavbarStyle() -> EOABaseNavbarStyle {
        .customLargeTitle
    }
    
    override func getLeftNavbarButtonTitle() -> String! {
        return localizedString("shared_string_back")
    }
    
    override func forceShowShevron() -> Bool {
        return true
    }

    
    //MARK: Actions
    
    @objc func onOptionsButtonClicked() {
        print("onOptionsButtonClicked")
    }
    
    @objc func onLanguagesButtonClicked() {
        if langs == nil || langs!.count <= 1 {
            OARootViewController.showInfoAlert(withTitle: nil, message: localizedString("no_other_translations"), in: self)
        }
    }
    
    @objc func showNavigation() {
//        let vc = TravelGuidesNavigationViewController(article: article!, selectedLang: selectedLang!)
        let vc = TravelGuidesNavigationViewController()
        vc.setupWith(article: article!, selectedLang: selectedLang!, navigationMap: [:], regionsNames: [], selectedItem: nil)
        vc.delegate = self
        self.showModalViewController(vc)
    }
    
    @objc func onContentsButtonClicked() {
        if contentItems == nil {
            contentItems = TravelJsonParser.parseJsonContents(jsonText: article!.contentsJson ?? "")
        }
        if let contentItems {
            let vc = TravelGuidesContentsViewController()
            vc.setupWith(article: article!, selectedLang: selectedLang!, contentItems: contentItems, selectedSubitemIndex: nil)
            vc.delegate = self
            self.showModalViewController(vc)
        }
    }
        
    @objc func onPointsButtonClicked() {
        if article == nil {
            return
        }
        
        //TODO: Add article to history here?
        
        let file = TravelObfHelper.shared.createGpxFile(article: article!)
        if gpx == nil {
            gpx = OATravelGuidesHelper.buildGpx(file, title: article!.title, document: article!.gpxFile)
        }
        
        saveState()
        delegate?.onOpenArticlePoints()
        OAAppSettings.sharedManager().travelGuidesState.wasWatchingGpx = true
        
        OAAppSettings.sharedManager().showGpx([file], update: true)
        OARootViewController.instance().mapPanel.openTargetView(with: gpx, selectedTab: .pointsTab, selectedStatisticsTab: .overviewTab, openedFromMap: false)
        
        delegate?.close()
        self.dismiss()
    }
    
    @objc func onBookmarkButtonClicked() {
        let isSaved = TravelObfHelper.shared.getBookmarksHelper().isArticleSaved(article: article!)
        TravelObfHelper.shared.saveOrRemoveArticle(article: article!, save: !isSaved)
        updateBookmarkButton()
        
        let articleName = article!.title ?? localizedString("shared_string_article")
        let message = isSaved ? localizedString("article_removed_from_bookmark") : localizedString("article_added_to_bookmark")
        OAUtilities.showToast(nil, details: articleName + message , duration: 4, in: self.view)
    }
    
    override func dismiss() {
        if historyArticleIds.count > 0 {
            self.articleId = historyArticleIds.popLast()
            self.selectedLang = historyLangs.popLast()
            populateArticle()
        } else {
            super.dismiss()
        }
    }
    
    override func onLeftNavbarButtonLongtapPressed() {
        super.dismiss()
    }
    
    
    //MARK: Data
    
    func saveState() {
        if let state = OAAppSettings.sharedManager().travelGuidesState {
            state.article = article
            state.articleId = articleId
            state.selectedLang = selectedLang
            state.langs = langs
            state.nightMode = nightMode
            state.historyArticleIds = historyArticleIds
            state.historyLangs = historyLangs
            state.gpxFile = gpxFile
            state.gpx = gpx
        }
    }
    
    func restoreState() {
        if let state = OAAppSettings.sharedManager().travelGuidesState {
            article = state.article
            articleId = state.articleId
            selectedLang = state.selectedLang
            langs = state.langs
            nightMode = state.nightMode
            historyArticleIds = state.historyArticleIds
            historyLangs = state.historyLangs
            gpxFile = state.gpxFile
            gpx = state.gpx
            
            title = getTitle()
            self.updateNavbar()
            self.applyLocalization()
            self.updateSaveButton()
            self.updateTrackButton(processing: false, gpxFile: state.gpxFile)
            self.loadWebView()
        }
        OAAppSettings.sharedManager().travelGuidesState.resetData()
    }
    
    override func getContent() -> String! {
        return createHtmlContent()
    }
    
    func populateArticle() {
        article = nil
        if articleId == nil {
            return
        }
        langs = TravelObfHelper.shared.getArticleLangs(articleId: articleId!)
        if (selectedLang == nil && langs != nil && langs!.count > 0) {
            selectedLang = langs![0]
        }
        
        article = TravelObfHelper.shared.getArticleById(articleId: articleId!, lang: selectedLang, readGpx: true, callback: self)
        
        if article == nil {
            return
        }
        
        title = getTitle()
        TravelObfHelper.shared.getBookmarksHelper().addToHistory(article: article!)
        
        UIView.transition(with: self.view, duration: 0.2) {
            self.updateNavbar()
            self.applyLocalization()
            self.updateSaveButton()
            self.updateBookmarkButton()
            self.loadWebView()
        }
        
    }
    
    func createHtmlContent() -> String? {
        
        guard article != nil else { return "" }
        
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
            let filepath = OsmAndApp.swiftInstance().travelGuidesPath + "/TravelGuidesDebug.html"
            do {
                if !FileManager.default.fileExists(atPath: OsmAndApp.swiftInstance().travelGuidesPath) {
                    try FileManager.default.createDirectory(atPath: OsmAndApp.swiftInstance().travelGuidesPath, withIntermediateDirectories: true)
                }
                try content.write(toFile: filepath, atomically: true, encoding: String.Encoding.utf8)
            } catch {
            }
        }
    }
    
 
    
    func updateSaveButton() {
        //TODO implement
    }
    
    func updateTrackButton(processing: Bool, gpxFile:  OAGPXDocumentAdapter?) {
        DispatchQueue.main.async {
            if (processing)
            {
                self.bottomStackView!.addSpinner(inCenterOfCurrentView: true)
                self.pointsButton!.setTitle("", for: .normal)
                self.pointsButton!.setImage(nil, for: .normal)
                self.pointsButton!.isEnabled = false
            }
            else
            {
                if gpxFile != nil && gpxFile!.pointsCount() > 0 {
                    let title = localizedString("shared_string_gpx_points") + ": " + String(gpxFile!.pointsCount())
                    self.pointsButton!.setTitle(title , for: .normal)
                    self.pointsButton!.isEnabled = true
                } else {
                    self.pointsButton!.setTitle("", for: .normal)
                    self.pointsButton!.isEnabled = false
                }
                self.bottomStackView!.removeSpinner()
            }
        }
    }
    
    override func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        let newUrl = OATravelGuidesHelper.normalizeFileUrl(navigationAction.request.url?.absoluteString) ?? ""
        let isWebPage = newUrl.hasPrefix(PAGE_PREFIX_HTTP) || newUrl.hasPrefix(PAGE_PREFIX_HTTPS)
        
        if newUrl.hasSuffix("showNavigation") {
            //Clicked on Breadcrumbs navigation pannel
            showNavigation()
            decisionHandler(.cancel)
        } else if newUrl == blankUrl {
            //On open new TravelGuides page via code
            decisionHandler(.allow)
        } else if newUrl.contains(WIKIVOYAGE_DOMAIN) && isWebPage {
            TravelGuidesUtils.processWikivoyageDomain(url: newUrl, delegate: self)
            decisionHandler(.cancel)
        } else if newUrl.contains(WIKI_DOMAIN) && isWebPage && article != nil {
            self.webView.addSpinner()
            let defaultCoordinates = CLLocation(latitude: article!.lat, longitude: article!.lon)
            TravelGuidesUtils.processWikipediaDomain(defaultLocation: defaultCoordinates, url: newUrl, delegate: self)
            decisionHandler(.cancel)
        } else if isWebPage {
            OAWikiArticleHelper.warnAboutExternalLoad(newUrl, sourceView: self.webView)
            decisionHandler(.cancel)
        } else if newUrl.hasPrefix(PREFIX_GEO) {

            //TODO: implement
            decisionHandler(.cancel)

        } else {
            decisionHandler(.allow)
        }
    }
    
    
    //MARK: TravelArticleDialogProtocol
    
    func getWebView() -> WKWebView {
        return webView
    }
    
    func moveToAnchor(link: String, title: String) {
        webView.evaluateJavaScript("scrollAnchor(\"" + link + "\", \"" + title + "\")")
        webView.load(URLRequest(url: URL(string: link)!))
    }
    
    func openArticleByTitle(title: String, selectedLang: String) {
        historyArticleIds.append(self.articleId!)
        historyLangs.append(self.selectedLang!)
        self.articleId = TravelObfHelper.shared.getArticleId(title: title, lang: selectedLang)
        self.selectedLang = selectedLang
        populateArticle()
    }
    
    func openArticleById(articleId: TravelArticleIdentifier, selectedLang: String) {
        historyArticleIds.append(self.articleId!)
        historyLangs.append(self.selectedLang!)
        self.articleId = articleId
        self.selectedLang = selectedLang
        populateArticle()
    }
    
    
    //MARK: OAWikiLanguagesWebDelegate
    
    func onLocaleSelected(_ locale: String!) {
        historyArticleIds.append(self.articleId!)
        historyLangs.append(self.selectedLang!)
        self.selectedLang = locale
        populateArticle()
    }
    
    func showLocalesVC(_ vc: UIViewController!) {
        showModalViewController(vc)
    }
    
    
    //MARK: GpxReadDelegate
    
    func onGpxFileReading() {
        updateTrackButton(processing: true, gpxFile: nil)
    }
    
    func onGpxFileRead(gpxFile: OAGPXDocumentAdapter?, article: TravelArticle) {
        self.gpxFile = gpxFile
        updateTrackButton(processing: false, gpxFile: gpxFile)
    }
}
