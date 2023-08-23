//
//  TravelArticleDialogViewController.swift
//  OsmAnd Maps
//
//  Created by nnngrach on 22.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit

class TravelArticleDialogViewController : OABaseWebViewController, SFSafariViewControllerDelegate {
    
    var articleId: TravelArticleIdentifier?
    var lang: String?
    var langs: [String]?
    var article: TravelArticle?
    
    var bottomView: UIView?
    var bottomStackView: UIStackView?
    var contentButton: UIButton?
    var pointsButton: UIButton?
    var bookmarkButton: UIButton?
    
    
    required init?(coder: NSCoder) {
        super.init()
    }
    
    init(articleId: TravelArticleIdentifier, lang: String) {
        super.init()
        self.articleId = articleId
        self.lang = lang
        self.langs = TravelObfHelper.shared.getArticleLangs(articleId: articleId)
    }
    
    init(article: TravelArticle, lang: String) {
        super.init()
        self.article = article
        self.lang = lang
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBottomButtonsView()
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
        contentButton!.titleLabel?.font = UIFont.preferredFont(forTextStyle: .footnote)
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
    
    @objc func onOptionsButtonClicked() {
        print("onOptionsButtonClicked")
    }
    
    @objc func onLanguagesButtonClicked() {
        print("onLanguagesButtonClicked")
    }
    
    @objc func onContentsButtonClicked() {
        print("onContentsButtonClicked")
    }
    
    @objc func onPointsButtonClicked() {
        print("onPointsButtonClicked")
    }
    
    @objc func onBookmarkButtonClicked() {
        print("onBookmarkButtonClicked")
    }
    
    override func getContent() -> String! {
        return createHtmlContent()
    }
    
    func createHtmlContent() -> String? {
        if article != nil {
            return article!.content
        }
        return ""
    }
    
}
