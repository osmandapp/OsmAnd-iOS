//
//  MyPlacesContainerViewController.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 08.05.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

protocol MyPlacesDelegate: AnyObject {
    func showBackButton(_ show: Bool)
    func updateSegmentedControlVisibility(_ isVisible: Bool)
    func updateEditMode(_ edit: Bool)
    func updateSearchEnabling(_ isEnabled: Bool)
    func updateTitle(_ title: String, hideSubtitle: Bool)
    func updateTitle(_ title: String, subtitle: String, hideSubtitle: Bool)
    func updateToolbar(with items: [UIBarButtonItem]?)
    func updateContentScrollView(_ scrollView: UIScrollView)
}

@objc protocol MyPlacesSearchable: AnyObject {
    func searchResults(for searchController: UISearchController)
    @objc optional func searchBarCancelButtonClicked(_ searchBar: UISearchBar)
}

protocol MyPlacesScrollResettable: AnyObject {
    func resetScrollPosition()
}

@objcMembers
final class MyPlacesContainerViewController: OACompoundViewController {
    @objc enum Tab: Int, CaseIterable {
        case favorites
        case tracks
        case osm
        case travel

        static var `default`: Tab {
            .favorites
        }
        
        var image: UIImage {
            switch self {
            case .favorites: .icCustom20Favorites
            case .tracks: .icCustom20Trip
            case .osm: .icCustom20Osm
            case .travel: .icCustom20Backpack
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
            case .favorites: FavoriteListViewController.self
            case .tracks: TracksViewController.self
            case .osm: OsmEditsListViewController.self
            case .travel: SavedArticlesTabViewController.self
            }
        }
    }
    
    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var segmentContainerView: UIView!
    @IBOutlet private weak var segmentControl: UISegmentedControl!
    @IBOutlet private weak var segmentContainerTopConstraint: NSLayoutConstraint!
    
