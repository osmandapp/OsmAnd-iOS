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
    func openArticle(article: TravelArticle, lang: String) 
}


@objc(OATravelExploreViewController)
@objcMembers
class TravelExploreViewController: OABaseNavbarViewController, TravelExploreViewControllerDelegate {
    
    var tabBarVC: UITabBarController?
    var exploreVC: ExploreTabViewController?
    var savedArticlesVC: SavedArticlesTabViewController?
    var spinner = UIActivityIndicatorView(style: .whiteLarge)

    override func viewDidLoad() {
        super.viewDidLoad()

        tabBarVC = UITabBarController()
        tabBarVC?.tabBar.tintColor = UIColor(rgb: color_primary_purple)

        exploreVC = ExploreTabViewController()
        exploreVC!.tabBarItem = UITabBarItem.init(title: localizedString("shared_string_explore"), image: UIImage.templateImageNamed("ic_custom_map_location_follow"), tag: 0)
        exploreVC!.tabViewDelegate = self

        savedArticlesVC = SavedArticlesTabViewController()
        savedArticlesVC!.tabBarItem = UITabBarItem.init(title: localizedString("saved_articles"), image: UIImage.templateImageNamed("ic_custom_save_to_file"), tag: 1)
        
        tabBarVC!.viewControllers = [exploreVC!, savedArticlesVC!]
        self.view.addSubview(tabBarVC!.view)
        
        populateData(resetData: true)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if tabBarVC != nil {
            tabBarVC!.view.frame = CGRect(
                x: self.tableView.frame.origin.x,
                y: self.getNavbarHeight(),
                width: self.tableView.frame.size.width,
                height: self.tableView.frame.size.height - self.getNavbarHeight())
        }
    }
    
    func updateTabs() {
        exploreVC?.update()
        savedArticlesVC?.update()
    }
    
    
    //MARK: Data
    
    override func getTitle() -> String! {
        localizedString("shared_string_travel_guides")
    }
    
    override func getRightNavbarButtons() -> [UIBarButtonItem]! {
        let button = createRightNavbarButton(localizedString("shared_string_options"), iconName: nil, action: #selector(onOptionsButtonClicked), menu: nil)
        button?.accessibilityLabel = localizedString("shared_string_options")
        return [button!]
    }
    
    func populateData(resetData: Bool) {
        self.view.addSpinner()
        let task = LoadWikivoyageDataAsyncTask(resetData: resetData)
        task.delegate = self;
        task.execute()
    }
    
    
    //MARK: Actions
    
    func onOptionsButtonClicked() {
        print("onOptionsButtonClicked")
    }
    
    func openArticle(article: TravelArticle, lang: String) {
        let vc = TravelArticleDialogViewController.init(article: article, lang: lang)
        //self.showModalViewController(vc)
        self.show(vc)
    }
    
    	
    //MARK: TravelExploreViewControllerDelegate
    
    func onDataLoaded() {
        updateTabs()
        self.view.removeSpinner()
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
