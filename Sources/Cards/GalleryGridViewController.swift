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
        let columns: Int
        if UIDevice.current.orientation.isLandscape {
            columns = 7
        } else {
            columns = 3
        }
        
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
                print("detailsAction")
            }
            detailsAction.accessibilityLabel = localizedString("shared_string_details")
            let openInBrowserAction = UIAction(title: localizedString("open_in_browser"), image: UIImage.icCustomExternalLink) { _ in
                if let item = card as? WikiImageCard {
                    item.opneURL(OARootViewController.instance().mapPanel)
                } else {
                    guard let item = card as? ImageCard else { return }
                    self?.openURLIfValid(urlString: item.imageUrl)
                }
            }
            openInBrowserAction.accessibilityLabel = localizedString("open_in_browser")
            let firsrSection = UIMenu(title: "", options: .displayInline, children: [detailsAction, openInBrowserAction ])
            let downloadAction = UIAction(title: localizedString("shared_string_download"), image: UIImage.icCustomDownload) { _ in
                guard let item = card as? ImageCard,
                      !item.imageUrl.isEmpty else { return }
                self?.downloadImageAndSaveToDocumentsDownload(urlString: item.imageUrl)
            }
            downloadAction.accessibilityLabel = localizedString("shared_string_download")
            let secondSection = UIMenu(title: "", options: .displayInline, children: [downloadAction])
            return UIMenu(title: "", image: nil, children: [firsrSection, secondSection])
        }
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: actionProvider)
    }
    
    private func openURLIfValid(urlString: String?) {
        guard let urlString, !urlString.isEmpty,
              let url = URL(string: urlString),
              UIApplication.shared.canOpenURL(url) else { return }
        
        UIApplication.shared.open(url)
    }

    private func downloadImageAndSaveToDocumentsDownload(urlString: String) {
        guard let url = URL(string: urlString) else {
            NSLog("Invalid URL.")
            return
        }
        
        // Download the image data from the URL
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self else { return }
            guard let data, error == nil else {
                NSLog("Error downloading data: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            // Get the path to the Documents folder
            let fileManager = FileManager.default
            guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
                NSLog("Could not get Documents directory.")
                return
            }
            
            // Create a "Download" subdirectory inside Documents
            let downloadDirectory = documentsDirectory.appendingPathComponent("Download")
            
            // Create the "Download" directory if it doesn't exist
            if !fileManager.fileExists(atPath: downloadDirectory.path) {
                do {
                    try fileManager.createDirectory(at: downloadDirectory, withIntermediateDirectories: true, attributes: nil)
                    NSLog("Download directory created at: \(downloadDirectory.path)")
                } catch {
                    NSLog("Error creating Download directory: \(error.localizedDescription)")
                    return
                }
            }
            
            // Create the full file URL in the "Download" folder
            let fileURL = downloadDirectory.appendingPathComponent(url.lastPathComponent)
            do {
                // Save the image data as a file in the "Download" folder
                try data.write(to: fileURL)
                DispatchQueue.main.async {
                    OAUtilities.showToast(localizedString("download_successful"), details: nil, duration: 4, in: self.view)
                }
                NSLog("File successfully saved at: \(fileURL.path)")
            } catch {
                DispatchQueue.main.async {
                    OAUtilities.showToast(localizedString("download_failed"), details: nil, duration: 4, in: self.view)
                }
                NSLog("Error saving file: \(error.localizedDescription)")
            }
        }.resume()
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
