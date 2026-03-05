//
//  OACollapsableTravelGuidesView.swift
//  OsmAnd
//
//  Created by Max Kojin on 13/02/26.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

final class OACollapsableTravelGuidesView: OACollapsableView  {
    
    private let kButtonHeight: CGFloat = 36.0

    private var articlesAllLangsMap = [String: [String: TravelArticle]]()
    private var buttons = [OAButton]()
    private var articles = [TravelArticle]()
    private var selectedButtinIndex = 0
    
    func setData(articlesMap: [String: [String: TravelArticle]]) {
        self.articlesAllLangsMap = articlesMap
        buildViews()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateButtonBorderColor()
        }
    }
    
    private func buildViews() {
        let appLang = OAUtilities.currentLang() ?? ""
        let mapLang = OAAppSettings.sharedManager().settingPrefMapLanguage.get()
        
        var i = 0
        for articleMap in articlesAllLangsMap.values {
            if let article = getArticle(articleMap: articleMap, appLang: appLang, mapLang: mapLang) {
                let btn = createButton(title: article.title ?? "")
                btn.tag = i
                i += 1
                self.addSubview(btn)
                buttons.append(btn)
                articles.append(article)
            }
        }
    }
    
    private func getArticle(articleMap: [String: TravelArticle], appLang: String, mapLang: String) -> TravelArticle? {
        var article = articleMap[appLang]
        if article == nil {
            article = articleMap[mapLang]
        }
        if article == nil {
            article = articleMap["en"]
        }
        
        return article != nil ? article : articleMap.first?.value
    }
    
    private func createButton(title: String) -> OAButton {
        let btn = OAButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.contentHorizontalAlignment = .left
        btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12.0, bottom: 0, right: 12.0)
        btn.titleLabel?.lineBreakMode = .byTruncatingTail
        btn.titleLabel?.font = .preferredFont(forTextStyle: .footnote)
        btn.layer.cornerRadius = 4.0
        btn.layer.masksToBounds = true
        btn.layer.borderWidth = 0.8
        btn.layer.borderColor = UIColor.customSeparator.cgColor
        btn.setBackgroundImage(OAUtilities.image(with: .clear), for: .normal)
        btn.tintColor = UIColor.iconColorActive
        btn.delegate = self
        return btn
    }
    
    func updateLayout(width: CGFloat) {
        var y: CGFloat = 0.0
        var viewHeight: CGFloat = 0.0
        var i = 0
        for button in buttons {
            if i > 0 {
                y += kButtonHeight + 10.0
                viewHeight += 10.0
            }
            
            let height: CGFloat = kButtonHeight
            button.frame = CGRect(x: kMarginLeft, y: y, width: width - kMarginLeft - kMarginRight, height: height)
            viewHeight += button.frame.size.height
            i += 1
        }
        
        viewHeight += 8.0
        self.frame = CGRect(x: self.frame.origin.x, y: self.frame.origin.y, width: width, height: viewHeight)
    }
    
    private func updateButtonBorderColor() {
        for button in buttons {
            button.layer.borderColor = UIColor.customSeparator.cgColor
        }
    }
    
    override func adjustHeight(forWidth width: CGFloat) {
        updateLayout(width: width)
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func copy(_ sender: Any?) {
        guard buttons.count > selectedButtinIndex else { return }
        let button = buttons[selectedButtinIndex]
        let pasteboard = UIPasteboard.general
        pasteboard.string = button.titleLabel?.text
    }
}

extension OACollapsableTravelGuidesView: OAButtonDelegate {
    
    func onButtonTapped(_ tag: Int) {
        guard articles.count > tag else { return }
        let article = articles[tag]
        let vc = TravelArticleDialogViewController(articleId: article.generateIdentifier(), lang: article.lang ?? "")
        OARootViewController.instance().navigationController?.pushViewController(vc, animated: true)
    }
    
    func onButtonLongPressed(_ tag: Int) {
        selectedButtinIndex = tag
        guard buttons.count > selectedButtinIndex else { return }
        OAUtilities.showMenu(in: self, from: buttons[selectedButtinIndex])
    }
}

