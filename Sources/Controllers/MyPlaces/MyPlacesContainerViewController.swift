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
    func updateSearchEnabling(_ isEnabled: Bool)
    func updateTitle(_ title: String, hideSubtitle: Bool)
    func updateToolbar(with items: [UIBarButtonItem]?)
}

@objc
protocol MyPlacesSearchable: AnyObject {
    func searchResults(for searchController: UISearchController)
    @objc optional func searchBarCancelButtonClicked(_ searchBar: UISearchBar)
}

@objcMembers
final class MyPlacesContainerViewController: OACompoundViewController {
    @objc enum Tab: Int, CaseIterable {
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
            case .osm: OsmEditsListViewController.self
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
    @IBOutlet private var safeAreaTopConstraint: NSLayoutConstraint!
    @IBOutlet private var superviewTopConstraint: NSLayoutConstraint!
    
    var selectedTab: Tab = .default
    var availableTabs: [Tab] = []
    var tracksFolderPathToOpenOnLoad: String?
    
    private let segmentedControlIconSize: CGFloat = 24
    private var availableViewControllers: [Tab: UIViewController] = [:]
    private var pageViewController: UIPageViewController?
    private var searchController: UISearchController?
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .default
    }
    
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
        segmentContainerView.backgroundColor = .clear
        pageViewController?.scrollView?.backgroundColor = .clear
        navigationController?.navigationBar.prefersLargeTitles = false
        view.backgroundColor = .viewBg
        openTracksFolderIfNeeded()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationItem.searchController = nil
    }
    
    func switchToWithSegmentControl(tab: Tab) {
        switchTo(tab: tab)
        segmentControl.selectedSegmentIndex = availableTabs.firstIndex(of: tab) ?? Tab.default.rawValue
    }
    
    func viewController(for tab: Tab) -> UIViewController? {
        guard let pageViewController else { return nil }
        let storyboard = UIStoryboard(name: "MyPlaces", bundle: nil)
        switch tab {
        case .favorites:
            if !availableViewControllers.contains(where: { $0.key == .favorites }),
               let favoritesViewController = storyboard.instantiateViewController(withIdentifier: "OAFavoriteListViewController") as? OAFavoriteListViewController {
                favoritesViewController.myPlacesDelegate = self
                availableViewControllers[tab] = favoritesViewController
            }
        case .tracks:
            if !availableViewControllers.contains(where: { $0.key == .tracks }) {
                let tracksViewController = TracksViewController(frame: pageViewController.view.frame, isRootFolder: true)
                tracksViewController.myPlacesDelegate = self
                availableViewControllers[tab] = tracksViewController
            }
        case .osm:
            if !availableViewControllers.contains(where: { $0.key == .osm }) {
                let osmEditsViewController = OsmEditsListViewController(frame: pageViewController.view.frame)
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
        
        if TravelLocalDataHelper.shared.savedAriticlesCount() > 1 {
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
        searchController?.searchResultsUpdater = self
        searchController?.searchBar.delegate = self
        searchController?.delegate = self
        searchController?.obscuresBackgroundDuringPresentation = false
        definesPresentationContext = true
        if #available(iOS 26.0, *) {
            if !OAUtilities.isIPad() {
                navigationItem.preferredSearchBarPlacement = .stacked
            }
        }
        updateSearchController()
    }
    
    private func setupNavbarTitle(with tab: Tab) {
        setupNavbarTitle(tab.title, hideSubtitle: false)
    }
    
    private func setupNavbarTitle(_ title: String, hideSubtitle: Bool) {
        navigationItem.setStackViewWithTitle(title,
                                             titleColor: .textColorPrimary,
                                             titleFont: .scaledSystemFont(ofSize: 17.0, weight: .semibold, maximumSize: 22.0),
                                             subtitle: hideSubtitle ? "" : localizedString("shared_string_my_places"),
                                             subtitleColor: .textColorSecondary,
                                             subtitleFont: .scaledSystemFont(ofSize: 12.0, maximumSize: 18.0))
    }
    
    private func setupNavbar(isSearchActive: Bool = false) {
        if isSearchActive {
            navigationController?.navigationBar.scrollEdgeAppearance = nil
        } else {
            let appearance = UINavigationBarAppearance()
            appearance.backgroundColor = .viewBg
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
        }
        safeAreaTopConstraint.isActive = !isSearchActive
        superviewTopConstraint.isActive = isSearchActive
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
    
    private func openTracksFolderIfNeeded() {
        guard let path = tracksFolderPathToOpenOnLoad else { return }
        tracksFolderPathToOpenOnLoad = nil
        (viewController(for: .tracks) as? TracksViewController)?.setFolderToOpenAfterLoad(path)
    }
    
    private func switchTo(tab: Tab) {
        selectedTab = availableTabs.first(where: { $0 == tab }) ?? .default
        if let viewController = viewController(for: selectedTab) {
            pageViewController?.setViewControllers([viewController], direction: .forward, animated: true)
        }
        DispatchQueue.main.async {
            self.setupNavbarTitle(with: self.selectedTab)
        }
    }
    
    private func initialSelectedTab() {
        switchToWithSegmentControl(tab: selectedTab)
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
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        guard let viewController = pendingViewControllers.first,
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
    }
    
    func updateTitle(_ title: String, hideSubtitle: Bool) {
        setupNavbarTitle(title, hideSubtitle: hideSubtitle)
    }
    
    func updateToolbar(with items: [UIBarButtonItem]?) {
        toolbarItems = items
    }
    
    func updateSearchEnabling(_ isEnabled: Bool) {
        let searchController = isEnabled ? searchController : nil
        navigationItem.searchController = searchController
        navigationItem.searchController?.isActive = true
        updateSegmentedControlVisibility(!isEnabled)
        setupNavbar(isSearchActive: isEnabled)
    }
}

// MARK: - UISearchResultsUpdating
extension MyPlacesContainerViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchableViewController = viewController(for: selectedTab) as? MyPlacesSearchable else {
            return
        }
        searchableViewController.searchResults(for: searchController)
    }
}

// MARK: - UISearchBarDelegate
extension MyPlacesContainerViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        guard let searchableViewController = viewController(for: selectedTab) as? MyPlacesSearchable else {
            return
        }
        searchableViewController.searchBarCancelButtonClicked?(searchBar)
    }
}

// MARK: - UISearchControllerDelegate
extension MyPlacesContainerViewController: UISearchControllerDelegate {
    func presentSearchController(_ searchController: UISearchController) {
        // The delay is introduced to allow UISearchController to fully initialize and become ready for interaction.
        // Sometimes, immediate attempts to make the searchBar the first responder can fail due to ongoing animations or the controller's initialization process.
        let searchBarActivationDelay = 0.1
        DispatchQueue.main.asyncAfter(deadline: .now() + searchBarActivationDelay) {
            if !searchController.searchBar.isFirstResponder {
                searchController.searchBar.becomeFirstResponder()
            }
        }
    }
}
