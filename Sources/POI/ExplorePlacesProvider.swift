//
//  ExplorePlacesProvider.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 19.12.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

protocol ExplorePlacesProvider: AnyObject {

    static var maxLevelZoomCache: Int { get }

    func getDataCollection(_ mapRect: QuadRect) -> [OAPOI]
    func getDataCollection(_ mapRect: QuadRect, limit: Int) -> [OAPOI]

    func addListener(_ listener: ExplorePlacesListener)
    func removeListener(_ listener: ExplorePlacesListener)

    func isLoading() -> Bool
    func isLoading(rect: QuadRect) -> Bool
}

protocol ExplorePlacesListener: AnyObject {
    func onNewExplorePlacesDownloaded()
    func onPartialExplorePlacesDownloaded()
}

extension ExplorePlacesListener {
    func onPartialExplorePlacesDownloaded() {}
}
