//
//  SharedSearchReaders.swift
//  OsmAnd
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation
import OsmAndShared

/// The obf files the shared search reads, kept open between searches.
///
/// The settings of the shared search hold readers, not resource ids, so a file is opened the first
/// time settings get it and held until the installed maps change. Then every reader is retired, as an
/// update puts the new file at the same path, and closed once nothing may be reading it: the searches
/// the core was asked for before, which `SearchUICore.runAfterSearch` waits for, and the shallow
/// searches the app runs on its own threads, which are counted here. Closing a reader under a search
/// throws inside OsmAndShared, where the exception cannot be caught.
@objc(OASharedSearchReaders)
final class SharedSearchReaders: NSObject {

    @objc static let shared = SharedSearchReaders()

    /// Readers retired together, closed once the searches before them have ended.
    private final class Retired {
        let readers: [BinaryMapIndexReader]
        var searchesEnded = false

        init(readers: [BinaryMapIndexReader]) {
            self.readers = readers
        }
    }

    private let lock = NSLock()
    private var readersByPath: [String: BinaryMapIndexReader] = [:]
    private var currentReaders = Set<ObjectIdentifier>()
    // by the path of a reader's file: kept after the reader is closed, so that settings holding it get the file again
    private var resourceIdsByPath: [String: String] = [:]
    private var retired: [Retired] = []
    private var shallowSearches = 0

    /// The readers of these resources, in their order, opened on first use; resources not installed are left out.
    @objc func readers(forResourceIds resourceIds: [String]) -> [BinaryMapIndexReader] {
        let pathsByResourceId = OAObfFileList.pathsByResourceId(for: resourceIds)
        lock.lock()
        defer { lock.unlock() }
        return openReaders(resourceIds, pathsByResourceId)
    }

    /// The resource ids of these readers, of those this pool opened, retired ones too.
    @objc func resourceIds(of readers: [BinaryMapIndexReader]) -> [String] {
        lock.lock()
        defer { lock.unlock() }
        return readers.compactMap { resourceIdsByPath[$0.getFile().path()] }
    }

    /// Whether none of these readers has been retired: settings holding a retired one get the files again.
    @objc func areCurrent(_ readers: [BinaryMapIndexReader]) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return readers.allSatisfy { currentReaders.contains(ObjectIdentifier($0)) }
    }

    /// Retires every reader, to be closed after the searches `core` was asked for until now and the
    /// shallow searches running now have ended.
    @objc func retireReaders(after core: SearchUICore) {
        let batch: Retired
        lock.lock()
        batch = Retired(readers: Array(readersByPath.values))
        readersByPath.removeAll()
        currentReaders.removeAll()
        retired.append(batch)
        lock.unlock()

        core.runAfterSearch { [weak self] in
            guard let self else { return }
            self.lock.lock()
            batch.searchesEnded = true
            self.lock.unlock()
            self.closeRetiredReaders()
        }
    }

    /// Starts a shallow search of these resources: the readers it is to read, which stay open until
    /// `endShallowSearch` even if the installed maps change meanwhile.
    @objc func beginShallowSearch(resourceIds: [String]) -> [BinaryMapIndexReader] {
        let pathsByResourceId = OAObfFileList.pathsByResourceId(for: resourceIds)
        lock.lock()
        defer { lock.unlock() }
        shallowSearches += 1
        return openReaders(resourceIds, pathsByResourceId)
    }

    @objc func endShallowSearch() {
        lock.lock()
        shallowSearches -= 1
        lock.unlock()
        closeRetiredReaders()
    }

    // under the lock
    private func openReaders(_ resourceIds: [String], _ pathsByResourceId: [String: String]) -> [BinaryMapIndexReader] {
        var readers: [BinaryMapIndexReader] = []
        for resourceId in resourceIds {
            guard let path = pathsByResourceId[resourceId] else { continue }
            if let reader = readersByPath[path] {
                readers.append(reader)
                continue
            }
            guard FileManager.default.fileExists(atPath: path) else { continue }

            let reader = BinaryMapIndexReader(filePath: path)
            readersByPath[path] = reader
            currentReaders.insert(ObjectIdentifier(reader))
            resourceIdsByPath[reader.getFile().path()] = resourceId
            readers.append(reader)
        }
        return readers
    }

    private func closeRetiredReaders() {
        var closable: [BinaryMapIndexReader] = []
        lock.lock()
        if shallowSearches == 0 {
            for batch in retired where batch.searchesEnded {
                closable.append(contentsOf: batch.readers)
            }
            retired.removeAll { $0.searchesEnded }
        }
        lock.unlock()

        for reader in closable {
            reader.close()
        }
    }
}
