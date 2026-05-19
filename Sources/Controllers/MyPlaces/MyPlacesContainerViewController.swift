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
    func updateSegmentedControlVisibility(_ isVisible: Bool)
    func updateEditMode(_ edit: Bool)
}

final class MyPlacesContainerViewController: OACompoundViewController {
    enum Tab: Int, CaseIterable {
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
        
        var controllerType: AnyClass {
            switch self {
            case .favorites: OAFavoriteListViewController.self
            case .tracks: TracksViewController.self
            case .osm: OAOsmEditsListViewController.self
            case .travel: SavedArticlesTabViewController.self
            }
        }
        
        static var `default`: Tab {
            .favorites
        }
    }
    
    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var segmentContainerView: UIView!
    @IBOutlet private weak var segmentControl: UISegmentedControl!
    
    var selectedTab: Tab = .default
    var availableTabs: [Tab] = []
    
    private let segmentedControlIconSize: CGFloat = 24
    private var availableViewControllers: [Tab: UIViewController] = [:]
    private var pageViewController: UIPageViewController?
    private var searchController: UISearchController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSegmentControl()
        setupTabs()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: false)
        setupSearchController()
        setupPageController()
        setupSegments()
        initialSelectedTab()
        setupNavbar()
        segmentContainerView.backgroundColor = .viewBg
        pageViewController?.scrollView?.backgroundColor = .viewBg
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.navigationItem.searchController = nil
    }
    
    func switchToWithSegmentControl(tab: Tab) {
        switchTo(tab: tab)
        segmentControl.selectedSegmentIndex = availableTabs.firstIndex(of: tab) ?? Tab.default.rawValue
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
        if let pageViewController {
            addChild(pageViewController)
            contentView.addSubview(pageViewController.view)
            pageViewController.didMove(toParent: self)
            pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                contentView.topAnchor.constraint(equalTo: pageViewController.view.topAnchor),
                contentView.leadingAnchor.constraint(equalTo: pageViewController.view.leadingAnchor),
                contentView.trailingAnchor.constraint(equalTo: pageViewController.view.trailingAnchor),
                contentView.bottomAnchor.constraint(equalTo: pageViewController.view.bottomAnchor)
            ])
        }
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
            guard let image = tab.image.resizedTemplateImage(with: segmentedControlIconSize) else {
                continue
            }
            segmentControl.insertSegment(with: image, at: index, animated: false)
        }
    }
    
    private func switchTo(tab: Tab) {
        let index = availableTabs.firstIndex(of: tab) ?? Tab.default.rawValue
        let tab = availableTabs[index]
        selectedTab = tab
        if let viewController = viewController(for: tab) {
            pageViewController?.setViewControllers([viewController], direction: .forward, animated: true)
        }
        setupNavbarTitle(with: tab)
    }
    
    private func initialSelectedTab() {
        switchToWithSegmentControl(tab: selectedTab)
    }
    
    private func viewController(for tab: Tab) -> UIViewController? {
        guard let pageViewController else { return nil }
        switch tab {
        case .favorites:
            if !availableViewControllers.contains(where: { $0.key == .favorites }),
               let favoritesViewController = OAFavoriteListViewController(frame: pageViewController.view.frame) {
                favoritesViewController.myPlacesDelegate = self
                availableViewControllers[tab] = favoritesViewController
            }
        case .tracks:
            if !availableViewControllers.contains(where: { $0.key == .tracks }) {
                let tracksViewController = TracksViewController(frame: pageViewController.view.frame)
                tracksViewController.myPlacesDelegate = self
                availableViewControllers[tab] = tracksViewController
            }
        case .osm:
            if !availableViewControllers.contains(where: { $0.key == .osm }) {
                let osmEditsViewController = OAOsmEditsListViewController(frame: pageViewController.view.frame)
                osmEditsViewController.myPlacesDelegate = self
                availableViewControllers[tab] = osmEditsViewController
            }
        case .travel:
            if !availableViewControllers.contains(where: { $0.key == .travel }) {
                let travelGuidesViewController = SavedArticlesTabViewController(frame: pageViewController.view.frame)
                travelGuidesViewController.myPlacesDelegate = self
                availableViewControllers[tab] = travelGuidesViewController
            }
        }
        return availableViewControllers[tab]
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
        guard let index = availableTabs.firstIndex(where: { viewController.isKind(of: $0.controllerType) }), index > 0 else { return nil }
        return self.viewController(for: availableTabs[index - 1])
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = availableTabs.firstIndex(where: { viewController.isKind(of: $0.controllerType) }), index < availableTabs.count - 1 else { return nil }
        return self.viewController(for: availableTabs[index + 1])
    }
}

// MARK: - UIPageViewControllerDelegate
extension MyPlacesContainerViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard let viewController = pageViewController.viewControllers?.first,
              let index = availableTabs.firstIndex(where: { viewController.isKind(of: $0.controllerType) }) else {
            return
        }
        let tab = availableTabs[index]
        segmentControl.selectedSegmentIndex = index
        setupNavbarTitle(with: tab)
        selectedTab = tab
    }
}

// MARK: - MyPlacesDelegate
extension MyPlacesContainerViewController: MyPlacesDelegate {
    func showBackButton(_ show: Bool) {
        navigationItem.hidesBackButton = !show
    }
    
    func updateSegmentedControlVisibility(_ isVisible: Bool) {
        guard let pageViewController else { return }
        pageViewController.delegate = isVisible ? self : nil
        pageViewController.dataSource = isVisible ? self : nil
        segmentContainerView.isHidden = !isVisible
    }
    
    func updateEditMode(_ edit: Bool) {
        updateSegmentedControlVisibility(!edit)
        let searchController = edit ? nil : searchController
        navigationController?.navigationItem.searchController = searchController
        navigationItem.searchController = searchController
    }
}
