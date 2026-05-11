//
//  MyPlacesContainerViewController.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 08.05.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

final class MyPlacesContainerViewController: OACompoundViewController {
    private enum Tab: Int, CaseIterable {
        case favorites
        case tracks
        case osm
        case travel
        
        var image: UIImage {
            switch self {
            case .favorites: .icCustomFavorites
            case .tracks: .icCustomTrip
            case .osm: .icCustomOsmEdits
            case .travel: .icCustomBackpack
            }
        }
    }
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var segmentContainerView: UIView!
    @IBOutlet weak var segmentControl: UISegmentedControl!
    
    private let segmentedControlIconSize: CGFloat = 24
    
    private var availableTabs: [Tab] = []
    private var pageViewController: UIPageViewController?
    private var favoritesViewController: OAFavoriteListViewController?
    private var tracksViewController: TracksViewController?
    private var osmEditsViewController: OAOsmEditsListViewController?
    private var travelGuidesViewController: SavedArticlesTabViewController?
    private var searchController: UISearchController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTabs()
        setupSegments()
        selectInitialTab()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: false)
        setupSearchController()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    private func setupUI() {
        segmentControl.addTarget(self, action: #selector(onSegmentChanged), for: .valueChanged)
        segmentControl.selectedSegmentTintColor = .tabBgColorSelected
        segmentControl.setTitleTextAttributes([.foregroundColor: UIColor.navBarTextColorPrimary], for: .selected)
    }
    
    private func setupTabs() {
        var tabs: [Tab] = [.favorites, .tracks]
        
        if OAIAPHelper.sharedInstance().osmEditing.isActive() {
            tabs.append(.osm)
        }
        
        if TravelLocalDataHelper.shared.hasSavedArticles() {
            tabs.append(.travel)
        }
        
        availableTabs = tabs
    }
    
    private func setupSearchController() {
        searchController = UISearchController(searchResultsController: nil)
        guard let searchController else { return }
        searchController.obscuresBackgroundDuringPresentation = false
        definesPresentationContext = true
        if #available(iOS 26.0, *) {
            if !OAUtilities.isIPad() {
                navigationItem.preferredSearchBarPlacement = .stacked
            }
        }
        navigationItem.searchController = searchController
        updateSearchController()
    }
    
    private func updateSearchController() {
        searchController?.searchBar.searchTextField.placeholder = localizedString("search_activity")
    }
    
    private func setupSegments() {
        segmentControl.removeAllSegments()
        
        for (index, tab) in availableTabs.enumerated() {
            segmentControl.insertSegment(with: tab.image.resizedImage(with: segmentedControlIconSize),
                                         at: index,
                                         animated: false)
        }
        
        segmentControl.selectedSegmentIndex = 0
    }
    
    private func selectInitialTab() {
        guard let first = availableTabs.first else { return }
        switchTo(tab: first)
    }
    
    private func switchTo(tab: Tab) {
        // - TODO:
    }
    
    @objc private func onBackPressed() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func onSegmentChanged() {
        let index = segmentControl.selectedSegmentIndex
        guard availableTabs.indices.contains(index) else { return }
        
        let tab = availableTabs[index]
        switchTo(tab: tab)
    }
}