    var selectedTab: Tab = .default
    var availableTabs: [Tab] = []
    var tracksFolderPathToOpenOnLoad: String?

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .default
    }
    
    private let segmentedControlIconSize: CGFloat = 24
    private let searchAnimationDuration: TimeInterval = 0.2
    private var availableViewControllers: [Tab: UIViewController] = [:]
    private var pageViewController: UIPageViewController?
    private var searchController: UISearchController?
    private var isSelectionMode = false
    private var isSearchActive = false
    private var isSearchBarAnimating = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        segmentContainerTopConstraint.constant = view.safeAreaInsets.top
        setupSegmentControl()
        setupTabs()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard !isSearchBarAnimating, searchController?.isActive != true else { return }
        segmentContainerTopConstraint.constant = view.safeAreaInsets.top
        updateContentSafeAreaInsets(segmentIsVisible: !segmentContainerView.isHidden && searchController?.isActive != true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItem.searchController = nil
        setupSearchController()
        setupPageController()
        setupSegments()
        initialSelectedTab()
        setupNavbar()
        pageViewController?.scrollView?.backgroundColor = .clear
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationController?.navigationBar.tintColor = .label
        view.backgroundColor = .viewBg
        openTracksFolderIfNeeded()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationItem.searchController = nil
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        guard !isSearchBarAnimating, searchController?.isActive != true else { return }
        segmentContainerTopConstraint.constant = view.safeAreaInsets.top
        view.layoutIfNeeded()
    }
    
    func switchToWithSegmentControl(tab: Tab) {
        switchTo(tab: tab)
        segmentControl.selectedSegmentIndex = availableTabs.firstIndex(of: tab) ?? Tab.default.rawValue
    }
    
    func viewController(for tab: Tab) -> UIViewController? {
        guard let pageViewController else { return nil }
        switch tab {
        case .favorites:
            if !availableViewControllers.contains(where: { $0.key == .favorites }) {
                let favoritesViewController = FavoriteListViewController(frame: pageViewController.view.frame)
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
        searchController?.hidesNavigationBarDuringPresentation = true
        definesPresentationContext = true
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.largeTitleDisplayMode = .never
        if #available(iOS 26.0, *) {
            navigationItem.preferredSearchBarPlacement = .stacked
        }
        updateSearchController()
    }

    private func showSearchController() {
        searchController?.searchBar.alpha = 0
        navigationItem.searchController = searchController
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.navigationItem.searchController?.isActive = true
        }
    }

    private func hideSearchController() {
        guard navigationItem.searchController?.isActive == true else {
            navigationItem.searchController = nil
            return
        }
        navigationItem.searchController?.isActive = false
    }
    
    private func setupNavbarTitle(with tab: Tab) {
        setupNavbarTitle(tab.title, hideSubtitle: false)
    }
    
    private func setupNavbarTitle(_ title: String, hideSubtitle: Bool) {
        setupNavbarTitle(title, subtitle: localizedString("shared_string_my_places"), hideSubtitle: hideSubtitle)
    }

    private func setupNavbarTitle(_ title: String, subtitle: String, hideSubtitle: Bool) {
        guard isSelectionMode else {
            navigationItem.titleView = nil
            navigationItem.title = title
            return
        }

        navigationItem.title = nil
        navigationItem.setStackViewWithTitle(title,
                                             titleColor: .textColorPrimary,
                                             titleFont: .scaledSystemFont(ofSize: 17.0, weight: .semibold, maximumSize: 22.0),
                                             subtitle: hideSubtitle ? "" : subtitle,
                                             subtitleColor: .textColorSecondary,
                                             subtitleFont: .scaledSystemFont(ofSize: 12.0, maximumSize: 18.0))
    }
    
    private func setupNavbar() {
        navigationController?.setDefaultNavigationBarAppearance()
    }

    private func updateContentSafeAreaInsets(segmentIsVisible: Bool) {
        guard let pageViewController else { return }
        let topInset = segmentIsVisible ? segmentContainerView.bounds.height : 0
        guard pageViewController.additionalSafeAreaInsets.top != topInset else { return }
        var insets = pageViewController.additionalSafeAreaInsets
        insets.top = topInset
        pageViewController.additionalSafeAreaInsets = insets
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
            image.accessibilityLabel = tab.title
            segmentControl.insertSegment(with: image, at: index, animated: false)
        }
    }
    
    private func openTracksFolderIfNeeded() {
        guard let path = tracksFolderPathToOpenOnLoad else { return }
        tracksFolderPathToOpenOnLoad = nil
        (viewController(for: .tracks) as? TracksViewController)?.setFolderToOpenAfterLoad(path)
    }
    
    private func switchTo(tab: Tab) {
        let targetTab = availableTabs.first(where: { $0 == tab }) ?? .default
        let isCurrentTabVisible = pageViewController?.viewControllers?.first?.isKind(of: targetTab.controllerType) == true
        guard !isCurrentTabVisible else { return }
        
        let previousTab = selectedTab
        selectedTab = targetTab
        if let viewController = viewController(for: selectedTab) {
            if previousTab != selectedTab {
                (viewController as? MyPlacesScrollResettable)?.resetScrollPosition()
            }
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
    func pageViewController(_ pageViewController: UIPageViewController,
                            willTransitionTo pendingViewControllers: [UIViewController]) {
        guard let viewController = pendingViewControllers.first,
              let index = availableTabs.firstIndex(where: { viewController.isKind(of: $0.controllerType) }) else {
            return
        }
        
        (viewController as? MyPlacesScrollResettable)?.resetScrollPosition()
        segmentControl.selectedSegmentIndex = index
        setupNavbarTitle(with: availableTabs[index])
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController],
                            transitionCompleted completed: Bool) {
        guard let viewController = pageViewController.viewControllers?.first,
              let index = availableTabs.firstIndex(where: { viewController.isKind(of: $0.controllerType) }) else {
            return
        }
        
        let tab = availableTabs[index]
        segmentControl.selectedSegmentIndex = index
        selectedTab = tab
        setupNavbarTitle(with: tab)
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
        updateContentSafeAreaInsets(segmentIsVisible: isVisible)
    }
    
    func updateEditMode(_ edit: Bool) {
        isSelectionMode = edit
        updateSegmentedControlVisibility(!edit)
        setupNavbar()
    }
    
    func updateTitle(_ title: String, hideSubtitle: Bool) {
        setupNavbarTitle(title, hideSubtitle: hideSubtitle)
    }

    func updateTitle(_ title: String, subtitle: String, hideSubtitle: Bool) {
        setupNavbarTitle(title, subtitle: subtitle, hideSubtitle: hideSubtitle)
    }
    
    func updateToolbar(with items: [UIBarButtonItem]?) {
        toolbarItems = items
    }
    
    func updateSearchEnabling(_ isEnabled: Bool) {
        if isEnabled {
            guard !isSearchActive else {
                showSearchController()
                return
            }
            
            isSearchActive = true
            isSearchBarAnimating = true
            updateContentSafeAreaInsets(segmentIsVisible: false)
            showSearchController()
            pageViewController?.delegate = nil
            pageViewController?.dataSource = nil
            let hiddenTransform = CGAffineTransform(translationX: 0, y: -segmentContainerView.bounds.height)
            UIView.animate(withDuration: searchAnimationDuration, delay: 0, options: .showHideTransitionViews) {
                self.segmentContainerView.transform = hiddenTransform
                self.segmentContainerView.alpha = 0
                self.view.layoutIfNeeded()
            } completion: { finished in
                guard finished else { return }
                self.segmentContainerView.isHidden = true
                self.segmentContainerView.transform = .identity
            }
        } else {
            hideSearchController()
        }
    }
    
    func updateContentScrollView(_ scrollView: UIScrollView) {
        setContentScrollView(scrollView, for: .top)
        if #available(iOS 26.0, *) {
            segmentContainerView.backgroundColor = .clear
            let interaction = segmentContainerView.interactions.compactMap { $0 as? UIScrollEdgeElementContainerInteraction }.first ?? UIScrollEdgeElementContainerInteraction()
            interaction.scrollView = scrollView
            interaction.edge = .top
            if interaction.view == nil {
                segmentContainerView.addInteraction(interaction)
            }
        } else {
            segmentContainerView.backgroundColor = .viewBg
            navigationItem.standardAppearance = navigationController?.navigationBar.scrollEdgeAppearance
        }
    }
}

