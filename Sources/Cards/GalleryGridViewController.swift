//
//  GalleryGridViewController.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 03.02.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import Kingfisher

final class GalleryGridViewController: OABaseNavbarViewController {
    private enum Constants {
        static let minColumnCount: Int = 2
        static let maxColumnCount: Int = 7
        static let pinchThreshold: CGFloat = 0.2
        static let visibleCellsUpdateDelay: TimeInterval = 0.5
    }
    var cards: [AbstractCard] = []
    var titleString: String = ""
    var placeholderImage: UIImage?
    lazy var downloadImageMetadataService = DownloadImageMetadataService.shared
    // swiftlint:disable all
    private var collectionView: UICollectionView!
    // swiftlint:enable all
    
    private var visibleCellsUpdateTimer: Timer?
    
    private var initialPinchColumnCount: Int = 3
    
    private var currentColumnCount: Int = 3 {
        didSet {
            let value = Int32(currentColumnCount)
            if OAUtilities.isLandscape() || OAUtilities.isiOSAppOnMac() {
                OAAppSettings.sharedManager().contextGallerySpanGridCountLandscape.set(value)
            } else {
                OAAppSettings.sharedManager().contextGallerySpanGridCount.set(value)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        currentColumnCount = columnCountForCurrentOrientation()
        initialPinchColumnCount = currentColumnCount
        configureCollectionView()
        downloadImageMetadataService.cards = cards.compactMap { $0 as? WikiImageCard }
        Task {
            await downloadImageMetadataService.downloadMetadataForAllCards()
        }
    }
    
    deinit {
        ImageCache.onlinePhotoAndMapillaryDefaultCache.clearMemoryCache()
    }
    
    override func getTitle() -> String {
        titleString
    }
    
    override func onRotation() {
        currentColumnCount = columnCountForCurrentOrientation()
        collectionView.setCollectionViewLayout(createCompositionalLayout(), animated: true) { [weak self] finished in
            guard finished else { return }
            self?.updateVisibleCells()
        }
    }
    
    private func columnCountForCurrentOrientation() -> Int {
        if OAUtilities.isLandscape() || OAUtilities.isiOSAppOnMac() {
            return Int(OAAppSettings.sharedManager().contextGallerySpanGridCountLandscape.get())
        } else {
            return Int(OAAppSettings.sharedManager().contextGallerySpanGridCount.get())
        }
    }
    
    private func configureCollectionView() {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: createCompositionalLayout())
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(GalleryCell.self, forCellWithReuseIdentifier: GalleryCell.reuseIdentifier)
        collectionView.register(TitleHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: TitleHeaderView.reuseIdentifier)
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        collectionView.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:))))
    }
    
    private func updateVisibleCells() {
        collectionView.indexPathsForVisibleItems.forEach { indexPath in
            guard indexPath.item < cards.count,
                  let cell = collectionView.cellForItem(at: indexPath) as? GalleryCell else { return }
            cell.configure(with: cards[indexPath.item])
        }
    }
    
    private func createCompositionalLayout() -> UICollectionViewLayout {
        let columns = max(Constants.minColumnCount, min(Constants.maxColumnCount, currentColumnCount))
        
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0 / CGFloat(columns)),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = .init(top: 0, leading: 3, bottom: 6, trailing: 3)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalWidth(1.0 / CGFloat(columns))
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 17, bottom: 0, trailing: 17)
        
        section.boundarySupplementaryItems = [
            NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(44)),
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top)
        ]
        
        return UICollectionViewCompositionalLayout(section: section)
    }
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .began:
            initialPinchColumnCount = currentColumnCount
            visibleCellsUpdateTimer?.invalidate()
        case .changed:
            let newColumnCount = CGFloat(initialPinchColumnCount) / gesture.scale
            let clampedColumnCount = CGFloat(max(Constants.minColumnCount,
                                                 min(Constants.maxColumnCount, Int(newColumnCount))))
            
            if abs(clampedColumnCount - CGFloat(currentColumnCount)) > Constants.pinchThreshold {
                currentColumnCount = Int(clampedColumnCount)
                collectionView.setCollectionViewLayout(createCompositionalLayout(), animated: false)
                
                visibleCellsUpdateTimer?.invalidate()
                visibleCellsUpdateTimer = Timer.scheduledTimer(withTimeInterval: Constants.visibleCellsUpdateDelay, repeats: false) { [weak self] _ in
                    self?.updateVisibleCells()
                }
            }
        case .ended, .cancelled:
            currentColumnCount = Int(currentColumnCount)
            collectionView.setCollectionViewLayout(createCompositionalLayout(), animated: true)
        default:
            break
        }
    }
}

// MARK: - UICollectionViewDataSource

extension GalleryGridViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        cards.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GalleryCell.reuseIdentifier, for: indexPath) as! GalleryCell
        cell.placeholderImage = placeholderImage
        cell.configure(with: cards[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                             withReuseIdentifier: TitleHeaderView.reuseIdentifier,
                                                                             for: indexPath)
            
            guard let typedHeaderView = headerView as? TitleHeaderView else { return headerView }
            
            let text = "\(cards.count) \(localizedString("shared_string_items"))"
            typedHeaderView.configure(with: text)
            return typedHeaderView
        default:
            return UICollectionReusableView()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? GalleryCell else { return }
        cell.cancelDownloadTask()
    }
}

