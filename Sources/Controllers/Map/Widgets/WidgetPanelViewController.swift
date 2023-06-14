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

    @IBOutlet weak var pageControl: UIPageControl!
    
    var pageViewController: UIPageViewController!
    var pages: [UIViewController] = []
    
    var widgetPages: [[OABaseWidgetView]] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pageViewController.dataSource = self
        pageViewController.delegate = self
        
        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.didMove(toParent: self)
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            pageViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            pageViewController.view.bottomAnchor.constraint(equalTo: pageControl.topAnchor)
        ])
        
        for page in widgetPages {
            let vc = WidgetPageViewController()
            vc.widgetViews = page
            pages.append(vc)
        }
        if pages.isEmpty {
            pages.append(UIViewController())
        }
        
        pageViewController.setViewControllers(pages, direction: .forward, animated: false)
        
        // Set up the page control
        pageControl.numberOfPages = pages.count
        pageControl.currentPage = 0

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
        pageViewController.setViewControllers(pages, direction: .forward, animated: true)
        
        // Set up the page control
        pageControl.numberOfPages = pages.count
        pageControl.currentPage = 0
    }
    
    // MARK: - UIPageViewControllerDataSource
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let currentIndex = pages.firstIndex(of: viewController), currentIndex > 0 else {
            return nil
        }
        return pages[currentIndex - 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let currentIndex = pages.firstIndex(of: viewController), currentIndex < pages.count - 1 else {
            return nil
        }
        return pages[currentIndex + 1]
    }
    
    // MARK: - UIPageViewControllerDelegate
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if let currentViewController = pageViewController.viewControllers?.first,
           let currentIndex = pages.firstIndex(of: currentViewController) {
            pageControl.currentPage = currentIndex
        }
    }
}
