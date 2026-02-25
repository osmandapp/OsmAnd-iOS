//
//  OAAmenitySearcher.mm
//  OsmAnd
//
//  Created by Max Kojin on 08/08/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

// OsmAnd-java/src/main/java/net/osmand/search/AmenitySearcher.java
// git revision c3d7a8a378dc84251eb7ca72dd10958af86d2225

#import "OAAmenitySearcher.h"
#import "OAPOIHelper.h"
#import "OAPOIHelper+cpp.h"
#import "OAPOI.h"
#import "OAPOIBaseType.h"
#import "OAPOIType.h"
#import "OAPOICategory.h"
#import "OAPOIFilter.h"
#import "OAPOIParser.h"
#import "OAPOIUIFilter.h"
#import "OAPhrasesParser.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "OAUtilities.h"
#import "OASearchPoiTypeFilter.h"
#import "OACollatorStringMatcher.h"
#import "OAMapUtils.h"
#import "OAResultMatcher.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "Localization.h"
#import "OANativeUtilities.h"
#import "OrderedDictionary.h"
#import "OsmAnd_Maps-Swift.h"


#include <OsmAndCore/CommonTypes.h>
#include <OsmAndCore/Data/DataCommonTypes.h>
#include <OsmAndCore/Data/ObfMapSectionInfo.h>
#include <OsmAndCore/Data/ObfPoiSectionInfo.h>
#include <OsmAndCore/Data/Road.h>
#include <OsmAndCore/ObfDataInterface.h>
#include <OsmAndCore/FunctorQueryController.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Search/ISearch.h>
#include <OsmAndCore/Search/BaseSearch.h>
#include <OsmAndCore/Search/AmenitiesByNameSearch.h>
#include <OsmAndCore/Search/AmenitiesInAreaSearch.h>
#include <OsmAndCore/QKeyValueIterator.h>
#include <OsmAndCore/ICU.h>
#include <OsmAndCore.h>
#include <OsmAndCore/Data/Amenity.h>
#include <OsmAndCore/Data/MapObject.h>
#include <OsmAndCore/Data/BinaryMapObject.h>

static const int AMENITY_SEARCH_RADIUS = 50;
static const int AMENITY_SEARCH_RADIUS_FOR_RELATION = 500;

int const kSearchLimitRaw = 5000;
int const kRadiusKmToMetersKoef = 1200.0;
int const kZoomToSearchPOI = 16.0;
using BinaryObjectMatcher = std::function<bool(const std::shared_ptr<const OsmAnd::BinaryMapObject>&)>;


@implementation OAAmenitySearcherRequest

- (instancetype)initWithMapObject:(OAMapObject *)mapObject
{
    self = [super init];
    if (self)
    {
        _osmId = [ObfConstants getOsmObjectId:mapObject];
        _type = [ObfConstants getOsmEntityType:mapObject];
        _names = [[NSMutableArray alloc] init];
        _tags = nil;
        _mainAmenityType = nil;

        if ([mapObject isKindOfClass:[OAPOI class]])
        {
            OAPOI *poi = (OAPOI *)mapObject;
            _latLon = [poi getLocation];
            _wikidata = [poi getWikidata];
            if (poi.name != nil)
                [_names addObject:poi.name];
            if (!NSDictionaryIsEmpty(poi.localizedNames))
                [_names addObjectsFromArray:(NSArray *)poi.localizedNames.allValues];
            _mainAmenityType = poi.subType;
        }
        else if ([mapObject isKindOfClass:[OARenderedObject class]])
        {
            OARenderedObject *renderedObject = (OARenderedObject *)mapObject;
            _latLon = [renderedObject getLocation];
            if (_latLon == nil || !CLLocationCoordinate2DIsValid(_latLon.coordinate))
            {
                _latLon = renderedObject.labelLatLon;
            }
            if (!NSDictionaryIsEmpty(renderedObject.localizedNames))
            {
                [_names addObjectsFromArray:(NSArray *)renderedObject.localizedNames.allValues];
            }
            NSString *value = renderedObject.tags[WIKIDATA_TAG];
            if (value)
            {
                _wikidata = value;
            }
            _tags = [NSMutableDictionary dictionaryWithDictionary:renderedObject.tags];
        }
        else if ([mapObject isKindOfClass:[OATransportStop class]])
        {
            OATransportStop *stop = (OATransportStop *)mapObject;
            [stop findAmenityDataIfNeeded];
            _latLon = [stop getLocation];
            if (stop.name)
            {
                [_names addObject:stop.name];
            }
            if (!NSDictionaryIsEmpty(stop.localizedNames))
            {
                [_names addObjectsFromArray:(NSArray *)stop.localizedNames.allValues];
            }
        }
        else
        {
            _latLon = [mapObject getLocation];
            _wikidata = nil;
            if (!NSDictionaryIsEmpty(mapObject.localizedNames))
            {
                [_names addObjectsFromArray:(NSArray *)mapObject.localizedNames.allValues];
            }
        }
    }
    return self;
}

- (instancetype)initWithMapObject:(OAMapObject *)mapObject names:(NSArray<NSString *> *)names
{
    self = [self initWithMapObject:mapObject];
    if (self)
    {
        _names = [names mutableCopy];
    }
    return self;
}

@end


// MARK: OAAmenitySearcher

@implementation OAAmenitySearcher
{
    OsmAndAppInstance _app;
    int _limitCounter;
    int _searchLimit;
    BOOL _isSearchDone;
    BOOL _breakSearch;
    double _radius;
    NSString *_prefLang;
    
    OsmAnd::AreaI _visibleArea;
    OsmAnd::ZoomLevel _zoomLevel;
    OsmAnd::PointI _myLocation;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _app = [OsmAndApp instance];
        _searchLimit = kSearchLimitRaw;
        _isSearchDone = YES;
        [self updateMyLocation];
    }
    return self;
}

