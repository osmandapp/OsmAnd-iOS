//
//  GalleryPhotoViewerViewController.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 10.02.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import Kingfisher

final class GalleryPhotoViewerViewController: UIViewController {
    
    var cards: [WikiImageCard] = []
    var selectedCard: WikiImageCard!
    
    private var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.prefetchDataSource = self
        collectionView.register(WikiImageFullSizeCell.self, forCellWithReuseIdentifier: WikiImageFullSizeCell.reuseIdentifier)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isPagingEnabled = true
        
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let index = cards.firstIndex(where: { $0 == selectedCard }) {
              let indexPath = IndexPath(item: index, section: 0)
              collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        }
    }
}

final class WikiImageFullSizeCell: UICollectionViewCell {
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        imageView.frame = contentView.bounds
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with model: WikiImageCard) {
        guard let url = URL(string: model.getSuitableUrl()) else { return }
        
        imageView.kf.indicatorType = .activity
        imageView.kf.setImage(
            with: url,
            options: [
                .targetCache(.galleryHighResolutionDiskCache)
            ])
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension GalleryPhotoViewerViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        .init(width: view.frame.width, height: view.frame.height)
    }
}

// MARK: - UICollectionViewDataSource

extension GalleryPhotoViewerViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        cards.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: WikiImageFullSizeCell.reuseIdentifier, for: indexPath) as! WikiImageFullSizeCell
        let model = cards[indexPath.item]
        cell.configure(with: model)
        return cell
    }
}

// MARK: - UICollectionViewDataSourcePrefetching

extension GalleryPhotoViewerViewController: UICollectionViewDataSourcePrefetching {
    
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        let urls = indexPaths.compactMap { indexPath -> URL? in
            let model = cards[indexPath.item]
            return URL(string: model.getSuitableUrl())
        }
     
        guard !urls.isEmpty else { return }
        ImagePrefetcher(urls: urls).start()
    }
}
