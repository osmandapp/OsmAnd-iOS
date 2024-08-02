//
//  DirectoryObserver.swift
//  OsmAnd Maps
//
//  Created by Skalii on 26.07.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
final class DirectoryObserver: NSObject {

    private let path: String
    private let notificationName: NSNotification.Name

    private var directoryFileDescriptor: CInt = -1
    private var dispatchSource: DispatchSourceFileSystemObject?
    private let queue = DispatchQueue(label: "DirectoryObserverQueue", attributes: .concurrent)

    init(_ path: String, notificationName: NSNotification.Name) {
        self.path = path
        self.notificationName = notificationName
    }

    func startObserving() {
        // Open the directory
        directoryFileDescriptor = open(path, O_EVTONLY)

        guard directoryFileDescriptor != -1 else {
            debugPrint("Unable to open directory: \(path)")
            return
        }

        // Create the dispatch source
        dispatchSource = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: directoryFileDescriptor,
            eventMask: .all,
            queue: queue
        )

        dispatchSource?.setEventHandler { [weak self] in
            guard let self else { return }

            debugPrint("Directory contents changed: \(self.path)")
            NotificationCenter.default.post(name: self.notificationName, object: self.path)
        }

        dispatchSource?.setCancelHandler { [weak self] in
            guard let self else { return }

            close(self.directoryFileDescriptor)
            self.directoryFileDescriptor = -1
            dispatchSource = nil
        }

        // Start monitoring
        dispatchSource?.resume()
    }

    func stopObserving() {
        dispatchSource?.cancel()
    }

    deinit {
        stopObserving()
    }
}