+ (OAAmenitySearcher *)sharedInstance
{
    static dispatch_once_t once;
    static OAAmenitySearcher * sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (NSArray<NSString *> *) getAmenityRepositories:(BOOL)includeTravel
{
    NSMutableArray<NSString *> *travelMaps = [NSMutableArray array];
    NSMutableArray<NSString *> *baseMaps = [NSMutableArray array];
    NSMutableArray<NSString *> *result = [NSMutableArray array];
    
    for (const auto& resource : OsmAndApp.instance.resourcesManager->getLocalResources())
    {
        if (resource->type == OsmAnd::ResourcesManager::ResourceType::Travel ||
            resource->type == OsmAnd::ResourcesManager::ResourceType::MapRegion)
        {
            NSString *fileName = resource->id.toNSString();
            
            if ([fileName hasSuffix:BINARY_TRAVEL_GUIDE_MAP_INDEX_EXT] && includeTravel)
            {
                [travelMaps addObject:fileName];
            }
            else if ([self isWorldMap:fileName])
            {
                [baseMaps addObject:fileName];
            }
            else
            {
                [result addObject:fileName];
            }
            
        }
    }
    
    [result addObjectsFromArray:baseMaps];
    [result addObjectsFromArray:travelMaps];
    
    return result;
}

- (BOOL) isWorldMap:(NSString *)fileName
{
    return [fileName hasPrefix:@"world_"] || [fileName containsString:@"basemap"];
}

- (void) setVisibleScreenDimensions:(OsmAnd::AreaI)area zoomLevel:(OsmAnd::ZoomLevel)zoom
{
    _visibleArea = area;
    _zoomLevel = zoom;
}

- (BOOL) breakSearch
{
    _breakSearch = !_isSearchDone;
    return _breakSearch;
}

- (NSArray<OAPOI *> *)searchAmenitiesWithFilter:(OASearchPoiTypeFilter *)filter searchLatLon:(CLLocation *)searchLatLon radius:(NSInteger)radius includeTravel:(BOOL)includeTravel
{
    return [OAAmenitySearcher findPOI:[OASearchPoiTypeFilter acceptAllPoiTypeFilter] additionalFilter:nil lat:searchLatLon.coordinate.latitude lon:searchLatLon.coordinate.longitude radius:radius includeTravel:includeTravel matcher:nil publish:nil];
}

- (nullable BaseDetailsObject *)searchDetailedObject:(id)object
{
    OAAmenitySearcherRequest *request;
    if ([object isKindOfClass:OAMapObject.class])
    {
        request = [[OAAmenitySearcherRequest alloc] initWithMapObject:object];
    }
    else if ([object isKindOfClass:BaseDetailsObject.class])
    {
        BaseDetailsObject *detailsObject = object;
        if ([detailsObject isObjectFull])
        {
            [self completeGeometry:detailsObject object:detailsObject.objects[0]];
            return detailsObject;
        }
        if (!NSArrayIsEmpty(detailsObject.objects))
        {
            return detailsObject = [self searchDetailedObject:detailsObject.objects[0]];
        }
    }
    BaseDetailsObject *detailsObject;
    if (request)
    {
        detailsObject = [self searchDetailedObjectWithRequest:request];
    }
    
    [self completeGeometry:detailsObject object:object];
    return detailsObject;
}

- (NSMutableArray<OAPOI *> *)filterAmenities:(NSArray<OAPOI *> *)amenities request:(OAAmenitySearcherRequest*) request
{
    int64_t osmId = request.osmId;
    CLLocation *latLon = request.latLon;
    NSString *wikidata = request.wikidata;
    NSArray<NSString *> *names = request.names;

    NSMutableArray<OAPOI *> *filtered = [NSMutableArray array];

    if (osmId > 0 || wikidata != nil)
    {
        filtered = [[self filterByOsmIdOrWikidata:amenities osmId:osmId point:latLon wikidata:wikidata] mutableCopy];
    }

    if (NSArrayIsEmpty(filtered))
    {
        OAPOI *amenity = [self findByName:amenities names:names searchLatLon:latLon];
        if (amenity)
        {
            if ([amenity getOsmId] > 0)
            {
                filtered = [[self filterByOsmIdOrWikidata:amenities
                                                    osmId:[amenity getOsmId]
                                                    point:[amenity getLocation]
                                                 wikidata:[amenity getWikidata]] mutableCopy];
            }
            else
            {
                // Don't exist in android. Bugfix for invalid obfId values from cpp
                [filtered addObject:amenity];
            }
        }
    }

    if (NSArrayIsEmpty(filtered) && !NSDictionaryIsEmpty(request.tags))
    {
        filtered = [[self filterByLatLonAndType:amenities point:latLon tags:request.tags] mutableCopy];
    }

    return filtered;
}

- (nullable BaseDetailsObject *)searchDetailedObjectWithRequest:(OAAmenitySearcherRequest *)request
{
    if (request.latLon == nil)
    {
        return nil;
    }

    CLLocation *latLon = request.latLon;

    NSInteger radius = [request.type isEqualToString:kEntityTypeRelation]
        ? AMENITY_SEARCH_RADIUS_FOR_RELATION
        : AMENITY_SEARCH_RADIUS;

    NSArray<OAPOI *> *amenities = [self searchAmenitiesWithFilter:[OASearchPoiTypeFilter acceptAllPoiTypeFilter]
                                                     searchLatLon:latLon
                                                           radius:radius
                                                    includeTravel:YES];

    NSMutableArray<OAPOI *> *filtered = [self filterAmenities:amenities request:request];

    if (!NSArrayIsEmpty(filtered))
    {
        if (request.mainAmenityType != nil)
        {
            NSString *type = request.mainAmenityType;
            [filtered sortUsingComparator:^NSComparisonResult(OAPOI *a1, OAPOI *a2)
             {
                BOOL m1 = [a1.subType isEqualToString:type];
                BOOL m2 = [a2.subType isEqualToString:type];                
                if (m1 == m2)
                {
                    return NSOrderedSame;
                }
                return m1 ? NSOrderedAscending : NSOrderedDescending;
            }];
        }
        return [[BaseDetailsObject alloc] initWithMapObjects:filtered lang:[[OAAppSettings sharedManager].settingPrefMapLanguage get]];
    }

    return nil;
}

- (void) completeGeometry:(BaseDetailsObject *)detailsObject object:(id)object
{
    if (!detailsObject)
        return;

    NSMutableArray<NSNumber *> *xx;
    NSMutableArray<NSNumber *> *yy;

    if ([object isKindOfClass:OAPOI.class])
    {
        OAPOI *amenity = object;
        xx = amenity.x;
        yy = amenity.y;
    }
    if ([object isKindOfClass:OARenderedObject.class])
    {
        OARenderedObject *renderedObject = object;
        xx = renderedObject.x;
        yy = renderedObject.y;
    }
    if ([object isKindOfClass:BaseDetailsObject.class])
    {
        BaseDetailsObject *base = object;
        xx = [base syntheticAmenity].x;
        yy = [base syntheticAmenity].y;
    }

    if (!NSArrayIsEmpty(xx) && !NSArrayIsEmpty(yy))
    {
        [detailsObject setX:xx];
        [detailsObject setY:yy];
    }
    else
    {
        const auto dataObjects = [self searchBinaryMapDataForAmenity:detailsObject.syntheticAmenity limit:1];
        for (const auto& dataObject : dataObjects)
        {
            if ([self copyCoordinates:detailsObject binaryObject:dataObject])
                break;
        }
    }
}

- (BOOL)copyCoordinates:(BaseDetailsObject *)detailsObject binaryObject:(const std::shared_ptr<const OsmAnd::BinaryMapObject>&)mapObject
{
    const int pointsLength = mapObject->points31.size();
    if ([detailsObject getPointsLength] < pointsLength)
    {
        [detailsObject clearGeometry];
        for (int i = 0; i < pointsLength; i++)
        {
            [detailsObject addX:@(mapObject->points31[i].x)];
            [detailsObject addY:@(mapObject->points31[i].y)];
        }
    }
    return pointsLength > 0;
}

- (QList<std::shared_ptr<const OsmAnd::BinaryMapObject>>) searchBinaryMapDataForAmenity:(OAPOI *)amenity limit:(int)limit
{
    const auto osmId = [ObfConstants getOsmObjectId:amenity];
    const BOOL checkId = osmId > 0;

    NSString *wikidata = [amenity getWikidata];;
    const BOOL checkWikidata = !NSStringIsEmpty(wikidata);
    const QString qWikidata = QString::fromNSString(wikidata);

    NSString *routeId = [amenity getRouteId];
    const BOOL checkRouteId = !NSStringIsEmpty(routeId);
    const QString qRouteId = QString::fromNSString(routeId);

    BinaryObjectMatcher matcher = [=](const std::shared_ptr<const OsmAnd::BinaryMapObject>& obj) -> bool
    {
        const auto objId = obj->id.getOsmId() >> 1;
        if (checkId && osmId == objId) {
            return true;
        }
        
        for (const auto& captionAttributeId : OsmAnd::constOf(obj->captionsOrder)) {
            const QString & value = OsmAnd::constOf(obj->captions)[captionAttributeId];
            if ((checkWikidata && value == qWikidata) || (checkRouteId && value == qRouteId)) {
                return true;
            }
        }
        return false;
    };

    return [self searchBinaryMapDataObjects:[amenity getLocation] matcher:matcher limit:limit];
}

- (QList<std::shared_ptr<const OsmAnd::BinaryMapObject>>) searchBinaryMapDataObjects:(CLLocation *)latLon matcher:(BinaryObjectMatcher)matcher limit:(int)limit
{
    QList<std::shared_ptr<const OsmAnd::BinaryMapObject>> list;
    const int y31 = OsmAnd::Utilities::get31TileNumberY(latLon.coordinate.latitude);
    const int x31 = OsmAnd::Utilities::get31TileNumberX(latLon.coordinate.longitude);

    const OsmAnd::AreaI bbox31(
        OsmAnd::PointI(x31, y31),
        OsmAnd::PointI(x31 + 1, y31 + 1)
    );

    const QList< std::shared_ptr<const OsmAnd::ObfFile> > repositories = [OAAmenitySearcher getAmenityRepositories:YES];
    const auto& obfsCollection = _app.resourcesManager->obfsCollection;
    if (!obfsCollection)
        return list;
    
    for (const std::shared_ptr<const OsmAnd::ObfFile> & res : repositories)
    {
        if (limit != -1 && list.size() >= limit)
            break;

        const auto& obfsDataInterface = obfsCollection->obtainDataInterface(res);
        if (!obfsDataInterface)
            continue;

        QList<std::shared_ptr<const OsmAnd::BinaryMapObject>> loadedBinaryMapObjects;
        QList<std::shared_ptr<const OsmAnd::Road>> loadedRoads;
        auto tileSurfaceType = OsmAnd::MapSurfaceType::Undefined;

        obfsDataInterface->loadBinaryMapObjects(
            &loadedBinaryMapObjects,
            &tileSurfaceType,
            nullptr,
            OsmAnd::ZoomLevel15,
            &bbox31
        );

        for (const auto& obj : loadedBinaryMapObjects)
        {
            if (!obj)
                continue;

            if (!matcher || matcher(obj))
            {
                list.append(obj);
                if (limit != -1 && list.size() >= limit)
                    break;
            }
        }
    }

    return list;
}

- (NSMutableArray<OAPOI *> *)filterByOsmIdOrWikidata:(NSArray<OAPOI *> *)amenities
                                               osmId:(int64_t)osmId
                                               point:(CLLocation *)point
                                            wikidata:(nullable NSString *)wikidata
{
    NSMutableArray<OAPOI *> *result = [NSMutableArray array];
    double minDist = AMENITY_SEARCH_RADIUS_FOR_RELATION * 4;

    for (OAPOI *amenity in amenities)
    {
        if (amenity.obfId != 0)
        {
            NSString *wiki = [amenity getWikidata];
            BOOL wikiEqual = (wiki && [wiki isEqualToString:wikidata]);
            int64_t amenityOsmId = [amenity getOsmId];
            BOOL idEqual = (amenityOsmId > 0 && amenityOsmId == osmId);

            if ((idEqual || wikiEqual) && ![amenity isClosed])
            {
                double dist = [OAMapUtils getDistance:amenity.getLocation.coordinate second:point.coordinate];
                if (dist < minDist)
                {
                    [result insertObject:amenity atIndex:0]; // to the top
                    minDist = dist;
                }
                else
                {
                    [result addObject:amenity];
                }
            }
        }
    }
    return [result copy];
}

- (NSMutableArray<OAPOI *> *)filterByLatLonAndType:(NSArray<OAPOI *> *)amenities
                                             point:(CLLocation *)point
                                              tags:(NSDictionary *)tags
{
    NSMutableArray<OAPOI *> *result = [NSMutableArray array];
    for (OAPOI *amenity in amenities)
    {
        if ([OAMapUtils areLocationEqual:amenity.getLocation l2:point])
        {
            NSString * type = amenity.subType;
            for (NSString *key in tags)
            {
                if ([type isEqualToString:tags[key]])
                {
                    [result addObject:amenity];
                    break;
                }
            }
            break;
        }
    }
    return [result copy];
}

- (nullable OAPOI *)findByName:(NSArray<OAPOI *> *)amenities names:(NSArray<NSString *> *)names searchLatLon:(CLLocation *)searchLatLon
{
    if (NSArrayIsEmpty(names) || NSArrayIsEmpty(amenities))
        return nil;

    NSArray<OAPOI *> *filtered = [amenities filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(OAPOI *poi, NSDictionary *_) {
        return !poi.isClosed && [self namesMatcher:poi matchList:names matchAllLanguagesAndAltNames:NO];
    }]];
    
    NSArray<OAPOI *> *sorted = [filtered sortedArrayUsingComparator:^NSComparisonResult(OAPOI *a, OAPOI *b) {
        double da = [OAMapUtils getDistance:a.getLocation.coordinate second:searchLatLon.coordinate];
        double db = [OAMapUtils getDistance:b.getLocation.coordinate second:searchLatLon.coordinate];
        return [@(da) compare:@(db)];
    }];

    for (OAPOI *amenity in sorted)
    {
        NSString *travelRouteId = amenity.getAdditionalInfo[@"route_id"];
        if (![amenity isClosed] && [amenity isRoutePoint] && NSStringIsEmpty(amenity.name) && travelRouteId && [names containsObject:travelRouteId])
        {
            return amenity;
        }
    }

    for (OAPOI *amenity in sorted)
    {
        if ([self namesMatcher:amenity matchList:names matchAllLanguagesAndAltNames:YES])
        {
            return amenity;
        }
    }

    return nil;
}

