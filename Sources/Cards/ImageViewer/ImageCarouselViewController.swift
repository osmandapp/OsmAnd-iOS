import Kingfisher

protocol ImageDataSource: AnyObject {
    func count() -> Int
    func imageItem(at index: Int) -> ImageItem
}

final class ImageCarouselViewController: UIPageViewController {
    // swiftlint:disable all
    private(set) var contentMetadataView: ContentMetadataView!
    // swiftlint:enable all
    
    private let imageDatasource: ImageDataSource?
    
    private var initialIndex = 0
    private var currentIndex = 0
    private let gradientLayer = CAGradientLayer()
    private let metadataContainerView = UIView()
    
    private lazy var downloadImageMetadataService = DownloadImageMetadataService.shared
    
    // MARK: - init
    init(imageDataSource: ImageDataSource?,
         initialIndex: Int = 0) {
        self.initialIndex = initialIndex
        self.currentIndex = initialIndex
        self.imageDatasource = imageDataSource
        
        super.init(transitionStyle: .scroll,
                   navigationOrientation: .horizontal,
                   options: [UIPageViewController.OptionsKey.interPageSpacing: 20])
        delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        configureNavigationBar()
        updateTitle(with: initialIndex)
        configureContentMetadataView()
        downloadMetadataIfNeeded()
        prefetchAdjacentItems()
        
        dataSource = self
        
        if let imageDatasource {
            let initialVC: ImageViewerController = .init(index: initialIndex,
                                                         imageItem: imageDatasource.imageItem(at: initialIndex))
            setViewControllers([initialVC], direction: .forward, animated: true)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didDownloadMetadata(notification:)),
                                               name: .didDownloadMetadata,
                                               object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        gradientLayer.frame = metadataContainerView.bounds
    }
    
    deinit {
        ImageCache.galleryHighResolutionDiskCache.clearMemoryCache()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        traitCollection.userInterfaceStyle == .dark
        ? .lightContent
        : .darkContent
    }
    
    // MARK: - Private func
    private func configureContentMetadataView() {
        metadataContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(metadataContainerView)
        NSLayoutConstraint.activate([
            metadataContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            metadataContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            metadataContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            metadataContainerView.heightAnchor.constraint(equalToConstant: 112)
        ])
        
        contentMetadataView = ContentMetadataView()
        contentMetadataView.translatesAutoresizingMaskIntoConstraints = false
        metadataContainerView.addSubview(contentMetadataView)
        contentMetadataView.bindFrameToSuperview()
        configureMetadataGradientLayer()
        
        updateMetaData(with: initialIndex)
    }
    
