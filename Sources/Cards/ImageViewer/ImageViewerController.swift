import Kingfisher

final class ImageViewerController: UIViewController {
    var index: Int = 0
    var placeholderImage: UIImage?
    
    private let animationDuration: TimeInterval = 0.25
    
    private var imageView: UIImageView = UIImageView(frame: .zero)
    
    private var lastLocation: CGPoint = .zero
    private var isAnimating: Bool = false
    private var maxZoomScale: CGFloat = 1.0
    // swiftlint:disable all
    private var scrollView: UIScrollView!
    private var imageItem: ImageItem!
    private var top: NSLayoutConstraint!
    private var leading: NSLayoutConstraint!
    private var trailing: NSLayoutConstraint!
    private var bottom: NSLayoutConstraint!
    // swiftlint:enable all
    
    private var metadataView: UIView? {
        guard let _parent = parent as? ImageCarouselViewController else { return nil }
        return _parent.contentMetadataView
    }
    
    private var gradientLayer: CAGradientLayer? {
        guard let _parent = parent as? ImageCarouselViewController else { return nil }
        return _parent.gradientLayer
    }
    
    init(index: Int, imageItem: ImageItem) {
        self.index = index
        self.imageItem = imageItem
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let view = UIView()
        
        view.backgroundColor = .clear
        self.view = view
        
        scrollView = UIScrollView()
        scrollView.delegate = self
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        
        scrollView.contentInsetAdjustmentBehavior = .never
        
        view.addSubview(scrollView)
        scrollView.bindFrameToSuperview()
        scrollView.backgroundColor = .clear
        scrollView.addSubview(imageView)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        top = imageView.topAnchor.constraint(equalTo: scrollView.topAnchor)
        leading = imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor)
        trailing = scrollView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor)
        bottom = scrollView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor)
        
        top.isActive = true
        leading.isActive = true
        trailing.isActive = true
        bottom.isActive = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureImageView()
        addGestureRecognizers()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        layout()
    }
    
    private func configureImageView() {
        guard case let .card(item) = imageItem else { return }
        guard let fullSizeUrlString = item.getGalleryFullSizeUrl(),
              let highResURL = URL(string: fullSizeUrlString) else {
            debugPrint("Invalid highRes URL")
            return
        }
        
        let placeholder = ImageCardPlaceholder(placeholderImage: placeholderImage)
        placeholder.add(to: imageView)
        
        let highResCache = ImageCache.onlinePhotoHighResolutionDiskCache
        
        // Try high-resolution image from cache
        highResCache.retrieveImage(forKey: fullSizeUrlString) { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                
                if let image = try? result.get().image {
                    placeholder.remove(from: self.imageView)
                    self.imageView.image = image
                    self.updateLayoutWithDelay()
                } else {
                    // High-res not in cache
                    if AFNetworkReachabilityManagerWrapper.isReachable() {
                        guard let lowResURL = URL(string: item.imageUrl) else {
                            debugPrint("Invalid lowRes URL")
                            return
                        }
                        placeholder.remove(from: self.imageView)
                        self.imageView.kf.indicatorType = .activity
                        // Download high-res
                        self.imageView.kf.setImage(
                            with: highResURL,
                            placeholder: ImageCardPlaceholder(placeholderImage: self.placeholderImage),
                            options: [
                                .targetCache(highResCache),
                                .lowDataMode(.network(lowResURL)),
                                .requestModifier(ImageDownloadRequestModifier())]) { [weak self] result in
                                    switch result {
                                    case .success:
                                        self?.updateLayoutWithDelay()
                                    case .failure(let error):
                                        debugPrint("download failed: url: \(highResURL) or \(lowResURL) | \(error.localizedDescription)")
                                    }
                                }
                    } else {
                        // No internet: fallback to low-res cache
                        ImageCache.onlinePhotoAndMapillaryDefaultCache.retrieveImage(forKey: item.imageUrl) { lowResult in
                            Task { @MainActor in
                                if let lowImage = try? lowResult.get().image {
                                    placeholder.remove(from: self.imageView)
                                    self.imageView.image = lowImage
                                    self.updateLayoutWithDelay()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func updateLayoutWithDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.layout()
        }
    }
    
    private func layout() {
        guard !isAnimating else { return }
        updateConstraintsForSize(view.bounds.size)
        updateMinMaxZoomScaleForSize(view.bounds.size)
    }
    
    // MARK: Add Gesture Recognizers
    private func addGestureRecognizers() {
        let panGesture = UIPanGestureRecognizer(
            target: self, action: #selector(didPan(_:)))
        panGesture.cancelsTouchesInView = false
        panGesture.delegate = self
        scrollView.addGestureRecognizer(panGesture)
        
        let pinchRecognizer = UITapGestureRecognizer(
            target: self, action: #selector(didPinch(_:)))
        pinchRecognizer.numberOfTapsRequired = 1
        pinchRecognizer.numberOfTouchesRequired = 2
        scrollView.addGestureRecognizer(pinchRecognizer)
        
        let singleTapGesture = UITapGestureRecognizer(
            target: self, action: #selector(didSingleTap(_:)))
        singleTapGesture.numberOfTapsRequired = 1
        singleTapGesture.numberOfTouchesRequired = 1
        scrollView.addGestureRecognizer(singleTapGesture)
        
        let doubleTapRecognizer = UITapGestureRecognizer(
            target: self, action: #selector(didDoubleTap(_:)))
        doubleTapRecognizer.numberOfTapsRequired = 2
        doubleTapRecognizer.numberOfTouchesRequired = 1
        scrollView.addGestureRecognizer(doubleTapRecognizer)
        
        singleTapGesture.require(toFail: doubleTapRecognizer)
    }
    
    @objc private func didPan(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard isAnimating == false,
              scrollView.zoomScale == scrollView.minimumZoomScale else { return }
        
        let container: UIView = imageView
        if gestureRecognizer.state == .began {
            lastLocation = container.center
        }
        
        if gestureRecognizer.state != .cancelled {
            let translation: CGPoint = gestureRecognizer
                .translation(in: view)
            container.center = CGPoint(
                x: lastLocation.x + translation.x,
                y: lastLocation.y + translation.y)
        }
        
        let diffY = view.center.y - container.center.y
        if gestureRecognizer.state == .ended {
            if abs(diffY) > 60 {
                dismiss(animated: true)
            } else {
                executeCancelAnimation()
            }
        }
    }
    
    @objc private func didPinch(_ recognizer: UITapGestureRecognizer) {
        var newZoomScale = scrollView.zoomScale / 1.5
        newZoomScale = max(newZoomScale, scrollView.minimumZoomScale)
        scrollView.setZoomScale(newZoomScale, animated: true)
    }
    
    @objc private func didSingleTap(_ recognizer: UITapGestureRecognizer) {
        guard !isAnimating else { return }
        guard let _parent = parent as? ImageCarouselViewController else { return }
        let isHidden = _parent.navigationController?.navigationBar.isHidden ?? false
        
        self.isAnimating = true
        CATransaction.begin()
        CATransaction.setCompletionBlock({
            self.isAnimating = false
        })
        _parent.navigationController?.setNavigationBarHidden(!isHidden, animated: true)
        CATransaction.commit()
        UIView.animate(withDuration: animationDuration) {
            let alphaValue: CGFloat = isHidden ? 1 : 0
            self.metadataView?.alpha = alphaValue
            self.gradientLayer?.opacity = Float(alphaValue)
        }
    }
    
    @objc private func didDoubleTap(_ recognizer: UITapGestureRecognizer) {
        zoomInOrOut(at: recognizer.location(in: imageView))
    }
}

// MARK: - UIGestureRecognizerDelegate
extension ImageViewerController: UIGestureRecognizerDelegate {
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard scrollView.zoomScale == scrollView.minimumZoomScale,
              let panGesture = gestureRecognizer as? UIPanGestureRecognizer else { return false }
        
        let velocity = panGesture.velocity(in: scrollView)
        return abs(velocity.y) > abs(velocity.x)
    }
}

// MARK: Adjusting the dimensions
extension ImageViewerController {
    
    func updateMinMaxZoomScaleForSize(_ size: CGSize) {
        let targetSize = imageView.bounds.size
        if targetSize.width == 0 || targetSize.height == 0 {
            return
        }
        
        let minScale = min(
            size.width / targetSize.width,
            size.height / targetSize.height)
        let maxScale = max(
            (size.width + 1.0) / targetSize.width,
            (size.height + 1.0) / targetSize.height)
        
        scrollView.minimumZoomScale = minScale
        //  NOTE: Xcode warning
        if minScale == 0 {
            scrollView.zoomScale = 0.0001
        } else {
            scrollView.zoomScale = minScale
        }
        
        maxZoomScale = maxScale
        scrollView.maximumZoomScale = maxZoomScale * 1.1
    }
    
    func zoomInOrOut(at point: CGPoint) {
        let newZoomScale = scrollView.zoomScale == scrollView.minimumZoomScale
        ? maxZoomScale : scrollView.minimumZoomScale
        let size = scrollView.bounds.size
        let w = size.width / newZoomScale
        let h = size.height / newZoomScale
        let x = point.x - (w * 0.5)
        let y = point.y - (h * 0.5)
        let rect = CGRect(x: x, y: y, width: w, height: h)
        scrollView.zoom(to: rect, animated: true)
    }
    
    func updateConstraintsForSize(_ size: CGSize) {
        let yOffset = max(0, (size.height - imageView.frame.height) / 2)
        top.constant = yOffset
        bottom.constant = yOffset
        
        let xOffset = max(0, (size.width - imageView.frame.width) / 2)
        leading.constant = xOffset
        trailing.constant = xOffset
        view.layoutIfNeeded()
    }
}

// MARK: - Animation Related stuff
extension ImageViewerController {
    
    private func executeCancelAnimation() {
        self.isAnimating = true
        UIView.animate(withDuration: animationDuration, animations: {
            self.imageView.center = self.view.center
        }, completion: { _ in
            self.isAnimating = false
        })
    }
}

// MARK: - UIScrollViewDelegate
extension ImageViewerController: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        updateConstraintsForSize(view.bounds.size)
    }
}
