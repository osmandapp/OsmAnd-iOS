//
//  POIImageLoader.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 13.01.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Kingfisher

@objcMembers
final class POIImageLoader: NSObject, @unchecked Sendable {
    /// Serial queue for thread-safe access to loadingImages
    private let queue = DispatchQueue(label: "com.osmand.poiImageLoader")
    
    /// Dictionary of current image download tasks (key = URL)
    private var loadingImages: [String: DownloadTask] = [:]
    
    /// Cancels all current image download tasks
    func cancelAll() {
        queue.async {
            for task in self.loadingImages.values {
                task.cancel()
            }
            self.loadingImages.removeAll()
        }
    }
    
    func fetchImages(_ places: [OAPOI],
                     completion: ((NSNumber, UIImage) -> Void)? = nil) {
        let imagesToLoad = Set(
            places.compactMap { $0.wikiIconUrl?.isEmpty == false ? $0.wikiIconUrl : nil }
        )
        
        queue.async {
            // Cancel obsolete tasks
            for (url, task) in self.loadingImages where !imagesToLoad.contains(url) {
                task.cancel()
                self.loadingImages.removeValue(forKey: url)
            }
            
            for place in places {
                guard let urlStr = place.wikiIconUrl, !urlStr.isEmpty else {
                    continue
                }
                guard self.loadingImages[urlStr] == nil else {
                    continue
                }
                guard let url = URL(string: urlStr) else {
                    continue
                }
                
                let placeId = NSNumber(value: place.obfId)
                
                // MARK: - Metrics
                let metrics = IconMetrics(textScale: OAAppSettings.sharedManager().textSize.get())
                
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
                        completion?(placeId, value.image)
                    case .failure(let error):
                        NSLog("[POIImageLoader] fetchImages -> failed to load \(urlStr): \(error)")
                        
                        guard let placeholderImageName = place.type?.iconName(),
                              let placeholderImage = OASvgHelper.mapImageNamed(placeholderImageName, scale: Float(scale)),
                              let cacheKey = placeholderCacheKey(placeholderImageName: placeholderImageName, metrics: metrics) else {
                            self.queue.async {
                                self.loadingImages.removeValue(forKey: urlStr)
                            }
                            return
                        }
                        
                        targetCache.retrieveImage(forKey: cacheKey) { [weak self] result in
                            guard let self else { return }
                            
                            self.queue.async {
                                guard self.loadingImages[urlStr] != nil else { return }
                                
                                if case .success(let value) = result, let cachedImage = value.image {
                                    self.loadingImages.removeValue(forKey: urlStr)
                                    DispatchQueue.main.async { completion?(placeId, cachedImage) }
                                    return
                                }
                                
                                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                                    guard let self else { return }
                                    
                                    let image = self.createProcessedPlaceholder(with: placeholderImage, metrics: metrics, option: KingfisherParsedOptionsInfo(options))
                                    
                                    self.queue.async {
                                        guard self.loadingImages[urlStr] != nil else { return }
                                        self.loadingImages.removeValue(forKey: urlStr)
                                        
                                        if let image {
                                            targetCache.store(image, forKey: cacheKey)
                                            DispatchQueue.main.async { completion?(placeId, image) }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                self.loadingImages[urlStr] = task
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
