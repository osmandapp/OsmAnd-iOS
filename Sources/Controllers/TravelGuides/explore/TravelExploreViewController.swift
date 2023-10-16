//
//  TravelExploreViewController.swift
//  OsmAnd Maps
//
//  Created by nnngrach on 24.07.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

protocol TravelExploreViewControllerDelegate : AnyObject {
    func populateData(resetData: Bool)
    func onDataLoaded()
    func openArticle(article: TravelArticle, lang: String?)
    func onOpenArticlePoints()

    func close()
}


@objc(OATravelExploreViewController)
@objcMembers
class TravelExploreViewController: OABaseNavbarViewController, TravelExploreViewControllerDelegate, GpxReadDelegate {

    var tabBarVC: UITabBarController?
    var exploreVC: ExploreTabViewController?
    var savedArticlesVC: SavedArticlesTabViewController?
    
    var searchView: UIView?
    var searchTextField: UITextField?
    var searchTransparentButton: UIButton?
    
    var isGpxReading = false

    override func viewDidLoad() {
        super.viewDidLoad()

        tabBarVC = UITabBarController()
        tabBarVC?.tabBar.tintColor = UIColor(rgb: color_primary_purple)

        exploreVC = ExploreTabViewController()
        exploreVC!.tabBarItem = UITabBarItem.init(title: localizedString("shared_string_explore"), image: UIImage.templateImageNamed("ic_custom_map_location_follow"), tag: 0)
        exploreVC!.tabViewDelegate = self

        savedArticlesVC = SavedArticlesTabViewController()
        savedArticlesVC!.tabBarItem = UITabBarItem.init(title: localizedString("saved_articles"), image: UIImage.templateImageNamed("ic_custom_save_to_file"), tag: 1)
        savedArticlesVC!.tabViewDelegate = self
        
        tabBarVC!.viewControllers = [exploreVC!, savedArticlesVC!]
        self.view.addSubview(tabBarVC!.view)
        
        if shouldShowSearch() {
            setupSearchView()
        }
        
        if OAAppSettings.sharedManager().travelGuidesState.wasWatchingGpx {
            restoreState()
        } else {
            populateData(resetData: true)
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        tabBarVC?.view.frame = CGRect(
            x: self.tableView.frame.origin.x,
            y: self.getNavbarHeight(),
            width: self.tableView.frame.size.width,
            height: self.tableView.frame.size.height - self.getNavbarHeight())
        
        let offset: CGFloat = OAUtilities.isLandscape() ? 0 : 8
        let navbarHeight = navigationController!.navigationBar.frame.height + OAUtilities.getTopMargin()
        searchView?.frame = CGRect(x: 0, y: navbarHeight, width: view.frame.width, height: 46 + offset)
        searchTextField?.frame = CGRect(x: 8 + OAUtilities.getLeftMargin(), y: offset, width: searchView!.frame.width - 16 - 2 * OAUtilities.getLeftMargin(), height: 38)
        searchTransparentButton?.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 46 + offset)
    }
    
    func updateTabs() {
        exploreVC?.update()
        savedArticlesVC?.update()
    }
    
    func shouldShowSearch() -> Bool {
        return !TravelObfHelper.shared.isOnlyDefaultTravelBookPresent()
    }
    
    func setupSearchView() {
        let offset: CGFloat = OAUtilities.isLandscape() ? 0 : 8
        let navbarHeight = navigationController!.navigationBar.frame.height + OAUtilities.getTopMargin()
        searchView = UIView()
        searchView?.backgroundColor = UIColor(rgb: color_primary_table_background)
        searchView?.frame = CGRect(x: 0, y: navbarHeight, width: view.frame.width, height: 46 + offset)
        view.addSubview(searchView!)
        
        searchTextField = OATextFieldWithPadding()
        searchTextField?.frame = CGRect(x: 8 + OAUtilities.getLeftMargin(), y: offset, width: searchView!.frame.width - 16 - 2 * OAUtilities.getLeftMargin(), height: 38)
        searchTextField?.layer.cornerRadius = 8
        searchTextField?.backgroundColor = .white
        searchTextField?.placeholder = localizedString("shared_string_search")
        searchTextField?.isUserInteractionEnabled = false
        searchView?.addSubview(searchTextField!)
        
        searchTransparentButton = UIButton()
        searchTransparentButton?.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 46 + offset)
        searchTransparentButton?.backgroundColor = .clear
        searchTransparentButton?.addTarget(self, action: #selector(onSearchViewClicked), for: .touchUpInside)
        searchView?.addSubview(searchTransparentButton!)
    }
    
    
    //MARK: Data
    
