//
//  GalaryContextMenuProvider.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 04.02.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import Kingfisher

enum GalaryContextMenuProvider {
    // TODO: mac os native download form
    static func downloadImageAndSaveToDocumentsDownload(urlString: String, view: UIView) {
        guard let url = URL(string: urlString) else {
            NSLog("Invalid URL.")
            return
        }
        
        ImageCache.default.retrieveImage(forKey: urlString) { result in
            switch result {
            case .success(let value):
                print(value.cacheType)

                // If the `cacheType is `.none`, `image` will be `nil`.
                print(value.image)

            case .failure(let error):
                print(error)
            }
        }
        
//        URLSession.shared.dataTask(with: url) { data, _, error in
//            guard let data, error == nil else {
//                NSLog("Error downloading data: \(error?.localizedDescription ?? "Unknown error")")
//                return
//            }
//            
//            // Get the path to the Documents folder
//            let fileManager = FileManager.default
//            guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
//                NSLog("Could not get Documents directory.")
//                return
//            }
//            
//            // Create a "Download" subdirectory inside Documents
//            let downloadDirectory = documentsDirectory.appendingPathComponent("Download")
//            
//            // Create the "Download" directory if it doesn't exist
//            if !fileManager.fileExists(atPath: downloadDirectory.path) {
//                do {
//                    try fileManager.createDirectory(at: downloadDirectory, withIntermediateDirectories: true, attributes: nil)
//                    NSLog("Download directory created at: \(downloadDirectory.path)")
//                } catch {
//                    NSLog("Error creating Download directory: \(error.localizedDescription)")
//                    return
//                }
//            }
//            
//            // Create the full file URL in the "Download" folder
//            let fileURL = downloadDirectory.appendingPathComponent(url.lastPathComponent)
//            do {
//                try data.write(to: fileURL)
//                DispatchQueue.main.async {
//                    OAUtilities.showToast(localizedString("download_successful"), details: nil, duration: 4, in: view)
//                }
//                NSLog("File successfully saved at: \(fileURL.path)")
//            } catch {
//                DispatchQueue.main.async {
//                    OAUtilities.showToast(localizedString("download_failed"), details: nil, duration: 4, in: view)
//                }
//                NSLog("Error saving file: \(error.localizedDescription)")
//            }
//        }.resume()
    }
    
    static func openURLIfValid(urlString: String?) {
        guard let urlString, !urlString.isEmpty,
              let url = URL(string: urlString),
              UIApplication.shared.canOpenURL(url) else { return }
        
   
        
       // UIApplication.shared.open(url)
    }
    
    static func openDetailsController(card: AbstractCard, rootController: OASuperViewController) {
        if let item = card as? WikiImageCard {
            let controller = GalleryGridDatailsViewController()
            controller.card = item
            controller.metadata = item.metadata
            controller.titleString = item.title
            rootController.showMediumSheetViewController(controller, isLargeAvailable: false)
        } else {
            guard let item = card as? ImageCard else { return }
            
        }
    }
}
