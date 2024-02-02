//
//  OAWidgetPanelViewController.swift
//  OsmAnd Maps
//
//  Created by Paul on 13.06.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit

@objc(OAWidgetPanelDelegate)
protocol WidgetPanelDelegate: AnyObject {
    func onPanelSizeChanged()
}

@objc(OAWidgetPanelViewController)
@objcMembers
final class WidgetPanelViewController: UIViewController, OAWidgetListener {
    private static let controlHeight: CGFloat = 26
    private static let contentHeight: CGFloat = 32
    private static let borderWidth: CGFloat = 1
    
    @IBOutlet var pageControlHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet private var contentView: UIView!
    @IBOutlet private var pageControl: UIPageControl! {
        didSet {
            pageControl.backgroundStyle = .minimal
            pageControl.isEnabled = false
        }
    }

    var specialPanelController: WidgetPanelViewController? = nil

    let isHorizontal: Bool
    let isSpecial: Bool

    var pageViewController: UIPageViewController!
    var pages: [UIViewController] = []
    var widgetPages: [[OABaseWidgetView]] = []
    
    var currentIndex: Int {
        guard let vc = pageViewController.viewControllers?.first else { return 0 }
        return pages.firstIndex(of: vc) ?? 0
    }
    
    weak var delegate: WidgetPanelDelegate?
    
    private let pageContainerView = UIView()
    
    private var isInTransition = false
    private var dayNightObserver: OAAutoObserverProxy!
    
    // MARK: - Init
    
    init() {
        self.isHorizontal = false
        self.isSpecial = false
        super.init(nibName: "OAWidgetPanelViewController", bundle: nil)
    }
    
    init(horizontal: Bool) {
        self.isHorizontal = horizontal
        self.isSpecial = false
        super.init(nibName: "OAWidgetPanelViewController", bundle: nil)
    }

    init(horizontal: Bool, special: Bool) {
        self.isHorizontal = horizontal
        self.isSpecial = special
        super.init(nibName: "OAWidgetPanelViewController", bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.isHorizontal = false
        self.isSpecial = false
        super.init(coder: coder)
    }
    
    // MARK: - Life Circle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dayNightObserver = OAAutoObserverProxy(self, withHandler: #selector(onDayNightModeChanged), andObserve: OsmAndApp.swiftInstance().dayNightModeObservable)
        
        setupViews()
        setupPageControl()
        updateWidgetPages(widgetPages)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        delegate?.onPanelSizeChanged()
    }
    
    deinit {
        dayNightObserver.detach()
    }
    
    // MARK: - Public Functions
    
    func calculateContentSize() -> CGSize {
        var width: CGFloat = 0
        var height: CGFloat = pages.isEmpty ? 0 : Self.contentHeight
        if hasWidgets() {
            for (idx, page) in pages.enumerated() {
                let widgetSize = (page as? WidgetPageViewController)?.layoutWidgets() ?? (0, 0)
                if idx == pageControl.currentPage {
                    height = widgetSize.1
                }
                width = max(width, widgetSize.0)
            }
            height = max(height, Self.contentHeight)
        }
        if !isHorizontal {
            width += 2
        }
        return CGSize(width: width, height: height)
    }
    
    func clearWidgets() {
        specialPanelController?.clearWidgets()

        pageViewController.dataSource = nil
        pageViewController.delegate = nil
        widgetPages.forEach { $0.forEach {
            $0.delegate = nil
            $0.removeFromSuperview()
        } }
        for viewController in pageViewController.children {
            viewController.willMove(toParent: nil)
            viewController.view.removeFromSuperview()
            viewController.removeFromParent()
        }
        for viewController in pages {
            if let pageViewController = viewController as? WidgetPageViewController {
                pageViewController.widgetViews = []
            }
        }
        pages.removeAll()
        widgetPages.removeAll()
        if !isHorizontal {
            pageViewController.dataSource = self
        }
        pageViewController.delegate = self
    }
    
    func updateWidgetPages(_ widgetPages: [[OABaseWidgetView]]) {
        guard let pageViewController else { return }
        pageViewController.dataSource = nil
        pageViewController.delegate = nil
        self.widgetPages = widgetPages
        widgetPages.forEach { $0.forEach { $0.delegate = self } }
        if isHorizontal {
            let vc = WidgetPageViewController()
            vc.simpleWidgetViews = widgetPages
            vc.isMultipleWidgetsInRow = true
            pages.append(vc)
        } else {
            for page in widgetPages {
                let vc = WidgetPageViewController()
                vc.widgetViews = page
                pages.append(vc)
            }
        }

        if pages.isEmpty {
            pages.append(UIViewController())
        }
        pageViewController.setViewControllers([pages[currentIndex]], direction: .forward, animated: false)
        if !isHorizontal {
            pageViewController.dataSource = self
        }
        pageViewController.delegate = self
        
        // Set up the page control
        pageControl.numberOfPages = pages.count
        pageControl.currentPage = currentIndex
        pageControl.isHidden = pages.count <= 1 || isHorizontal
        pageControlHeightConstraint.constant = pageControl.isHidden ? 0 : Self.controlHeight
    }

    func hasWidgets() -> Bool {
        if !widgetPages.isEmpty {
            for widgetPage in widgetPages {
                for widget in widgetPage {
                    if !widget.isHidden {
                        return true
                    }
                }
            }
        }
        return false
    }
    
    func updateWidgetSizes() {
        if !isInTransition {
            updateContainerSize()
        }
    }
    
