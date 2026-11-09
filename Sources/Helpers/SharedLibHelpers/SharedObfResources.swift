//
//  SharedObfResources.swift
//  OsmAnd
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation
import OsmAndShared

/// Supplies installed resources to the shared registry and translates the app's resource IDs.
/// The registry owns file handles, metadata and repositories for every consumer.
@objc(OASharedObfResources)
final class SharedObfResources: NSObject {

    @objc static let shared = SharedObfResources()

    private let registry = ObfReaderRegistry()
    private let lock = NSLock()
    private var pathsByResourceId: [String: String] = [:]
    // Old results and phrases still need to identify a file after it has been removed.
    private var resourceIdsByPath: [String: String] = [:]
    private var useLiveForRouting = false
    private var resourcesObserver: OAAutoObserverProxy?

    private override init() {
        super.init()
        if let observable = OsmAndApp.swiftInstance()?.localResourcesChangedObservable {
            resourcesObserver = OAAutoObserverProxy(self,
                withHandler: #selector(onLocalResourcesChanged(observer:key:value:)),
                andObserve: observable)
        }
        refreshFiles()
    }

    deinit {
        resourcesObserver?.detach()
        registry.close()
    }

    /// Updates file stamps and eligibility; unchanged resources retain their readers.
    @objc func refreshFiles() {
        lock.lock()
        defer { lock.unlock() }
        let files = OAObfFileList.filesForSharedRegistry()
        pathsByResourceId = files.mapValues { $0.path }
        for (resourceId, path) in pathsByResourceId {
            resourceIdsByPath[path] = resourceId
        }
        useLiveForRouting = OAAppSettings.sharedManager().useOsmLiveForRouting
        registry.setFiles(files: Array(files.values))
    }

    /// Readers for the requested resources, in the registry's file-version order.
    @objc func searchReaders(forResourceIds resourceIds: [String]) -> [BinaryMapIndexReader] {
        lock.lock()
        let paths = Set(resourceIds.compactMap { pathsByResourceId[$0] })
        lock.unlock()
        return registry.getFileReaders().compactMap { resource in
            guard paths.contains(resource.getFile().path()),
                  let header = resource.getShallowReader(),
                  header.containsPoiData() || header.containsAddressData() else { return nil }
            return resource.getReader(type: .quickSearch)
        }
    }

    @objc func resourceIds(of readers: [BinaryMapIndexReader]) -> [String] {
        lock.lock()
        defer { lock.unlock() }
        return readers.compactMap { resourceIdsByPath[$0.getFile().path()] }
    }

    @objc func areCurrentSearchReaders(_ readers: [BinaryMapIndexReader]) -> Bool {
        readers.allSatisfy { reader in
            registry.getFileReader(path: reader.getFile().path())?.getReader(type: .quickSearch) === reader
        }
    }

    @objc func routingReaders() -> [BinaryMapIndexReader] {
        lock.lock()
        let settingsChanged = useLiveForRouting != OAAppSettings.sharedManager().useOsmLiveForRouting
        lock.unlock()
        if settingsChanged {
            refreshFiles()
        }
        return registry.getRoutingMapFiles()
    }

    /// Returns the persistent POI repository for a registered resource.
    @objc func amenityRepository(forResourceId resourceId: String) -> AmenityIndexRepository? {
        lock.lock()
        let path = pathsByResourceId[resourceId]
        lock.unlock()
        guard let path else { return nil }
        return registry.getAmenityRepository(path: path)
    }

    func travelRepositories() -> [AmenityIndexRepository] {
        repositories(forPaths: OAObfFileList.travelFilePaths())
    }

    func travelAndMapRepositories() -> [AmenityIndexRepository] {
        repositories(forPaths: OAObfFileList.travelAndMapFilePaths())
    }

    private func repositories(forPaths paths: [String]) -> [AmenityIndexRepository] {
        paths.compactMap { registry.getAmenityRepository(path: $0) }
    }

    @objc private func onLocalResourcesChanged(observer: Any, key: Any, value: Any) {
        refreshFiles()
    }
}
