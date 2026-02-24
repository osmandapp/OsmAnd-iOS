//
//  ExplorePlacesOnlineProvider.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 19.12.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import OsmAndShared

final class ExplorePlacesOnlineProvider: ExplorePlacesProvider {
    
    private struct TileKey: Hashable {
        let zoom: Int
        let tileX: Int
        let tileY: Int
    }
    
    // MARK: - Constants
    static let maxLevelZoomCache = 13
    
    private static let defaultLimitPoints = 200
    private static let maxTilesPerQuadRect = 12
    private static let maxTilesPerCache = maxTilesPerQuadRect * 2
    private static let loadAllTinyRect: Double = 0.5

    // MARK: - Properties
    private let dbHelper: PlacesDatabaseHelper
    private let lock = NSLock()
    
    private var loadingTasks: [TileKey: GetExplorePlacesImagesTask] = [:]
    private var tilesCache: [TileKey: [OAPOI]] = [:]
    private var listeners: [ExplorePlacesListener] = []

    init() {
        self.dbHelper = PlacesDatabaseHelper()
    }

    // MARK: - Protocol Implementation: Listeners
    func addListener(_ listener: ExplorePlacesListener) {
        lock.lock(); defer { lock.unlock() }
        if !listeners.contains(where: { $0 === listener }) {
            listeners.append(listener)
        }
    }

    func removeListener(_ listener: ExplorePlacesListener) {
        lock.lock(); defer { lock.unlock() }
        listeners.removeAll { $0 === listener }
    }

    private func notifyListeners(isPartial: Bool) {
        DispatchQueue.main.async {
            self.listeners.forEach {
                isPartial ? $0.onPartialExplorePlacesDownloaded() : $0.onNewExplorePlacesDownloaded()
            }
        }
    }

    // MARK: - Protocol Implementation: Data Collection
    func getDataCollection(_ rect: QuadRect) -> [OAPOI] {
        getDataCollection(rect, limit: Self.defaultLimitPoints)
    }
    
    @discardableResult
    func getDataCollection(_ rect: QuadRect, limit: Int) -> [OAPOI] {
        let kRect = KQuadRect(left: rect.left, top: rect.top, right: rect.right, bottom: rect.bottom)
        
        lock.lock()
        loadingTasks = loadingTasks.filter { (_, task) in
            let isRelevant = task.isRunning() &&
                             (kRect.contains(box: task.mapRect) ||
                              KQuadRect.companion.intersects(a: kRect, b: task.mapRect))
            if !isRelevant { task.cancel() }
            return isRelevant
        }
        lock.unlock()

        var zoom = Double(Self.maxLevelZoomCache)
        let mapUtils = KMapUtils.shared
        while zoom >= 0 {
            let tileWidth = Int(mapUtils.getTileNumberX(zoom: zoom, longitude: rect.right)) -
                            Int(mapUtils.getTileNumberX(zoom: zoom, longitude: rect.left)) + 1
            let tileHeight = Int(mapUtils.getTileNumberY(zoom: zoom, latitude: rect.bottom)) -
                             Int(mapUtils.getTileNumberY(zoom: zoom, latitude: rect.top)) + 1
            if tileWidth * tileHeight <= Self.maxTilesPerQuadRect { break }
            zoom -= 3
        }
        zoom = max(zoom, 1)

        let minTileX = Int(mapUtils.getTileNumberX(zoom: zoom, longitude: rect.left))
        let maxTileX = Int(mapUtils.getTileNumberX(zoom: zoom, longitude: rect.right))
        let minTileY = Int(mapUtils.getTileNumberY(zoom: zoom, latitude: rect.top))
        let maxTileY = Int(mapUtils.getTileNumberY(zoom: zoom, latitude: rect.bottom))
        
        guard minTileX <= maxTileX, minTileY <= maxTileY else {
            NSLog("[ExplorePlacesOnlineProvider] -> Coordinate error: Invalid tile range")
            return []
        }

        let loadAll = Int(zoom) == Self.maxLevelZoomCache &&
                      (abs(Double(maxTileX - minTileX)) <= Self.loadAllTinyRect)

        var filteredAmenities: [OAPOI] = []
        var uniqueIds = Set<Int64>()
        let languages = getPreferredLangs()

        for tx in minTileX...maxTileX {
            for ty in minTileY...maxTileY {
                let tileKey = TileKey(zoom: Int(zoom), tileX: tx, tileY: ty)
                
                if !dbHelper.isDataExpired(zoom: Int32(zoom), tileX: Int32(tx), tileY: Int32(ty), languages: languages) {
                    lock.lock()
                    let cached = tilesCache[tileKey]
                    lock.unlock()
                    
                    if let cached {
                        cached.forEach { filterAmenity($0, rect, &filteredAmenities, &uniqueIds, loadAll) }
                    } else {
                        let places = dbHelper.getPlaces(zoom: Int32(zoom), tileX: Int32(tx), tileY: Int32(ty), languages: languages)
                        var list: [OAPOI] = []
                        for item in places {
                            if let amenity = createAmenity(item) {
                                filterAmenity(amenity, rect, &filteredAmenities, &uniqueIds, loadAll)
                                list.append(amenity)
                            }
                        }
                        lock.lock()
                        tilesCache[tileKey] = list
                        lock.unlock()
                    }
                } else {
                    loadTile(zoom: Int(zoom), tileX: tx, tileY: ty, languages: languages)
                }
            }
        }

        clearCache(zoom: Int(zoom), minX: minTileX, maxX: maxTileX, minY: minTileY, maxY: maxTileY)
        filteredAmenities.sort { $0.getTravelEloNumber() > $1.getTravelEloNumber() }
        
        return limit > 0 ? Array(filteredAmenities.prefix(limit)) : filteredAmenities
    }

