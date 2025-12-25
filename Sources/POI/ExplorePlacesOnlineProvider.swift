//
//  ExplorePlacesOnlineProvider.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 19.12.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class ExplorePlacesOnlineProvider: ExplorePlacesProvider {

    static let maxLevelZoomCache = 13
    
    private static let defaultLimitPoints = 200
    private static let maxTilesPerQuadRect = 12
    private static let maxTilesPerCache = maxTilesPerQuadRect * 2
    private static let loadAllTinyRect: Double = 0.5
    // FIXME:

  //  private let dbHelper: PlacesDatabaseHelper

    private struct TileKey: Hashable {
        let zoom: Int
        let tileX: Int
        let tileY: Int
    }
    // FIXME:
  //  private var loadingTasks: [TileKey: GetExplorePlacesImagesTask] = [:]
    private var tilesCache: [TileKey: [OAPOI]] = [:]

    private var listeners: [ExplorePlacesListener] = []

    init() {
        // FIXME:
      //  self.dbHelper = PlacesDatabaseHelper(app)
    }

    // MARK: - Listeners

    func addListener(_ listener: ExplorePlacesListener) {
        if !listeners.contains(where: { $0 === listener }) {
            listeners.append(listener)
        }
    }

    func removeListener(_ listener: ExplorePlacesListener) {
        listeners.removeAll { $0 === listener }
    }

    private func notifyListeners(isPartial: Bool) {
        DispatchQueue.main.async {
            self.listeners.forEach {
                isPartial
                    ? $0.onPartialExplorePlacesDownloaded()
                    : $0.onNewExplorePlacesDownloaded()
            }
        }
    }
    

    // MARK: - Preferred languages
    
    private func getPreferredLangs() -> [String] {
        let preferred = OAAppSettings.sharedManager().settingPrefMapLanguage.get()
        var result: [String] = []
        var seen = Set<String>()
        if let plugin = OAPluginsHelper.getPlugin(OAWikipediaPlugin.self) as? OAWikipediaPlugin {
            if plugin.hasCustomSettings() {
                if plugin.getLanguagesToShow().contains(preferred), seen.insert(preferred).inserted {
                    result.append(preferred)
                }
                for lang in plugin.getLanguagesToShow() {
                    if seen.insert(lang).inserted {
                        result.append(lang)
                    }
                }
            }
        }
        return result
    }

    // MARK: - Data loading

    func getDataCollection(_ rect: QuadRect) -> [OAPOI] {
        getDataCollection(rect, limit: Self.defaultLimitPoints)
    }
    
    @discardableResult
    func getDataCollection(_ rect: QuadRect, limit: Int) -> [OAPOI] {

//        // MARK: - Cancel outdated loading tasks
//        objc_sync_enter(loadingTasks)
//        defer { objc_sync_exit(loadingTasks) }
//
//        guard let rect = rect else {
//            loadingTasks.values.forEach { $0.cancel() }
//            return []
//        }
//
       // let kRect = SharedUtil.kQuadRect(rect)
//
//        loadingTasks = loadingTasks.filter { (_, task) in
//            let shouldCancel =
//                !task.isRunning ||
//                (!kRect.contains(task.mapRect) &&
//                 !KQuadRect.intersects(kRect, task.mapRect))
//
//            if shouldCancel {
//                task.cancel()
//            }
//            return !shouldCancel
//        }

        // MARK: - Calculate zoom
        var zoom: Double = Double(Self.maxLevelZoomCache)
        let mapUtils = KMapUtils.shared

        while zoom >= 0 {
            let tileWidth =
            Int(mapUtils.getTileNumberX(zoom: zoom, longitude: rect.right)) -
            Int(mapUtils.getTileNumberX(zoom: zoom, longitude: rect.left)) + 1

            let tileHeight =
            Int(mapUtils.getTileNumberY(zoom: zoom, latitude: rect.bottom)) -
            Int(mapUtils.getTileNumberY(zoom: zoom, latitude: rect.top)) + 1

            if tileWidth * tileHeight <= Self.maxTilesPerQuadRect {
                break
            }
            zoom -= 3
        }

        zoom = max(zoom, 1)

        // MARK: - Tile bounds
        let minTileX = Double(mapUtils.getTileNumberX(zoom: zoom, longitude: rect.left))
        let maxTileX = Double(mapUtils.getTileNumberX(zoom: zoom, longitude: rect.right))
        let minTileY = Double(mapUtils.getTileNumberY(zoom: zoom, latitude: rect.top))
        let maxTileY = Double(mapUtils.getTileNumberY(zoom: zoom, latitude: rect.bottom))

        let loadAll =
        Int(zoom) == Self.maxLevelZoomCache &&
        (abs(maxTileX - minTileX) <= Self.loadAllTinyRect ||
             abs(maxTileY - minTileY) <= Self.loadAllTinyRect)

        // MARK: - Fetch data
        var filteredAmenities: [OAPOI] = []
        var uniqueIds = Set<Int64>()
        let languages = getPreferredLangs()

        for tileX in Int(minTileX)...Int(maxTileX) {
            for tileY in Int(minTileY)...Int(maxTileY) {
                
                //                if !dbHelper.isDataExpired(zoom, tileX, tileY, languages) {
                //
                //                    let tileKey = TileKey(zoom: Int(zoom), tileX: tileX, tileY: tileY)
                //
                //                    if let cachedPlaces = tilesCache[tileKey] {
                //                        for amenity in cachedPlaces {
                //                            filterAmenity(amenity, rect, &filteredAmenities, &uniqueIds, loadAll)
                //                        }
                //                    } else {
                //                        // FIXME:
                //                     //   let places = dbHelper.getPlaces(zoom, tileX, tileY, languages)
                //                        var cached: [OAPOI] = []
                //
                //                        for item in places {
                //                            // FIXME:
                ////                            if let amenity = createAmenity(item) {
                ////                                filterAmenity(
                ////                                    amenity,
                ////                                    into: &filteredAmenities,
                ////                                    rect: rect,
                ////                                    uniqueIds: &uniqueIds,
                ////                                    loadAll: loadAll
                ////                                )
                ////                                cached.append(amenity)
                //                            }
                //                       }
                //
                //                        tilesCache[tileKey] = cached
            }
        }

//                } else {
//                    // FIXME:
//                  //  loadTile(zoom, tileX, tileY, languages)
//                }
          //  }
    //    }

        clearCache(
            zoom: Int(zoom),
            minX: Int(minTileX),
            maxX: Int(maxTileX),
            minY: Int(minTileY),
            maxY: Int(maxTileY)
        )
//}
//}

        // MARK: - Sort by Elo (desc)
//        filteredAmenities.sort {
//            $0.getTravelEloNumber() > $1.getTravelEloNumber()
//        }

        // MARK: - Apply limit
        if limit > 0, filteredAmenities.count > limit {
            return Array(filteredAmenities.prefix(limit))
        }

        return filteredAmenities
    }
