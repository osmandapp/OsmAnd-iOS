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
    
    /// Dictionary of current image download tasks (key = URL)
    //private(set) var loadingImages: [String: DownloadTask] = [:]
    private(set) var loadingImages: [String: DownloadTask] = [:]
    
    /// Serial queue for thread-safe access to loadingImages
    private let queue = DispatchQueue(label: "com.osmand.poiImageLoader")
    
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
    
    /// Fetches images for an array of POI
    /// - Parameters:
    ///   - places: array of POI objects
    ///   - completion: called for each successfully loaded image with placeId and UIImage
    func fetchImages(_ places: [OAPOI], completion: ((NSNumber, UIImage) -> Void)? = nil) {
        
        // Collect all URLs that need to be loaded
        let imagesToLoad = Set(places.compactMap { $0.wikiIconUrl?.isEmpty == false ? $0.wikiIconUrl : nil })
        
        queue.async {
            // Cancel tasks no longer needed
            for (url, task) in self.loadingImages {
                if !imagesToLoad.contains(url) {
                    task.cancel()
                    self.loadingImages.removeValue(forKey: url)
                }
            }
            
            for place in places {
                guard let urlStr = place.wikiIconUrl, !urlStr.isEmpty else { continue }
                let placeId = NSNumber(value: place.obfId)
                
                if self.loadingImages[urlStr] != nil { continue }
                guard let url = URL(string: urlStr) else { continue }
                
                let iconSize = 45 * OAAppSettings.sharedManager().textSize.get()
                
                let targetSize = CGSize(width: iconSize, height: iconSize)
                let processor =
                ResizingImageProcessor(referenceSize: targetSize, mode: .aspectFill)
                |> CroppingImageProcessor(size: targetSize, anchor: .init(x: 0.5, y: 0.5))
                |> RoundCornerImageProcessor(cornerRadius: targetSize.width / 2)
                |> BorderImageProcessor(border: .init(color: .white, lineWidth: 2.0, radius: .heightFraction(0.5)))
                
                let options: KingfisherOptionsInfo = [
                    .processor(processor),
                    .scaleFactor(UIScreen.main.scale),
                    .cacheOriginalImage
                ]
                
                // Start download task
                let task = KingfisherManager.shared.retrieveImage(with: url, options: options, progressBlock: nil) { [weak self] result in
                    DispatchQueue.main.async {
                        guard let self else { return }
                        
                        // Remove task safely on the serial queue
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
                }
                
                // Store the download task safely on the serial queue
                self.loadingImages[urlStr] = task
            }
        }
    }
}