    // MARK: - Protocol Implementation: Loading Status
    func isLoading() -> Bool {
        lock.lock(); defer { lock.unlock() }
        return !loadingTasks.isEmpty
    }

    func isLoading(rect: QuadRect) -> Bool {
        lock.lock(); defer { lock.unlock() }
        let kRect = KQuadRect(left: rect.left, top: rect.top, right: rect.right, bottom: rect.bottom)
        return loadingTasks.values.contains { task in
            task.isRunning() && KQuadRect.companion.intersects(a: kRect, b: task.mapRect)
        }
    }

    // MARK: - Private Helpers
    private func filterAmenity(_ amenity: OAPOI, _ rect: QuadRect, _ result: inout [OAPOI], _ uniqueIds: inout Set<Int64>, _ loadAll: Bool) {
        let lat = amenity.latitude
        let lon = amenity.longitude
        if (rect.contains(lon, top: lat, right: lon, bottom: lat) || loadAll),
           uniqueIds.insert(amenity.obfId).inserted {
            result.append(amenity)
        }
    }

    private func getPreferredLangs() -> [String] {
        let preferred = OAAppSettings.sharedManager().settingPrefMapLanguage.get()
        var result: [String] = []
        var seen = Set<String>()
        
        if let plugin = OAPluginsHelper.getPlugin(OAWikipediaPlugin.self) as? OAWikipediaPlugin,
           plugin.hasCustomSettings() {
            let pluginLangs = plugin.getLanguagesToShow() ?? []
            if pluginLangs.contains(preferred) {
                if seen.insert(preferred).inserted { result.append(preferred) }
            }
            for lang in pluginLangs where seen.insert(lang).inserted {
                result.append(lang)
            }
        }
        if result.isEmpty { result.append(preferred) }
        return result
    }

    private func createAmenity(_ featureData: WikiCoreHelper.OsmandApiFeatureData) -> OAPOI? {
        let amenity = OAPOI()
        guard let props = featureData.properties else { return nil }

        if let id = props.id, !id.isEmpty {
            amenity.setAdditionalInfo(WIKIDATA_TAG, value: id.hasPrefix("Q") ? id : "Q" + id)
            if let parsedId = Int64(id.replacingOccurrences(of: "Q", with: "")) {
                amenity.obfId = -parsedId
            }
        }

        amenity.name = props.wikiTitle
        // NOTE: android use TransliterationHelper
        amenity.enName = amenity.name ?? ""
        
        if let desc = props.wikiDesc {
            amenity.setAdditionalInfo(DESCRIPTION_TAG, value: desc)
        }
        
        if let labelsJson = props.labelsJson, labelsJson.length > 2 {
            OAMapObject.parseNamesJSON(labelsJson, object: amenity)
        }
        
        if let wikiLangs = props.wikiLangs, !wikiLangs.isEmpty {
            let langArray = wikiLangs.components(separatedBy: ",")
            let langSet = Set(langArray)
            
            amenity.updateContentLocales(langSet)
        }

        if let photo = props.photoTitle, !photo.isEmpty {
            let img = WikiHelper.shared.getImageData(imageFileName: photo)
            amenity.setAdditionalInfo(WIKI_PHOTO_TAG, value: img.imageHiResUrl)
            amenity.wikiIconUrl = img.imageIconUrl
            amenity.wikiImageStubUrl = img.imageStubUrl
        }

        if let geometry = featureData.geometry, let coords = geometry.coordinates, coords.size >= 2 {
            amenity.longitude = coords.get(index: 0)
            amenity.latitude = coords.get(index: 1)
        }
        
        let wikiCat = OAPOIHelper.sharedInstance().getPoiCategory(byName: "osmwiki")
        let category = props.poitype.flatMap { OAPOIHelper.sharedInstance().getPoiCategory(byName: $0) } ?? wikiCat
        let subtype = props.poisubtype ?? "wikiplace"

        if let categoryName = category?.name {
            amenity.type = OAPOIHelper.sharedInstance().getPoiType(byCategory: categoryName, name: subtype)
        } 
        if amenity.type == nil {
            amenity.type = category?.poiTypes.first
        }
        amenity.subType = subtype

        amenity.setTravelEloNumber(props.elo?.int32Value ?? DEFAULT_ELO)
        return amenity
    }

