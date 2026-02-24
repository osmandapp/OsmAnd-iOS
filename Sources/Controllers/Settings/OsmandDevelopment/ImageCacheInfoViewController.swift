//
//  ImageCacheInfoViewController.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 08.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import Kingfisher

/// Structure to describe a cache
private struct CacheInfo {
    let title: String
    let cache: ImageCache
    let onClear: (() -> Void)?
}

@objcMembers
final class ImageCacheInfoViewController: UITableViewController {
    /// List of caches to display
    private lazy var caches: [CacheInfo] = {
        [
            CacheInfo(title: localizedString("image_cache_online_photo_high_res"), cache: .onlinePhotoHighResolutionDiskCache, onClear: nil),
            CacheInfo(title: localizedString("image_cache_online_photo_mapillary_default_cache"), cache: .onlinePhotoAndMapillaryDefaultCache, onClear: {
                URLSessionManager.removeAllCachedResponses(for: URLSessionConfigProvider.onlineAndMapillaryPhotosAPIKey)
            }),
            CacheInfo(title: popularPlacesCacheTitle(), cache: .popularPlacesWikipedia, onClear: nil)
        ]
    }()
    
    private let cellIdentifier = "cacheCell"
    
    private var cacheSizes: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = localizedString("image_cache")
        navigationController?.setDefaultNavigationBarAppearance()
        configureNavigationLeftBarButtonItemButtons()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        cacheSizes = Array(repeating: localizedString("shared_string_loading"), count: caches.count)
        updateAllCacheSizes()
    }
    
    // MARK: - Update cache sizes
    
    private func updateAllCacheSizes() {
        for (index, cacheInfo) in caches.enumerated() {
            cacheInfo.cache.calculateDiskStorageSize { [weak self] result in
                DispatchQueue.main.async {
                    guard let self else { return }
                    switch result {
                    case .success(let size):
                        self.cacheSizes[index] = self.formattedCacheSize(size)
                    case .failure(let error):
                        self.cacheSizes[index] = "Error: \(error.localizedDescription)"
                    }
                    self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .fade)
                }
            }
        }
    }
    
    private func formattedCacheSize(_ bytes: UInt) -> String {
        ByteCountFormatter.fileSizeFormatter.string(fromByteCount: Int64(bytes))
    }
    
    private func popularPlacesCacheTitle() -> String {
        let popularPlaces = localizedString("popular_places")
        let wikipedia = "(\(localizedString("shared_string_wikipedia")))"
        let cache = localizedString("shared_string_cache")

        let combined = String(format: NSLocalizedString("ltr_or_rtl_combine_via_space", comment: ""), popularPlaces, wikipedia)

        return "\(cache) \(combined)"
    }
    
    // MARK: - Alert for clearing cache
    
    private func presentClearCacheAlert(for index: Int) {
        let cacheInfo = caches[index]
        let alertTitle = "\(localizedString("shared_string_clear")) \(cacheInfo.title)"
        let alert = UIAlertController(
            title: alertTitle,
            message: localizedString("remove_cache_alert"),
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: localizedString("shared_string_clear"), style: .destructive) { [weak self] _ in
            cacheInfo.onClear?()
            cacheInfo.cache.clearCache {
                DispatchQueue.main.async {
                    self?.updateAllCacheSizes()
                }
            }
        })
        
        alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
        present(alert, animated: true)
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
 
    @objc private func onCloseBarButtonActon(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - UITableViewDataSource
extension ImageCacheInfoViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        caches.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) ?? UITableViewCell(style: .default, reuseIdentifier: cellIdentifier)
        cell.accessoryType = .disclosureIndicator
        
        let cacheInfo = caches[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        content.text = cacheInfo.title
        content.secondaryText = cacheSizes[indexPath.row]
        cell.contentConfiguration = content
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension ImageCacheInfoViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        presentClearCacheAlert(for: indexPath.row)
    }
}
