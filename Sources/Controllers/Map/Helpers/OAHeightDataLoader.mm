//
//  OAHeightDataLoader.mm
//  OsmAnd
//
//  Created by Max Kojin on 15/06/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

// OsmAnd-java/src/main/java/net/osmand/binary/HeightDataLoader.java
// git revision a9b2a06728af2430efcc0bcf90b0c3568d239da1

#import "OAHeightDataLoader.h"
#import "OsmAnd_Maps-Swift.h"

#include <binaryRead.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/ObfDataInterface.h>
#include <OsmAndCore/Data/Road.h>
#include <OsmAndCore/Map/AmenitySymbolsProvider.h>

static const int ZOOM_TO_LOAD_TILES = 15;
static const int ZOOM_TO_LOAD_TILES_SHIFT_L = ZOOM_TO_LOAD_TILES + 1;
static const int ZOOM_TO_LOAD_TILES_SHIFT_R = 31 - ZOOM_TO_LOAD_TILES;


@implementation OAHeightDataLoader
{
    std::map<RouteSubregion, std::vector<RouteDataObject *>> _loadedSubregions;
    std::map<BinaryMapFile *, std::vector<RouteSubregion>> _readers;
    
    int64_t _osmId;
    std::map<int64_t, std::shared_ptr<const OsmAnd::Road> > _results;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        // force load subregions in map files (if needed)
        // heigh data will be load for selected map file only in loadRouteDataObjects()
        const auto& localResources = OsmAndApp.instance.resourcesManager->getSortedLocalResources();
        for (const auto& resource : localResources)
        {
            cacheBinaryMapFileIfNeeded(resource->localPath.toStdString(), true);
            initBinaryMapFile(resource->localPath.toStdString(), false, true);
        }
        
        std::vector<BinaryMapFile *> readers = getOpenMapFiles();
        for (const auto& r : readers)
        {
            std::vector<RouteSubregion> subregions;
            std::vector<std::shared_ptr<RoutingIndex>> routingIndexes = r->routingIndexes;
            
            for (const auto& rInd : routingIndexes)
            {
                std::vector<RouteSubregion> subregs = rInd->subregions;
                // create a copy to avoid leaks to the original structure
                for (const auto& rs : subregs)
                {
                    RouteSubregion subregionCopy = RouteSubregion(rs);
                    subregions.push_back(subregionCopy);
                }
            }
            
            _readers[r] = subregions;
        }
        
    }
    return self;
}

- (NSMutableArray<OASWptPt *> *)loadHeightDataAsWaypoints:(int64_t)osmId bbox31:(OASKQuadRect *)bbox31
{
    _results.clear();
    _osmId = osmId;
    [self loadRouteDataObjects:bbox31 results:_results];
    
    std::shared_ptr<const OsmAnd::Road> found = _results[osmId];
    if (found != nullptr && found->points31.size() > 0)
    {
        NSMutableArray<OASWptPt *> *waypoints = [NSMutableArray new];
        QVector<float> heightArray = found->calculateHeightArray();
        
        for (int i = 0; i < found->points31.size(); i++)
        {
            OASWptPt *point = [[OASWptPt alloc] init];
            [point setLat:OsmAnd::Utilities::get31LatitudeY(found->points31[i].y)];
            [point setLon:OsmAnd::Utilities::get31LongitudeX(found->points31[i].x)];
            
            int j = i * 2 + 1;
            if (heightArray.size() > j)
            {
                [point setEle:heightArray[j]];
            }
            [waypoints addObject:point];
        }
        
        return waypoints;
    }
    return nil;
}

- (BOOL)loadRouteDataObjects:(OASKQuadRect *)bbox31 results:(std::map<int64_t, std::shared_ptr<const OsmAnd::Road> >&)results
{
    int loaded = 0;
    
    uint32_t left = (int)(bbox31.left) >> ZOOM_TO_LOAD_TILES_SHIFT_R;
    uint32_t top = (int)(bbox31.top) >> ZOOM_TO_LOAD_TILES_SHIFT_R;
    uint32_t right = (int)(bbox31.right) >> ZOOM_TO_LOAD_TILES_SHIFT_R;
    uint32_t bottom = (int)(bbox31.bottom) >> ZOOM_TO_LOAD_TILES_SHIFT_R;
    
    for (int x = left; x <= right; x++)
    {
        for (int y = top; y <= bottom; y++)
        {
            if ([self isCancelled])
            {
                return loaded > 0;
            }
            
            loaded += [self loadRouteDataObjects:x y:y results:results];
        }
    }
    return loaded > 0;
}

- (int)loadRouteDataObjects:(int)x y:(int)y results:(std::map<int64_t, std::shared_ptr<const OsmAnd::Road> >&)results
{
    int loaded = 0;
    std::unordered_set<int64_t> deletedIds;
    std::map<int64_t, std::shared_ptr<RoutingIndex>> usedIds;
    
    uint32_t left = x << ZOOM_TO_LOAD_TILES_SHIFT_R;
    uint32_t top = y << ZOOM_TO_LOAD_TILES_SHIFT_R;
    uint32_t right = (x + 1) << ZOOM_TO_LOAD_TILES_SHIFT_R;
    uint32_t bottom = (y + 1) << ZOOM_TO_LOAD_TILES_SHIFT_R;
    SearchQuery q(left, right, top, bottom);
    
    OsmAndAppInstance app = [OsmAndApp instance];
    const auto& obfsCollection = app.resourcesManager->obfsCollection;
    
    QList< std::shared_ptr<const OsmAnd::Road> > roadsInBBox;
    const auto bbox31 = OsmAnd::AreaI(top, left, bottom, right);
    
    const auto obfDataInterface = obfsCollection->obtainDataInterface(
        &bbox31,
        OsmAnd::MinZoomLevel,
        OsmAnd::MaxZoomLevel,
        OsmAnd::ObfDataTypesMask().set(OsmAnd::ObfDataType::Routing));
    
    QList< std::shared_ptr<const OsmAnd::ObfRoutingSectionReader::DataBlock> > referencedCacheEntries;
    
    obfDataInterface->loadRoads(
        OsmAnd::RoutingDataLevel::Detailed,
        &bbox31,
        &roadsInBBox,
        nullptr,
        nullptr,
        nullptr,
        &referencedCacheEntries,
        nullptr,
        nullptr);
    

    for (std::shared_ptr<const OsmAnd::Road> object : roadsInBBox)
    {
        if ([self isCancelled])
        {
            return loaded;
        }
        
        if ([self publish:object])
        {
            int64_t objId = object->id.id;
            if (deletedIds.count(objId))
            {
                // live-updates, osmand_change=delete
                continue;
            }
            
            if (object->isDeleted())
            {
                deletedIds.insert(objId);
                continue;
            }

            //if (usedIds.containsKey(obj.id) && usedIds.get(obj.id) != obj.region) {
            //    // live-update, changed tags
            //    continue;
            //}
            
            int64_t shiftedId = objId >> SHIFT_ID;
            BOOL valueExisted = results.count(shiftedId) > 0;
            if (!valueExisted)
                loaded += 1;
            
            results[shiftedId] = object;
            //usedIds[objId] = object->region;
        }
    }
    return loaded;
}

- (BOOL)publish:(std::shared_ptr<const OsmAnd::Road>)route
{
    return route != nullptr && (route->id.id >> SHIFT_ID == _osmId);
}

- (BOOL)isCancelled
{
    return _results[_osmId] != nullptr || (_cancellable && [_cancellable isCancelled]);
}

@end