- (BOOL)namesMatcher:(OAPOI *)amenity matchList:(NSArray<NSString *> *)matchList matchAllLanguagesAndAltNames:(BOOL)matchAllLanguagesAndAltNames
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    NSString *lang = [settings.settingPrefMapLanguage get];
    BOOL transliterate = [settings.settingMapLanguageTranslit get];

    NSString *poiSimpleFormat = [[OAPOIHelper sharedInstance] getPoiStringWithoutType:amenity];
    if (poiSimpleFormat && [matchList containsObject:poiSimpleFormat])
    {
        return YES;
    }

    NSString *amenityName = [amenity getName:lang transliterate:transliterate];
    if (!NSStringIsEmpty(amenityName))
    {
        for (NSString *match in matchList)
        {
            if ([match hasSuffix:amenityName] || [match isEqualToString:amenityName])
            {
                return YES;
            }
        }
    }
    
    OAPOIType *st = [[OAPOIHelper sharedInstance] getPoiTypeByName:amenity.subType];
    if (st)
    {
        if (st.nameLocalized && [matchList containsObject:st.nameLocalized])
        {
            return YES;
        }
    }
    else
    {
        if ([matchList containsObject:amenity.subType])
        {
            return YES;
        }
    }

    if (matchAllLanguagesAndAltNames)
    {
        NSMutableSet<NSString *> *allAmenityNames = [NSMutableSet set];
        [allAmenityNames addObjectsFromArray:amenity.getAltNamesMap.allValues];
        [allAmenityNames addObjectsFromArray:[amenity getNamesMap:YES].allValues];

        NSString *typeName = amenity.subType;
        if (!NSStringIsEmpty(typeName))
        {
            for (NSString *n in allAmenityNames.allObjects)
            {
                [allAmenityNames addObject:[NSString stringWithFormat:@"%@ %@", typeName, n]];
            }
        }

        for (NSString *match in matchList)
        {
            if ([allAmenityNames containsObject:match])
            {
                return YES;
            }
        }
    }

    return NO;
}


// MARK: OAPOIHeler poi find methods
// here are all existed methods exrtracted as is.

- (void) updateMyLocation
{
    CLLocation* lastKnownLocation = [OsmAndApp instance].locationServices.lastKnownLocation;
    auto mapTarget31 = [OsmAndApp instance].data.mapLastViewedState.target31;
    _myLocation = lastKnownLocation
        ? OsmAnd::PointI(get31TileNumberX(lastKnownLocation.coordinate.longitude), get31TileNumberY(lastKnownLocation.coordinate.latitude))
        : OsmAnd::PointI(mapTarget31.x, mapTarget31.y);
}

- (void) onPOIFound:(const OsmAnd::ISearch::IResultEntry&)resultEntry
{
    OAPOI *poi = [self.class parsePOI:resultEntry];
    if (poi)
    {
        const auto amenity = ((OsmAnd::AmenitiesByNameSearch::ResultEntry&)resultEntry).amenity;
        poi.distanceMeters = OsmAnd::Utilities::squareDistance31(_myLocation, amenity->position31);
        
        _limitCounter--;
        
        if (_delegate)
            [_delegate poiFound:poi];
    }
}

- (void) onPOIFound:(const OsmAnd::ISearch::IResultEntry&)resultEntry poi:(OAPOI *)poi
{
    if (poi)
    {
        const auto amenity = ((OsmAnd::AmenitiesByNameSearch::ResultEntry&)resultEntry).amenity;
        poi.distanceMeters = OsmAnd::Utilities::squareDistance31(_myLocation, amenity->position31);
        
        _limitCounter--;
        
        if (_delegate)
            [_delegate poiFound:poi];
    }
}

+ (QList< std::shared_ptr<const OsmAnd::ObfFile> >) getAmenityRepositories:(BOOL)includeTravel
{
    QList< std::shared_ptr<const OsmAnd::ObfFile> > baseMaps;
    QList< std::shared_ptr<const OsmAnd::ObfFile> > result;
    
    OsmAndAppInstance app = [OsmAndApp instance];
    QList<std::shared_ptr<const OsmAnd::ObfFile> > obfFiles = app.resourcesManager->obfsCollection->getObfFiles();
    
    std::sort(obfFiles.begin(), obfFiles.end(), [](const auto &a, const auto &b) {
        NSString *nameA = a->filePath.toNSString();
        NSString *nameB = b->filePath.toNSString();
        if (nameA)
            nameA = [OAUtilities simplifyFileName:[nameA lastPathComponent]];
        if (nameB)
            nameB = [OAUtilities simplifyFileName:[nameB lastPathComponent]];
        
        return [nameA compare:nameB] == NSOrderedAscending;
    });
    
    for (const auto& file : obfFiles)
    {
        NSString *path = file->filePath.toNSString();
        if ([path hasSuffix:BINARY_TRAVEL_GUIDE_MAP_INDEX_EXT])
        {
            // android has here TravelRendererHelper.getFileVisibilityProperty()
            //if (!includeTravel || !app.getTravelRendererHelper().getFileVisibilityProperty(fileName).get()) {
            if (!includeTravel)
                continue;
        }
        
        if ([self isWorldMap:path])
            baseMaps.append(file);
        else
            result.append(file);
    }
    result.append(baseMaps);
    return result;
}

+ (NSArray<NSString *> *) getAmenityRepositoriesNames:(BOOL)includeTravel
{
    NSMutableArray<NSString *> *filePaths = [NSMutableArray new];
    const auto files = [self getAmenityRepositories:includeTravel];
    for (const auto file : files)
    {
        [filePaths addObject:file->filePath.toNSString()];
    }
    return filePaths;
}

+ (BOOL) isWorldMap:(NSString *)obfFilePath
{
    NSString *fileName = [[obfFilePath lastPathComponent] lowerCase];
    return [fileName hasPrefix:@"world_"] || [fileName containsString:@"basemap"];
}

+ (OAPOIRoutePoint *) distFromLat:(double)latitude longitude:(double)longitude locations:(NSArray<CLLocation *> *)locations radius:(double)radius
{
    double dist = radius + 0.1;
    CLLocation *l = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
    OAPOIRoutePoint *rp = nil;
    // Special iterations because points stored by pairs!
    for (int i = 1; i < locations.count; i += 2)
    {
        double d = [OAMapUtils getOrthogonalDistance:l fromLocation:locations[i - 1] toLocation:locations[i]];
        if (d < dist)
        {
            rp = [[OAPOIRoutePoint alloc] init];
            dist = d;
            rp.deviateDistance = dist;
            rp.pointA = locations[i - 1];
            rp.pointB = locations[i];
        }
    }
    if (rp && rp.deviateDistance != 0 && rp.pointA && rp.pointB)
    {
        rp.deviationDirectionRight = [OAMapUtils rightSide:latitude lon:longitude aLat:rp.pointA.coordinate.latitude aLon:rp.pointA.coordinate.longitude bLat:rp.pointB.coordinate.latitude bLon:rp.pointB.coordinate.longitude];
    }
    return rp;
}

+ (OAPOI *) parsePOI:(const OsmAnd::ISearch::IResultEntry&)resultEntry
{
    return [self.class parsePOI:resultEntry withValues:YES withContent:YES];
}

