import Kingfisher

protocol ImageDataSource: AnyObject {
    func count() -> Int
    func imageItem(at index: Int) -> ImageItem
}

final class ImageCarouselViewController: UIPageViewController {
    private(set) var contentMetadataView: ContentMetadataView!
    private(set) lazy var navItem = UINavigationItem()
    
    private let imageDatasource: ImageDataSource?
    private var wikiImageCards: [WikiImageCard]?
    
    private var initialIndex = 0
    private var currentIndex = 0
    
    private lazy var downloadMetadataProvider = DownloadMetadataProvider()
    
    private(set) lazy var navBar: UINavigationBar = {
        let _navBar = UINavigationBar(frame: .zero)
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = .viewBg
        
        let blurAppearance = UINavigationBarAppearance()
        appearance.shadowImage = nil
        appearance.shadowColor = nil
        blurAppearance.shadowColor = nil
        
        _navBar.standardAppearance = blurAppearance
        _navBar.scrollEdgeAppearance = appearance
        
        _navBar.titleTextAttributes = [
            .foregroundColor: UIColor.textColorPrimary,
            .font: UIFont.preferredFont(forTextStyle: .subheadline)
        ]
        _navBar.tintColor = .iconColorActive
        
      //  UINavigationBar.appearance().standardAppearance = appearance
        return _navBar
    }()
    
    init(
        imageDataSource: ImageDataSource?,
        initialIndex: Int = 0) {
            
            self.initialIndex = initialIndex
            self.currentIndex = initialIndex
            self.imageDatasource = imageDataSource
            
            super.init(
                transitionStyle: .scroll,
                navigationOrientation: .horizontal,
                options: [UIPageViewController.OptionsKey.interPageSpacing: 20])
            delegate = self
            
            modalPresentationStyle = .custom
            modalPresentationCapturesStatusBarAppearance = true
        }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        addNavBar()
        configureContentMetadataView()
        downloadMetadataIfNeeded()
        prefetchAdjacentItems()
        
        dataSource = self
        
        if let imageDatasource {
            let initialVC: ImageViewerController = .init(
                index: initialIndex,
                imageItem: imageDatasource.imageItem(at: initialIndex))
            setViewControllers([initialVC], direction: .forward, animated: true)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navBar.alpha = 1.0
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .darkContent
//        traitCollection.userInterfaceStyle == .dark
//        ? .lightContent
//        : .darkContent;
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
        updateMetaData(with: initialIndex)
    }
    
    private func addNavBar() {
        let closeBarButton = createNavbarButton(title: localizedString("shared_string_close"), icon: nil, color: .iconColorActive, action: #selector(onCloseBarButtonActon), target: self, menu: nil)
        
        navItem.leftBarButtonItem = closeBarButton
        navItem.leftBarButtonItem?.tintColor = .white
        
        var menuItems: [UIAction] {
            return [
                UIAction(title: "Standard item", image: UIImage(systemName: "sun.max"), handler: { (_) in
                }),
                UIAction(title: "Disabled item", image: UIImage(systemName: "moon"), attributes: .disabled, handler: { (_) in
                }),
                UIAction(title: "Delete..", image: UIImage(systemName: "trash"), attributes: .destructive, handler: { (_) in
                })
            ]
        }
        
        var demoMenu: UIMenu {
            return UIMenu(title: "My menu", image: nil, identifier: nil, options: [], children: menuItems)
        }
        
        let sharedBarButton = createNavbarButton(title: nil, icon: .icCustomExportOutlined, color: .iconColorActive, action: #selector(onSharedBarButtonActon(_:)), target: self, menu: nil)
        
        let detailsBarButton = createNavbarButton(title: nil, icon: .icNavbarOverflowMenuOutlined, color: .iconColorActive, action: nil, target: nil, menu: demoMenu)
        
        navItem.rightBarButtonItems = [detailsBarButton, sharedBarButton]
        
        navBar.alpha = 0.0
        navBar.items = [navItem]
        navBar.insert(to: view)
        
        updateTitle(with: initialIndex)
    }
    
    private func updateTitle(with pageIndex: Int) {
        guard let card = getCardForIndex(pageIndex) else { return }
        navBar.topItem?.title = card.title
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
        
        wikiImageCards = datasource.imageItems.compactMap { [weak self] item in
            if case .card(let card) = item {
                card.onMetadataUpdated = { [weak self, weak card] in
                    guard let self else { return }
                    guard let obj = getCardForIndex(currentIndex) else { return }
                    if obj === card {
                        updateMetaData(with: currentIndex)
                    }
                }
                return card
            }
            return nil
        }
        if let wikiImageCards, !wikiImageCards.isEmpty {
            downloadMetadataProvider.cards = wikiImageCards
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
        
        let previousIndex = currentIndex == 0 ? imageDatasource.count() - 1 : currentIndex - 1
        let nextIndex = currentIndex == imageDatasource.count() - 1 ? 0 : currentIndex + 1
        
        let urls = [previousIndex, nextIndex].compactMap { index -> URL? in
            guard index >= 0 && index < imageDatasource.count() else { return nil }
            guard let card = getCardForIndex(index) else { return nil }
            guard let fullSizeUrl = card.getGalleryFullSizeUrl(), let url = URL(string: fullSizeUrl) else {
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
    
    @objc private func onCloseBarButtonActon(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func onSharedBarButtonActon(_ sender: UIBarButtonItem) {
        guard let obj = getCardForIndex(currentIndex),
        let url = URL(string: obj.urlWithCommonAttributions) else { return }
        
        showActivity([url], sourceView: view, barButtonItem: sender)
    }
    
    deinit {
        ImageCache.galleryHighResolutionDiskCache.clearMemoryCache()
    }
}

extension ImageCarouselViewController: UIPageViewControllerDataSource {
    
    public func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController) -> UIViewController? {
            
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
    
    public func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController) -> UIViewController? {
            
            guard let vc = viewController as? ImageViewerController, let imageDatasource = imageDatasource else {
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
    
    public func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed,
           let vc = viewControllers?.first as? ImageViewerController {
            debugPrint("Current page: \(vc.index)")
            currentIndex = vc.index
            updatePage(index: currentIndex)
        }
    }
    
    private func updatePage(index: Int) {
        updateTitle(with: index)
        updateMetaData(with: index)
        prefetchAdjacentItems()
    }
    
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