    override func getTitle() -> String! {
        localizedString("shared_string_travel_guides")
    }
    
    override func getLeftNavbarButtonTitle() -> String! {
        return localizedString("shared_string_back")
    }
    
    override func forceShowShevron() -> Bool {
        return true
    }
    
    override func getRightNavbarButtons() -> [UIBarButtonItem]! {
        let optionsButton = createRightNavbarButton(nil, iconName: "ic_navbar_overflow_menu_stroke", action: #selector(onOptionsButtonClicked), menu: nil)
        optionsButton?.accessibilityLabel = localizedString("shared_string_options")
        return [optionsButton!]
    }
    
    func populateData(resetData: Bool) {
        self.view.addSpinner()
        let task = LoadWikivoyageDataAsyncTask(resetData: resetData)
        task.delegate = self;
        task.execute()
    }
    
    func saveState() {
        if tabBarVC != nil {
            OAAppSettings.sharedManager().travelGuidesState.mainMenuSelectedTab = tabBarVC!.selectedIndex
        }
        if let exploreVC {
            exploreVC.saveState()
        }
    }
    
    func restoreState() {
        if let tabBarVC {
            tabBarVC.selectedIndex = OAAppSettings.sharedManager().travelGuidesState.mainMenuSelectedTab
        }
        if let exploreVC {
            exploreVC.restoreState()
        }
        
        let wasOpenedTravelGpx = OAAppSettings.sharedManager().travelGuidesState.article == nil
        if wasOpenedTravelGpx  {
            OAAppSettings.sharedManager().travelGuidesState.resetData()
        } else {
            let vc = TravelArticleDialogViewController.init()
            vc.delegate = self
            self.show(vc)
        }
    }
    
    
    //MARK: Actions
    
    func onOptionsButtonClicked() {
        print("onOptionsButtonClicked")
    }
    
    func openArticle(article: TravelArticle, lang: String?) {
        if article is TravelGpx {
            self.view.addSpinner()
            openGpx(gpx: article as! TravelGpx)
        } else {
            let vc = TravelArticleDialogViewController.init(articleId: article.generateIdentifier(), lang: lang!)
            vc.delegate = self
            self.show(vc)
        }
    }
    
    func openGpx(gpx: TravelGpx) {
        TravelObfHelper.shared.getArticleById(articleId: gpx.generateIdentifier(), lang: nil, readGpx: true, callback: self)
    }
    
    @objc func onSearchViewClicked() {
        var vc = TravelSearchDialogViewController()
        vc.tabViewDelegate = self
        vc.lang = OAUtilities.currentLang()
        self.show(vc)
    }
    
    	
    //MARK: TravelExploreViewControllerDelegate
    
    func onDataLoaded() {
        updateTabs()
        self.view.removeSpinner()
    }
    
    func close() {
        self.dismiss()
    }
    
    func onOpenArticlePoints() {
        saveState()
    }
    
    
    //MARK: GpxReadDelegate
    
    func onGpxFileReading() {
    }
    
    func onGpxFileRead(gpxFile: OAGPXDocumentAdapter?, article: TravelArticle) {
        //Open TravelGpx track
        article.gpxFile = gpxFile
        let filename = TravelObfHelper.shared.createGpxFile(article: article)
        OATravelGuidesHelper.createGpxFile(article, fileName: filename)
        let gpx = OATravelGuidesHelper.buildGpx(filename, title: article.title, document: gpxFile)
        
        saveState()
        OAAppSettings.sharedManager().travelGuidesState.wasWatchingGpx = true
        
        OAAppSettings.sharedManager().showGpx([filename], update: true)
        OARootViewController.instance().mapPanel.openTargetView(with: gpx, selectedTab: .overviewTab, selectedStatisticsTab: .overviewTab, openedFromMap: false)
        self.dismiss()
    }

}


class LoadWikivoyageDataAsyncTask {
    weak var delegate: TravelExploreViewControllerDelegate?
    var travelHelper: TravelObfHelper
    var resetData: Bool
    
    init (resetData: Bool) {
        travelHelper = TravelObfHelper.shared;
        self.resetData = resetData
    }
    
    func execute() {
        DispatchQueue.global(qos: .default).async {
            self.doInBackground()
            DispatchQueue.main.async {
                self.onPostExecute()
            }
        }
    }
    
    func doInBackground() {
        travelHelper.initializeDataToDisplay(resetData: resetData)
    }
    
    func onPostExecute() {
        if delegate != nil {
            delegate!.onDataLoaded()
        }
    }
}