+ (nullable OAPOI *) parsePOI:(const OsmAnd::ISearch::IResultEntry&)resultEntry withValues:(BOOL)withValues withContent:(BOOL)withContent
{
    const auto& amenity = ((OsmAnd::AmenitiesByNameSearch::ResultEntry&)resultEntry).amenity;
    OAPOIType *type = [self.class parsePOITypeByAmenity:amenity];
    return [self.class parsePOIByAmenity:amenity type:type withValues:withValues withContent:withContent];
}

+ (OAPOIType *) parsePOITypeByAmenity:(const std::shared_ptr<const OsmAnd::Amenity> &)amenity
{
    OAPOIHelper *helper = [OAPOIHelper sharedInstance];
    OAPOIType *type = nil;
    if (!amenity->categories.isEmpty() && ![[OAAppSettings sharedManager] isTypeDisabled:amenity->subType.toNSString()])
    {
        const auto& catList = amenity->getDecodedCategories();
        if (!catList.isEmpty())
        {
            NSString *category = catList.first().category.toNSString();
            NSString *subCategory = catList.first().subcategory.toNSString();
            
            type = [helper getPoiTypeByCategory:category name:subCategory];
            if (!type)
            {
                OAPOICategory *c = [[OAPOICategory alloc] initWithName:category];
                type = [[OAPOIType alloc] initWithName:subCategory category:c];
                type.nameLocalized = [helper getPhrase:type];
                type.nameLocalizedEN = [helper getPhraseEN:type];
            }
        }
    }
    return type;
}

+ (OAPOI *) parsePOIByAmenity:(const std::shared_ptr<const OsmAnd::Amenity> &)amenity
{
    OAPOIType *type = [self.class parsePOITypeByAmenity:amenity];
    return [self.class parsePOIByAmenity:amenity type:type];
}

+ (OAPOI *) parsePOIByAmenity:(const std::shared_ptr<const OsmAnd::Amenity> &)amenity type:(OAPOIType *)type
{
    return [self.class parsePOIByAmenity:amenity type:type withValues:YES withContent:YES];
}

+ (OAPOI *) parsePOIByAmenity:(const std::shared_ptr<const OsmAnd::Amenity> &)amenity type:(OAPOIType *)type withValues:(BOOL)withValues withContent:(BOOL)withContent
{
    if (!type || type.mapOnly || [[OAAppSettings sharedManager] isTypeDisabled:amenity->subType.toNSString()])
        return nil;
    
    OsmAnd::LatLon latLon = OsmAnd::Utilities::convert31ToLatLon(amenity->position31);
    NSString *lang = [OAAppSettings sharedManager].settingPrefMapLanguage.get;
    
    OAPOI *poi = [[OAPOI alloc] init];
    poi.obfId = amenity->id;
    poi.latitude = latLon.latitude;
    poi.longitude = latLon.longitude;
    poi.name = amenity->nativeName.toNSString();
    poi.cityName = amenity->getCityFromTagGroups(QString::fromNSString(lang)).toNSString();
    
    NSMutableDictionary *names = [NSMutableDictionary dictionary];
    NSString *nameLocalized = [OAPOIHelper processLocalizedNames:amenity->localizedNames nativeName:amenity->nativeName names:names];
    if (nameLocalized.length > 0)
        poi.nameLocalized = nameLocalized;
    
    MutableOrderedDictionary *content = [MutableOrderedDictionary new];
    MutableOrderedDictionary *values = [MutableOrderedDictionary new];
    [OAPOIHelper processDecodedValues:amenity->getDecodedValues() content:(withContent ? content : nil) values:(withValues ? values : nil)];
    poi.values = values;
    poi.localizedContent = content;
    
    if (!poi.nameLocalized)
        poi.nameLocalized = poi.name;
    
    poi.type = type;
    poi.subType = amenity->subType.toNSString();

    if (poi.name.length == 0)
        poi.name = type.nameLocalized;
    if (poi.nameLocalized.length == 0)
        poi.nameLocalized = type.nameLocalized;
    if (poi.enName.length == 0)
        poi.enName = type.nameLocalizedEN;

    if (names.count == 0)
    {
        NSString *lang = [OAAppSettings sharedManager].settingPrefMapLanguage.get;
        NSString *transliterated = type.nameLocalized && type.nameLocalized.length > 0 ? OsmAnd::ICU::transliterateToLatin(QString::fromNSString(type.nameLocalized)).toNSString() : @"";
        [names setObject:transliterated forKey:@""];
        [names setObject:type.nameLocalized forKey:lang ? lang : @""];
        [names setObject:type.nameLocalizedEN forKey:@"en"];
    }
    poi.localizedNames = names;
    
    return poi;
}

- (void) findPOIsByKeyword:(NSString *)keyword
{
    int radius = -1;
    [self findPOIsByKeyword:keyword categoryName:nil poiTypeName:nil radiusIndex:&radius];
}

- (void) findPOIsByKeyword:(NSString *)keyword categoryName:(NSString *)categoryName poiTypeName:(NSString *)typeName radiusIndex:(int *)radiusIndex
{
    _isSearchDone = NO;
    _breakSearch = NO;
    if (*radiusIndex  < 0)
        _radius = 0.0;
    else
        _radius = kSearchRadiusKm[*radiusIndex] * kRadiusKmToMetersKoef;
    
    [self updateMyLocation];
    
    const auto& obfsCollection = _app.resourcesManager->obfsCollection;
    
    std::shared_ptr<const OsmAnd::IQueryController> ctrl;
    ctrl.reset(new OsmAnd::FunctorQueryController([self]
                                       (const OsmAnd::FunctorQueryController* const controller)
                                       {
                                           // should break?
                                           return (_radius == 0.0 && _limitCounter < 0) || _breakSearch;
                                       }));
    
    _limitCounter = _searchLimit;
    
    _prefLang = [OAAppSettings sharedManager].settingPrefMapLanguage.get;
    
    if (_radius == 0.0)
    {
        const std::shared_ptr<OsmAnd::AmenitiesByNameSearch::Criteria>& searchCriteria = std::shared_ptr<OsmAnd::AmenitiesByNameSearch::Criteria>(new OsmAnd::AmenitiesByNameSearch::Criteria);
        
        searchCriteria->name = QString::fromNSString(keyword ? keyword : @"");
        searchCriteria->obfInfoAreaFilter = _visibleArea;
        
        const auto search = std::shared_ptr<const OsmAnd::AmenitiesByNameSearch>(new OsmAnd::AmenitiesByNameSearch(obfsCollection));
        search->performSearch(*searchCriteria,
                              [self]
                              (const OsmAnd::ISearch::Criteria& criteria, const OsmAnd::ISearch::IResultEntry& resultEntry)
                              {
                                  [self onPOIFound:resultEntry];
                              },
                              ctrl);
    }
    else
    {
        const std::shared_ptr<OsmAnd::AmenitiesInAreaSearch::Criteria>& searchCriteria = std::shared_ptr<OsmAnd::AmenitiesInAreaSearch::Criteria>(new OsmAnd::AmenitiesInAreaSearch::Criteria);
                
        auto categoriesFilter = QHash<QString, QStringList>();
        if (categoryName && typeName) {
            categoriesFilter.insert(QString::fromNSString(categoryName), QStringList(QString::fromNSString(typeName)));
        } else if (categoryName) {
            categoriesFilter.insert(QString::fromNSString(categoryName), QStringList());
        }
        searchCriteria->categoriesFilter = categoriesFilter;
        
        while (true)
        {
            searchCriteria->bbox31 = (OsmAnd::AreaI)OsmAnd::Utilities::boundingBox31FromAreaInMeters(_radius, _myLocation);
            
            const auto search = std::shared_ptr<const OsmAnd::AmenitiesInAreaSearch>(new OsmAnd::AmenitiesInAreaSearch(obfsCollection));
            search->performSearch(*searchCriteria,
                                  [self]
                                  (const OsmAnd::ISearch::Criteria& criteria, const OsmAnd::ISearch::IResultEntry& resultEntry)
                                  {
                                      [self onPOIFound:resultEntry];
                                  },
                                  ctrl);
            
            if (_limitCounter == _searchLimit && _radius < 12000.0)
            {
                *radiusIndex += 1;
                _radius = kSearchRadiusKm[*radiusIndex] * kRadiusKmToMetersKoef;
            }
            else
            {
                break;
            }
        }
    }

    _isSearchDone = YES;
    
    if (_delegate)
        [_delegate searchDone:_breakSearch];

}

