//
//  DirectoryObserver.swift
//  OsmAnd Maps
//
//  Created by Skalii on 26.07.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objc enum DirectoryObserverType: Int {
    case colorPalette

    var path: String {
        switch self {
        case .colorPalette:
            return OsmAndApp.swiftInstance().colorsPalettePath
        }
    }

    var notificationName: NSNotification.Name {
        switch self {
        case .colorPalette:
            return NSNotification.Name("ColorPaletteDicrectoryUpdated")
        }
    }
}

@objcMembers
final class DirectoryObserver: NSObject {

    static let updatedKey = "updated"
    static let deletedKey = "deleted"
    static let createdKey = "created"

    private let type: DirectoryObserverType

    private var directoryFileDescriptor: CInt = -1
    private var dispatchSource: DispatchSourceFileSystemObject?
    private let queue = DispatchQueue(label: "DirectoryObserverQueue", attributes: .concurrent)

    init(_ type: DirectoryObserverType) {
        self.type = type
    }

    func startObserving() {
        // Open the directory
        directoryFileDescriptor = open(type.path, O_EVTONLY)

        guard directoryFileDescriptor != -1 else {
            debugPrint("Unable to open directory: \(type.path)")
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

            debugPrint("Directory contents changed: \(self.type.path)")
            NotificationCenter.default.post(name: self.type.notificationName, object: self.type.path)
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