    private func loadTile(zoom: Int, tileX: Int, tileY: Int, languages: [String]) {
        let key = TileKey(zoom: zoom, tileX: tileX, tileY: tileY)
        lock.lock()
        if loadingTasks[key] != nil {
            lock.unlock()
            return
        }
        lock.unlock()

        let mapUtils = KMapUtils.shared
        let tRect = KQuadRect(
            left: mapUtils.getLongitudeFromTile(zoom: Double(zoom), x: Double(tileX)),
            top: mapUtils.getLatitudeFromTile(zoom: Double(zoom), y: Double(tileY)),
            right: mapUtils.getLongitudeFromTile(zoom: Double(zoom), x: Double(tileX + 1)),
            bottom: mapUtils.getLatitudeFromTile(zoom: Double(zoom), y: Double(tileY + 1))
        )
        
        let listener = ExplorePlacesTaskListener {
        } onFinish: { [weak self] result in
            guard let self else { return }
            self.lock.lock()
            let currentlyLoading = !self.loadingTasks.isEmpty
            self.lock.unlock()
            self.notifyListeners(isPartial: currentlyLoading)

            var map: [String: [WikiCoreHelper.OsmandApiFeatureData]] = [:]
            if !result.isEmpty {
                for item in result {
                    if let p = item.properties {
                        let l = (p.lang?.isEmpty == false ? p.lang : nil)
                            ?? (p.wikiLang?.isEmpty == false ? p.wikiLang : nil)
                            ?? "en"
                        map[l, default: []].append(item)
                    }
                }
            }

            for lang in languages where map[lang] == nil {
                map[lang] = []
            }
            self.dbHelper.insertPlaces(zoom: Int32(zoom), tileX: Int32(tileX), tileY: Int32(tileY), placesByLang: map)

            self.lock.lock()
            self.loadingTasks.removeValue(forKey: key)
            self.lock.unlock()
        }

        let task = GetExplorePlacesImagesTask(mapRect: tRect, zoom: Int32(zoom), languages: languages, listener: listener)
        lock.lock()
        loadingTasks[key] = task
        lock.unlock()
        task.execute(params: .init(size: 0) { _ in .init() })
    }

    private func clearCache(zoom: Int, minX: Int, maxX: Int, minY: Int, maxY: Int) {
        lock.lock(); defer { lock.unlock() }
        tilesCache = tilesCache.filter { $0.key.zoom == zoom }
        if tilesCache.count > Self.maxTilesPerCache {
            let sorted = tilesCache.keys.sorted { k1, k2 in
                let d1 = max(0, max(minX - k1.tileX, k1.tileX - maxX)) + max(0, max(minY - k1.tileY, k1.tileY - maxY))
                let d2 = max(0, max(minX - k2.tileX, k2.tileX - maxX)) + max(0, max(minY - k2.tileY, k2.tileY - maxY))
                return d1 < d2
            }
            sorted.dropFirst(Self.maxTilesPerCache).forEach { tilesCache.removeValue(forKey: $0) }
        }
    }
}

// MARK: - Task Listener Adapter
private class ExplorePlacesTaskListener: NSObject, GetExplorePlacesImagesTaskGetImageCardsListener {
    let start: () -> Void
    let finish: ([WikiCoreHelper.OsmandApiFeatureData]) -> Void
    
    init(onStart: @escaping () -> Void, onFinish: @escaping ([WikiCoreHelper.OsmandApiFeatureData]) -> Void) {
        self.start = onStart
        self.finish = onFinish
    }
    
    func onTaskStarted() {
        start()
    }
    
    func onFinish(result: [WikiCoreHelper.OsmandApiFeatureData]) {
        finish(result)
    }
}
