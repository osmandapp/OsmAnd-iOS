//
//  POIImageLoader.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 13.01.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Kingfisher

@objcMembers
final class POIImageLoadRequest: NSObject {
    let placeId: NSNumber
    let url: String
    let placeholderImageName: String?
    let textScale: CGFloat

    init(placeId: NSNumber, url: String, placeholderImageName: String?, textScale: CGFloat) {
        self.placeId = placeId
        self.url = url
        self.placeholderImageName = placeholderImageName
        self.textScale = textScale
    }
}

@objcMembers
final class POIImageLoader: NSObject, @unchecked Sendable {
    /// Serial queue for thread-safe access to loadingImages
    private let queue = DispatchQueue(label: "com.osmand.poiImageLoader")
    
    /// Dictionary of current image download tasks (key = placeId)
    private var loadingTasks: [NSNumber: DownloadTask] = [:]
    
    /// Cancels all current image download tasks
    func cancelAll() {
        queue.async {
            for task in self.loadingTasks.values {
                task.cancel()
            }
            self.loadingTasks.removeAll()
        }
    }
    
    func fetchImages(_ places: [POIImageLoadRequest],
                     completion: ((NSNumber, UIImage) -> Void)? = nil) {
        let requestedPlaceIds = Set(places.map { $0.placeId })
        
        queue.async {
            // Cancel obsolete tasks
            for (placeId, task) in self.loadingTasks where !requestedPlaceIds.contains(placeId) {
                task.cancel()
                self.loadingTasks.removeValue(forKey: placeId)
            }
            
            for place in places {
                let urlStr = place.url
                guard !urlStr.isEmpty else {
                    continue
                }
                
                let placeId = place.placeId
                guard self.loadingTasks[placeId] == nil else {
                    continue
                }
                
                guard let url = URL(string: urlStr) else {
                    continue
                }
                
                // MARK: - Metrics
                let metrics = IconMetrics(textScale: place.textScale)
                
                // MARK: - Kingfisher processor
                let processor = self.makeIconProcessor(metrics: metrics)
                
                let retryStrategy = TooManyRequestsRetryStrategy(
                    maxRetryCount: 5,
                    retryInterval: .custom { attempt in
                        let base: TimeInterval = 1.0
                        let backoff = base * Double(attempt + 1)
                        return Double.random(in: backoff...(backoff * 2)) // jitter
                    }
                )
                
                let scale = UITraitCollection.current.displayScale
                let targetCache = ImageCache.popularPlacesWikipedia
                
                let options: KingfisherOptionsInfo = [
                    .processor(processor),
                    .scaleFactor(scale),
                    .cacheSerializer(FormatIndicatedCacheSerializer.png),
                    .cacheOriginalImage,
                    .targetCache(targetCache),
                    .retryStrategy(retryStrategy)
                ]
                                
                // MARK: - Load image
                let task = KingfisherManager.shared.retrieveImage(with: url,
                                                                  options: options) { [weak self] result in
                    guard let self else { return }
                    
                    switch result {
                    case .success(let value):
                        self.queue.async {
                            guard self.loadingTasks[placeId] != nil else { return }
                            self.loadingTasks.removeValue(forKey: placeId)
                            completion?(placeId, value.image)
                        }
                    case .failure(let error):
                        NSLog("[POIImageLoader] fetchImages -> failed to load \(urlStr): \(error)")
                        
                        guard let placeholderImageName = place.placeholderImageName,
                              let placeholderImage = OASvgHelper.mapImageNamed(placeholderImageName, scale: Float(scale)),
                              let cacheKey = self.placeholderCacheKey(placeholderImageName: placeholderImageName, metrics: metrics) else {
                            self.queue.async {
                                self.loadingTasks.removeValue(forKey: placeId)
                            }
                            return
                        }
                        
                        targetCache.retrieveImage(forKey: cacheKey) { [weak self] result in
                            guard let self else { return }
                            
                            self.queue.async {
                                guard self.loadingTasks[placeId] != nil else { return }
                                
                                if case .success(let value) = result, let cachedImage = value.image {
                                    self.loadingTasks.removeValue(forKey: placeId)
                                    completion?(placeId, cachedImage)
                                    return
                                }
                                
                                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                                    guard let self else { return }
                                    
                                    let image = self.createProcessedPlaceholder(with: placeholderImage, metrics: metrics, option: KingfisherParsedOptionsInfo(options))
                                    
                                    self.queue.async {
                                        guard self.loadingTasks[placeId] != nil else { return }
                                        self.loadingTasks.removeValue(forKey: placeId)
                                        
                                        if let image {
                                            targetCache.store(image, forKey: cacheKey)
                                            completion?(placeId, image)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                self.loadingTasks[placeId] = task
            }
        }
    }
    
    private func makeIconProcessor(metrics: IconMetrics) -> ImageProcessor {
        let processor = ResizingImageProcessor(referenceSize: metrics.imageTargetSize, mode: .aspectFill)
        |> CroppingImageProcessor(size: metrics.imageTargetSize, anchor: .init(x: 0.5, y: 0.5))
        |> RoundCornerImageProcessor(cornerRadius: metrics.imageArea / 2, backgroundColor: .clear)
        |> BorderImageProcessor(border: .init(
            color: .popularPlaceBgDefault.currentMapThemeColor,
            lineWidth: metrics.border,
            radius: .heightFraction(0.5)))
        |> CircularShadowProcessor(
            shadowOffset: CGSize(width: 0, height: 2 * metrics.textScale),
            shadowBlur: 6 * metrics.textScale,
            shadowColor: UIColor.black.withAlphaComponent(0.2),
            shadowPadding: 8 * metrics.textScale)
        return processor
    }
    
    private func placeholderCacheKey(placeholderImageName: String,
                                     metrics: IconMetrics) -> String? {
        return [
            "poi_placeholder",
            placeholderImageName,
            "scale_\(metrics.textScale)",
            "icon_\(UIColor.popularPlacePlaceholderBg.currentMapThemeColor.hashValue)"
        ].joined(separator: "_")
    }
    
    func createProcessedPlaceholder(with image: UIImage, metrics: IconMetrics, option: KingfisherParsedOptionsInfo) -> UIImage? {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = option.scaleFactor
        format.opaque = false
        
        let renderer = UIGraphicsImageRenderer(size: metrics.imageTargetSize, format: format)
        
        let baseImage = renderer.image { context in
            UIColor.popularPlacePlaceholderBg.currentMapThemeColor.setFill()
            context.fill(CGRect(origin: .zero, size: metrics.imageTargetSize))
        }
        
        let tintedImage = image.withRenderingMode(.alwaysTemplate)
        
        let combinedImage = renderer.image { _ in
            baseImage.draw(at: .zero)
            
            let padding: CGFloat = 15 * metrics.textScale
            let size = metrics.imageArea - padding
            let origin = CGPoint(
                x: (metrics.imageTargetSize.width - size) / 2,
                y: (metrics.imageTargetSize.height - size) / 2
            )
            
            UIColor.popularPlacePlaceholderIcon.currentMapThemeColor.setFill()
            tintedImage.draw(in: CGRect(origin: origin, size: CGSize(width: size, height: size)))
        }
        
        let processor = RoundCornerImageProcessor(cornerRadius: metrics.imageArea / 2, backgroundColor: .clear)
        |> BorderImageProcessor(border: .init(
            color: .popularPlaceBgDefault.currentMapThemeColor,
            lineWidth: metrics.border,
            radius: .heightFraction(0.5)))
        |> CircularShadowProcessor(
            shadowOffset: CGSize(width: 0, height: 2 * metrics.textScale),
            shadowBlur: 6 * metrics.textScale,
            shadowColor: UIColor.black.withAlphaComponent(0.2),
            shadowPadding: 8 * metrics.textScale
        )
        
        return processor.process(item: .image(combinedImage), options: option)
    }
}
