//
//  PopularPlacesSearcher.swift
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit
import OsmAndShared

struct PopularPlaceDetails {
    let detailedPoi: OAPOI
    let address: String?
    let descriptionText: String?

    init(poi: OAPOI, preferredLocale: String) {
        let detailsObject = OAAmenitySearcher.sharedInstance().searchDetailedObject(poi)
        let detailedPoi = detailsObject?.syntheticAmenity ?? poi
        let relatedPois = [poi] + (detailsObject?.objects.compactMap { $0 as? OAPOI } ?? [])
        let cityName = relatedPois.map(\.cityName).first { !$0.isEmpty }
        let address = [Self.streetAddress(for: detailedPoi), cityName].compactMap { $0 }.filter { !$0.isEmpty }
        self.detailedPoi = detailedPoi
        self.address = address.isEmpty ? nil : address.joined(separator: ", ")
        descriptionText = Self.descriptionText(for: poi, preferredLocale: preferredLocale)
            ?? (detailedPoi === poi ? nil : Self.descriptionText(for: detailedPoi, preferredLocale: preferredLocale))
    }

    static func preferredLocale() -> String {
        let locale: String = OAAppSettings.sharedManager().settingPrefMapLanguage.get()
        return locale.isEmpty ? OAUtilities.currentLang() ?? "en" : locale
    }

    private static func streetAddress(for poi: OAPOI) -> String? {
        guard let street = poi.getAdditionalInfo("addr_street"), !street.isEmpty else { return nil }
        guard let houseNumber = poi.getAdditionalInfo("addr_housenumber"), !houseNumber.isEmpty else { return street }
        return "\(street) \(houseNumber)"
    }

    private static func descriptionText(for poi: OAPOI, preferredLocale: String) -> String? {
        let articleLocale = OAPluginsHelper.onGetMapObjectsLocale(poi, preferredLocale: preferredLocale)
        let description = poi.getTagContent("description", lang: articleLocale) ?? ""
        let text = description.isEmpty ? articleContent(of: poi, locale: articleLocale) ?? "" : description
        guard !text.isEmpty, let partialContent = OAWikiArticleHelper.getPartialContent(text), !partialContent.isEmpty else { return nil }
        return partialContent
    }

    private static func articleContent(of poi: OAPOI, locale: String) -> String? {
        guard let content = poi.localizedContent as? [String: String] else { return nil }
        if let text = [locale, "", "en"].lazy.compactMap({ content[$0] }).first(where: { !$0.isEmpty }) {
            return text
        }
        return content.values.max { $0.count < $1.count }
    }
}

final class PopularPlace {
    let poi: OAPOI
    fileprivate(set) var details: PopularPlaceDetails?

    init(poi: OAPOI, details: PopularPlaceDetails? = nil) {
        self.poi = poi
        self.details = details
    }

    var name: String {
        let settings: OAAppSettings = OAAppSettings.sharedManager()
        return poi.getName(settings.settingPrefMapLanguage.get(), transliterate: settings.settingMapLanguageTranslit.get()) ?? poi.nameLocalized ?? poi.name ?? ""
    }

    var typeName: String? {
        guard let key = poi.getOsmandPoiKey() ?? poi.subType else { return nil }
        return OAPOIHelper.sharedInstance().getPoiType(byName: key)?.nameLocalized
    }

    func matches(_ query: String) -> Bool {
        [name, poi.nameLocalized, poi.name]
            .compactMap { $0 }
            .contains { $0.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil }
    }

    func contentConfiguration(style: PoiContentConfiguration.Style, secondaryContent: PointSecondaryContent?) -> PoiContentConfiguration {
        let settings: OAAppSettings = OAAppSettings.sharedManager()
        let detailedPoi = details?.detailedPoi ?? poi
        let openingHours = OAPOIHelper.sharedInstance().getShortFormattedOpeningHours(detailedPoi)
        var openingHoursColor: UIColor?
        if !openingHours.isEmpty, let parser = OAOpeningHoursParser(string: detailedPoi.openingHours) {
            openingHoursColor = parser.isOpenedForTime() ? .accentsGreen : .textColorDisruptive
        }
        let imageURL = settings.wikiShowImagePreviews.get() ? poi.wikiIconUrl.flatMap { URL(string: $0) } : nil
        return PoiContentConfiguration(style: style,
                                       title: name,
                                       icon: poi.icon(),
                                       imageURL: imageURL,
                                       secondaryContent: secondaryContent,
                                       address: details?.address,
                                       openingHours: openingHours,
                                       openingHoursColor: openingHoursColor,
                                       descriptionText: details?.descriptionText)
    }
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
        let detailedPlacesCount: Int
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

