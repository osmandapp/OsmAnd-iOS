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

final class PopularPlacesSearcher: NSObject {
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

    private struct CacheKey: Equatable {
        let latitude: CLLocationDegrees
        let longitude: CLLocationDegrees
        let dataSourceType: EOAWikiDataSourceType
        let mapLanguage: String?
        let wikiLanguages: [String]
        let limit: Int
    }

    private static let searchRadiusMeters: Int32 = 15000

    private let queue = DispatchQueue(label: "net.osmand.explore.popularPlaces", qos: .userInitiated)
    private var token: LoadingToken?
    private var cachedPlaces: (key: CacheKey, places: [PopularPlace])?
    private var cacheGeneration = 0
    private var localResourcesChangedObserver: OAAutoObserverProxy?

    override init() {
        super.init()
        localResourcesChangedObserver = OAAutoObserverProxy(self,
                                                            withHandler: #selector(onLocalResourcesChanged(observer:key:value:)),
                                                            andObserve: OsmAndApp.swiftInstance().localResourcesChangedObservable)
    }

    deinit {
        localResourcesChangedObserver?.detach()
    }

    var isLoading: Bool {
        token != nil
    }

    var isDataSourceAvailable: Bool {
        AFNetworkReachabilityManagerWrapper.isReachable() || OAAppSettings.sharedManager().wikiDataSourceType.get() != .online
    }

    var filter: OAPOIUIFilter? {
        OAPOIFiltersHelper.sharedInstance().getTopWikiPoiFilter()
    }

    func load(center: CLLocationCoordinate2D, limit: Int, completion: @escaping ([PopularPlace]) -> Void) {
        guard token == nil else { return }
        let cacheKey = Self.cacheKey(center: center, limit: limit)
        if let cachedPlaces, cachedPlaces.key == cacheKey {
            completion(cachedPlaces.places)
            return
        }
        guard let filter else {
            completion([])
            return
        }

        let loadingToken = LoadingToken()
        token = loadingToken
        let generation = cacheGeneration
        let rect = KMapUtils.shared.calculateLatLonBbox(latitude: center.latitude,
                                                         longitude: center.longitude,
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
                if !places.isEmpty && generation == self.cacheGeneration {
                    self.cachedPlaces = (cacheKey, places)
                }
                completion(places)
            }
        }
    }

    func cancel() {
        token?.cancel()
        token = nil
    }

    func invalidate() {
        cancel()
        resetCache()
    }

    private func resetCache() {
        cacheGeneration += 1
        cachedPlaces = nil
    }

    @objc private func onLocalResourcesChanged(observer: Any, key: Any, value: Any) {
        DispatchQueue.main.async { [weak self] in
            self?.resetCache()
        }
    }

    private static func cacheKey(center: CLLocationCoordinate2D, limit: Int) -> CacheKey {
        let settings = OAAppSettings.sharedManager()
        let wikiPlugin = OAPluginsHelper.getPlugin(OAWikipediaPlugin.self) as? OAWikipediaPlugin
        let wikiLanguages = wikiPlugin?.hasCustomSettings() == true ? wikiPlugin?.getLanguagesToShow() ?? [] : []
        return CacheKey(latitude: center.latitude,
                        longitude: center.longitude,
                        dataSourceType: settings.wikiDataSourceType.get(),
                        mapLanguage: settings.settingPrefMapLanguage.get(),
                        wikiLanguages: wikiLanguages,
                        limit: limit)
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