    // MARK: - Private Functions
    
    private func setupViews() {
        view.layer.masksToBounds = true
        pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        if !isHorizontal {
            pageViewController.dataSource = self
        }
        pageViewController.delegate = self
        pageViewController.scrollView?.delegate = self
        
        // Add the container view to the view hierarchy
        view.addSubview(pageContainerView)
        
        // Set up constraints
        pageContainerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pageContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: isHorizontal ? 0 : Self.borderWidth),
            pageContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: isHorizontal ? 0 : -Self.borderWidth),
            pageContainerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: isHorizontal ? 0 : Self.borderWidth),
            pageContainerView.bottomAnchor.constraint(equalTo: pageControl.topAnchor),
            pageContainerView.widthAnchor.constraint(equalToConstant: 0),
            pageContainerView.heightAnchor.constraint(equalToConstant: Self.contentHeight)
        ])
        
        // Add the page view controller as a child view controller
        addChild(pageViewController)
        pageContainerView.addSubview(pageViewController.view)
        pageViewController.didMove(toParent: self)
        
        // Set up constraints for the page view controller's view
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pageViewController.view.leadingAnchor.constraint(equalTo: pageContainerView.leadingAnchor),
            pageViewController.view.trailingAnchor.constraint(equalTo: pageContainerView.trailingAnchor),
            pageViewController.view.topAnchor.constraint(equalTo: pageContainerView.topAnchor),
            pageViewController.view.bottomAnchor.constraint(equalTo: pageContainerView.bottomAnchor)
        ])
    }
    
    private func setupPageControl() {
        let isNight = OAAppSettings.sharedManager().nightMode
        pageControl.backgroundColor = UIColor(rgb: Int(isNight ? color_control_night : color_control_day))
        pageControl.currentPageIndicatorTintColor = UIColor(rgb: Int(isNight ? color_on_map_icon_tint_color_dark : color_on_map_icon_tint_color_light))
        pageControl.pageIndicatorTintColor = UIColor(rgb: Int(isNight ? color_icon_inactive_night : color_icon_inactive))
    }
    
    private func updateContainerSize() {
        guard UIApplication.shared.mainScene != nil else { return }
        let contentSize = calculateContentSize()
        let mapHudViewController = OARootViewController.instance().mapPanel.hudViewController
        if self == mapHudViewController?.mapInfoController?.leftPanelController {
            mapHudViewController?.leftWidgetsViewWidthConstraint.constant = contentSize.width
        } else if self == mapHudViewController?.mapInfoController?.rightPanelController {
            mapHudViewController?.rightWidgetsViewWidthConstraint.constant = contentSize.width
        } else if self == mapHudViewController?.mapInfoController?.topPanelController.specialPanelController {
            mapHudViewController?.middleWidgetsViewWidthConstraint.constant = contentSize.width
            mapHudViewController?.middleWidgetsViewHeightConstraint.constant = contentSize.height
        }

        // Update the height constraint of the container view
        for constraint in pageContainerView.constraints {
            if constraint.firstItem === pageContainerView {
                if constraint.firstAttribute == .height {
                    constraint.constant = contentSize.height
                } else if constraint.firstAttribute == .width {
                    constraint.constant = contentSize.width
                }
            }
        }
        view.isHidden = !hasWidgets()
        //view.layoutIfNeeded()
        view.setNeedsLayout()
    }
    
    @objc private func onDayNightModeChanged() {
        DispatchQueue.main.async {
            self.setupPageControl()
        }
    }
    
    // MARK: - @IBAction's
    
    @IBAction private func pageControlTapped(_ sender: Any) {
        guard let pageControl = sender as? UIPageControl else { return }
        let selectedPage = pageControl.currentPage
        pageViewController.setViewControllers([pages[selectedPage]], direction: selectedPage > currentIndex ? .forward : .reverse, animated: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateContainerSize()
            }
        }
    }
}

// MARK: - OAWidgetListener

extension WidgetPanelViewController {
    func widgetChanged(_ widget: OABaseWidgetView?) {
        updateWidgetSizes()
    }
    
    func widgetVisibilityChanged(_ widget: OABaseWidgetView, visible: Bool) {
        updateWidgetSizes()
    }
    
    func widgetClicked(_ widget: OABaseWidgetView) {
        updateWidgetSizes()
    }
}

// MARK: - UIScrollViewDelegate

extension WidgetPanelViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isInTransition = true
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        isInTransition = false
        updateContainerSize()
    }
}

// MARK: - UIPageViewControllerDelegate

extension WidgetPanelViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        isInTransition = true
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed,
              let currentVC = pageViewController.viewControllers?.first,
              let _ = pages.firstIndex(of: currentVC) else { return }
        isInTransition = false
        pageControl.currentPage = currentIndex
        updateContainerSize()
    }
}

// MARK: - UIPageViewControllerDataSource

extension WidgetPanelViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let vcIndex = pages.firstIndex(of: viewController ) else { return nil }
        let prevIndex = vcIndex - 1
        guard prevIndex >= 0 else {
            pageControl.currentPage = 0
            return nil
        }
        guard pages.count > prevIndex else { return nil }
        return pages[prevIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let vcIndex = pages.firstIndex(of: viewController ) else { return nil }
        let nextIndex = vcIndex + 1
        guard nextIndex < pages.count else {
            pageControl.currentPage = pages.count - 1
            return nil
        }
        guard pages.count > nextIndex else { return nil }
        return pages[nextIndex]
    }
}
