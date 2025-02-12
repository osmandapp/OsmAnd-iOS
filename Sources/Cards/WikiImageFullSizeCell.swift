//
//  WikiImageFullSizeCell.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 10.02.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import Kingfisher

final class WikiImageFullSizeCell: UICollectionViewCell {
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
//    private let scrollView: ImageScrollView = {
//        let scrollView = ImageScrollView()
//        scrollView.minimumZoomScale = 1.0
//        scrollView.zoomScale = 1.0
//        scrollView.maximumZoomScale = 4.0
//        //scrollView.delegate = self
//        return scrollView
//    }()
    
//    private var imageDownloadTask: DownloadTask?
//    private var currentUrlString: String?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        setupImageScrollView()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
//        scrollView.imageZoomView.kf.cancelDownloadTask()
//        scrollView.clear()
    }
    
    private func setupImageScrollView() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
      //  scrollView.contentInsetAdjustmentBehavior = .never
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
//    func configure(with model: WikiImageCard) {
//            guard let fullSizeUrlString = model.getGalleryFullSizeUrl(),
//                  let url = URL(string: fullSizeUrlString) else { return }
//
//            currentUrlString = fullSizeUrlString
//
//            let task = ImageDownloader.default.downloadImage(with: url) { [weak self] result in
//                guard let self else { return }
//                Task { @MainActor in
//         
//                    if self.currentUrlString == fullSizeUrlString {
//                        switch result {
//                        case .success(let value):
//                            let cache = ImageCache.galleryHighResolutionDiskCache
//                            cache.store(value.image, forKey: fullSizeUrlString)
//                            DispatchQueue.main.async {
//                                self.scrollView.set(image: value.image)
//                                //  activityIndicator.stopAnimating()
//                            }
//                         
//                        case .failure(let error):
//                            // Ошибка загрузки
//                            print("Failed to load image: \(error.localizedDescription)")
//                          //  activityIndicator.stopAnimating()
//                        }
//                    }
//                }
//            }
//            self.imageDownloadTask = task
//        }

    
    func configure(with model: WikiImageCard) {
        guard let fullSizeUrlString = model.getGalleryFullSizeUrl(),
              let url = URL(string: fullSizeUrlString) else {
            return
        }
     //   scrollView.setImage(with: url)
        imageView.kf.indicatorType = .activity
        imageView.kf.setImage(
            with: url,
            options: [
                .targetCache(.galleryHighResolutionDiskCache)
            ])
    }
}