//    
//    @objc
//    private func createAmenity(_ featureData: OsmandApiFeatureData) -> OAPOI? {
//        let amenity = OAPOI()
//        let properties = featureData.properties
//
//        // Additional info
//        amenity.setAdditionalInfo(
//            WIKIDATA,
//            app.getString(
//                R.string.wikidata_id_pattern,
//                properties.id
//            )
//        )
//
//        // Names & description
//        amenity.setName(properties.wikiTitle)
//        amenity.setEnName(
//            TransliterationHelper.transliterate(amenity.getName())
//        )
//        amenity.setDescription(properties.wikiDesc)
//
//        // Languages
//        if !Algorithms.isEmpty(properties.wikiLangs) {
//            let langs = Set(properties.wikiLangs.split(separator: ",").map(String.init))
//            amenity.updateContentLocales(langs)
//        }
//
//        // Photo
//        if !Algorithms.isEmpty(properties.photoTitle) {
//            let imageData = WikiHelper.shared.getImageData(properties.photoTitle)
//            amenity.setWikiPhoto(imageData.imageHiResUrl)
//            amenity.setWikiIconUrl(imageData.imageIconUrl)
//            amenity.setWikiImageStubUrl(imageData.imageStubUrl)
//        }
//
//        // Location (lat, lon)
//        let coords = featureData.geometry.coordinates
//        amenity.setLocation(coords[1], coords[0])
//
//        // Category & subtype
//        var poiType = properties.poitype
//        var subtype = properties.poisubtype
//
//        let wikiCategory = app.getPoiTypes().getPoiCategoryByName("osmwiki")
//        var category: PoiCategory? =
//            Algorithms.isEmpty(poiType) ? nil :
//            app.getPoiTypes().getPoiCategoryByName(poiType)
//
//        if Algorithms.isEmpty(subtype) || category == nil {
//            category = wikiCategory
//            subtype = "wikiplace"
//        }
//
//        guard let finalCategory = category else {
//            return nil
//        }
//
//        amenity.setType(finalCategory)
//        amenity.setSubType(subtype)
//
//        // ID
//        if properties.osmid > 0 {
//            let entityType = Entity.EntityType.valueOf(properties.osmtype)
//            let objectId = ObfConstants.createMapObjectIdFromCleanOsmId(
//                properties.osmid,
//                entityType
//            )
//            amenity.setId(objectId)
//        } else {
//            amenity.setId(-Int64(properties.id)!)
//        }
//
//        // Elo
//        amenity.setTravelEloNumber(
//            properties.elo?.intValue ?? DEFAULT_ELO
//        )
//
//        return amenity
//    }