// MARK: - UISearchResultsUpdating
extension MyPlacesContainerViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard !isSearchBarAnimating || !searchController.isActive else { return }
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
    func didPresentSearchController(_ searchController: UISearchController) {
        isSearchActive = true
        isSearchBarAnimating = false
        updateSearchResults(for: searchController)
        UIView.animate(withDuration: 0.1, delay: 0, options: [.beginFromCurrentState]) {
            searchController.searchBar.alpha = 1
        }
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        isSearchBarAnimating = true
        navigationItem.searchController = nil
        pageViewController?.delegate = self
        pageViewController?.dataSource = self
        segmentContainerView.transform = CGAffineTransform(translationX: 0, y: -segmentContainerView.bounds.height)
        segmentContainerView.isHidden = false
        UIView.animate(withDuration: 0.4, delay: 0, options: [.beginFromCurrentState]) {
            searchController.searchBar.alpha = 0
            self.segmentContainerView.transform = .identity
            self.segmentContainerView.alpha = 1
            self.updateContentSafeAreaInsets(segmentIsVisible: true)
            self.view.layoutIfNeeded()
        }
    }
    
    func didDismissSearchController(_ searchController: UISearchController) {
        isSearchBarAnimating = false
        segmentContainerTopConstraint.constant = view.safeAreaInsets.top
        view.layoutIfNeeded()
        if navigationItem.searchController === searchController {
            navigationItem.searchController = nil
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.isSearchActive = false
        }
    }
    
    func presentSearchController(_ searchController: UISearchController) {
        if !searchController.searchBar.isFirstResponder {
            searchController.searchBar.becomeFirstResponder()
        }
    }
}
