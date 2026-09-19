//
//  SharedObfReaders.swift
//  OsmAnd
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation
import OsmAndShared

/// The obf files the shared travel code reads, kept open between requests.
///
/// Opening a reader reads the file's section headers, so they are held until the installed maps
/// change rather than opened per search. A repository is handed out instead of a reader: it asks
/// for the reader on every call and answers nothing while the file is not open, which is what lets
/// a reader be replaced underneath work that is already holding a repository.
///
/// Closing a reader that a background build is still reading through throws inside OsmAndShared,
/// where the exception cannot be caught, so a reader whose file went away is only closed once no
/// travel work is in flight.
final class SharedObfReaders: NSObject {

    static let shared = SharedObfReaders()

    private let lock = NSLock()

    /// One reader per file path, opened lazily the first time that file is searched.
    private var readersByPath: [String: BinaryMapIndexReader] = [:]

    /// One repository per file path, long lived: it outlives the reader it reads through.
    private var repositoriesByPath: [String: BinaryAmenityIndexRepository] = [:]

    /// Readers of files that are no longer installed, waiting for the work using them to finish.
    private var staleReaders: [BinaryMapIndexReader] = []

    /// How many searches or builds are holding repositories right now.
    private var inFlight = 0

    private var resourcesObserver: OAAutoObserverProxy?

    private override init() {
        super.init()
        if let observable = OsmAndApp.swiftInstance()?.localResourcesChangedObservable {
            resourcesObserver = OAAutoObserverProxy(self,
                                                    withHandler: #selector(onLocalResourcesChanged(observer:key:value:)),
                                                    andObserve: observable)
        }
    }

    deinit {
        resourcesObserver?.detach()
    }

    /// Wikivoyage: the installed `.travel.obf` files.
    func travelRepositories() -> [AmenityIndexRepository] {
        repositories(forPaths: OAObfFileList.travelFilePaths())
    }

    /// Everything that may hold gpx tracks: travel files and ordinary map regions.
    func travelAndMapRepositories() -> [AmenityIndexRepository] {
        repositories(forPaths: OAObfFileList.travelAndMapFilePaths())
    }

    /// Runs `work` with the readers held open, so that a change of the installed maps in the middle
    /// of it does not close a file being read.
    func withReadersHeld<T>(_ work: () throws -> T) rethrows -> T {
        lock.lock()
        inFlight += 1
        lock.unlock()
        defer {
            lock.lock()
            inFlight -= 1
            let canClose = inFlight == 0
            let toClose = canClose ? staleReaders : []
            if canClose {
                staleReaders = []
            }
            lock.unlock()
            for reader in toClose {
                reader.close()
            }
        }
        return try work()
    }

    /// Drops the readers of files that are no longer installed. Called on its own when the caller
    /// knows the maps changed before the observable fires.
    func invalidate() {
        forgetUninstalledFiles()
    }

    private func repositories(forPaths paths: [String]) -> [AmenityIndexRepository] {
        lock.lock()
        defer { lock.unlock() }

        var result: [AmenityIndexRepository] = []
        for path in paths {
            if let repository = repositoriesByPath[path] {
                result.append(repository)
                continue
            }
            let repository = BinaryAmenityIndexRepository(path: path, readerSupplier: ReaderSupplier(path: path, pool: self))
            repositoriesByPath[path] = repository
            result.append(repository)
        }
        return result
    }

    /// The reader for `path`, opened on first use. Called from the repository, on whatever thread
    /// the search runs on.
    fileprivate func reader(for path: String) -> BinaryMapIndexReader? {
        lock.lock()
        defer { lock.unlock() }

        if let reader = readersByPath[path] {
            return reader
        }
        guard FileManager.default.fileExists(atPath: path) else { return nil }

        let reader = BinaryMapIndexReader(filePath: path)
        readersByPath[path] = reader
        return reader
    }

    @objc private func onLocalResourcesChanged(observer: Any, key: Any, value: Any) {
        forgetUninstalledFiles()
    }

    private func forgetUninstalledFiles() {
        lock.lock()
        let installed = Set(OAObfFileList.travelAndMapFilePaths())
        var closable: [BinaryMapIndexReader] = []
        for (path, reader) in readersByPath where !installed.contains(path) {
            readersByPath.removeValue(forKey: path)
            repositoriesByPath.removeValue(forKey: path)
            if inFlight == 0 {
                closable.append(reader)
            } else {
                staleReaders.append(reader)
            }
        }
        lock.unlock()

        for reader in closable {
            reader.close()
        }
    }

    /// What the shared repository asks for its reader through. It holds the pool weakly: the pool
    /// owns the repositories, and a repository outliving the pool must answer nothing rather than
    /// keep it alive.
    private final class ReaderSupplier: NSObject, ObfReaderSupplier {

        private let path: String
        private weak var pool: SharedObfReaders?

        init(path: String, pool: SharedObfReaders) {
            self.path = path
            self.pool = pool
        }

        func getReader() -> BinaryMapIndexReader? {
            pool?.reader(for: path)
        }
    }
}