//    func getDataCollection(_ rect: QuadRect, limit: Int) -> [OAPOI] {
//
//        let zoom = calculateZoom(for: rect)
//        let (minX, maxX, minY, maxY) = tileBounds(rect, zoom)
//
//        let loadAll = zoom == Self.maxLevelZoomCache &&
//            (abs(maxX - minX) <= Self.loadAllTinyRect ||
//             abs(maxY - minY) <= Self.loadAllTinyRect)
//
//        var result: [Amenity] = []
//        var uniqueIds = Set<Int64>()
//        let languages = getPreferredLangs()
//
//        for x in Int(minX)...Int(maxX) {
//            for y in Int(minY)...Int(maxY) {
//                if !dbHelper.isDataExpired(zoom: zoom, tileX: x, tileY: y, languages: languages) {
//                    let key = TileKey(zoom: zoom, tileX: x, tileY: y)
//
//                    let amenities = tilesCache[key] ?? loadCachedTile(key, languages)
//                    amenities.forEach {
//                        filterAmenity($0, rect, &result, &uniqueIds, loadAll)
//                    }
//                } else {
//                    loadTile(zoom: zoom, tileX: x, tileY: y, languages: languages)
//                }
//            }
//        }
//
//        clearCache(zoom: zoom, minX: Int(minX), maxX: Int(maxX), minY: Int(minY), maxY: Int(maxY))
//
//        result.sort { $0.travelEloNumber > $1.travelEloNumber }
//
//        return limit > 0 ? Array(result.prefix(limit)) : result
//    }

    // MARK: - Helpers

    private func filterAmenity(
        _ amenity: OAPOI,
        _ rect: QuadRect,
        _ result: inout [OAPOI],
        _ uniqueIds: inout Set<Int64>,
        _ loadAll: Bool
    ) {
        let lat = amenity.getLocation().coordinate.latitude
        let lon = amenity.getLocation().coordinate.longitude

        if (rect.contains(lon, top: lat, right: lon, bottom: lat) || loadAll),
           uniqueIds.insert(amenity.obfId).inserted {
            result.append(amenity)
        }
    }

    private func clearCache(zoom: Int, minX: Int, maxX: Int, minY: Int, maxY: Int) {
//        tilesCache = tilesCache.filter { $0.key.zoom == zoom }
//
//        if tilesCache.count > Self.maxTilesPerCache {
//            let sortedKeys = tilesCache.keys.sorted {
//                abs($0.tileX - minX) + abs($0.tileY - minY)
//                <
//                abs($1.tileX - minX) + abs($1.tileY - minY)
//            }
//            sortedKeys.dropFirst(Self.maxTilesPerCache).forEach {
//                tilesCache.removeValue(forKey: $0)
//            }
//        }
    }

    // MARK: - Loading state
    
    func isLoading() -> Bool {
        return false
    }
    
    func isLoading(rect: QuadRect) -> Bool {
        return false
    }

//    func isLoading() -> Bool {
//       // !loadingTasks.isEmpty
//    }
//
//    func isLoading(rect: QuadRect) -> Bool {
//        return false
//        // FIXME:
////        let kRect = QuadRect(rect: rect)
////        return loadingTasks.values.contains { $0.mapRect.contains(kRect) }
//    }
}
