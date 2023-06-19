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
class WidgetPanelViewController: UIViewController {
    
    static let controlHeight: CGFloat = 26
    
    private var isInTransition = false
    
    @IBOutlet var pageControlHeightConstraint: NSLayoutConstraint!

    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var collectionHeightConstraint: NSLayoutConstraint!
    @IBOutlet var collectionWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var pageControl: UIPageControl!
    
    var widgetPages: [[OABaseWidgetView]] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(PageCollectionViewCell.self, forCellWithReuseIdentifier: PageCollectionViewCell.getIdentifier())
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.sectionInset = .zero
        collectionView.collectionViewLayout = layout
        collectionView.isPagingEnabled = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        collectionView.reloadData()
        updateContainerViewSize(for: 0)

        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @IBAction func pageControlTapped(_ sender: Any) {
        guard let pageControl = sender as? UIPageControl else { return }
        let selectedPage = pageControl.currentPage
        collectionView.reloadData()
    }
    
    func clearWidgets() {
        widgetPages.removeAll()
        collectionView.reloadData()
    }
    
    func updateWidgetPages(_ widgetPages: [[OABaseWidgetView]]) {
        self.widgetPages = widgetPages
        collectionView.reloadData()
        
        // Set up the page control
        pageControl.numberOfPages = widgetPages.count
        pageControl.currentPage = 0
        pageControl.isHidden = widgetPages.count <= 1;
        pageControlHeightConstraint.constant = pageControl.isHidden ? 0 : Self.controlHeight
    }
    
    func hasWidgets() -> Bool {
        return !widgetPages.isEmpty
    }
}

extension WidgetPanelViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return widgetPages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PageCollectionViewCell.getIdentifier(), for: indexPath) as! PageCollectionViewCell
        cell.configure(with: widgetPages[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return calculateSize(section: indexPath.section)
    }
    
    private func calculateMaxSize() -> CGSize {
//        let views = widgetPages[section]
        var width: CGFloat = 0
        var height: CGFloat = 0
        for i in widgetPages.indices {
            let size = calculateSize(section: i)
            width = max(width, size.width)
            height = max(height, size.height)
        }
        return CGSize(width: width, height: height)
    }
    
    private func calculateSize(section: Int) -> CGSize {
        let views = widgetPages[section]
        var width: CGFloat = 0
        var height: CGFloat = 0
        for widget in views {
            if let widget = widget as? OATextInfoWidget {
                widget.adjustViewSize()
            } else {
                widget.sizeToFit()
            }
            width = max(width, widget.frame.size.width)
            if !widget.isHidden {
                height += widget.frame.size.height
            }
        }
        return CGSize(width: width, height: height)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)

        if let visibleIndexPath = collectionView.indexPathForItem(at: visiblePoint) {
            pageControl.currentPage = visibleIndexPath.item
            updateContainerViewSize(for: visibleIndexPath.item)
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            } completion: { _ in
                self.collectionView.scrollToItem(at: visibleIndexPath, at: .centeredHorizontally, animated: false)
            }
        }
    }
    
    private func updateContainerViewSize(for pageIndex: Int) {
        let cellSize = calculateMaxSize()
        collectionHeightConstraint.constant = cellSize.height
        collectionWidthConstraint.constant = cellSize.width
//        view.layoutIfNeeded()
    }
}

class PageCollectionViewCell: UICollectionViewCell {
    
    private var stackView: UIStackView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupStackView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupStackView() {
        stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0)
        ])
    }
    
    func configure(with views: [UIView]) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        views.forEach {
            if let widget = $0 as? OATextInfoWidget {
                widget.adjustViewSize()
            }
            $0.heightAnchor.constraint(equalToConstant: $0.frame.size.height).isActive = true
            stackView.addArrangedSubview($0)
        }
    }
}
