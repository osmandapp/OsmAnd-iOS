//
//  GalleryGridViewController.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 03.02.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import Kingfisher

final class GalleryGridViewController: OABaseNavbarViewController {
    
    var cards: [AbstractCard] = []
    var titleString: String = ""
    
    private var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureCollectionView()
    }
    
    override func getTitle() -> String {
        titleString
    }
    
    override func onRotation() {
        collectionView.setCollectionViewLayout(createCompositionalLayout(), animated: true)
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
    }
    
    private func createCompositionalLayout() -> UICollectionViewLayout {
        let columns = UIDevice.current.orientation.isLandscape
        ? OAAppSettings.sharedManager().contextGallerySpanGridCountLandscape.get()
        : OAAppSettings.sharedManager().contextGallerySpanGridCount.get()
        
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0 / CGFloat(columns)), heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = .init(top: 0, leading: 3, bottom: 6, trailing: 3)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalWidth(1.0 / CGFloat(columns)))
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
}

// MARK: - UICollectionViewDataSource
extension GalleryGridViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        cards.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GalleryCell.reuseIdentifier, for: indexPath) as! GalleryCell
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
            
            let text = "\(cards.count)" + " " + localizedString("shared_string_items")
            typedHeaderView.configure(with: text)
            return typedHeaderView
        default: assert(false, "Invalid element type")
        }
    }
}

// MARK: - UICollectionViewDelegate
extension GalleryGridViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView,
                        contextMenuConfigurationForItemAt indexPath: IndexPath,
                        point: CGPoint) -> UIContextMenuConfiguration? {
        contextMenuInteraction(with: cards[indexPath.row])
    }
    
    private func contextMenuInteraction(with card: AbstractCard) -> UIContextMenuConfiguration? {
        let actionProvider: UIContextMenuActionProvider = { [weak self] _ in
            let detailsAction = UIAction(title: localizedString("shared_string_details"), image: UIImage.icCustomInfoOutlined) { _ in
                guard let self else { return }
                GalaryContextMenuProvider.openDetailsController(card: card, rootController: self)
            }
            detailsAction.accessibilityLabel = localizedString("shared_string_details")
            let openInBrowserAction = UIAction(title: localizedString("open_in_browser"), image: UIImage.icCustomExternalLink) { _ in
                if let item = card as? WikiImageCard {
                    item.opneURL(OARootViewController.instance().mapPanel)
                } else {
                    guard let item = card as? ImageCard else { return }
                    GalaryContextMenuProvider.openURLIfValid(urlString: item.imageUrl)
                }
            }
            openInBrowserAction.accessibilityLabel = localizedString("open_in_browser")
            let firsrSection = UIMenu(title: "", options: .displayInline, children: [detailsAction, openInBrowserAction ])
            let downloadAction = UIAction(title: localizedString("shared_string_download"), image: UIImage.icCustomDownload) { _ in
                guard let self else { return }
                guard let item = card as? ImageCard,
                      !item.imageUrl.isEmpty else { return }
                GalaryContextMenuProvider.downloadImageAndSaveToDocumentsDownload(urlString: item.imageUrl, view: self.view)
            }
            downloadAction.accessibilityLabel = localizedString("shared_string_download")
            let secondSection = UIMenu(title: "", options: .displayInline, children: [downloadAction])
            return UIMenu(title: "", image: nil, children: [firsrSection, secondSection])
        }
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: actionProvider)
    }
}

// MARK: - GalleryCell
final private class GalleryCell: UICollectionViewCell {
    
    private let imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with card: AbstractCard) {
        guard let item = card as? ImageCard else { return }
        guard !item.imageUrl.isEmpty,
              let url = URL(string: item.imageUrl) else { return }
        
        imageView.kf.indicatorType = .activity
        imageView.kf.setImage(
            with: url,
            placeholder: nil,
            options: [
                .processor(DownsamplingImageProcessor(size: imageView.bounds.size)),
                .scaleFactor(UIScreen.main.scale),
                .cacheOriginalImage
            ])
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