//public class ImageScrollView: UIScrollView, UIGestureRecognizerDelegate {
//  
//  // MARK: - Public
//  
//  public var imageView: UIImageView? {
//    didSet {
//      oldValue?.removeGestureRecognizer(tap)
//      oldValue?.removeFromSuperview()
//      if let imageView = self.imageView {
//        initialImageFrame = .null
//        imageView.isUserInteractionEnabled = true
//        imageView.addGestureRecognizer(tap)
//        addSubview(imageView)
//      }
//    }
//  }
//  
//  // MARK: - Initialization
//  
//  override init(frame: CGRect) {
//    super.init(frame: frame)
//    configure()
//  }
//  
//  required init?(coder: NSCoder) {
//    super.init(coder: coder)
//    configure()
//  }
//  
//  deinit {
//    stopObservingBoundsChange()
//  }
//  
//  // MARK: - UIScrollView
//  
//  public override func layoutSubviews() {
//    super.layoutSubviews()
//    setupInitialImageFrame()
//  }
//  
//  public override var contentOffset: CGPoint {
//    didSet {
//      let contentSize = self.contentSize
//      let scrollViewSize = self.bounds.size
//      var newContentOffset = contentOffset
//      
//      if contentSize.width < scrollViewSize.width {
//        newContentOffset.x = (contentSize.width - scrollViewSize.width) * 0.5
//      }
//      
//      if contentSize.height < scrollViewSize.height {
//        newContentOffset.y = (contentSize.height - scrollViewSize.height) * 0.5
//      }
//      
//      super.contentOffset = newContentOffset
//    }
//  }
//  
//  // MARK: - UIGestureRecognizerDelegate
//  
//  public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//    return otherGestureRecognizer === self.panGestureRecognizer
//  }
//  
//  // MARK: - Private: Tap to Zoom
//  
//  private lazy var tap: UITapGestureRecognizer = {
//    let tap = UITapGestureRecognizer(target: self, action: #selector(tapToZoom(_:)))
//    tap.numberOfTapsRequired = 2
//    tap.delegate = self
//    return tap
//  }()
//  
//  @IBAction private func tapToZoom(_ sender: UIGestureRecognizer) {
//    guard sender.state == .ended else { return }
//    if zoomScale > minimumZoomScale {
//      setZoomScale(minimumZoomScale, animated: true)
//    } else {
//      guard let imageView = self.imageView else { return }
//      let tapLocation = sender.location(in: imageView)
//      let zoomRectWidth = imageView.frame.size.width / maximumZoomScale;
//      let zoomRectHeight = imageView.frame.size.height / maximumZoomScale;
//      let zoomRectX = tapLocation.x - zoomRectWidth * 0.5;
//      let zoomRectY = tapLocation.y - zoomRectHeight * 0.5;
//      let zoomRect = CGRect(
//        x: zoomRectX,
//        y: zoomRectY,
//        width: zoomRectWidth,
//        height: zoomRectHeight)
//      self.zoom(to: zoomRect, animated: true)
//    }
//  }
//
//  // MARK: - Private: Geometry
//  
//  private var initialImageFrame: CGRect = .null
//  
//  private var imageAspectRatio: CGFloat {
//    guard let image = imageView?.image else { return 1 }
//    return image.size.width / image.size.height
//  }
//  
//  private func configure() {
//    self.showsVerticalScrollIndicator = false
//    self.showsHorizontalScrollIndicator = false
//    self.startObservingBoundsChange()
//  }
//  
//  private func rectSize(for aspectRatio: CGFloat, thatFits size: CGSize) -> CGSize {
//    let containerWidth = size.width
//    let containerHeight = size.height
//    var resultWidth: CGFloat = 0
//    var resultHeight: CGFloat = 0
//    
//    if aspectRatio <= 0 || containerHeight <= 0 {
//      return size
//    }
//    
//    if containerWidth / containerHeight >= aspectRatio {
//      resultHeight = containerHeight
//      resultWidth = containerHeight * aspectRatio
//    } else {
//      resultWidth = containerWidth
//      resultHeight = containerWidth / aspectRatio
//    }
//    
//    return CGSize(width: resultWidth, height: resultHeight)
//  }
//  
//  private func scaleImageForTransition(from oldBounds: CGRect, to newBounds: CGRect) {
//    guard let imageView = self.imageView else { return}
//    
//    let oldContentOffset = CGPoint(x: oldBounds.origin.x, y: oldBounds.origin.y)
//    let oldSize = oldBounds.size
//    let newSize = newBounds.size
//    var containedImageSizeOld = rectSize(for: imageAspectRatio, thatFits: oldSize)
//    let containedImageSizeNew = rectSize(for: imageAspectRatio, thatFits: newSize)
//    
//    if containedImageSizeOld.height <= 0 {
//      containedImageSizeOld = containedImageSizeNew
//    }
//    
//    let orientationRatio = containedImageSizeNew.height / containedImageSizeOld.height
//    let transform = CGAffineTransform(scaleX: orientationRatio, y: orientationRatio)
//    self.imageView?.frame = imageView.frame.applying(transform)
//    self.contentSize = imageView.frame.size;
//    
//    var xOffset = (oldContentOffset.x + oldSize.width * 0.5) * orientationRatio - newSize.width * 0.5
//    var yOffset = (oldContentOffset.y + oldSize.height * 0.5) * orientationRatio - newSize.height * 0.5
//    
//    xOffset -= max(xOffset + newSize.width - contentSize.width, 0)
//    yOffset -= max(yOffset + newSize.height - contentSize.height, 0)
//    xOffset -= min(xOffset, 0)
//    yOffset -= min(yOffset, 0)
//    
//    self.contentOffset = CGPoint(x: xOffset, y: yOffset)
//  }
//  
//  private func setupInitialImageFrame() {
//    guard self.imageView != nil, initialImageFrame == .null else { return }
//    let imageViewSize = rectSize(for: imageAspectRatio, thatFits: bounds.size)
//    initialImageFrame = CGRect(x: 0, y: 0, width: imageViewSize.width, height: imageViewSize.height)
//    imageView?.frame = initialImageFrame
//    contentSize = initialImageFrame.size
//  }
//  
//  // MARK: - Private: KVO
//  
//  private var boundsObserver: NSKeyValueObservation?
//  
//  private func startObservingBoundsChange() {
//    boundsObserver = observe(
//      \.bounds,
//      options: [.old, .new],
//      changeHandler: { [weak self] (object, change) in
//        if let oldRect = change.oldValue,
//          let newRect = change.newValue,
//          oldRect.size != newRect.size {
//          self?.scaleImageForTransition(from: oldRect, to: newRect)
//        }
//    })
//  }
//  
//  private func stopObservingBoundsChange() {
//    boundsObserver?.invalidate()
//    boundsObserver = nil
//  }
//}

