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
class WidgetPanelViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    static let controlHeight: CGFloat = 26
    
    private var isInTransition = false
    
    @IBOutlet var pageControlHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var pageControl: UIPageControl!
    
    var pageViewController: UIPageViewController!
    var pages: [UIViewController] = []
    
    var widgetPages: [[OABaseWidgetView]] = []
    var currentIndex: Int {
        guard let vc = pageViewController.viewControllers?.first else { return 0 }
        return pages.firstIndex(of: vc) ?? 0
    }
    
    let pageContainerView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pageViewController.dataSource = self
        pageViewController.delegate = self
        
        // Add the container view to the view hierarchy
        view.addSubview(pageContainerView)
        
        // Set up constraints
        pageContainerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pageContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageContainerView.topAnchor.constraint(equalTo: view.topAnchor),
            pageContainerView.bottomAnchor.constraint(equalTo: pageControl.topAnchor),
            pageContainerView.widthAnchor.constraint(equalToConstant: 0),
            pageContainerView.heightAnchor.constraint(equalToConstant: 0)
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
        
        updateWidgetPages(widgetPages)
    }
    
    @IBAction func pageControlTapped(_ sender: Any) {
        guard let pageControl = sender as? UIPageControl else { return }
        let selectedPage = pageControl.currentPage
        pageViewController.setViewControllers([pages[selectedPage]], direction: selectedPage > currentIndex ? .forward : .reverse, animated: true) { [weak self] _ in
            self?.updateContainerSize()
        }
    }
    
    private func calculateContentSize() -> (width: CGFloat, height: CGFloat) {
        if let controller = pages[currentIndex] as? WidgetPageViewController {
            return controller.layoutWidgets()
        }
        return (0, 0)
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

//        UIView.transition(with: view, duration: 0.2, options: .transitionCrossDissolve, animations: {
        self.view.superview?.layoutIfNeeded()
//        }, completion: nil)
    }
    
    func clearWidgets() {
        pages.removeAll()
        widgetPages.removeAll()
        guard let pageViewController else { return }
        pageViewController.setViewControllers([UIViewController()], direction: .forward, animated: false)
    }
    
    func updateWidgetPages(_ widgetPages: [[OABaseWidgetView]]) {
        guard let pageViewController else { return }
        self.widgetPages = widgetPages
        for page in widgetPages {
            let vc = WidgetPageViewController()
            vc.widgetViews = page
            pages.append(vc)
        }
        if pages.isEmpty {
            pages.append(UIViewController())
        }
        pageViewController.setViewControllers([pages[currentIndex]], direction: .forward, animated: true)
        
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
        pageControl.currentPage = currentIndex
        updateWidgetSizes()
    }
}
