//
//  CardsViewController.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 28.01.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class EmptyStateCard: AbstractCard { }

final class CardsViewController: UIView {
    private typealias DataSource = UICollectionViewDiffableDataSource<Section, AbstractCard>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, AbstractCard>
    
    enum Section: Int {
        case bigPhoto, smallPhoto, mapillaryBanner, noInternet, noPhotos
    }
    
    var contentType: CollapsableCardsType = .onlinePhoto
    var didChangeHeightAction: ((Section, Float) -> Void)?
    // swiftlint:disable all
    var сardsFilter: CardsFilter! {
        didSet {
            applySnapshot()
        }
    }
    
    private var dataSource: DataSource!
    private var collectionView: UICollectionView!
    // swiftlint:enable all
    private var imageDataSource: SimpleImageDatasource?
    
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
            guard let self else { return }
            if show {
                clearDataSource()
            }
            collectionView.showActivityIndicator(show: show)
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
            NoImagesCell.reuseIdentifier,
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
    
    private func clearDataSource() {
        dataSource.apply(Snapshot(), animatingDifferences: false)
    }
    
    private func configureContentInset(isEmpty: Bool) {
        collectionView.contentInset = isEmpty ? .zero : .init(top: 0, left: 20, bottom: 0, right: 20)
    }
    
    private func applySnapshot(animatingDifferences: Bool = false) {
        var snapshot = Snapshot()
        var section: Section = .bigPhoto
        if let noInternetCard = сardsFilter.noInternetCard {
            collectionView.isScrollEnabled = false
            configureContentInset(isEmpty: true)
            snapshot.appendSections([.noInternet])
            snapshot.appendItems([noInternetCard])
            section = .noInternet
        } else {
            // Content sections
            configureContentInset(isEmpty: false)
            switch contentType {
            case .onlinePhoto:
                let onlinePhotoCards = сardsFilter.onlinePhotosSection
                if !onlinePhotoCards.isEmpty {
                    collectionView.isScrollEnabled = true
                    snapshot.appendSections([.bigPhoto])
                    snapshot.appendItems([onlinePhotoCards[0]])
                    section = .bigPhoto
                    if onlinePhotoCards.count > 1 {
                        let smallPhotos = Array(onlinePhotoCards.dropFirst())
                        snapshot.appendSections([.smallPhoto])
                        snapshot.appendItems(smallPhotos)
                    }
                } else {
                    collectionView.isScrollEnabled = false
                    configureContentInset(isEmpty: true)
                    snapshot.appendSections([.noPhotos])
                    snapshot.appendItems([EmptyStateCard()])
                    section = .noPhotos
                }
            case .mapillary:
                let mapillaryCards = сardsFilter.mapillaryImageCards
                if !mapillaryCards.isEmpty {
                    collectionView.isScrollEnabled = true
                    snapshot.appendSections([.bigPhoto])
                    snapshot.appendItems([mapillaryCards[0]])
                    section = .bigPhoto
                    if mapillaryCards.count > 1 {
                        let smallPhotos = Array(mapillaryCards.dropFirst())
                        snapshot.appendSections([.smallPhoto])
                        snapshot.appendItems(smallPhotos)
                    }
                    if сardsFilter.hasMapillaryBanner {
                        snapshot.appendSections([.mapillaryBanner])
                        snapshot.appendItems([EmptyStateCard()])
                        section = .mapillaryBanner
                    }
                } else {
                    collectionView.isScrollEnabled = false
                    configureContentInset(isEmpty: true)
                    snapshot.appendSections([.noPhotos])
                    snapshot.appendItems([EmptyStateCard()])
                    section = .noPhotos
                }
            }
        }
        dataSource.applySnapshotUsingReloadData(snapshot) { [weak self] in
            guard let self else { return }
            didChangeHeightAction?(section, contentHeight)
        }
    }
    
    private func makeDataSource() -> DataSource {
        let source = DataSource(collectionView: collectionView) { [weak self] collectionView, indexPath, item -> UICollectionViewCell in
            guard let self else { return UICollectionViewCell() }
            let section = dataSource.snapshot().sectionIdentifiers[indexPath.section]
            switch section {
            case .noInternet:
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: NoInternetCardCell.reuseIdentifier,
                    for: indexPath) as? NoInternetCardCell else { fatalError("Cannot create new cell NoInternetCardCell") }
                if let item = item as? NoInternetCard {
                    cell.configure(item: item)
                }
                return cell
            case .bigPhoto, .smallPhoto:
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: ImageCardCell.reuseIdentifier,
                    for: indexPath) as? ImageCardCell else { fatalError("Cannot create new cell ImageCardCell") }
                if let item = item as? ImageCard {
                    cell.configure(item: item, showLogo: section == .bigPhoto)
                }
                return cell
            case .mapillaryBanner:
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: MapillaryContributeCell.reuseIdentifier,
                    for: indexPath) as? MapillaryContributeCell else { fatalError("Cannot create new cell MapillaryContributeCell") }
                return cell
            case .noPhotos:
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: NoImagesCell.reuseIdentifier,
                    for: indexPath) as? NoImagesCell else { fatalError("Cannot create new cell NoImagesCell") }
                cell.showAddPhotosButton(contentType == .mapillary)
                return cell
            }
        }
        return source
    }
}

// MARK: - UICollectionViewDelegate

extension CardsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let card = dataSource.itemIdentifier(for: indexPath) else { return }
        
        if card is WikiImageCard {
            let wikiCards = dataSource.snapshot().itemIdentifiers.compactMap { $0 as? WikiImageCard }
            guard let initialIndex = wikiCards.firstIndex(where: { $0 === card }) else { return }
            let imageDataSource = SimpleImageDatasource(imageItems: wikiCards.compactMap { ImageItem.card($0) })
            let imageCarouselController = ImageCarouselViewController(imageDataSource: imageDataSource, initialIndex: initialIndex)
            
            let navController = UINavigationController(rootViewController: imageCarouselController)
            navController.modalPresentationStyle = .custom
            navController.modalPresentationCapturesStatusBarAppearance = true
            OARootViewController.instance().mapPanel?.navigationController?.present(navController, animated: true)
        } else {
            card.onCardPressed(OARootViewController.instance().mapPanel)
        }
    }
}

// MARK: - NSCollectionLayoutSection

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
        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .absolute(smallCellWidth),
            heightDimension: .absolute(156))
        
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: groupSize,
            subitem: item, count: 2
        )
        
        let spacing: CGFloat = 12
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

// MARK: - ContentHeight

fileprivate extension CardsViewController {
    var contentHeight: Float {
        guard let cell = collectionView.visibleCells.compactMap({ $0 as? CellHeightDelegate }).first else {
            return 156.0
        }
        return cell.height()
    }
}

// MARK: - UICollectionView

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