    private func configureMetadataGradientLayer() {
        gradientLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.cgColor
        ]
        
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        
        metadataContainerView.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    private func configureNavigationBar() {
        navigationController?.setDefaultNavigationBarAppearance()
        
        let closeBarButton = createNavbarButton(title: localizedString("shared_string_close"),
                                                icon: nil,
                                                color: .iconColorActive,
                                                action: #selector(onCloseBarButtonActon),
                                                target: self,
                                                menu: nil)
        
        navigationItem.leftBarButtonItem = closeBarButton
        
        var firstSectionItems = [UIAction]()
        let detailsAction = UIAction(title: localizedString("shared_string_details"), image: UIImage.icCustomInfoOutlined) { [weak self] _ in
            guard let self,
                  let card = getCardForIndex(currentIndex),
                  let parent else { return }
            GalleryContextMenuProvider.openDetailsController(card: card, rootController: parent)
        }
        detailsAction.accessibilityLabel = localizedString("shared_string_details")
        firstSectionItems.append(detailsAction)
        
        let openInBrowserAction = UIAction(title: localizedString("open_in_browser"), image: UIImage.icCustomExternalLink) { [weak self] _ in
            guard let self, let card = getCardForIndex(currentIndex) else { return }
            
            guard let viewController = OAWebViewController(urlAndTitle: card.urlWithCommonAttributions, title: card.title) else { return }
            let navigationController = UINavigationController(rootViewController: viewController)
            navigationController.modalPresentationStyle = .fullScreen
            
            parent?.present(navigationController, animated: true, completion: nil)
        }
        openInBrowserAction.accessibilityLabel = localizedString("open_in_browser")
        
        firstSectionItems.append(openInBrowserAction)
        
        let firstSection = UIMenu(title: "", options: .displayInline, children: firstSectionItems)
        let downloadAction = UIAction(title: localizedString("shared_string_download"), image: UIImage.icCustomDownload) { [weak self] _ in
            guard let self, let card = getCardForIndex(currentIndex), !card.imageUrl.isEmpty  else { return }
            GalleryContextMenuProvider.downloadImage(urlString: card.imageUrl, view: view)
        }
        downloadAction.accessibilityLabel = localizedString("shared_string_download")
        let secondSection = UIMenu(title: "", options: .displayInline, children: [downloadAction])
        let menu = UIMenu(title: "", image: nil, children: [firstSection, secondSection])
        
        let sharedBarButton = createNavbarButton(title: nil, icon: .icCustomExportOutlined, color: .iconColorActive, action: #selector(onSharedBarButtonActon(_:)), target: self, menu: nil)
        
        let detailsBarButton = createNavbarButton(title: nil, icon: .icNavbarOverflowMenuOutlined, color: .iconColorActive, action: nil, target: nil, menu: menu)
        
        navigationItem.rightBarButtonItems = [detailsBarButton, sharedBarButton]
    }
    
    private func updateTitle(with pageIndex: Int) {
        guard let card = getCardForIndex(pageIndex) else { return }
        navigationItem.title = card.title
    }
    
    private func updateMetaData(with pageIndex: Int) {
        guard let card = getCardForIndex(pageIndex) else { return }
        contentMetadataView.updateMetadata(with: card.metadata, imageName: card.topIcon)
    }
    
    private func getCardForIndex(_ index: Int) -> WikiImageCard? {
        guard let imageDatasource else { return nil }
        
        if case .card(let card) = imageDatasource.imageItem(at: index) {
            return card
        } else {
            return nil
        }
    }
    
    private func downloadMetadataIfNeeded() {
        guard let datasource = imageDatasource as? SimpleImageDatasource else { return }
        let wikiImageCards = datasource.imageItems.compactMap { item in
            if case .card(let card) = item {
                return card
            }
            return nil
        }
        if !wikiImageCards.isEmpty {
            downloadImageMetadataService.cards = wikiImageCards
            prefetchMetadata()
        }
    }
    
    private func showContentMetadataView(show: Bool) {
        UIView.animate(withDuration: 0.25, animations: {
            self.contentMetadataView.alpha = show ? 1.0 : 0.0
            self.contentMetadataView.transform = !show ? .init(translationX: 0, y: 113) : .identity
        })
    }
    
    private func prefetchAdjacentItems() {
        guard let imageDatasource else { return }
        
        let previousIndex = (currentIndex - 1 + imageDatasource.count()) % imageDatasource.count()
        let nextIndex = (currentIndex + 1) % imageDatasource.count()
        
        let urls = [previousIndex, nextIndex].compactMap { index -> URL? in
            guard index >= 0 && index < imageDatasource.count() else { return nil }
            guard let card = getCardForIndex(index) else { return nil }
            guard let fullSizeUrl = card.getGalleryFullSizeUrl(), let url = URL(string: fullSizeUrl) else {
                return nil
            }
            return url
        }
        
        prefetchImages(with: urls)
    }
    
    private func prefetchMetadata() {
        guard let imageDatasource else { return }
        // Get 2 previous and 2 next indices relative to the current index
        let indicesForPrefetch = [
            (currentIndex - 2 + imageDatasource.count()) % imageDatasource.count(),
            (currentIndex - 1 + imageDatasource.count()) % imageDatasource.count(),
            currentIndex,
            (currentIndex + 1) % imageDatasource.count(),
            (currentIndex + 2) % imageDatasource.count()
        ]

        let cardsForPrefetch = indicesForPrefetch.compactMap { index -> WikiImageCard? in
            guard index >= 0 && index < imageDatasource.count() else { return nil }
            guard let card = getCardForIndex(index),
                  let metadata = card.metadata else { return nil }
            
            let isMetadataMissing = [
                metadata.date,
                metadata.author,
                metadata.license
            ].contains { downloadImageMetadataService.isEmpty($0) }
            
            guard isMetadataMissing && !card.isMetaDataDownloaded && !card.isMetaDataDownloading else { return nil }
            return card
        }
        
        if !cardsForPrefetch.isEmpty {
            Task { [weak self] in
                guard let self else { return }
                await downloadImageMetadataService.downloadMetadata(for: cardsForPrefetch)
            }
        } else {
            debugPrint("No cards to prefetch metadata")
        }
    }

    private func prefetchImages(with urls: [URL]) {
        guard !urls.isEmpty else { return }
        ImagePrefetcher(urls: urls, options: [.targetCache(.galleryHighResolutionDiskCache)]).start()
    }
    
    @objc private func didDownloadMetadata(notification: Notification) {
        guard let cards = notification.userInfo?["cards"] as? [WikiImageCard] else { return }
        guard let obj = getCardForIndex(currentIndex) else { return }
    
        if cards.contains(where: { $0 === obj }) {
            updateMetaData(with: currentIndex)
        }
    }
    
    @objc private func onCloseBarButtonActon(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func onSharedBarButtonActon(_ sender: UIBarButtonItem) {
        guard let obj = getCardForIndex(currentIndex) else { return }
        guard let encodedURLString = obj.urlWithCommonAttributions.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encodedURLString) else {
            NSLog("Error: Encoding failed or invalid URL: \( obj.urlWithCommonAttributions)")
            return
        }
        
        showActivity([url], sourceView: view, barButtonItem: sender)
    }
}

extension ImageCarouselViewController: UIPageViewControllerDataSource {
    
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        guard let vc = viewController as? ImageViewerController, let imageDatasource = imageDatasource else {
            return nil
        }
        
