//
//  GalaryContextMenuProvider.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 04.02.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import Kingfisher

enum GalaryContextMenuProvider {
    
    static func downloadImage(urlString: String, view: UIView) {
        guard let url = URL(string: urlString) else {
            NSLog("downloadImage -> Invalid URL.")
            return
        }
        
        do {
            // Attempt to get data from the disk cache
            if let data = try ImageCache.default.diskStorage.value(
                forKey: url.absoluteString,
                forcedExtension: nil,
                extendingExpiration: .cacheTime
            ) {
                saveDataToFile(data, at: url, view: view)
            } else {
                handleImageDownload(from: url, view: view)
            }
        } catch let error as KingfisherError {
            handleDownloadError(error, view: view)
        } catch {
            handleDownloadError(nil, view: view)
        }
    }
    
    private static func handleImageDownload(from url: URL, view: UIView) {
        guard AFNetworkReachabilityManagerWrapper.isReachable() else {
            showNoInternetAlert(in: view)
            return
        }
        
        // Download image if not cached
        ImageDownloader.default.downloadImage(with: url) { result in
            switch result {
            case .success(let value):
                saveDataToFile(value.originalData, at: url, view: view)
            case .failure(let error):
                handleDownloadError(error, view: view)
            }
        }
    }
    
    private static func getDocumentsDirectory() -> URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }
    
    private static func createDownloadDirectory(at path: URL) -> Bool {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: path.path) {
            do {
                try fileManager.createDirectory(at: path, withIntermediateDirectories: true, attributes: nil)
                NSLog("Download directory created at: \(path.path)")
                return true
            } catch {
                NSLog("Error creating Download directory: \(error.localizedDescription)")
                return false
            }
        }
        return true
    }
    
    private static func saveDataToFile(_ data: Data, at url: URL, view: UIView) {
        // Path to Documents directory
        guard let documentsDirectory = getDocumentsDirectory() else { return }
        let downloadDirectory = documentsDirectory.appendingPathComponent("Download")
        
        // Create the Download directory if it doesn't exist
        if !createDownloadDirectory(at: downloadDirectory) { return }
        
        // File URL in the Download directory
        let fileURL = downloadDirectory.appendingPathComponent(url.lastPathComponent)
        
        do {
            try data.write(to: fileURL)
            DispatchQueue.main.async {
                OAUtilities.showToast(localizedString("download_successful"), details: nil, duration: 4, in: view)
            }
            NSLog("File successfully saved at: \(fileURL.path)")
        } catch {
            DispatchQueue.main.async {
                OAUtilities.showToast(localizedString("download_failed"), details: nil, duration: 4, in: view)
            }
            NSLog("Error saving file: \(error.localizedDescription)")
        }
    }
    
    private static func handleDownloadError(_ error: Error?, view: UIView) {
        DispatchQueue.main.async {
            OAUtilities.showToast(localizedString("download_failed"), details: nil, duration: 4, in: view)
        }
        NSLog("Download failed with error: \(error?.localizedDescription ?? "Unknown error")")
    }
    
    private static func showNoInternetAlert(in view: UIView) {
        let alert = UIAlertController(title: nil,
                                      message: localizedString("osm_upload_no_internet"),
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: localizedString("shared_string_ok"), style: .cancel, handler: nil))
        view.parentViewController?.present(alert, animated: true, completion: nil)
    }
    
    static func openURLIfValid(urlString: String?) {
        guard let urlString, !urlString.isEmpty,
              let url = URL(string: urlString),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }
    
    static func openDetailsController(card: AbstractCard, rootController: OASuperViewController) {
        guard let item = card as? WikiImageCard else { return }
        let controller = GalleryGridDatailsViewController()
        controller.card = item
        controller.metadata = item.metadata
        controller.titleString = item.title
        rootController.showMediumSheetViewController(controller, isLargeAvailable: false)
    }
}