//class ImageScrollView: UIScrollView, UIScrollViewDelegate {
//
//    var imageZoomView: UIImageView!
//    
//    lazy var zoomingTap: UITapGestureRecognizer = {
//        let zoomingTap = UITapGestureRecognizer(target: self, action: #selector(handleZoomingTap))
//        zoomingTap.numberOfTapsRequired = 2
//        return zoomingTap
//    }()
//    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        
//        delegate = self
//        showsVerticalScrollIndicator = false
//        showsHorizontalScrollIndicator = false
//        decelerationRate = UIScrollView.DecelerationRate.fast
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    func clear() {
//        imageZoomView?.removeFromSuperview()
//        imageZoomView = nil
//    }
//    
//    func set(image: UIImage) {
//        imageZoomView?.removeFromSuperview()
//        imageZoomView = nil
//        imageZoomView = UIImageView(image: image)
//        addSubview(imageZoomView)
//        
//        configurateFor(imageSize: image.size)
//    }
//    
//    func configurateFor(imageSize: CGSize) {
//        contentSize = imageSize
//        
//        setCurrentMaxandMinZoomScale()
//        zoomScale = minimumZoomScale
//        
//        imageZoomView.addGestureRecognizer(zoomingTap)
//        imageZoomView.isUserInteractionEnabled = true
//    }
//    
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        
//        centerImage()
//    }
//    
//    func setCurrentMaxandMinZoomScale() {
//        let boundsSize = bounds.size
//        let imageSize = imageZoomView.bounds.size
//        
//        let xScale = boundsSize.width / imageSize.width
//        let yScale = boundsSize.height / imageSize.height
//        let minScale = min(xScale, yScale)
//        
//        var maxScale: CGFloat = 1.0
//        if minScale < 0.1 {
//            maxScale = 0.3
//        }
//        if minScale >= 0.1 && minScale < 0.5 {
//            maxScale = 0.7
//        }
//        if minScale >= 0.5 {
//            maxScale = max(1.0, minScale)
//        }
//        
//        minimumZoomScale = minScale
//        maximumZoomScale = maxScale
//    }
//    
//    func centerImage() {
//        let boundsSize = bounds.size
//        var frameToCenter = imageZoomView.frame
//        
//        if frameToCenter.size.width < boundsSize.width {
//            frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2
//        } else {
//            frameToCenter.origin.x = 0
//        }
//        
//        if frameToCenter.size.height < boundsSize.height {
//            frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2
//        } else {
//            frameToCenter.origin.y = 0
//        }
//        
//        imageZoomView.frame = frameToCenter
//    }
//    
//    // gesture
//    @objc func handleZoomingTap(sender: UITapGestureRecognizer) {
//        let location = sender.location(in: sender.view)
//        zoom(point: location, animated: true)
//    }
//    
//    func zoom(point: CGPoint, animated: Bool) {
//        let currectScale = self.zoomScale
//        let minScale = self.minimumZoomScale
//        let maxScale = self.maximumZoomScale
//        
//        if minScale == maxScale && minScale > 1 {
//            return
//        }
//        
//        let toScale = maxScale
//        let finalScale = (currectScale == minScale) ? toScale : minScale
//        let zoomRect = zoomRect(scale: finalScale, center: point)
//        zoom(to: zoomRect, animated: animated)
//    }
//    
//    func zoomRect(scale: CGFloat, center: CGPoint) -> CGRect {
//        var zoomRect = CGRect.zero
//        let bounds = self.bounds
//        
//        zoomRect.size.width = bounds.size.width / scale
//        zoomRect.size.height = bounds.size.height / scale
//        
//        zoomRect.origin.x = center.x - (zoomRect.size.width / 2)
//        zoomRect.origin.y = center.y - (zoomRect.size.height / 2)
//        return zoomRect
//    }
//    
//    // MARK: - UIScrollViewDelegate
//    
//    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
//        imageZoomView
//    }
//    
//    func scrollViewDidZoom(_ scrollView: UIScrollView) {
//        centerImage()
//    }
//}

import Kingfisher

final class ImageScrollView: UIScrollView, UIScrollViewDelegate {

    var imageZoomView: UIImageView!
    
    lazy var zoomingTap: UITapGestureRecognizer = {
        let zoomingTap = UITapGestureRecognizer(target: self, action: #selector(handleZoomingTap))
        zoomingTap.numberOfTapsRequired = 2
        return zoomingTap
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        delegate = self
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        decelerationRate = UIScrollView.DecelerationRate.fast
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func clear() {
        imageZoomView?.removeFromSuperview()
        imageZoomView = nil
    }
    
    func setImage(with url: URL) {
        imageZoomView?.removeFromSuperview()
        imageZoomView = nil
        imageZoomView = UIImageView(frame: bounds)
        addSubview(imageZoomView)
        
        imageZoomView.kf.indicatorType = .activity
        imageZoomView.kf.setImage(with: url) { [weak self, weak imageZoomView] result in
            switch result {
            case .success(let value):
                imageZoomView?.image = value.image
                imageZoomView?.frame = .init(x: 0, y: 0, width: value.image.size.width, height: value.image.size.height)
                self?.configurateFor(imageSize: value.image.size)
            case .failure(let error):
                print("error downloading image: \(error.localizedDescription)")
            }
        }
    }
    
    func configurateFor(imageSize: CGSize) {
        contentSize = imageSize
        
        setCurrentMaxandMinZoomScale()
        zoomScale = minimumZoomScale
        
        imageZoomView.addGestureRecognizer(zoomingTap)
        imageZoomView.isUserInteractionEnabled = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        centerImage()
    }
    
    func setCurrentMaxandMinZoomScale() {
        let boundsSize = bounds.size
        let imageSize = imageZoomView.bounds.size
        
        let xScale = boundsSize.width / imageSize.width
        let yScale = boundsSize.height / imageSize.height
        let minScale = min(xScale, yScale)
        
        var maxScale: CGFloat = 1.0
        if minScale < 0.1 {
            maxScale = 0.3
        }
        if minScale >= 0.1 && minScale < 0.5 {
            maxScale = 0.7
        }
        if minScale >= 0.5 {
            maxScale = max(1.0, minScale)
        }
        
//        minimumZoomScale = //minScale
//        maximumZoomScale = //maxScale
    }
    
    func centerImage() {
        let boundsSize = bounds.size
        var frameToCenter = imageZoomView.frame
        
        if frameToCenter.size.width < boundsSize.width {
            frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2
        } else {
            frameToCenter.origin.x = 0
        }
        
        if frameToCenter.size.height < boundsSize.height {
            frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2
        } else {
            frameToCenter.origin.y = 0
        }
        
        imageZoomView.frame = frameToCenter
    }
    
    // Gesture
    @objc func handleZoomingTap(sender: UITapGestureRecognizer) {
        let location = sender.location(in: sender.view)
        zoom(point: location, animated: true)
    }
    
    func zoom(point: CGPoint, animated: Bool) {
        let currectScale = self.zoomScale
        let minScale = self.minimumZoomScale
        let maxScale = self.maximumZoomScale
        
        if minScale == maxScale && minScale > 1 {
            return
        }
        
        let toScale = maxScale
        let finalScale = (currectScale == minScale) ? toScale : minScale
        let zoomRect = zoomRect(scale: finalScale, center: point)
        zoom(to: zoomRect, animated: animated)
    }
    
    func zoomRect(scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        let bounds = self.bounds
        
        zoomRect.size.width = bounds.size.width / scale
        zoomRect.size.height = bounds.size.height / scale
        
        zoomRect.origin.x = center.x - (zoomRect.size.width / 2)
        zoomRect.origin.y = center.y - (zoomRect.size.height / 2)
        return zoomRect
    }
    
    // MARK: - UIScrollViewDelegate
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageZoomView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImage()
    }
}