    func load(center: CLLocationCoordinate2D, detailedPlacesCount: Int, completion: @escaping ([PopularPlace]) -> Void) {
        guard token == nil else { return }
        let cacheKey = Self.cacheKey(center: center, detailedPlacesCount: detailedPlacesCount)
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
        let preferredLocale = PopularPlaceDetails.preferredLocale()
        let rect = KMapUtils.shared.calculateLatLonBbox(latitude: center.latitude,
                                                         longitude: center.longitude,
                                                         radiusMeters: Self.searchRadiusMeters)
        let matcher = OAResultMatcher<OAPOI>(publishFunc: { _ in true }, cancelledFunc: { loadingToken.isCancelled })
        queue.async {
            filter.clearCurrentResults()
            let pois = filter.searchAmenities(rect.top, left: rect.left, bottom: rect.bottom, right: rect.right, zoom: -1, matcher: matcher, filterUnique: true)
            var places: [PopularPlace] = []
            for (index, poi) in pois.enumerated() {
                guard !loadingToken.isCancelled else { break }
                let details = index < detailedPlacesCount ? PopularPlaceDetails(poi: poi, preferredLocale: preferredLocale) : nil
                places.append(PopularPlace(poi: poi, details: details))
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

    private static func cacheKey(center: CLLocationCoordinate2D, detailedPlacesCount: Int) -> CacheKey {
        let settings = OAAppSettings.sharedManager()
        let wikiPlugin = OAPluginsHelper.getPlugin(OAWikipediaPlugin.self) as? OAWikipediaPlugin
        let wikiLanguages = wikiPlugin?.hasCustomSettings() == true ? wikiPlugin?.getLanguagesToShow() ?? [] : []
        return CacheKey(latitude: center.latitude,
                        longitude: center.longitude,
                        dataSourceType: settings.wikiDataSourceType.get(),
                        mapLanguage: settings.settingPrefMapLanguage.get(),
                        wikiLanguages: wikiLanguages,
                        detailedPlacesCount: detailedPlacesCount)
    }
}

final class PopularPlaceDetailsLoader {
    private static let maxPendingCount = 20

    private let queue = DispatchQueue(label: "net.osmand.explore.popularPlaces.details", qos: .userInitiated)
    private var pendingPlaces: [PopularPlace] = []
    private var isLoading = false

    var onDetailsLoaded: ((PopularPlace) -> Void)?

    func request(_ place: PopularPlace) {
        guard place.details == nil, !pendingPlaces.contains(where: { $0 === place }) else { return }
        pendingPlaces.append(place)
        if pendingPlaces.count > Self.maxPendingCount {
            pendingPlaces.removeFirst(pendingPlaces.count - Self.maxPendingCount)
        }
        loadNextIfNeeded()
    }

    func cancelRequest(for place: PopularPlace) {
        pendingPlaces.removeAll { $0 === place }
    }

    func cancelAll() {
        pendingPlaces.removeAll()
    }

    private func loadNextIfNeeded() {
        guard !isLoading else { return }
        pendingPlaces.removeAll { $0.details != nil }
        guard !pendingPlaces.isEmpty else { return }
        let place = pendingPlaces.removeFirst()
        isLoading = true
        let poi = place.poi
        let preferredLocale = PopularPlaceDetails.preferredLocale()
        queue.async { [weak self] in
            let details = PopularPlaceDetails(poi: poi, preferredLocale: preferredLocale)
            DispatchQueue.main.async { [weak self] in
                place.details = details
                guard let self else { return }
                isLoading = false
                onDetailsLoaded?(place)
                loadNextIfNeeded()
            }
        }
    }
}