// MARK: - UICollectionViewDelegate

extension GalleryGridViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let itemsCards = cards.compactMap { $0 as? ImageCard }
        guard indexPath.row < itemsCards.count else { return }
        
        let card = itemsCards[indexPath.row]
        
        guard let initialIndex = itemsCards.firstIndex(where: { $0 === card }) else { return }
        let imageDataSource = SimpleImageDatasource(imageItems: itemsCards.compactMap { ImageItem.card($0) }, placeholderImage: placeholderImage)
        let imageCarouselController = ImageCarouselViewController(imageDataSource: imageDataSource, title: titleString, initialIndex: initialIndex)
        
        let navController = UINavigationController(rootViewController: imageCarouselController)
        navController.modalPresentationStyle = .custom
        navController.modalTransitionStyle = .crossDissolve
        navController.modalPresentationCapturesStatusBarAppearance = true
        OARootViewController.instance().mapPanel?.navigationController?.present(navController, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        contextMenuConfigurationForItemAt indexPath: IndexPath,
                        point: CGPoint) -> UIContextMenuConfiguration? {
        contextMenuInteraction(with: cards[indexPath.row])
    }
    
    private func contextMenuInteraction(with card: AbstractCard) -> UIContextMenuConfiguration? {
        let actionProvider: UIContextMenuActionProvider = { [weak self] _ in
            guard let self else { return nil }
            var firstSectionItems = [UIAction]()
            if card is WikiImageCard {
                let detailsAction = UIAction(title: localizedString("shared_string_details"), image: .icCustomInfoOutlined) { _ in
                    GalleryContextMenuProvider.openDetailsController(card: card, rootController: self)
                }
                detailsAction.accessibilityLabel = localizedString("shared_string_details")
                firstSectionItems.append(detailsAction)
            }
            
            let openInBrowserAction = UIAction(title: localizedString("open_in_browser"), image: .icCustomExternalLink) { _ in
                SafariPresenter.present(from: self, card: card)
            }
            openInBrowserAction.accessibilityLabel = localizedString("open_in_browser")
            
            firstSectionItems.append(openInBrowserAction)
            
            let firstSection = UIMenu(title: "", options: .displayInline, children: firstSectionItems)
            let downloadAction = UIAction(title: localizedString("shared_string_download"), image: .icCustomDownload) { _ in
                guard let item = card as? ImageCard,
                      !item.imageUrl.isEmpty else { return }
                GalleryContextMenuProvider.downloadImage(urlString: item.imageUrl,
                                                         view: self.view,
                                                         cache: .onlinePhotoAndMapillaryDefaultCache)
            }
            downloadAction.accessibilityLabel = localizedString("shared_string_download")
            let secondSection = UIMenu(title: "", options: .displayInline, children: [downloadAction])
            return UIMenu(title: "", image: nil, children: [firstSection, secondSection])
        }
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: actionProvider)
    }
}

// MARK: - GalleryCell

final private class GalleryCell: UICollectionViewCell {
    
    var placeholderImage: UIImage?
    
    private let imageView = UIImageView()
    private let offlineCacheImageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .viewBg
        contentView.addSubview(imageView)
        
        offlineCacheImageView.translatesAutoresizingMaskIntoConstraints = false
        offlineCacheImageView.contentMode = .scaleAspectFit
        offlineCacheImageView.image = .icCustomDownloadOfflineWithBg
        offlineCacheImageView.isHidden = true
        contentView.addSubview(offlineCacheImageView)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            offlineCacheImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 6),
            offlineCacheImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            offlineCacheImageView.widthAnchor.constraint(equalToConstant: 30),
            offlineCacheImageView.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - PrepareForReuse
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.kf.cancelDownloadTask()
        imageView.image = nil
        offlineCacheImageView.isHidden = true
    }
    
    // MARK: - Configure
    
    func configure(with card: AbstractCard) {
        guard let item = card as? ImageCard else { return }
        guard !item.imageUrl.isEmpty,
              let url = URL(string: item.imageUrl) else { return }
        
        let cache = ImageCache.onlinePhotoAndMapillaryDefaultCache
        let isCached = cache.isCached(forKey: url.absoluteString)
        let imageCardPlaceholder = ImageCardPlaceholder(placeholderImage: placeholderImage, shouldShowPlaceholder: !isCached)
        
        imageView.kf.indicatorType = isCached ? .none : .activity
        imageView.kf.setImage(
            with: url,
            placeholder: imageCardPlaceholder,
            options: [
                .targetCache(cache),
                .requestModifier(ImageDownloadRequestModifier()),
                .processor(DownsamplingImageProcessor(size: bounds.size)),
                .scaleFactor(UIScreen.main.scale),
                .cacheOriginalImage
            ]) { [weak self] result in
                switch result {
                case .success:
                    self?.offlineCacheImageView.isHidden = AFNetworkReachabilityManagerWrapper.isReachable()
                case .failure:
                    self?.offlineCacheImageView.isHidden = true
                }
            }
    }
    
    func cancelDownloadTask() {
        imageView.kf.cancelDownloadTask()
    }
}

final private class TitleHeaderView: UICollectionReusableView {
    private let titleLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        titleLabel.textColor = .textColorSecondary
        titleLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 3),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with text: String) {
        titleLabel.text = text
    }
}

struct WikiImageInfo: Codable {
    var title: String
    var pageId: Int
    var data: String?
}