- (void) findPOIsByFilter:(OAPOIUIFilter *)filter radiusIndex:(int *)radiusIndex
{
    _isSearchDone = NO;
    _breakSearch = NO;
    if (*radiusIndex  < 0)
        _radius = 0.0;
    else
        _radius = kSearchRadiusKm[*radiusIndex] * kRadiusKmToMetersKoef;
    
    [self updateMyLocation];
    
    if (filter && ![filter isEmpty])
    {
        const auto& obfsCollection = _app.resourcesManager->obfsCollection;
        
        std::shared_ptr<const OsmAnd::IQueryController> ctrl;
        ctrl.reset(new OsmAnd::FunctorQueryController([self]
                                                      (const OsmAnd::FunctorQueryController* const controller)
                                                      {
                                                          // should break?
                                                          return (_radius == 0.0 && _limitCounter < 0) || _breakSearch;
                                                      }));
        
        _limitCounter = _searchLimit;
        
        _prefLang = [OAAppSettings sharedManager].settingPrefMapLanguage.get;
        
        const std::shared_ptr<OsmAnd::AmenitiesInAreaSearch::Criteria>& searchCriteria = std::shared_ptr<OsmAnd::AmenitiesInAreaSearch::Criteria>(new OsmAnd::AmenitiesInAreaSearch::Criteria);
        
        auto categoriesFilter = QHash<QString, QStringList>();
        NSMapTable<OAPOICategory *, NSMutableSet<NSString *> *> *types = [filter getAcceptedTypes];
        for (OAPOICategory *category in types.keyEnumerator)
        {
            QStringList list = QStringList();
            NSSet<NSString *> *subcategories = [types objectForKey:category];
            if (subcategories != [OAPOIBaseType nullSet])
            {
                for (NSString *sub in subcategories)
                    list << QString::fromNSString(sub);
            }
            categoriesFilter.insert(QString::fromNSString(category.name), list);
        }
        searchCriteria->categoriesFilter = categoriesFilter;
        
        OAAmenityNameFilter *nameFilter = nil;
        if (filter.filterByName.length > 0)
            nameFilter = [filter getNameFilter:filter.filterByName];
        
        while (true)
        {
            searchCriteria->bbox31 = (OsmAnd::AreaI)OsmAnd::Utilities::boundingBox31FromAreaInMeters(_radius, _myLocation);
            
            const auto search = std::shared_ptr<const OsmAnd::AmenitiesInAreaSearch>(new OsmAnd::AmenitiesInAreaSearch(obfsCollection));
            search->performSearch(*searchCriteria,
                                  [self, &nameFilter]
                                  (const OsmAnd::ISearch::Criteria& criteria, const OsmAnd::ISearch::IResultEntry& resultEntry)
                                  {
                                      OAPOI *poi = [self.class parsePOI:resultEntry];
                                      if (!nameFilter || [nameFilter accept:poi])
                                          [self onPOIFound:resultEntry poi:poi];
                                  },
                                  ctrl);
            
            if (_limitCounter == _searchLimit && _radius < 12000.0)
            {
                *radiusIndex += 1;
                _radius = kSearchRadiusKm[*radiusIndex] * kRadiusKmToMetersKoef;
            }
            else
            {
                break;
            }
        }
    }
    
    _isSearchDone = YES;
    
    if (_delegate)
        [_delegate searchDone:_breakSearch];
}

+ (OAPOI *)findPOIByName:(NSString *)name lat:(double)lat lon:(double)lon
{
    auto keyword = QString::fromNSString(name);
    OsmAnd::PointI pointI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(lat, lon));
    const auto& searchCriteria = std::make_shared<OsmAnd::AmenitiesInAreaSearch::Criteria>();
    searchCriteria->bbox31 = (OsmAnd::AreaI)OsmAnd::Utilities::boundingBox31FromAreaInMeters(15, pointI);
    
    const auto& obfsCollection = [OsmAndApp instance].resourcesManager->obfsCollection;
    const auto search = std::make_shared<const OsmAnd::AmenitiesInAreaSearch>(obfsCollection);

    std::shared_ptr<const OsmAnd::Amenity> amenity;
    std::shared_ptr<const OsmAnd::IQueryController> ctrl;
    ctrl.reset(new OsmAnd::FunctorQueryController([self, &amenity]
                                                  (const OsmAnd::IQueryController* const controller)
                                                  {
                                                      return amenity != nullptr;
                                                  }));
    OAAppSettings *settings = [OAAppSettings sharedManager];
    search->performSearch(*searchCriteria,
                          [self, &amenity, &keyword, settings]
                          (const OsmAnd::ISearch::Criteria& criteria, const OsmAnd::ISearch::IResultEntry& resultEntry)
                          {
                              auto a = ((OsmAnd::AmenitiesInAreaSearch::ResultEntry&)resultEntry).amenity;
                              if (![settings isTypeDisabled:a->subType.toNSString()] && (a->nativeName == keyword || a->localizedNames.contains(keyword)))
                                  amenity = qMove(a);
                          }, ctrl);
    if (amenity)
        return [OAAmenitySearcher parsePOIByAmenity:amenity];

    return nil;
}

+ (OAPOI *) findPOIByOsmId:(uint64_t)osmId lat:(double)lat lon:(double)lon
{
    OsmAndAppInstance app = [OsmAndApp instance];
    const auto& obfsCollection = app.resourcesManager->obfsCollection;
    
    std::shared_ptr<const OsmAnd::IQueryController> ctrl;
    bool cancel = false;
    ctrl.reset(new OsmAnd::FunctorQueryController([&cancel]
                                                  (const OsmAnd::FunctorQueryController* const controller)
                                                  {
                                                      return cancel;
                                                  }));
    
    const std::shared_ptr<OsmAnd::AmenitiesInAreaSearch::Criteria>& searchCriteria = std::shared_ptr<OsmAnd::AmenitiesInAreaSearch::Criteria>(new OsmAnd::AmenitiesInAreaSearch::Criteria);
    

    OsmAnd::LatLon latLon(lat, lon);
    const auto location = OsmAnd::Utilities::convertLatLonTo31(latLon);
    searchCriteria->bbox31 = (OsmAnd::AreaI)OsmAnd::Utilities::boundingBox31FromAreaInMeters(15, location);
    
    const auto search = std::shared_ptr<const OsmAnd::AmenitiesInAreaSearch>(new OsmAnd::AmenitiesInAreaSearch(obfsCollection));
    OAPOI *res = nil;
    search->performSearch(*searchCriteria,
                          [&osmId, &res, &cancel]
                          (const OsmAnd::ISearch::Criteria& criteria, const OsmAnd::ISearch::IResultEntry& resultEntry)
                          {
                                OAPOI *poi = [OAAmenitySearcher parsePOI:resultEntry];
                                if (poi && osmId == [ObfConstants getOsmObjectId:poi])
                                {
                                    res = poi;
                                    cancel = true;
                                }
                          },
                          ctrl);
    
    return res;
}


+ (OAPOI *) findPOIByOriginName:(NSString *)originName lat:(double)lat lon:(double)lon
{
    OsmAndAppInstance app = [OsmAndApp instance];
    const auto& obfsCollection = app.resourcesManager->obfsCollection;
    
    std::shared_ptr<const OsmAnd::IQueryController> ctrl;
    bool cancel = false;
    ctrl.reset(new OsmAnd::FunctorQueryController([&cancel]
                                                  (const OsmAnd::FunctorQueryController* const controller)
                                                  {
                                                      // should break?
                                                      return cancel;
                                                  }));
    
    const std::shared_ptr<OsmAnd::AmenitiesInAreaSearch::Criteria>& searchCriteria = std::shared_ptr<OsmAnd::AmenitiesInAreaSearch::Criteria>(new OsmAnd::AmenitiesInAreaSearch::Criteria);
    

    OsmAnd::LatLon latLon(lat, lon);
    const auto location = OsmAnd::Utilities::convertLatLonTo31(latLon);
    searchCriteria->bbox31 = (OsmAnd::AreaI)OsmAnd::Utilities::boundingBox31FromAreaInMeters(15, location);
    
    const auto search = std::shared_ptr<const OsmAnd::AmenitiesInAreaSearch>(new OsmAnd::AmenitiesInAreaSearch(obfsCollection));
    OAPOI *res = nil;
    search->performSearch(*searchCriteria,
                          [&originName, &res, &cancel]
                          (const OsmAnd::ISearch::Criteria& criteria, const OsmAnd::ISearch::IResultEntry& resultEntry)
                          {
                                OAPOI *poi = [OAAmenitySearcher parsePOI:resultEntry];
                                if (poi && [poi.toStringEn isEqualToString:originName])
                                {
                                    res = poi;
                                    cancel = true;
                                }
                          },
                          ctrl);
    
    return res;
}

+ (NSArray<OAPOI *> *) findPOIsByTagName:(NSString *)tagName name:(NSString *)name location:(OsmAnd::PointI)location categoryName:(NSString *)categoryName poiTypeName:(NSString *)typeName radius:(int)radius
{
    OsmAnd::AreaI bbox31 = (OsmAnd::AreaI)OsmAnd::Utilities::boundingBox31FromAreaInMeters(radius, location);
    return [self findPOIsByTagName:tagName name:name location:location categoryName:categoryName poiTypeName:typeName bbox31:bbox31];
}

+ (NSArray<OAPOI *> *) findPOIsByTagName:(NSString *)tagName name:(NSString *)name location:(OsmAnd::PointI)location categoryName:(NSString *)categoryName poiTypeName:(NSString *)typeName bboxTopLeft:(CLLocationCoordinate2D)bboxTopLeft bboxBottomRight:(CLLocationCoordinate2D)bboxBottomRight;
{
    OsmAnd::PointI topLeftPoint31 = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(bboxTopLeft.latitude, bboxTopLeft.longitude));
    OsmAnd::PointI bottomRightPoint31 = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(bboxBottomRight.latitude, bboxBottomRight.longitude));
    OsmAnd::AreaI bbox31 = OsmAnd::AreaI(topLeftPoint31, bottomRightPoint31);
    return [self findPOIsByTagName:tagName name:name location:location categoryName:categoryName poiTypeName:typeName bbox31:bbox31];
}

