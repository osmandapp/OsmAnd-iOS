//
//  GalleryPhotoViewerViewController.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 10.02.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import Kingfisher

final class GalleryPhotoViewerViewController: OABaseNavbarViewController, UICollectionViewDelegate {
    
    var cards: [WikiImageCard] = []
    var selectedCard: WikiImageCard!
    var currentCard: WikiImageCard?
    var isFirstLaunch = true
    var lastContentOffsetX: CGFloat = 0
    
  //  private var carouselSections: [Int: CarouselSection] = [:]
    private var carouselSection: CarouselSection?
    
    private var collectionView: UICollectionView!
    private var contentMetadataView: ContentMetadataView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        isFirstLaunch = true
        tableView.removeFromSuperview()
        configureCollectionView()
        configureContentMetadataView()
        addGestureRecognizers()
      //  automaticallyAdjustsScrollViewInsets = false
       // edgesForExtendedLayout = []
    }
    
    private func configureContentMetadataView() {
        contentMetadataView = ContentMetadataView()
        contentMetadataView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentMetadataView)
        
        NSLayoutConstraint.activate([
            contentMetadataView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            contentMetadataView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentMetadataView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentMetadataView.heightAnchor.constraint(equalToConstant: 112)
        ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isFirstLaunch {
            isFirstLaunch = false
//            if let index = cards.firstIndex(where: { $0 == selectedCard }) {
//                lastContentOffsetX = view.frame.width * CGFloat(index)
//            }
           
           collectionView.layoutIfNeeded()
            scrollToSelectedItem()
            prefetchAdjacentItems()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        carouselSection?.isEnabledVisibleItemsInvalidationHandler = true
    }
    
    override func getTitle() -> String {
        if let currentCard {
            return currentCard.title
        } else {
            return selectedCard.title
        }
    }
    
//    private func createCompositionalLayout() -> UICollectionViewLayout {
//        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
//        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
//        let item = NSCollectionLayoutItem(layoutSize: itemSize)
//        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
//        
//        let section = NSCollectionLayoutSection(group: group)
//        section.orthogonalScrollingBehavior = .paging
//        
////        section.visibleItemsInvalidationHandler = { [weak self] (visibleItems, offset, environment) in
////            guard let self else { return }
////            let items = visibleItems.filter { $0.representedElementKind == nil} /// Filter supplementary views out
////            let width = environment.container.effectiveContentSize.width
////            let itemWidth = width * itemScale
////            let itemOffset = (width - itemWidth) / 2
////            let xOffset = offset.x + itemOffset
////            items.forEach { item in
////                let distanceFromCenter = abs((item.frame.midX - offset.x) - width / 2.0)
////                let minScale: CGFloat = 0.9
////                let scale: CGFloat = minScale + (1.0 - minScale) * exp(-distanceFromCenter / (itemWidth / 2))
////                self.scales[item.indexPath] = scale
////                guard let cell = self.collectionView?.cellForItem(at: item.indexPath) else { return }
////                self.applyTransform(to: cell, at: item.indexPath)
////            }
////            let currentPage = Int((xOffset / itemWidth).rounded())
////            updatePageControl(with: currentPage)
////        }
//        
//        
////        section.visibleItemsInvalidationHandler = { [weak self] visibleItems, offset, _ in
////            guard let self else { return }
////            let page = round(offset.x / view.bounds.width)
////            guard let firstVisibleItem = visibleItems.first else { return }
////               
////               // Получаем индекс текущей страницы
////               let currentPageIndex = firstVisibleItem.indexPath.item
////            debugPrint("Тек. Стран: \(currentPageIndex)")
////            updatePage(Int(page))
////        }
//        
//        return UICollectionViewCompositionalLayout(section: section)
//    }
    
    private lazy var layout: UICollectionViewLayout = UICollectionViewCompositionalLayout { [weak self] sectionIndex, layoutEnvironment in
        guard let self else { return nil }
     //   guard let sectionItem = self.dataSource.sectionIdentifier(for: sectionIndex) else { return nil }

        // Ensure that we are checking if a carouselSection already exists
        
        if carouselSection == nil {
            // Create a new carouselSection if none exists
            carouselSection = CarouselSection(collectionView: self.collectionView)
            carouselSection?.isEnabledVisibleItemsInvalidationHandler = false
            carouselSection?.didUpdatePage = { page in
                print(page)
                if page > 0 {
                   // self.pagerDots[sectionItem]?.update(currentPage: page)
                }
            }
        }

        // Return the layout configuration for the section
        return carouselSection?.layoutSection(for: sectionIndex, layoutEnvironment: layoutEnvironment)
    }
    
    private func configureCollectionView() {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.prefetchDataSource = self
        collectionView.register(WikiImageFullSizeCell.self, forCellWithReuseIdentifier: WikiImageFullSizeCell.reuseIdentifier)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isPagingEnabled = true
       // collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.backgroundColor = .black
        
        //contentInsetAdjustmentBehavior = .never
        
        view.addSubview(collectionView)
        
     //   let top = UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 0

        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
    }
    
//    func updateNavigationBarVisibility() {
//        let isNavigationBarHidden = navigationController?.isNavigationBarHidden ?? false
//        
//        // Adjust the contentInset of the collection view based on navigation bar visibility
//        if isNavigationBarHidden {
//            // If the navigation bar is hidden, add padding to the top of the collection view
//            collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
//        } else {
//            // If the navigation bar is visible, adjust the top inset accordingly
//            let statusBarHeight = UIApplication.shared.statusBarFrame.height
//            collectionView.contentInset = UIEdgeInsets(top: statusBarHeight + (navigationController?.navigationBar.frame.height ?? 0), left: 0, bottom: 0, right: 0)
//        }
//        
//        // If you're changing visibility of the navigation bar during a scroll, ensure the content is updated
//        collectionView.setContentOffset(collectionView.contentOffset, animated: false)
//    }
    
    private func addGestureRecognizers() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapCollectionView))
        collectionView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    private func scrollToSelectedItem() {
        guard let index = cards.firstIndex(where: { $0 == selectedCard }) else { return }
        let indexPath = IndexPath(item: index, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        contentMetadataView.updateMetadata(with: selectedCard.metadata, imageName: selectedCard.topIcon)
    }
    
    private func prefetchAdjacentItems() {
        guard let currentIndex = cards.firstIndex(where: { $0 == selectedCard }) else { return }
        
        let previousIndex = currentIndex == 0 ? cards.count - 1 : currentIndex - 1
        let nextIndex = currentIndex == cards.count - 1 ? 0 : currentIndex + 1
        
        let urls = [previousIndex, nextIndex].compactMap { index -> URL? in
            guard index >= 0 && index < cards.count else { return nil }
            let model = cards[index]
            guard let fullSizeUrl = model.getGalleryFullSizeUrl(), let url = URL(string: fullSizeUrl) else {
                return nil
            }
            return url
        }
        
        prefetcher(with: urls)
    }
    
    private func prefetcher(with urls: [URL]) {
        guard !urls.isEmpty else { return }
        ImagePrefetcher(urls: urls, options: [ .targetCache(.galleryHighResolutionDiskCache)]).start()
    }
    
    @objc private func didTapCollectionView() {
        let isHidden = navigationController?.navigationBar.isHidden ?? false
        navigationController?.setNavigationBarHidden(!isHidden, animated: true)
        
        showContentMetadataView(show: isHidden)
    }
    
    private func showContentMetadataView(show: Bool) {
        UIView.animate(withDuration: 0.25, animations: {
            self.contentMetadataView.alpha = show ? 1.0 : 0.0
            self.contentMetadataView.transform = !show ? .init(translationX: 0, y: 113) : .identity
        })
    }
    
    private func updatePage(_ page: Int) {
        let card = cards[page]
        if card !== currentCard {
            currentCard = cards[page]
            debugPrint("Current page: \(page)")
            if let currentCard {
                contentMetadataView.updateMetadata(with: currentCard.metadata, imageName: currentCard.topIcon)
                applyLocalization()
            }
        }
    }
    
//    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
//        super.viewWillTransition(to: size, with: coordinator)
////        guard let flowLayout = collectionView.collectionViewLayout as? UICollectionViewLayout else {
////            return
////        }
//        collectionView.collectionViewLayout.invalidateLayout()
//    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
          super.viewWillTransition(to: size, with: coordinator)
        //  lastContentOffsetX = collectionView.contentOffset.x
      }
    
    override func viewDidLayoutSubviews() {
         super.viewDidLayoutSubviews()
         
         // Рассчитываем текущую страницу на основе lastContentOffsetX
        // let pageWidth = collectionView.frame.width
      //   let currentPage = Int(lastContentOffsetX / pageWidth)
        
     //   let obj = selectedCard ?? currentCard
       // self.collectionView.layoutIfNeeded()
        
//        if let index = cards.firstIndex(where: { $0 == obj }) {
//            DispatchQueue.main.async {
//                let indexPath = IndexPath(item: index, section: 0)
//                self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
//            }
////            DispatchQueue.main.async {
////                //self.collectionView.setContentOffset(CGPoint(x: CGFloat(index) * pageWidth, y: 0), animated: false)
////            }
//        }
         
         // Перемещаем коллекцию на нужную страницу
       //  collectionView.setContentOffset(CGPoint(x: CGFloat(currentPage) * pageWidth, y: 0), animated: false)
     }
    
