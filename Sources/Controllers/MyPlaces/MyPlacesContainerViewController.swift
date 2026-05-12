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
        setupUI()
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
            viewControllers.append(favoritesViewController)
            pageViewController.setViewControllers([favoritesViewController], direction: .forward, animated: false)
        }
        
        viewControllers.append(TracksViewController(frame: pageViewController.view.frame))
        
        if OAIAPHelper.sharedInstance().osmEditing.isActive() {
            viewControllers.append(OAOsmEditsListViewController(frame: pageViewController.view.frame))
        }
        
        if TravelLocalDataHelper.shared.hasSavedArticles() {
            viewControllers.append(SavedArticlesTabViewController(frame: pageViewController.view.frame))
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
        guard let index = availableTabs.firstIndex(of: tab) else { return }
        pageViewController?.setViewControllers([availableViewControllers[index]], direction: .forward, animated: true)
    }
    
    @objc private func onBackPressed() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func onSegmentChanged() {
        view.endEditing(true)
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
    }
}
