import Kingfisher

protocol ImageDataSource: AnyObject {
    var placeholderImage: UIImage? { get }
    func count() -> Int
    func imageItem(at index: Int) -> ImageItem
}

final class ImageCarouselViewController: UIPageViewController {
    // swiftlint:disable all
    private(set) var contentMetadataView: ContentMetadataView!
    // swiftlint:enable all
    
    private let imageDatasource: ImageDataSource?
    private let metadataContainerView = TouchesPassView()
    
    private(set) var gradientLayer = CAGradientLayer()
    
    private var initialIndex = 0
    private var currentIndex = 0
    private var titleString = ""
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        traitCollection.userInterfaceStyle == .dark
        ? .lightContent
        : .darkContent
    }
    
    override var canBecomeFirstResponder: Bool {
        true
    }
    
    override var keyCommands: [UIKeyCommand]? {
        [
            UIKeyCommand(input: UIKeyCommand.inputLeftArrow, modifierFlags: [], action: #selector(didPressLeftArrow)),
            UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(didPressRightArrow))
        ]
    }
    
    // MARK: - Init
    init(imageDataSource: ImageDataSource?,
         title: String,
         initialIndex: Int = 0) {
        self.initialIndex = initialIndex
        self.currentIndex = initialIndex
        self.imageDatasource = imageDataSource
        self.titleString = title
        
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
        navigationItem.title = titleString
        
        configureNavigationBarAppearance()
        configureContentMetadataView()
        prefetchAdjacentItems()
        
        if let imageDatasource {
            let initialVC: ImageViewerController = .init(index: initialIndex,
                                                         imageItem: imageDatasource.imageItem(at: initialIndex))
            initialVC.placeholderImage = imageDatasource.placeholderImage
            setViewControllers([initialVC], direction: .forward, animated: true)
            
            if imageDatasource.count() > 1 {
                dataSource = self
            }
            configureNavigationBarButtons()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let gradientHeight = 112 + view.safeAreaInsets.bottom
        
        gradientLayer.frame = CGRect(
            x: metadataContainerView.bounds.origin.x,
            y: view.frame.height - gradientHeight,
            width: view.bounds.width,
            height: gradientHeight
        )
    }
    
    deinit {
        ImageCache.onlinePhotoHighResolutionDiskCache.clearMemoryCache()
    }
    
    // MARK: - Private func
    private func configureContentMetadataView() {
        metadataContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(metadataContainerView)
        NSLayoutConstraint.activate([
            metadataContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            metadataContainerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            metadataContainerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
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
        
        gradientLayer.startPoint = .init(x: 0.5, y: 0)
        gradientLayer.endPoint = .init(x: 0.5, y: 1)
        
        view.layer.insertSublayer(gradientLayer, below: metadataContainerView.layer)
    }
    
    private func configureNavigationBarAppearance() {
        navigationController?.setDefaultNavigationBarAppearance()
    }
    
    private func configureNavigationLeftBarButtonItemButtons() {
        let closeBarButton = createNavbarButton(title: localizedString("shared_string_close"),
                                                icon: nil,
                                                color: .iconColorActive,
                                                action: #selector(onCloseBarButtonActon),
                                                target: self,
                                                menu: nil)
        navigationItem.leftBarButtonItem = closeBarButton
    }
    
    private func configureNavigationRightBarButtonItemButtons() {
        guard let card = getCardForIndex(currentIndex) else {
            return
        }
        
        var firstSectionItems = [UIAction]()
        if card is WikiImageCard {
            let detailsAction = UIAction(title: localizedString("shared_string_details"), image: .icCustomInfoOutlined) { [weak self] _ in
                guard let self,
                      let card = getCardForIndex(currentIndex),
                      let parent else { return }
                GalleryContextMenuProvider.openDetailsController(card: card, rootController: parent)
            }
            detailsAction.accessibilityLabel = localizedString("shared_string_details")
            firstSectionItems.append(detailsAction)
        }
        
        let openInBrowserAction = UIAction(title: localizedString("open_in_browser"), image: .icCustomExternalLink) { [weak self] _ in
            guard let self, let card = getCardForIndex(currentIndex) else { return }
            SafariPresenter.present(from: self, card: card)
        }
        openInBrowserAction.accessibilityLabel = localizedString("open_in_browser")
        
        firstSectionItems.append(openInBrowserAction)
        
        let firstSection = UIMenu(title: "", options: .displayInline, children: firstSectionItems)
        let downloadAction = UIAction(title: localizedString("shared_string_download"), image: .icCustomDownload) { [weak self] _ in
            guard let self, let card = getCardForIndex(currentIndex) else { return }
            guard let fullSizeUrl = card.getGalleryFullSizeUrl(), !fullSizeUrl.isEmpty else { return }
            guard let url = URL(string: fullSizeUrl) else {
                return
            }
            
            let cache: ImageCache
            let urlString: String
            // Attempting to download the high-resolution image first
            if ImageCache.onlinePhotoHighResolutionDiskCache.isCached(forKey: url.absoluteString) {
                cache = .onlinePhotoHighResolutionDiskCache
                urlString = fullSizeUrl
            } else {
                guard !card.imageUrl.isEmpty else {
                    return
                }
                cache = .onlinePhotoAndMapillaryDefaultCache
                urlString = card.imageUrl
            }
            GalleryContextMenuProvider.downloadImage(urlString: urlString, view: view, cache: cache)
        }
        downloadAction.accessibilityLabel = localizedString("shared_string_download")
        let secondSection = UIMenu(title: "", options: .displayInline, children: [downloadAction])
        let menu = UIMenu(title: "", image: nil, children: [firstSection, secondSection])
        
        let sharedBarButton = createNavbarButton(title: nil, icon: .icCustomExportOutlined, color: .iconColorActive, action: #selector(onSharedBarButtonActon(_:)), target: self, menu: nil)
        
        let detailsBarButton = createNavbarButton(title: nil, icon: .icNavbarOverflowMenuOutlined, color: .iconColorActive, action: nil, target: nil, menu: menu)
        
        navigationItem.rightBarButtonItems = [detailsBarButton, sharedBarButton]
    }
    
    private func configureNavigationBarButtons() {
        configureNavigationLeftBarButtonItemButtons()
        configureNavigationRightBarButtonItemButtons()
    }

    private func updateMetaData(with pageIndex: Int) {
        guard let card = getCardForIndex(pageIndex) as? WikiImageCard else {
            contentMetadataView.updateMetadata(with: nil, imageName: "")
            return
        }
        contentMetadataView.updateMetadata(with: card.metadata, imageName: card.topIcon)
    }
    
    private func getCardForIndex(_ index: Int) -> ImageCard? {
        guard let imageDatasource else { return nil }
        
        if case .card(let card) = imageDatasource.imageItem(at: index) {
            return card
        } else {
            return nil
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
    
    private func prefetchImages(with urls: [URL]) {
        guard !urls.isEmpty else { return }
        ImagePrefetcher(urls: urls, options: [.targetCache(.onlinePhotoHighResolutionDiskCache)]).start()
    }
    
    @objc private func onCloseBarButtonActon(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func onSharedBarButtonActon(_ sender: UIBarButtonItem) {
        guard let card = getCardForIndex(currentIndex) else { return }

        let url: URL

        switch card {
        case let wikiCard as WikiImageCard:
            guard let encoded = wikiCard.urlWithCommonAttributions
                .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let encodedURL = URL(string: encoded) else {
                NSLog("Error: Invalid encoded URL: \(wikiCard.urlWithCommonAttributions)")
                return
            }
            url = encodedURL
        case let urlCard as UrlImageCard:
            guard let imageURL = URL(string: urlCard.imageUrl) else {
                NSLog("Error: Invalid URL: \(urlCard.imageUrl)")
                return
            }
            url = imageURL
        default:
            return
        }

        showActivity([url], sourceView: view, barButtonItem: sender)
    }
}

extension ImageCarouselViewController: UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        guard let vc = viewController as? ImageViewerController, let imageDatasource else {
            return nil
        }
        
        var newIndex = vc.index - 1
        if newIndex < 0 {
            newIndex = imageDatasource.count() - 1
        }
        
        let controller = ImageViewerController(
            index: newIndex,
            imageItem: imageDatasource.imageItem(at: newIndex))
        controller.placeholderImage = imageDatasource.placeholderImage
        
        return controller
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let vc = viewController as? ImageViewerController, let imageDatasource else {
            return nil
        }
        
        var newIndex = vc.index + 1
        if newIndex >= imageDatasource.count() {
            newIndex = 0
        }
        
        let controller = ImageViewerController(
            index: newIndex,
            imageItem: imageDatasource.imageItem(at: newIndex))
        controller.placeholderImage = imageDatasource.placeholderImage
        
        return controller
    }
}

extension ImageCarouselViewController: UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed,
           let vc = viewControllers?.first as? ImageViewerController {
            currentIndex = vc.index
            updatePage(index: currentIndex)
            configureNavigationRightBarButtonItemButtons()
        }
    }
    
    private func updatePage(index: Int) {
        updateMetaData(with: index)
        prefetchAdjacentItems()
    }
}

// MARK: - KeyCommands
extension ImageCarouselViewController {
    
    private func navigate(to direction: NavigationDirection) {
        guard let imageDatasource, imageDatasource.count() > 1 else { return }
        guard let currentVC = viewControllers?.first else { return }
        
        let targetVC: ImageViewerController? = {
            switch direction {
            case .forward:
                return pageViewController(self, viewControllerAfter: currentVC) as? ImageViewerController
            case .reverse:
                return pageViewController(self, viewControllerBefore: currentVC) as? ImageViewerController
            @unknown default:
                assertionFailure("Unhandled navigation direction: \(direction)")
                return nil
            }
        }()
        
        guard let targetVC else { return }
        
        if let presented = parent?.presentedViewController {
            presented.dismiss(animated: true)
        }
        
        setViewControllers([targetVC], direction: direction, animated: true) { [weak self] completed in
            guard let self, completed else { return }
            currentIndex = targetVC.index
            updatePage(index: currentIndex)
        }
    }
    
    @objc private func didPressLeftArrow() {
        navigate(to: .reverse)
    }
    
    @objc private func didPressRightArrow() {
        navigate(to: .forward)
    }
}