+ (NSArray<OAPOI *> *) findPOIsByTagName:(NSString *)tagName name:(NSString *)name location:(OsmAnd::PointI)location categoryName:(NSString *)categoryName poiTypeName:(NSString *)typeName bbox31:(OsmAnd::AreaI)bbox31
{
    OsmAndAppInstance _app = [OsmAndApp instance];
    const auto& obfsCollection = _app.resourcesManager->obfsCollection;
    
    std::shared_ptr<const OsmAnd::IQueryController> ctrl;
    ctrl.reset(new OsmAnd::FunctorQueryController([]
                                                  (const OsmAnd::FunctorQueryController* const controller)
                                                  {
                                                      // should break?
                                                      return false;
                                                  }));
    
    const std::shared_ptr<OsmAnd::AmenitiesInAreaSearch::Criteria>& searchCriteria = std::shared_ptr<OsmAnd::AmenitiesInAreaSearch::Criteria>(new OsmAnd::AmenitiesInAreaSearch::Criteria);
    
    auto categoriesFilter = QHash<QString, QStringList>();
    if (categoryName && typeName) {
        categoriesFilter.insert(QString::fromNSString(categoryName), QStringList(QString::fromNSString(typeName)));
    } else if (categoryName) {
        categoriesFilter.insert(QString::fromNSString(categoryName), QStringList());
    }
    searchCriteria->categoriesFilter = categoriesFilter;
    searchCriteria->bbox31 = bbox31;
    
    const auto search = std::shared_ptr<const OsmAnd::AmenitiesInAreaSearch>(new OsmAnd::AmenitiesInAreaSearch(obfsCollection));
    NSMutableArray<OAPOI *> *arr = [NSMutableArray array];
    NSMutableSet<NSString *> *deduplicateTypeIdSet = [NSMutableSet set];
    search->performSearch(*searchCriteria,
                          [&arr, &tagName, &name, &location, &deduplicateTypeIdSet]
                          (const OsmAnd::ISearch::Criteria& criteria, const OsmAnd::ISearch::IResultEntry& resultEntry)
                          {
                              const auto &am = ((OsmAnd::AmenitiesByNameSearch::ResultEntry&)resultEntry).amenity;
                              NSString *typeIdKey = [OAAmenitySearcher getAmenityTypeIdKey:am];
                              if (![deduplicateTypeIdSet containsObject:typeIdKey])
                              {
                                  [deduplicateTypeIdSet addObject:typeIdKey];
                                  OAPOI *poi = [OAAmenitySearcher parsePOI:resultEntry withValues:tagName != nil withContent:NO];
                                  if (poi && (!tagName || [poi.values valueForKey:tagName]) && (!name || [poi.name isEqualToString:name] || [poi.localizedNames.allValues containsObject:name]))
                                  {
                                      poi.distanceMeters = OsmAnd::Utilities::squareDistance31(location, am->position31);
                                      [OAPOIHelper fetchValuesContentPOIByAmenity:am poi:poi];
                                      [arr addObject:poi];
                                  }
                              }
                          },
                          ctrl);
    
    return [NSArray arrayWithArray:arr];
}

+ (NSArray<OAPOI *> *) findTravelGuides:(NSArray<NSString *> *)categoryNames currentLocation:(OsmAnd::PointI)currentLocation bbox31:(OsmAnd::AreaI)bbox31 reader:(NSString *)reader publish:(BOOL(^)(OAPOI *poi))publish
{
    OsmAndAppInstance _app = [OsmAndApp instance];
    const auto& obfsCollection = _app.resourcesManager->obfsCollection;
    BOOL done = false;
    
    std::shared_ptr<const OsmAnd::IQueryController> ctrl;
    ctrl.reset(new OsmAnd::FunctorQueryController([&done]
                                                  (const OsmAnd::FunctorQueryController* const controller)
                                                  {
                                                      return done;
                                                  }));
    
    const std::shared_ptr<OsmAnd::AmenitiesInAreaSearch::Criteria>& searchCriteria = std::shared_ptr<OsmAnd::AmenitiesInAreaSearch::Criteria>(new OsmAnd::AmenitiesInAreaSearch::Criteria);
    
    if (bbox31.width() != 0 && bbox31.height() != 0)
    {
        searchCriteria->bbox31 = bbox31;
    }
    
    const auto search = std::shared_ptr<const OsmAnd::AmenitiesInAreaSearch>(new OsmAnd::AmenitiesInAreaSearch(obfsCollection));
    NSMutableArray<OAPOI *> *arr = [NSMutableArray array];
    NSMutableSet<NSString *> *deduplicateTypeIdSet = [NSMutableSet set];

    search->performTravelGuidesSearch(QString::fromNSString(reader), *searchCriteria,
                                      [&categoryNames, &arr, &currentLocation, &deduplicateTypeIdSet, &publish, &done](const OsmAnd::ISearch::Criteria& criteria, const OsmAnd::ISearch::IResultEntry& resultEntry)
                          {
                                const auto &am = ((OsmAnd::AmenitiesByNameSearch::ResultEntry&)resultEntry).amenity;
                                NSString *typeIdKey = [OAAmenitySearcher getAmenityTypeIdKey:am];
                                if (![deduplicateTypeIdSet containsObject:typeIdKey])
                                {
                                    if ([OATravelObfHelper.shared searchFilterShouldAccept:am->subType.toNSString() filterSubcategories:categoryNames])
                                    {
                                        [deduplicateTypeIdSet addObject:typeIdKey];
                                        OAPOI *poi = [OAAmenitySearcher parsePOI:resultEntry withValues:YES withContent:YES];
                                        poi.distanceMeters = OsmAnd::Utilities::squareDistance31(currentLocation, am->position31);
                                        if (publish)
                                        {
                                            done = publish(poi);
                                        }
                                        else
                                        {
                                            [arr addObject:poi];
                                        }
                                    }
                                }
                          },
                          ctrl);
    
    return [NSArray arrayWithArray:arr];
}

- (NSArray<OAPOI *> *) findTravelGuidesByKeyword:(NSString *)keyword categoryNames:(NSArray<NSString *> *)categoryNames poiTypeName:(NSString *)typeName currentLocation:(OsmAnd::PointI)currentLocation bbox31:(OsmAnd::AreaI)bbox31 reader:(NSString *)reader publish:(BOOL(^)(OAPOI *poi))publish
{
    _isSearchDone = NO;
    _breakSearch = NO;
    
    [self updateMyLocation];

    const auto& obfsCollection = _app.resourcesManager->obfsCollection;
    
    std::shared_ptr<const OsmAnd::IQueryController> ctrl;
    ctrl.reset(new OsmAnd::FunctorQueryController([self]
                                       (const OsmAnd::FunctorQueryController* const controller)
                                       {
                                           // should break?
                                            return _isSearchDone || _breakSearch || _limitCounter < 0;
                                       }));
    
    _limitCounter = _searchLimit;
    _prefLang = [OAAppSettings sharedManager].settingPrefMapLanguage.get;
    
    const std::shared_ptr<OsmAnd::AmenitiesByNameSearch::Criteria>& searchCriteria = std::shared_ptr<OsmAnd::AmenitiesByNameSearch::Criteria>(new OsmAnd::AmenitiesByNameSearch::Criteria);
    
    searchCriteria->name = QString::fromNSString(keyword ? keyword : @"");
    searchCriteria->obfInfoAreaFilter = _visibleArea;
    searchCriteria->bbox31 = bbox31;
    searchCriteria->xy31 = currentLocation;
    
    if (categoryNames)
    {
        auto categoriesFilter = QHash<QString, QStringList>();
        QStringList categories = QStringList();
        for (NSString *categoryName in categoryNames)
            categories.append(QString::fromNSString(categoryName));
        
        categoriesFilter.insert(QString::fromNSString(@"travel"), categories);
        categoriesFilter.insert(QString::fromNSString(@"routes"), categories);
        searchCriteria->categoriesFilter = categoriesFilter;
    }
    
    NSMutableArray<OAPOI *> *arr = [NSMutableArray array];

    const auto search = std::shared_ptr<const OsmAnd::AmenitiesByNameSearch>(new OsmAnd::AmenitiesByNameSearch(obfsCollection));
    
    search->performTravelGuidesSearch(QString::fromNSString(reader),
                                      *searchCriteria,
                                      [self, &arr, &publish]
                                        (const OsmAnd::ISearch::Criteria& criteria, const OsmAnd::ISearch::IResultEntry& resultEntry)
                                        {
                                            const auto &am = ((OsmAnd::AmenitiesByNameSearch::ResultEntry&)resultEntry).amenity;

                                            OAPOI *poi = [self.class parsePOI:resultEntry withValues:YES withContent:YES];
                                            poi.distanceMeters = OsmAnd::Utilities::squareDistance31(_myLocation, am->position31);
                                            
                                            if (publish)
                                            {
                                                _isSearchDone = publish(poi);
                                            }
                                            
                                            [arr addObject:poi];
                                            _limitCounter--;
                                        },
                                        ctrl);
    
    _isSearchDone = YES;
    
    return [NSArray arrayWithArray:arr];
}

