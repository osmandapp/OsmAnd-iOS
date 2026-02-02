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
    
    override init() {
        super.init()
    }
    
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
                guard let urlStr = place.wikiIconUrl, !urlStr.isEmpty else { continue }
                guard self.loadingImages[urlStr] == nil else { continue }
                guard let url = URL(string: urlStr) else { continue }
                
                let placeId = NSNumber(value: place.obfId)
                
                // MARK: - Metrics
                let metrics = IconMetrics(
                    textScale: OAAppSettings.sharedManager().textSize.get()
                )
                
                // MARK: - Kingfisher processor
                let processor =
                ResizingImageProcessor(referenceSize: metrics.imageTargetSize, mode: .aspectFill)
                |> CroppingImageProcessor(size: metrics.imageTargetSize, anchor: .init(x: 0.5, y: 0.5))
                |> RoundCornerImageProcessor(cornerRadius: metrics.imageArea / 2, backgroundColor: .clear)
                |> BorderImageProcessor(border: .init(color: .white, lineWidth: metrics.border, radius: .heightFraction(0.5)))
                |> OSMCircularShadowProcessor(shadowOffset: CGSize(width: 0, height: 2 * metrics.textScale),
                                              shadowBlur: 6 * metrics.textScale,
                                              shadowColor: UIColor.black.withAlphaComponent(0.2),
                                              shadowPadding: 8 * metrics.textScale)
                
                let options: KingfisherOptionsInfo = [
                    .processor(processor),
                    .scaleFactor(UIScreen.main.scale),
                    .cacheSerializer(FormatIndicatedCacheSerializer.png)
                ]
                
                // MARK: - Load image
                let task = KingfisherManager.shared.retrieveImage(
                    with: url,
                    options: options,
                    progressBlock: nil
                ) { [weak self] result in
                    guard let self else { return }
                    
                    self.queue.async {
                        self.loadingImages.removeValue(forKey: urlStr)
                    }
                    
                    switch result {
                    case .success(let value):
                        completion?(placeId, value.image)
                    case .failure(let error):
                        NSLog("[POIImageLoader] fetchImages -> failed to load \(urlStr): \(error)")
                    }
                }
                
                self.loadingImages[urlStr] = task
            }
        }
    }
}

struct IconMetrics {
    let textScale: CGFloat
    
    // MARK: - Design contract (textScale = 1)
    private let baseImageArea: CGFloat = 50   // full image area, includes border
    private let baseBorder: CGFloat    = 4    // drawn inside imageArea
    private let baseShadow: CGFloat    = 66   // canvas with shadow
    
    // MARK: - Scaled values
    var imageArea: CGFloat {
        baseImageArea * textScale
    }
    
    var border: CGFloat {
        baseBorder * textScale
    }
    
    var shadow: CGFloat {
        baseShadow * textScale
    }
    
    var imageTargetSize: CGSize {
        CGSize(width: imageArea, height: imageArea)
    }
    
    // MARK: - Geometry inside shadow canvas
    
    /// Top-left origin of imageArea inside shadow canvas
    /// Centers imageArea (50x50) inside shadow canvas (66x66)
    var imageOriginInShadow: CGPoint {
        CGPoint(
            x: (shadow - imageArea) / 2,
            y: (shadow - imageArea) / 2
        )
    }
    
    /// Rect of visible icon (image + borders) inside shadow canvas
    var imageRectInShadow: CGRect {
        CGRect(
            origin: imageOriginInShadow,
            size: imageTargetSize
        )
    }
}

/// Processor that adds a circular shadow to an image
struct OSMCircularShadowProcessor: ImageProcessor {
    // Required by ImageProcessor
    let identifier: String
    
    // Parameters
    let shadowOffset: CGSize
    let shadowBlur: CGFloat
    let shadowColor: UIColor
    let shadowPadding: CGFloat
    
    init(shadowOffset: CGSize,
         shadowBlur: CGFloat,
         shadowColor: UIColor,
         shadowPadding: CGFloat) {
        self.shadowOffset = shadowOffset
        self.shadowBlur = shadowBlur
        self.shadowColor = shadowColor
        self.shadowPadding = shadowPadding
        self.identifier =
        "com.osmand.CircularShadowProcessor." +
        "\(shadowOffset.width)x\(shadowOffset.height)." +
        "\(shadowBlur)." +
        "\(shadowPadding)." +
        "\(shadowColor.hashValue)"
    }
    
    func process(item: ImageProcessItem, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        switch item {
        case .image(let image):
            let canvasSize = CGSize(
                width: image.size.width + 2 * shadowPadding,
                height: image.size.height + 2 * shadowPadding
            )
            
            let format = UIGraphicsImageRendererFormat.default()
            format.opaque = false
            format.scale = image.scale
            
            let renderer = UIGraphicsImageRenderer(size: canvasSize, format: format)
            return renderer.image { ctx in
                let cgContext = ctx.cgContext
                
                let imageOrigin = CGPoint(x: shadowPadding, y: shadowPadding)
                let imageRect = CGRect(origin: imageOrigin, size: image.size)
                
                cgContext.addEllipse(in: imageRect)
                cgContext.setShadow(
                    offset: shadowOffset,
                    blur: shadowBlur,
                    color: shadowColor.cgColor
                )
                cgContext.setFillColor(UIColor.white.cgColor)
                cgContext.fillPath()
                
                image.draw(in: imageRect)
            }
        case .data:
            return (DefaultImageProcessor.default |> self).process(item: item, options: options)
        }
    }
}

@objcMembers
final class POITopPlaceImageDecorator: NSObject {
    
    static func selectedImage(for image: UIImage) -> UIImage {
        let metrics = IconMetrics(textScale: OAAppSettings.sharedManager().textSize.get())
        return imageWithSelection(image, metrics: metrics)
    }
    
    static private func imageWithSelection(_ image: UIImage,
                                           metrics: IconMetrics) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = false
        format.scale = image.scale
        
        return UIGraphicsImageRenderer(size: image.size, format: format).image { context in
            
            let ctx = context.cgContext
            
            image.draw(at: .zero)
            
            ctx.setShadow(offset: .zero, blur: 0, color: nil)
            ctx.setStrokeColor(UIColor.systemPurple.cgColor)
            
            let purpleLineWidth = 2 * metrics.textScale
            ctx.setLineWidth(purpleLineWidth)
            ctx.strokeEllipse(in: metrics.imageRectInShadow)
        }
    }
}
