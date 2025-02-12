//
//  CarouselSection.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 11.02.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//


final class CarouselSection {
    private weak var collectionView: UICollectionView?
    var isRotating = false
    var isEnabledVisibleItemsInvalidationHandler = true

    init(collectionView: UICollectionView) {
        self.collectionView = collectionView
        self.isRotating = false
    }

    var didUpdatePage: ((Int) -> Void)?

    func layoutSection(for sectionIndex: Int, layoutEnvironment: any NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalWidth(1.0)
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitems: [item]
        )
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .paging

        section.visibleItemsInvalidationHandler = { [weak self] (visibleItems, offset, environment) in
            guard let self else { return }
            guard !self.isRotating else { return }
            guard self.isEnabledVisibleItemsInvalidationHandler else { return }
            /// Filter supplementary views out
            let items = visibleItems.filter { $0.representedElementKind == nil }
            guard !items.isEmpty else { return }
            let width = environment.container.effectiveContentSize.width
            let itemWidth = items[0].frame.width
            let itemOffset = (width - itemWidth) / 2
            let xOffset = offset.x + itemOffset
            
            let nearestIndex = (xOffset / itemWidth).rounded()
            let currentPage = Int(nearestIndex)
            didUpdatePage?(currentPage - 1)
            let count = collectionView?.numberOfItems(inSection: sectionIndex) ?? 0
            guard let scrollViews = self.collectionView?.findScrollViews() else {
                return
            }
            guard let scrollView = scrollViews.findScrollView(at: offset) else {
                return }
            if currentPage == count - 1 {
                scrollView.contentOffset = .init(x: offset.x - itemWidth*CGFloat(count-2), y: offset.y)
            } else if currentPage == 0 {
                scrollView.contentOffset = .init(x: offset.x + itemWidth*CGFloat(count-2), y: offset.y)
            }
        }
        return section
    }
}

extension UICollectionView {
    func findScrollViews() -> [UIScrollView] {
        subviews.compactMap{ $0 as? UIScrollView }
    }
}

extension Array where Element == UIScrollView {
    /// Find current horizontal scroll view by comparing current y offsets of collection view with scroll view
    func findScrollView(at offset: CGPoint) -> UIScrollView? {
        guard !isEmpty else { return nil }
        return first { view in
            round(abs(view.contentOffset.y - offset.y)) == .zero
        }
    }
}
