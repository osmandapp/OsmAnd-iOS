//
//  OAWidgetPanelViewController.swift
//  OsmAnd Maps
//
//  Created by Paul on 13.06.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit

@objc(OAWidgetPanelViewController)
@objcMembers
class WidgetPanelViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, OAWidgetListener {
    
    private static let controlHeight: CGFloat = 26
    private static let contentHeight: CGFloat = 32
    private static let borderWidth: CGFloat = 2
    
    private var isInTransition = false
    
    @IBOutlet var pageControlHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var pageControl: UIPageControl!
    
    var pageViewController: UIPageViewController!
    var pages: [UIViewController] = []
    
    var widgetPages: [[OABaseWidgetView]] = []
    var currentIndex: Int {
        guard let vc = pageViewController.viewControllers?.first else { return 0 }
        return pages.firstIndex(of: vc) ?? 0
    }
    
    let pageContainerView = UIView()
    var dayNightObserver: OAAutoObserverProxy!
    
    weak var delegate: WidgetPanelDelegate?
    
    deinit {
        dayNightObserver.detach()
    }
    
    private func setupViews() {
        pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pageViewController.dataSource = self
        pageViewController.delegate = self
        
        contentView.layer.borderWidth = Self.borderWidth
        contentView.layer.borderColor = UIColor.black.withAlphaComponent(0.3).cgColor
        
        // Add the container view to the view hierarchy
        view.addSubview(pageContainerView)
        
        // Set up constraints
        pageContainerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pageContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Self.borderWidth),
            pageContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Self.borderWidth),
            pageContainerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Self.borderWidth),
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dayNightObserver = OAAutoObserverProxy(self, withHandler: #selector(onDayNightModeChanged), andObserve: OsmAndApp.swiftInstance().dayNightModeObservable)
        
        setupViews()
        setupPageControl()
        updateWidgetPages(widgetPages)
    }
    
    @objc private func onDayNightModeChanged() {
        DispatchQueue.main.async {
            self.setupPageControl()
        }
    }
    
    @IBAction func pageControlTapped(_ sender: Any) {
        guard let pageControl = sender as? UIPageControl else { return }
        let selectedPage = pageControl.currentPage
        pageViewController.setViewControllers([pages[selectedPage]], direction: selectedPage > currentIndex ? .forward : .reverse, animated: true) { [weak self] _ in
            DispatchQueue.main.async { [weak self] in
                self?.updateContainerSize()
            }
        }
    }
    
    private func calculateContentSize() -> (width: CGFloat, height: CGFloat) {
        var width: CGFloat = 0
        var height: CGFloat = Self.contentHeight
        for (idx, page) in pages.enumerated() {
            let widgetSize = (page as? WidgetPageViewController)?.layoutWidgets() ?? (0, 0)
            if idx == currentIndex {
                height = widgetSize.1
            }
            width = max(width, widgetSize.0)
        }
        height = max(height, Self.contentHeight)
        return (width + 2, height)
    }
    
    private func updateContainerSize() {
        let contentSize = calculateContentSize()
        
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

        self.view.layoutIfNeeded()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        delegate?.onPanelSizeChanged()
    }
    
    func clearWidgets() {
        pageViewController.dataSource = nil
        pageViewController.delegate = nil
        for viewController in pageViewController.children {
            viewController.willMove(toParent: nil)
            viewController.view.removeFromSuperview()
            viewController.removeFromParent()
        }
        pages.removeAll()
        widgetPages.removeAll()
        pageViewController.dataSource = self
        pageViewController.delegate = self
    }
    
    func updateWidgetPages(_ widgetPages: [[OABaseWidgetView]]) {
        guard let pageViewController else { return }
        pageViewController.dataSource = nil
        pageViewController.delegate = nil
        self.widgetPages = widgetPages
        widgetPages.forEach { $0.forEach { $0.delegate = self } }
        for page in widgetPages {
            let vc = WidgetPageViewController()
            vc.widgetViews = page
            pages.append(vc)
        }
        if pages.isEmpty {
            pages.append(UIViewController())
        }
        pageViewController.setViewControllers([pages[currentIndex]], direction: .forward, animated: false)
        pageViewController.dataSource = self
        pageViewController.delegate = self
        
        // Set up the page control
        pageControl.numberOfPages = pages.count
        pageControl.currentPage = currentIndex
        pageControl.isHidden = pages.count <= 1;
        pageControlHeightConstraint.constant = pageControl.isHidden ? 0 : Self.controlHeight
    }
    
    func hasWidgets() -> Bool {
        return !widgetPages.isEmpty
    }
    
    func updateWidgetSizes() {
        if !isInTransition {
            updateContainerSize()
        }
    }
    
    // MARK: - UIPageViewControllerDataSource
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard currentIndex > 0 else {
            return nil
        }
        return pages[currentIndex - 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard currentIndex < pages.count - 1 else {
            return nil
        }
        return pages[currentIndex + 1]
    }
    
    // MARK: - UIPageViewControllerDelegate
    
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        isInTransition = true
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if !completed || !finished { return }
        
        isInTransition = false
        DispatchQueue.main.async { [weak self] in
            self?.pageControl.currentPage = self?.currentIndex ?? 0
            self?.updateContainerSize()
        }
    }
    
    // MARK: OAWidgetListener
    
    func widgetChanged(_ widget: OABaseWidgetView?) {
        if delegate != nil {
            updateWidgetSizes()
        }
    }
    
    func widgetVisibilityChanged(_ widget: OABaseWidgetView, visible: Bool) {
        updateWidgetSizes()
    }
    
    func widgetClicked(_ widget: OABaseWidgetView) {
        updateWidgetSizes()
    }
}

@objc(OAWidgetPanelDelegate)
protocol WidgetPanelDelegate: AnyObject {
    func onPanelSizeChanged()
}
