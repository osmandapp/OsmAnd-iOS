//
//  PopularPlacesSearcher.swift
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation
import OsmAndShared

struct PopularPlace {
    let poi: OAPOI
    let detailedPoi: OAPOI
    let address: String?
}

final class PopularPlacesSearcher {
    private final class LoadingToken {
        private let lock = NSLock()
        private var cancelled = false

        var isCancelled: Bool {
            lock.lock()
            defer { lock.unlock() }
            return cancelled
        }

        func cancel() {
            lock.lock()
            cancelled = true
            lock.unlock()
        }
    }

    private static let searchRadiusMeters: Int32 = 15000

    private let queue = DispatchQueue(label: "net.osmand.explore.popularPlaces", qos: .userInitiated)
    private var token: LoadingToken?

    var isLoading: Bool {
        token != nil
    }

    var isDataSourceAvailable: Bool {
        AFNetworkReachabilityManagerWrapper.isReachable() || OAAppSettings.sharedManager().wikiDataSourceType.get() != .online
    }

    var filter: OAPOIUIFilter? {
        OAPOIFiltersHelper.sharedInstance().getTopWikiPoiFilter()
    }

    func load(limit: Int, completion: @escaping ([PopularPlace]) -> Void) {
        guard token == nil else { return }
        guard let filter, let center = OARootViewController.instance()?.mapPanel?.mapViewController.getMapLocation() else {
            completion([])
            return
        }

        let loadingToken = LoadingToken()
        token = loadingToken
        let rect = KMapUtils.shared.calculateLatLonBbox(latitude: center.coordinate.latitude,
                                                         longitude: center.coordinate.longitude,
                                                         radiusMeters: Self.searchRadiusMeters)
        let matcher = OAResultMatcher<OAPOI>(publishFunc: { _ in true }, cancelledFunc: { loadingToken.isCancelled })
        queue.async {
            let pois = filter.searchAmenities(rect.top, left: rect.left, bottom: rect.bottom, right: rect.right, zoom: -1, matcher: matcher, filterUnique: true)
            var places: [PopularPlace] = []
            for poi in pois.prefix(limit) {
                guard !loadingToken.isCancelled else { break }
                places.append(Self.popularPlace(for: poi))
            }
            DispatchQueue.main.async { [weak self] in
                guard let self, self.token === loadingToken, !loadingToken.isCancelled else { return }
                self.token = nil
                completion(places)
            }
        }
    }

    func cancel() {
        token?.cancel()
        token = nil
    }

    private static func popularPlace(for poi: OAPOI) -> PopularPlace {
        let detailsObject = OAAmenitySearcher.sharedInstance().searchDetailedObject(poi)
        let detailedPoi = detailsObject?.syntheticAmenity ?? poi
        let relatedPois = [poi] + (detailsObject?.objects.compactMap { $0 as? OAPOI } ?? [])
        let cityName = relatedPois.map(\.cityName).first { !$0.isEmpty }
        let address = [streetAddress(for: detailedPoi), cityName].compactMap { $0 }.filter { !$0.isEmpty }
        return PopularPlace(poi: poi,
                            detailedPoi: detailedPoi,
                            address: address.isEmpty ? nil : address.joined(separator: ", "))
    }

    private static func streetAddress(for poi: OAPOI) -> String? {
        guard let street = poi.getAdditionalInfo("addr_street"), !street.isEmpty else { return nil }
        guard let houseNumber = poi.getAdditionalInfo("addr_housenumber"), !houseNumber.isEmpty else { return street }
        return "\(street) \(houseNumber)"
    }
}
