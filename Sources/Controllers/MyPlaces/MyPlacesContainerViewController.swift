//
//  MyPlacesContainerViewController.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 08.05.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

@objc
protocol MyPlacesDelegate: AnyObject {
    func showBackButton(_ show: Bool)
    func setSegmentedControlVisibility(_ show: Bool)
    func setEditMode(_ edit: Bool)
}

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
        
        var title: String {
            switch self {
            case .favorites: localizedString("shared_string_favorites")
            case .tracks: localizedString("shared_string_gpx_tracks")
            case .osm: localizedString("osm_edits_title")
            case .travel: localizedString("shared_string_travel_guides")
            }
        }
    }
    
    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var segmentContainerView: UIView!
    @IBOutlet private weak var segmentControl: UISegmentedControl!
    
    private let segmentedControlIconSize: CGFloat = 24
    
    private var availableTabs: [Tab] = []
    private var availableViewControllers: [UIViewController] = []
    private var pageViewController: UIPageViewController?
    private var searchController: UISearchController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSegmentControl()
        setupTabs()
        setupSegments()
        selectInitialTab()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: false)
        setupSearchController()
        setupPageController()
        setupViewControllers()
        setupNavbar()
        segmentContainerView.backgroundColor = .viewBg
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.navigationItem.searchController = nil
    }
    
    private func setupSegmentControl() {
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
    
    private func setupPageController() {
        pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
        pageViewController?.dataSource = self
        pageViewController?.delegate = self
        let frame = CGRect(x: 0, y: 0, width: contentView.frame.size.width, height: contentView.frame.size.height)
        pageViewController?.view.frame = frame
        pageViewController?.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        if let pageViewController {
            addChild(pageViewController)
            contentView.addSubview(pageViewController.view)
            pageViewController.didMove(toParent: self)
        }
    }
    
    private func setupViewControllers() {
        guard let pageViewController else { return }
        var viewControllers: [UIViewController] = []
        
        if let favoritesViewController = OAFavoriteListViewController(frame: pageViewController.view.frame) {
            favoritesViewController.myPlacesDelegate = self
            viewControllers.append(favoritesViewController)
            pageViewController.setViewControllers([favoritesViewController], direction: .forward, animated: false)
        }
        
        let tracksViewController = TracksViewController(frame: pageViewController.view.frame)
        tracksViewController.myPlacesDelegate = self
        viewControllers.append(tracksViewController)
        
        if OAIAPHelper.sharedInstance().osmEditing.isActive() {
            let osmEditsViewController = OAOsmEditsListViewController(frame: pageViewController.view.frame)
            osmEditsViewController.myPlacesDelegate = self
            viewControllers.append(osmEditsViewController)
        }
        
        if TravelLocalDataHelper.shared.hasSavedArticles() {
            let travelGuidesViewController = SavedArticlesTabViewController(frame: pageViewController.view.frame)
            travelGuidesViewController.myPlacesDelegate = self
            viewControllers.append(travelGuidesViewController)
        }
        
        availableViewControllers = viewControllers
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
        navigationController?.navigationItem.searchController = searchController
        navigationItem.searchController = searchController
        updateSearchController()
    }
    
    private func setupNavbarTitle(with tab: Tab) {
        navigationItem.setStackViewWithTitle(tab.title,
                                             titleColor: .textColorPrimary,
                                             titleFont: .scaledSystemFont(ofSize: 17.0, weight: .semibold, maximumSize: 22.0),
                                             subtitle: localizedString("shared_string_my_places"),
                                             subtitleColor: .textColorSecondary,
                                             subtitleFont: .scaledSystemFont(ofSize: 12.0, maximumSize: 18.0))
    }
    
    private func setupNavbar() {
        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = .viewBg
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
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
        
        segmentControl.selectedSegmentIndex = Tab.favorites.rawValue
    }
    
    private func selectInitialTab() {
        guard let first = availableTabs.first else { return }
        switchTo(tab: first)
    }
    
    private func switchTo(tab: Tab) {
        guard let index = availableTabs.firstIndex(of: tab) else { return }
        pageViewController?.setViewControllers([availableViewControllers[index]], direction: .forward, animated: true)
        setupNavbarTitle(with: tab)
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

// MARK: - UIPageViewControllerDataSource
extension MyPlacesContainerViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = availableViewControllers.firstIndex(of: viewController), index > 0 else { return nil }
        return availableViewControllers[index - 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = availableViewControllers.firstIndex(of: viewController), index < availableViewControllers.count - 1 else { return nil }
        return availableViewControllers[index + 1]
    }
}

// MARK: - UIPageViewControllerDelegate
extension MyPlacesContainerViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard let viewController = pageViewController.viewControllers?.first,
              let index = availableViewControllers.firstIndex(of: viewController) else {
            return
        }
        segmentControl.selectedSegmentIndex = index
        setupNavbarTitle(with: availableTabs[index])
    }
}

// MARK: - MyPlacesDelegate
extension MyPlacesContainerViewController: MyPlacesDelegate {
    func showBackButton(_ show: Bool) {
        navigationItem.hidesBackButton = !show
    }
    
    func setSegmentedControlVisibility(_ show: Bool) {
        guard let pageViewController else { return }
        pageViewController.delegate = show ? self : nil
        pageViewController.dataSource = show ? self : nil
        segmentContainerView.isHidden = !show
    }
    
    func setEditMode(_ edit: Bool) {
        setSegmentedControlVisibility(!edit)
        let searchController = edit ? nil : searchController
        navigationController?.navigationItem.searchController = searchController
        navigationItem.searchController = searchController
    }
}