+ (NSArray<OAPOI *> *) findPOIsByFilter:(OASearchPoiTypeFilter *)filter topLatitude:(double)topLatitude leftLongitude:(double)leftLongitude bottomLatitude:(double)bottomLatitude rightLongitude:(double)rightLongitude matcher:(OAResultMatcher<OAPOI *> *)matcher
{
    NSMutableArray<OAPOI *> *arr = [NSMutableArray array];
    if (filter && ![filter isEmpty])
    {
        OsmAndAppInstance _app = [OsmAndApp instance];
        const auto& obfsCollection = _app.resourcesManager->obfsCollection;

        std::shared_ptr<const OsmAnd::IQueryController> ctrl;
        ctrl.reset(new OsmAnd::FunctorQueryController([&matcher]
                                                      (const OsmAnd::FunctorQueryController* const controller)
                                                      {
                                                          // should break?
                                                          return matcher && [matcher isCancelled];
                                                      }));
        
        const std::shared_ptr<OsmAnd::AmenitiesInAreaSearch::Criteria>& searchCriteria = std::shared_ptr<OsmAnd::AmenitiesInAreaSearch::Criteria>(new OsmAnd::AmenitiesInAreaSearch::Criteria);
        OsmAnd::PointI topLeftPoint31 = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(topLatitude, leftLongitude));
        OsmAnd::PointI bottomRightPoint31 = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(bottomLatitude, rightLongitude));
        searchCriteria->bbox31 = OsmAnd::AreaI(topLeftPoint31, bottomRightPoint31);
        NSMutableSet<NSString *> *deduplicateTypeIdSet = [NSMutableSet set];
        const auto search = std::shared_ptr<const OsmAnd::AmenitiesInAreaSearch>(new OsmAnd::AmenitiesInAreaSearch(obfsCollection));
        search->performSearch(*searchCriteria,
                              [&arr, &filter, &matcher, &deduplicateTypeIdSet]
                              (const OsmAnd::ISearch::Criteria& criteria, const OsmAnd::ISearch::IResultEntry& resultEntry)
                              {
                                  const auto& amenity = ((OsmAnd::AmenitiesByNameSearch::ResultEntry&)resultEntry).amenity;
                                  NSString *typeIdKey = [OAAmenitySearcher getAmenityTypeIdKey:amenity];
                                  if (![deduplicateTypeIdSet containsObject:typeIdKey])
                                  {
                                      [deduplicateTypeIdSet addObject:typeIdKey];
                                      OAPOIType *type = [OAAmenitySearcher parsePOITypeByAmenity:amenity];
                                      if (type && [filter accept:type.category subcategory:type.name])
                                      {
                                          OAPOI *poi = [OAAmenitySearcher parsePOIByAmenity:amenity type:type];
                                          if (poi)
                                          {
                                              if (matcher)
                                                  [matcher publish:poi];
                                              
                                              [arr addObject:poi];
                                          }
                                      }
                                  }
                              },
                              ctrl);
    }
    return [NSArray arrayWithArray:arr];
}

+ (NSArray<OAPOI *> *) findPOI:(OASearchPoiTypeFilter *)searchFilter additionalFilter:(OATopIndexFilter *)additionalFilter lat:(double)lat lon:(double)lon radius:(int)radius includeTravel:(BOOL)includeTravel matcher:(OAResultMatcher<OAPOI *> *)matcher publish:(BOOL(^)(OAPOI *poi))publish
{
    OsmAnd::PointI point31 = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(lat, lon));
    OsmAnd::AreaI bbox31 = (OsmAnd::AreaI)OsmAnd::Utilities::boundingBox31FromAreaInMeters(radius, point31);
    return [self findPOI:searchFilter additionalFilter:additionalFilter bbox31:bbox31 currentLocation:point31 includeTravel:includeTravel matcher:matcher publish:publish];
}

+ (NSString *) getAmenityTypeIdKey:(const std::shared_ptr<const OsmAnd::Amenity> &)amenity
{
    OAPOIType *type = [OAAmenitySearcher parsePOITypeByAmenity:amenity];
    if (type)
        return [NSString stringWithFormat:@"%@-%@-%@", type.category.name, type.name, @(amenity->id.id)];
    else
        return [NSString stringWithFormat:@"%@", @(amenity->id.id)];
}

+ (NSArray<OAPOI *> *) findPOI:(OASearchPoiTypeFilter *)searchFilter additionalFilter:(OATopIndexFilter *)additionalFilter bbox31:(OsmAnd::AreaI )bbox31 currentLocation:(OsmAnd::PointI)currentLocation includeTravel:(BOOL)includeTravel matcher:(OAResultMatcher<OAPOI *> *)matcher publish:(BOOL(^)(OAPOI *poi))publish
{
    NSMutableSet<NSNumber *> *openAmenities = [NSMutableSet new];
    NSMutableSet<NSNumber *> *closedAmenities = [NSMutableSet new];
    NSMutableArray<OAPOI *> *actualAmenities = [NSMutableArray array];
    NSMutableSet<NSString *> *deduplicateTypeIdSet = [NSMutableSet set];

    OASearchPoiTypeFilter *filter = searchFilter;
    BOOL done = false;
    
    std::shared_ptr<const OsmAnd::IQueryController> ctrl;
    ctrl.reset(new OsmAnd::FunctorQueryController([&done]
                                                  (const OsmAnd::FunctorQueryController* const controller)
                                                  {
                                                      return done;
                                                  }));
    
    const std::shared_ptr<OsmAnd::AmenitiesInAreaSearch::Criteria>& searchCriteria = std::shared_ptr<OsmAnd::AmenitiesInAreaSearch::Criteria>(new OsmAnd::AmenitiesInAreaSearch::Criteria);
    const auto& obfsCollection = [OsmAndApp instance].resourcesManager->obfsCollection;
    NSArray<NSString *> *repos = [self getAmenityRepositoriesNames:includeTravel];
    const auto search = std::shared_ptr<const OsmAnd::AmenitiesInAreaSearch>(new OsmAnd::AmenitiesInAreaSearch(obfsCollection));
    
    if (bbox31.width() != 0 && bbox31.height() != 0)
    {
        searchCriteria->bbox31 = bbox31;
    }
    
    BOOL isEmpty = !filter || [filter isEmpty];
    
    if (isEmpty && additionalFilter)
    {
        filter = nil;
    }
    if (!isEmpty || additionalFilter)
    {
        for (NSString *repoName in repos)
        {
            if (matcher && matcher.isCancelled)
            {
                break;
            }
            
            NSMutableArray<OAPOI *> *foundAmenities = [NSMutableArray array];

            search->performTravelGuidesSearch(QString::fromNSString(repoName), *searchCriteria,
                                              [&filter, &foundAmenities, &currentLocation, &deduplicateTypeIdSet, &publish, &done](const OsmAnd::ISearch::Criteria& criteria, const OsmAnd::ISearch::IResultEntry& resultEntry)
                                  {
                                        const auto &am = ((OsmAnd::AmenitiesByNameSearch::ResultEntry&)resultEntry).amenity;

                                        OAPOIType *type = [OAAmenitySearcher parsePOITypeByAmenity:am];
                                        BOOL accept = [filter accept:type.category subcategory:type.name];
                                        NSString *typeIdKey = [OAAmenitySearcher getAmenityTypeIdKey:am];

                                        if (![deduplicateTypeIdSet containsObject:typeIdKey] && accept)
                                        {
                                            [deduplicateTypeIdSet addObject:typeIdKey];
    
                                            OAPOI *poi = [OAAmenitySearcher parsePOI:resultEntry withValues:YES withContent:YES];
                                            poi.distanceMeters = OsmAnd::Utilities::squareDistance31(currentLocation, am->position31);
                                            
                                            if (publish)
                                            {
                                                done = publish(poi);
                                            }
                                            else
                                            {
                                                if (poi)
                                                    [foundAmenities addObject:poi];
                                            }
                                        }
                                  },
                                  ctrl);
            
            for (OAPOI *amenity in foundAmenities)
            {
                NSNumber *obfId = @(amenity.obfId);
                if ([amenity isClosed])
                {
                    [closedAmenities addObject:obfId];
                }
                else if (![closedAmenities containsObject:obfId])
                {
                    [openAmenities addObject:obfId];
                    [actualAmenities addObject:amenity];
                }
            }
        }
    }
    return actualAmenities;
}

