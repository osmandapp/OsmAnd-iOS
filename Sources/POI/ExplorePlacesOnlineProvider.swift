//
//  ExplorePlacesOnlineProvider.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 19.12.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import Foundation
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
        NSLog("[TopWikiTrace][ExplorePlacesOnlineProvider] notifyListeners isPartial=\(isPartial) listeners=\(listeners.count)")
        DispatchQueue.main.async {
            self.listeners.forEach {
                isPartial ? $0.onPartialExplorePlacesDownloaded() : $0.onNewExplorePlacesDownloaded()
            }
        }
    }

    // MARK: - Protocol Implementation: Data Collection
    func getDataCollection(_ rect: QuadRect) -> [OAPOI] {
        getDataCollection(rect, limit: Self.defaultLimitPoints, isCancelled: nil)
    }
    
    @discardableResult
    func getDataCollection(_ rect: QuadRect, limit: Int) -> [OAPOI] {
        getDataCollection(rect, limit: limit, isCancelled: nil)
    }

    @discardableResult
    func getDataCollection(_ rect: QuadRect, limit: Int, isCancelled: (() -> Bool)?) -> [OAPOI] {
        if isCancelled?() ?? false {
            NSLog("[TopWikiTrace][ExplorePlacesOnlineProvider] getDataCollection cancelledBeforeStart rect=(\(rect.left),\(rect.top),\(rect.right),\(rect.bottom))")
            return []
        }

        NSLog("[TopWikiTrace][ExplorePlacesOnlineProvider] getDataCollection start rect=(\(rect.left),\(rect.top),\(rect.right),\(rect.bottom)) limit=\(limit)")
        let kRect = KQuadRect(left: rect.left, top: rect.top, right: rect.right, bottom: rect.bottom)
        pruneLoadingTasks(keeping: kRect)

        if isCancelled?() ?? false {
            NSLog("[TopWikiTrace][ExplorePlacesOnlineProvider] getDataCollection cancelledAfterPrune rect=(\(rect.left),\(rect.top),\(rect.right),\(rect.bottom))")
            return []
        }

        guard let tileRange = resolveTileRange(for: rect) else {
            NSLog("[ExplorePlacesOnlineProvider] -> Coordinate error: Invalid tile range")
            return []
        }
        let zoom = tileRange.zoom
        let minTileX = tileRange.minTileX
        let maxTileX = tileRange.maxTileX
        let minTileY = tileRange.minTileY
        let maxTileY = tileRange.maxTileY
        NSLog("[TopWikiTrace][ExplorePlacesOnlineProvider] getDataCollection tileRange zoom=\(zoom) x=\(minTileX)...\(maxTileX) y=\(minTileY)...\(maxTileY)")

        let loadAll = zoom == Self.maxLevelZoomCache &&
                      (abs(Double(maxTileX - minTileX)) <= Self.loadAllTinyRect)

        var filteredAmenities: [OAPOI] = []
        var uniqueIds = Set<Int64>()
        let languages = getPreferredLangs()

        for tx in minTileX...maxTileX {
            for ty in minTileY...maxTileY {
                if isCancelled?() ?? false {
                    NSLog("[TopWikiTrace][ExplorePlacesOnlineProvider] getDataCollection cancelledMidLoop zoom=\(zoom) tile=(\(tx),\(ty))")
                    return []
                }

                let tileKey = TileKey(zoom: Int(zoom), tileX: tx, tileY: ty)
                
                if !dbHelper.isDataExpired(zoom: Int32(zoom), tileX: Int32(tx), tileY: Int32(ty), languages: languages) {
                    lock.lock()
                    let cached = tilesCache[tileKey]
                    lock.unlock()
                    
                    if let cached {
                        NSLog("[TopWikiTrace][ExplorePlacesOnlineProvider] getDataCollection memoryCache tile=(\(tx),\(ty),z\(zoom)) count=\(cached.count)")
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
                        NSLog("[TopWikiTrace][ExplorePlacesOnlineProvider] getDataCollection dbCache tile=(\(tx),\(ty),z\(zoom)) raw=\(places.count) mapped=\(list.count)")
                        lock.lock()
                        tilesCache[tileKey] = list
                        lock.unlock()
                    }
                } else {
                    if isCancelled?() ?? false {
                        NSLog("[TopWikiTrace][ExplorePlacesOnlineProvider] getDataCollection cancelledBeforeLoadTile tile=(\(tx),\(ty),z\(zoom))")
                        return []
                    }
                    NSLog("[TopWikiTrace][ExplorePlacesOnlineProvider] getDataCollection scheduleLoad tile=(\(tx),\(ty),z\(zoom))")
                    loadTile(zoom: zoom, tileX: tx, tileY: ty, languages: languages)
                }
            }
        }

        clearCache(zoom: zoom, minX: minTileX, maxX: maxTileX, minY: minTileY, maxY: maxTileY)
        filteredAmenities.sort { $0.getTravelEloNumber() > $1.getTravelEloNumber() }
        NSLog("[TopWikiTrace][ExplorePlacesOnlineProvider] getDataCollection done result=\(filteredAmenities.count) uniqueIds=\(uniqueIds.count)")
        
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
            isTaskRelevant(task, for: kRect)
        }
    }

    func cancelLoading(except rect: QuadRect?) {
        if let rect {
            NSLog("[TopWikiTrace][ExplorePlacesOnlineProvider] cancelLoading except=(\(rect.left),\(rect.top),\(rect.right),\(rect.bottom))")
        } else {
            NSLog("[TopWikiTrace][ExplorePlacesOnlineProvider] cancelLoading except=nil")
        }
        let kRect = rect.map { KQuadRect(left: $0.left, top: $0.top, right: $0.right, bottom: $0.bottom) }
        pruneLoadingTasks(keeping: kRect)
    }

    // MARK: - Private Helpers
    private func resolveTileRange(for rect: QuadRect) -> (zoom: Int, minTileX: Int, maxTileX: Int, minTileY: Int, maxTileY: Int)? {
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

        let resolvedZoom = max(Int(zoom), 1)
        let minTileX = Int(mapUtils.getTileNumberX(zoom: Double(resolvedZoom), longitude: rect.left))
        let maxTileX = Int(mapUtils.getTileNumberX(zoom: Double(resolvedZoom), longitude: rect.right))
        let minTileY = Int(mapUtils.getTileNumberY(zoom: Double(resolvedZoom), latitude: rect.top))
        let maxTileY = Int(mapUtils.getTileNumberY(zoom: Double(resolvedZoom), latitude: rect.bottom))
        guard minTileX <= maxTileX, minTileY <= maxTileY else {
            return nil
        }
        return (resolvedZoom, minTileX, maxTileX, minTileY, maxTileY)
    }

    private func isTaskRelevant(_ task: GetExplorePlacesImagesTask, for rect: KQuadRect) -> Bool {
        rect.contains(box: task.mapRect) || KQuadRect.companion.intersects(a: rect, b: task.mapRect)
    }

    private func pruneLoadingTasks(keeping rect: KQuadRect?) {
        var tasksToCancel: [GetExplorePlacesImagesTask] = []
        var cancelledKeys: [TileKey] = []

        lock.lock()
        let keysToRemove = loadingTasks.compactMap { key, task in
            guard let rect else { return key }
            return isTaskRelevant(task, for: rect) ? nil : key
        }
        for key in keysToRemove {
            if let task = loadingTasks.removeValue(forKey: key) {
                tasksToCancel.append(task)
                cancelledKeys.append(key)
            }
        }
        lock.unlock()

        if !cancelledKeys.isEmpty {
            let cancelled = cancelledKeys.map { "(\($0.tileX),\($0.tileY),z\($0.zoom))" }.joined(separator: ",")
            NSLog("[TopWikiTrace][ExplorePlacesOnlineProvider] pruneLoadingTasks cancelled=\(cancelled)")
        }
        tasksToCancel.forEach { $0.cancel() }
    }

    private func filterAmenity(_ amenity: OAPOI, _ rect: QuadRect, _ result: inout [OAPOI], _ uniqueIds: inout Set<Int64>, _ loadAll: Bool) {
        let lat = amenity.latitude
        let lon = amenity.longitude
        if (rect.contains(lon, top: lat, right: lon, bottom: lat) || loadAll),
           uniqueIds.insert(amenity.getSignedId()).inserted {
            result.append(amenity)
        }
    }

    private func getPreferredLangs() -> [String] {
        let preferredLang = OAAppSettings.sharedManager().settingPrefMapLanguage.get()
        let languages = NSMutableOrderedSet()
        if let plugin = OAPluginsHelper.getPlugin(OAWikipediaPlugin.self) as? OAWikipediaPlugin,
           plugin.hasCustomSettings() {
            let pluginLangs = plugin.getLanguagesToShow() ?? []
            if pluginLangs.contains(preferredLang) {
                languages.add(preferredLang)
            }
            languages.addObjects(from: pluginLangs)
        }
        return languages.array.compactMap { $0 as? String }
    }

    private func createAmenity(_ featureData: WikiCoreHelper.OsmandApiFeatureData) -> OAPOI? {
        let amenity = OAPOI()
        guard let properties = featureData.properties else { return nil }
        
        let id = properties.id
        
        if let osmId = properties.osmid?.uint64Value, osmId > 0, osmId != OAMapObject.getInvalidObfId() {
            let osmType = properties.osmtype
            let objectId = ObfConstants.createMapObjectIdFromCleanOsmId(osmId, type: EOAEntityType(rawValue: Int(osmType)))
            amenity.obfId = objectId
        } else if let id, let parsedId = UInt64(id) {
            amenity.obfId = parsedId
        }

        amenity.name = properties.wikiTitle
        // NOTE: android use TransliterationHelper
        amenity.enName = amenity.name ?? ""
        
        if let desc = properties.wikiDesc {
            amenity.setAdditionalInfo(DESCRIPTION_TAG, value: desc)
        }
        
        if let labelsJson = properties.labelsJson, labelsJson.length > 2 {
            OAMapObject.parseNamesJSON(labelsJson, object: amenity)
        }
        
        if let wikiLangs = properties.wikiLangs, !wikiLangs.isEmpty {
            let langArray = wikiLangs.components(separatedBy: ",")
            let langSet = Set(langArray)
            
            amenity.updateContentLocales(langSet)
        }

        if let photo = properties.photoTitle, !photo.isEmpty {
            let img = WikiHelper.shared.getImageData(imageFileName: photo)
            amenity.setAdditionalInfo(WIKI_PHOTO_TAG, value: photo)
            amenity.wikiIconUrl = img.imageIconUrl
            amenity.wikiImageStubUrl = img.imageStubUrl
        }

        if let geometry = featureData.geometry, let coords = geometry.coordinates, coords.size >= 2 {
            amenity.longitude = coords.get(index: 0)
            amenity.latitude = coords.get(index: 1)
        }
        
        let wikiCat = OAPOIHelper.sharedInstance().getPoiCategory(byName: "osmwiki")
        let category = properties.poitype.flatMap { OAPOIHelper.sharedInstance().getPoiCategory(byName: $0) } ?? wikiCat
        let subtype = properties.poisubtype ?? "wikiplace"

        if let categoryName = category.name {
            amenity.type = OAPOIHelper.sharedInstance().getPoiType(byCategory: categoryName, name: subtype)
        } 
        if amenity.type == nil {
            amenity.type = category.poiTypes.first
        }
        amenity.subType = subtype

        amenity.setTravelEloNumber(properties.elo?.int32Value ?? DEFAULT_ELO)
        return amenity
    }

    private func loadTile(zoom: Int, tileX: Int, tileY: Int, languages: [String]) {
        let key = TileKey(zoom: zoom, tileX: tileX, tileY: tileY)
        lock.lock()
        if loadingTasks[key] != nil {
            lock.unlock()
            NSLog("[TopWikiTrace][ExplorePlacesOnlineProvider] loadTile alreadyLoading tile=(\(tileX),\(tileY),z\(zoom))")
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

        var task: GetExplorePlacesImagesTask?
        let listener = ExplorePlacesTaskListener {
            NSLog("[TopWikiTrace][ExplorePlacesOnlineProvider] loadTile started tile=(\(tileX),\(tileY),z\(zoom))")
        } onFinish: { [weak self] result in
            guard let self else { return }

            self.lock.lock()
            guard let currentTask = self.loadingTasks[key],
                  let loadingTask = task,
                  ObjectIdentifier(currentTask) == ObjectIdentifier(loadingTask) else {
                self.lock.unlock()
                NSLog("[TopWikiTrace][ExplorePlacesOnlineProvider] loadTile lateFinishIgnored tile=(\(tileX),\(tileY),z\(zoom)) result=\(result.count)")
                return
            }
            self.lock.unlock()
            NSLog("[TopWikiTrace][ExplorePlacesOnlineProvider] loadTile finish tile=(\(tileX),\(tileY),z\(zoom)) result=\(result.count)")

            var map: [String: [WikiCoreHelper.OsmandApiFeatureData]] = [:]
            var amenities: [OAPOI] = []
            if !result.isEmpty {
                for item in result {
                    if let p = item.properties {
                        let l = (p.lang?.isEmpty == false ? p.lang : nil)
                            ?? (p.wikiLang?.isEmpty == false ? p.wikiLang : nil)
                            ?? "en"
                        map[l, default: []].append(item)
                    }
                    if let amenity = self.createAmenity(item) {
                        amenities.append(amenity)
                    }
                }
            }

            for lang in languages where map[lang] == nil {
                map[lang] = []
            }

            self.dbHelper.insertPlaces(zoom: Int32(zoom), tileX: Int32(tileX), tileY: Int32(tileY), placesByLang: map)

            self.lock.lock()
            guard let currentTask = self.loadingTasks[key],
                  ObjectIdentifier(currentTask) == ObjectIdentifier(loadingTask) else {
                self.lock.unlock()
                NSLog("[TopWikiTrace][ExplorePlacesOnlineProvider] loadTile completionDroppedAfterDbInsert tile=(\(tileX),\(tileY),z\(zoom)) result=\(result.count)")
                return
            }

            self.tilesCache[key] = amenities
            self.loadingTasks.removeValue(forKey: key)
            let currentlyLoading = !self.loadingTasks.isEmpty
            self.lock.unlock()

            NSLog("[TopWikiTrace][ExplorePlacesOnlineProvider] loadTile dbInsert tile=(\(tileX),\(tileY),z\(zoom)) amenities=\(amenities.count) langs=\(map.keys.sorted()) currentlyLoading=\(currentlyLoading)")
            self.notifyListeners(isPartial: currentlyLoading)
        }

        task = GetExplorePlacesImagesTask(mapRect: tRect, zoom: Int32(zoom), languages: languages, listener: listener)
        lock.lock()
        loadingTasks[key] = task
        lock.unlock()
        NSLog("[TopWikiTrace][ExplorePlacesOnlineProvider] loadTile queued tile=(\(tileX),\(tileY),z\(zoom)) rect=(\(tRect.left),\(tRect.top),\(tRect.right),\(tRect.bottom)) languages=\(languages)")
        task?.execute(params: .init(size: 0) { _ in .init() })
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
