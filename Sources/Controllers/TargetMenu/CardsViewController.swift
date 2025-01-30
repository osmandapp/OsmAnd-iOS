//
//  CardsViewController.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 28.01.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class CardsViewController: UIView, UICollectionViewDelegate {
    private typealias DataSource = UICollectionViewDiffableDataSource<Section, Int>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Int>
    
    enum Section: Int {
        case bigPhoto, smallPhoto, mapillaryBanner, noInternet, noPhotos
    }
    
    var contentType: CollapsableCardsType = .onlinePhoto
    var didChangeHeightAction: ((Section, Float) -> Void)?
    
    var cards: [AbstractCard] = [] {
        didSet {
            applySnapshot()
        }
    }
    // swiftlint:disable superfluous_disable_command trailing_newline
    private var dataSource: DataSource!
    private var collectionView: UICollectionView!
    // swiftlint:enable superfluous_disable_command trailing_newline
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureCollectionView()
        registerCels()
        dataSource = makeDataSource()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func reloadData() {
        applySnapshot()
    }
    
    func showSpinner(show: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.collectionView.showActivityIndicator(show: show)
        }
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { [weak self] sectionNumber, _ -> NSCollectionLayoutSection? in
            guard let self else { return nil }
            let section = dataSource.snapshot().sectionIdentifiers[sectionNumber]
            switch section {
            case .bigPhoto:
                return .listSection()
            case .smallPhoto:
                return .gridSection()
            case .mapillaryBanner:
                return .bannerSection()
            case .noInternet, .noPhotos:
                return .emptySection()
            }
        }
        
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .horizontal
        config.interSectionSpacing = 12
        layout.configuration = config
        
        return layout
    }
    
    private func registerCels() {
        [
            ImageCard.getCellNibId(),
            NoImagesCard.getCellNibId(),
            NoInternetCard.getCellNibId(),
            MapillaryContributeCard.getCellNibId()
        ].forEach { collectionView.register(UINib(nibName: $0, bundle: nil), forCellWithReuseIdentifier: $0) }
    }
    
    private func configureCollectionView() {
        collectionView = UICollectionView(frame: bounds, collectionViewLayout: createLayout())
        collectionView.delegate = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    private func applySnapshot(animatingDifferences: Bool = false) {
        var snapshot = Snapshot()
        var section: Section = .bigPhoto
        if isNoInternetState {
            snapshot.appendSections([.noInternet])
            snapshot.appendItems([0])
            section = .noInternet
        } else if cards.isEmpty {
            snapshot.appendSections([.noPhotos])
            snapshot.appendItems([0])
            section = .noPhotos
        } else {
            // Content sections
            //
            
            //
            
            if hasMapillaryBanner {
                snapshot.appendSections([.mapillaryBanner])
                snapshot.appendItems([0])
                section = .mapillaryBanner
            }
        }
        
        dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
        didChangeHeightAction?(section, contentHeight)
    }
    
    private func makeDataSource() -> DataSource {
        let source = DataSource(collectionView: collectionView) { [weak self] collectionView, indexPath, _ -> UICollectionViewCell in
            guard let self else { return UICollectionViewCell() }
            let section = dataSource.snapshot().sectionIdentifiers[indexPath.section]
            switch section {
            case .noInternet:
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: NoInternetCardCell.reuseIdentifier,
                    for: indexPath) as? NoInternetCardCell else { fatalError("Cannot create new cell NoInternetCardCell") }
                collectionView.isScrollEnabled = false
                if let item = cards[indexPath.row] as? NoInternetCard {
                    cell.configure(item: item)
                }
                return cell
            case .bigPhoto:
                fatalError("bigPhoto")
            case .smallPhoto:
                fatalError("smallPhoto")
            case .mapillaryBanner:
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: MapillaryContributeCell.reuseIdentifier,
                    for: indexPath) as? MapillaryContributeCell else { fatalError("Cannot create new cell MapillaryContributeCell") }
                collectionView.isScrollEnabled = true
                return cell
            case .noPhotos:
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: NoImagesCell.reuseIdentifier,
                    for: indexPath) as? NoImagesCell else { fatalError("Cannot create new cell NoImagesCell") }
                collectionView.isScrollEnabled = false
                cell.showAddPhotosButton(contentType == .mapilary)
                return cell
            }
            
            return UICollectionViewCell()
        }
        return source
    }
}

fileprivate extension NSCollectionLayoutSection {
    static func emptySection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .fractionalHeight(1.0))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                       subitems: [item])
        return NSCollectionLayoutSection(group: group)
    }
    
    static func listSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(widthDimension: .absolute(156),
                                               heightDimension: .absolute(156))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                       subitems: [item])
        return NSCollectionLayoutSection(group: group)
    }
    
    static func bannerSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(widthDimension: .absolute(240),
                                               heightDimension: .absolute(156))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                       subitems: [item])
        return NSCollectionLayoutSection(group: group)
    }
    
    static func gridSection() -> NSCollectionLayoutSection {
        let smallCellWidth = 72.0
        
        let itemSize = NSCollectionLayoutSize(widthDimension: .absolute(smallCellWidth),
                                              heightDimension: .absolute(smallCellWidth))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let spacing: CGFloat = 12
        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .absolute(smallCellWidth),
            heightDimension: .absolute(156))
        
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: groupSize,
            subitem: item, count: 2
        )
        
        group.interItemSpacing = .fixed(spacing)
        
        let horizontalGroup = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .estimated(1.0),
                heightDimension: .absolute(156)),
            subitems: [group]
        )
        
        let section = NSCollectionLayoutSection(group: horizontalGroup)
        section.interGroupSpacing = 12
        
        return section
    }
}

fileprivate extension CardsViewController {
    var isNoInternetState: Bool {
        cards.contains { $0 is NoInternetCard }
    }
    
    var hasPhoto: Bool {
        cards.contains {
            guard let item = $0 as? ImageCard else { return false }
            return item.key.isEmpty
        }
    }
    
    var hasMapillaryBanner: Bool {
        cards.contains { $0 is MapillaryContributeCard }
    }
    
    var contentHeight: Float {
        guard let cell = collectionView.visibleCells.compactMap({ $0 as? CellHeightDelegate }).first else {
            return 156.0
        }
        return cell.height()
    }
}

fileprivate extension UICollectionView {
    func showActivityIndicator(show: Bool) {
        if show {
            let indicator = UIActivityIndicatorView(style: .large)
            indicator.hidesWhenStopped = true
            backgroundView = indicator
            indicator.startAnimating()
        } else {
            if let indicator = backgroundView as? UIActivityIndicatorView {
                indicator.stopAnimating()
                indicator.removeFromSuperview()
            }
        }
    }
}