//    override func viewWillLayoutSubviews() {
//        super.viewWillLayoutSubviews()
//            
////        guard let columnLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
////            return
////        }
//    //    collectionView.collectionViewLayout.invalidateLayout()
//    }
//    
//    override func onRotation() {
//        collectionView.setCollectionViewLayout(createCompositionalLayout(), animated: true)
//    }
    
    deinit {
        print("GalleryPhotoViewerViewController deinit")
    }
}

// MARK: - UICollectionViewDataSource

extension GalleryPhotoViewerViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        cards.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: WikiImageFullSizeCell.reuseIdentifier, for: indexPath) as? WikiImageFullSizeCell else { fatalError("Could not dequeue a WikiImageFullSizeCell") }
        
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
            guard let fullSizeUrlString = model.getGalleryFullSizeUrl(),
                  let url = URL(string: fullSizeUrlString) else {
                return nil
            }
            return url
        }
        
        prefetcher(with: urls)
    }
}

extension GalleryPhotoViewerViewController {

    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // Получаем текущий индекс видимой страницы
        let visibleIndex = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
        
        print("Current page index: \(visibleIndex)")
    }

    // Этот метод срабатывает после того, как анимация прокрутки завершена.
    override func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        let visibleIndex = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
        
        print("Current page index: \(visibleIndex)")
    }
}