        var newIndex = vc.index - 1
        if newIndex < 0 {
            newIndex = imageDatasource.count() - 1
        }
        
        return ImageViewerController(
            index: newIndex,
            imageItem: imageDatasource.imageItem(at: newIndex))
    }
    
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        guard let vc = viewController as? ImageViewerController, let imageDatasource else {
            return nil
        }
        
        var newIndex = vc.index + 1
        if newIndex >= imageDatasource.count() {
            newIndex = 0
        }
        
        return ImageViewerController(
            index: newIndex,
            imageItem: imageDatasource.imageItem(at: newIndex))
    }
}

extension ImageCarouselViewController: UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed,
           let vc = viewControllers?.first as? ImageViewerController {
            currentIndex = vc.index
            debugPrint("Current page: \(currentIndex)")
            updatePage(index: currentIndex)
        }
    }
    
    private func updatePage(index: Int) {
        updateTitle(with: index)
        updateMetaData(with: index)
        prefetchAdjacentItems()
        prefetchMetadata()
    }
}

extension ImageCarouselViewController {
    
    private func createNavbarButton(title: String?, icon: UIImage?, color: UIColor, action: Selector?, target: AnyObject?, menu: UIMenu?) -> UIBarButtonItem {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 44, height: 30))
        button.titleLabel?.lineBreakMode = .byTruncatingMiddle
        button.titleLabel?.numberOfLines = 1
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        button.tintColor = color
        button.setTitleColor(color, for: .normal)
        button.setTitleColor(color.withAlphaComponent(0.3), for: .highlighted)
        
        if let title = title {
            button.setTitle(title, for: .normal)
        }
        
        if let icon = icon {
            button.setImage(icon, for: .normal)
        }
        
        button.removeTarget(nil, action: nil, for: .allEvents)
        if let action {
            button.addTarget(target, action: action, for: .touchUpInside)
        }
        button.translatesAutoresizingMaskIntoConstraints = false
        
        if let menu {
            button.showsMenuAsPrimaryAction = true
            button.menu = menu
        }
        
        let rightNavbarButton = UIBarButtonItem(customView: button)
        
        if let title {
            rightNavbarButton.accessibilityLabel = title
        }
        
        return rightNavbarButton
    }
}