+ (NSArray<OAPOI *> *) findPOIsByName:(NSString *)query topLatitude:(double)topLatitude leftLongitude:(double)leftLongitude bottomLatitude:(double)bottomLatitude rightLongitude:(double)rightLongitude matcher:(OAResultMatcher<OAPOI *> *)matcher
{
    OACollatorStringMatcher *mt = [[OACollatorStringMatcher alloc] initWithPart:query mode:CHECK_STARTS_FROM_SPACE];
    NSMutableArray<OAPOI *> *arr = [NSMutableArray array];
    OsmAndAppInstance _app = [OsmAndApp instance];
    const auto& obfsCollection = _app.resourcesManager->obfsCollection;
    
    std::shared_ptr<const OsmAnd::IQueryController> ctrl;
    ctrl.reset(new OsmAnd::FunctorQueryController([&matcher]
                                                  (const OsmAnd::FunctorQueryController* const controller)
                                                  {
                                                      // should break?
                                                      return matcher && [matcher isCancelled];
                                                  }));
    
    const std::shared_ptr<OsmAnd::AmenitiesInAreaSearch::Criteria>& searchCriteria = std::shared_ptr<OsmAnd::AmenitiesInAreaSearch::Criteria>(new OsmAnd::AmenitiesInAreaSearch::Criteria);
    OsmAnd::PointI topLeftPoint31 = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(topLatitude, leftLongitude));
    OsmAnd::PointI bottomRightPoint31 = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(bottomLatitude, rightLongitude));
    searchCriteria->bbox31 = OsmAnd::AreaI(topLeftPoint31, bottomRightPoint31);
    
    const auto search = std::shared_ptr<const OsmAnd::AmenitiesInAreaSearch>(new OsmAnd::AmenitiesInAreaSearch(obfsCollection));
    search->performSearch(*searchCriteria,
                          [&arr, &mt, &matcher]
                          (const OsmAnd::ISearch::Criteria& criteria, const OsmAnd::ISearch::IResultEntry& resultEntry)
                          {
                              OAPOI *poi = [OAAmenitySearcher parsePOI:resultEntry];
                              if (poi)
                              {
                                  BOOL __block matches = [mt matches:[poi.name lowerCase]] || [mt matches:[poi.nameLocalized lowerCase]];
                                  if (!matches)
                                  {
                                      for (NSString *s in poi.localizedNames)
                                      {
                                          matches = [mt matches:[s lowerCase]];
                                          if (matches)
                                              break;
                                      }
                                      if (!matches)
                                      {
                                          [poi.values enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString *  _Nonnull value, BOOL * _Nonnull stop) {
                                              if ([key indexOf:@"_name"] != -1)
                                              {
                                                  matches = [mt matches:value];
                                                  if (matches)
                                                      *stop = YES;
                                              }
                                          }];
                                      }
                                  }
                                  if (matches)
                                  {
                                      if (matcher)
                                          [matcher publish:poi];
                                      
                                      [arr addObject:poi];
                                  }
                              }
                          },
                          ctrl);
    
    return [NSArray arrayWithArray:arr];
}

+ (NSArray<OAPOI *> *) searchPOIsOnThePath:(NSArray<CLLocation *> *)locations radius:(double)radius filter:(OASearchPoiTypeFilter *)filter matcher:(OAResultMatcher<OAPOI *> *)matcher
{
    NSMutableArray<OAPOI *> *arr = [NSMutableArray array];
    if (locations && locations.count > 0 && filter && ![filter isEmpty])
    {
        OsmAndAppInstance _app = [OsmAndApp instance];
        const auto& obfsCollection = _app.resourcesManager->obfsCollection;
        
        std::shared_ptr<const OsmAnd::IQueryController> ctrl;
        ctrl.reset(new OsmAnd::FunctorQueryController([&matcher]
                                                      (const OsmAnd::FunctorQueryController* const controller)
                                                      {
                                                          // should break?
                                                          return matcher && [matcher isCancelled];
                                                      }));
        
        const std::shared_ptr<OsmAnd::AmenitiesInAreaSearch::Criteria>& searchCriteria = std::shared_ptr<OsmAnd::AmenitiesInAreaSearch::Criteria>(new OsmAnd::AmenitiesInAreaSearch::Criteria);
        
        CLLocationDegrees topLatitude = locations[0].coordinate.latitude;
        CLLocationDegrees bottomLatitude = locations[0].coordinate.latitude;
        CLLocationDegrees leftLongitude = locations[0].coordinate.longitude;
        CLLocationDegrees rightLongitude = locations[0].coordinate.longitude;
        for (CLLocation *l in locations)
        {
            topLatitude = MAX(topLatitude, l.coordinate.latitude);
            bottomLatitude = MIN(bottomLatitude, l.coordinate.latitude);
            leftLongitude = MIN(leftLongitude, l.coordinate.longitude);
            rightLongitude = MAX(rightLongitude, l.coordinate.longitude);
        }
        OsmAnd::PointI topLeftPoint31 = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(topLatitude, leftLongitude));
        OsmAnd::PointI bottomRightPoint31 = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(bottomLatitude, rightLongitude));
        searchCriteria->obfInfoAreaFilter = OsmAnd::AreaI(topLeftPoint31, bottomRightPoint31);
        
        double coeff = (double) (radius / OsmAnd::Utilities::getTileDistanceWidth(kZoomToSearchPOI));

        NSMapTable<NSNumber *, NSMutableArray<CLLocation *> *> *zooms = [NSMapTable strongToStrongObjectsMapTable];
        for (NSInteger i = 1; i < locations.count; i++)
        {
            CLLocation *cr = locations[i];
            CLLocation *pr = locations[i - 1];
            double tx = OsmAnd::Utilities::getTileNumberX(kZoomToSearchPOI, cr.coordinate.longitude);
            double ty = OsmAnd::Utilities::getTileNumberY(kZoomToSearchPOI, cr.coordinate.latitude);
            double px = OsmAnd::Utilities::getTileNumberX(kZoomToSearchPOI, pr.coordinate.longitude);
            double py = OsmAnd::Utilities::getTileNumberY(kZoomToSearchPOI, pr.coordinate.latitude);
            double topLeftX = MIN(tx, px) - coeff;
            double topLeftY = MIN(ty, py) - coeff;
            double bottomRightX = MAX(tx, px) + coeff;
            double bottomRightY = MAX(ty, py) + coeff;
            for (int x = (int) topLeftX; x <= bottomRightX; x++)
            {
                for (int y = (int) topLeftY; y <= bottomRightY; y++)
                {
                    NSNumber *hash = [NSNumber numberWithLongLong:((((long long) x) << (long)kZoomToSearchPOI) + y)];
                    NSMutableArray<CLLocation *> *ll = [zooms objectForKey:hash];
                    if (!ll)
                    {
                        ll = [NSMutableArray array];
                        [zooms setObject:ll forKey:hash];
                    }
                    [ll addObject:pr];
                    [ll addObject:cr];
                }
            }
            
        }
        int sleft = INT_MAX;
        int sright = 0;
        int stop = INT_MAX;
        int sbottom = 0;
        for (NSNumber *n in zooms.keyEnumerator)
        {
            long long vl = n.longLongValue;
            long long x = (vl >> (long)kZoomToSearchPOI) << (31 - (long)kZoomToSearchPOI);
            long long y = (vl & ((1 << (long)kZoomToSearchPOI) - 1)) << (31 - (long)kZoomToSearchPOI);
            sleft = (int) MIN(x, sleft);
            stop = (int) MIN(y, stop);
            sbottom = (int) MAX(y, sbottom);
            sright = (int) MAX(x, sright);
        }
        searchCriteria->bbox31 = OsmAnd::AreaI(OsmAnd::PointI(sleft, stop), OsmAnd::PointI(sright, sbottom));

        searchCriteria->tileFilter = [&zooms] (const OsmAnd::TileId tileId, const OsmAnd::ZoomLevel zoomLevel)
        {
            long long zx = (long)tileId.x << ((long)kZoomToSearchPOI - zoomLevel);
            long long zy = (long)tileId.y << ((long)kZoomToSearchPOI - zoomLevel);
            NSNumber *hash = [NSNumber numberWithLongLong:((zx << (long)kZoomToSearchPOI) + zy)];
            return [zooms objectForKey:hash] != nil;
        };
        
        const auto search = std::shared_ptr<const OsmAnd::AmenitiesInAreaSearch>(new OsmAnd::AmenitiesInAreaSearch(obfsCollection));
        search->performSearch(*searchCriteria,
                              [&arr, &filter, &matcher, &radius, &zooms]
                              (const OsmAnd::ISearch::Criteria& criteria, const OsmAnd::ISearch::IResultEntry& resultEntry)
                              {
                                  const auto amenity = ((OsmAnd::AmenitiesByNameSearch::ResultEntry&)resultEntry).amenity;
                                  OAPOIType *type = [OAAmenitySearcher parsePOITypeByAmenity:amenity];
                                  if (type && [filter accept:type.category subcategory:type.name])
                                  {
                                      OAPOI *poi = [OAAmenitySearcher parsePOIByAmenity:amenity type:type];
                                      if (poi)
                                      {
                                          if (radius > 0)
                                          {
                                              double lat = poi.latitude;
                                              double lon = poi.longitude;
                                              long long x = (long long) OsmAnd::Utilities::getTileNumberX(kZoomToSearchPOI, lon);
                                              long long y = (long long) OsmAnd::Utilities::getTileNumberY(kZoomToSearchPOI, lat);
                                              NSNumber *hash = [NSNumber numberWithLongLong:(x << (long)kZoomToSearchPOI) | y];
                                              NSMutableArray<CLLocation *> *locs = [zooms objectForKey:hash];
                                              if (!locs)
                                                  return;
                                              
                                              OAPOIRoutePoint *routePoint = [OAAmenitySearcher distFromLat:lat longitude:lon locations:locs radius:radius];
                                              if (!routePoint)
                                                  return;
                                              else
                                                  poi.routePoint = routePoint;
                                          }
                                          
                                          if (matcher)
                                              [matcher publish:poi];
                                          
                                          [arr addObject:poi];
                                      }
                                  }
                              },
                              ctrl);
    }
    return [NSArray arrayWithArray:arr];
}

@end
