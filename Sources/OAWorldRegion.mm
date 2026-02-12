//
//  OAWorldRegion.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 4/27/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAWorldRegion.h"
#import "OADownloadsManager.h"
#import "Localization.h"
#import "OALog.h"
#import "OAIAPHelper.h"
#import "OAProducts.h"
#import "OAUtilities.h"
#import "OAPointIContainer.h"
#import "OAIndexConstants.h"
#import "OAWorldRegion+Protected.h"
#import "OAResourcesUIHelper.h"
#import "QuadRect.h"
#import "Weather/OAWeatherHelper.h"
#import "OsmAndApp.h"
#import "OAMapUtils+cpp.h"
#import "OANativeUtilities.h"

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/WorldRegion.h>
#include <OsmAndCore/WorldRegions.h>
#include <OsmAndCore/Data/MapObject.h>
#include <OsmAndCore/Data/BinaryMapObject.h>
#include <OsmAndCore/Data/ObfMapObject.h>
#include <OsmAndCore/Data/ObfMapSectionInfo.h>
#include <OsmAndCore/KeyedEntriesCollection.h>

#define kWorld @"world"

@implementation OAWorldRegion
{
    std::shared_ptr<const OsmAnd::WorldRegion> _worldRegion;
}

- (instancetype) initWorld
{
    self = [super init];
    if (self)
    {
        [self commonInit];
        _regionId = nil;
        _downloadsIdPrefix = @"world_";
        _nativeName = nil;
        _localizedName = nil;
        _allNames = nil;
        _superregion = nil;
    }
    return self;
}

- (instancetype) initFrom:(const std::shared_ptr<const OsmAnd::WorldRegion> &)region
{
    self = [super init];
    if (self)
    {
        [self commonInit];
        
        _worldRegion = region;
        [self findBoundaries];
        _regionId = _worldRegion->fullRegionName.toNSString();
        
        if (_worldRegion->downloadName.isEmpty() && _worldRegion->fullRegionName.count('_') == 1) {
            // Weather_Us_northamerica.tifsqlite.zip -> Us_northamerica -> northamerica_us
            // Weather_Canada_northamerica.tifsqlite.zip -> Canada_northamerica -> northamerica_canada
            QStringList parts = _worldRegion->fullRegionName.split('_');
            _downloadsIdPrefix = (parts[1] + QStringLiteral("_") + parts[0] + QStringLiteral(".")).toNSString();
        } else {
            _downloadsIdPrefix = [_worldRegion->downloadName.toNSString() stringByAppendingString:@"."];
        }
        
        _nativeName = _worldRegion->nativeName.toNSString();
        
        _regionLeftHandDriving = _worldRegion->regionLeftHandDriving.toNSString();
        _regionLang = _worldRegion->regionLang.toNSString();
        _regionMetric = _worldRegion->regionMetric.toNSString();
        _regionRoadSigns = _worldRegion->regionRoadSigns.toNSString();
        _wikiLink = _worldRegion->wikiLink.toNSString();
        _population = _worldRegion->population.toNSString();
        _regionMap = _worldRegion->regionMap;
        _regionRoads = _worldRegion->regionRoads;
        _regionJoinMap = _worldRegion->regionJoinMap;
        _regionJoinRoads = _worldRegion->regionJoinRoads;
        _regionSearchText = _worldRegion->regionSearchText.toNSString();

        OsmAnd::LatLon latLonTopLeft = OsmAnd::Utilities::convert31ToLatLon(region->mapObject->bbox31.topLeft);
        OsmAnd::LatLon latLonBottomRight = OsmAnd::Utilities::convert31ToLatLon(region->mapObject->bbox31.bottomRight);

        double minLat = latLonBottomRight.latitude;
        double maxLat = latLonTopLeft.latitude;
        double minLon = latLonTopLeft.longitude;
        double maxLon = latLonBottomRight.longitude;

        for (const auto& additionalObject : region->additionalMapObjects)
        {
            OsmAnd::LatLon addTopLeft = OsmAnd::Utilities::convert31ToLatLon(additionalObject->bbox31.topLeft);
            OsmAnd::LatLon addBottomRight = OsmAnd::Utilities::convert31ToLatLon(additionalObject->bbox31.bottomRight);
            
            minLat = MIN(minLat, addTopLeft.latitude);
            maxLat = MAX(maxLat, addBottomRight.latitude);
            minLon = MIN(minLon, addTopLeft.longitude);
            maxLon = MAX(maxLon, addBottomRight.longitude);
        }

        _bboxTopLeft = CLLocationCoordinate2DMake(maxLat, minLon);
        _bboxBottomRight = CLLocationCoordinate2DMake(minLat, maxLon);
        
        double centerLat = (maxLat + minLat) / 2.0;
        double centerLon = (maxLon + minLon) / 2.0;
        _regionCenter = CLLocationCoordinate2DMake(centerLat, centerLon);

        [self setLocalizedNamesFrom:region->localizedNames];
        
        if (!_localizedName && _nativeName.length == 0)
        {
            for (const auto& entry : OsmAnd::rangeOf(OsmAnd::constOf(region->mapObject->captions)))
            {
                const auto& rule = *region->mapObject->attributeMapping->decodeMap.getRef(entry.key());
                if (rule.tag == QString("key_name"))
                {
                    _nativeName = [entry.value().toNSString() capitalizedStringWithLocale:[NSLocale currentLocale]];
                    break;
                }
            }
        }
    }
    return self;
}

- (instancetype) initWithId:(NSString*)regionId andLocalizedName:(NSString*)localizedName
{
    self = [super init];
    if (self) {
        [self commonInit];
        _regionId = regionId;
        _downloadsIdPrefix = [regionId stringByAppendingString:@"."];
        _nativeName = nil;
        _localizedName = localizedName;
        if (localizedName != nil)
            _allNames = @[_localizedName];
    }
    return self;
}

- (instancetype) initWithId:(NSString*)regionId
        andAcceptedExtension:(NSString*)acceptedExtension
           andLocalizedName:(NSString*)localizedName
{
    self = [self initWithId:regionId andDownloadIdPrefix:@"" andLocalizedName:localizedName];
    if (self) {
        _acceptedExtension = acceptedExtension;
    }
    return self;
}

- (instancetype) initWithId:(NSString*)regionId
        andDownloadIdPrefix:(NSString*)downloadIdPrefix
           andLocalizedName:(NSString*)localizedName
{
    self = [super init];
    if (self) {
        [self commonInit];
        _regionId = regionId;
        _downloadsIdPrefix = downloadIdPrefix;
        _nativeName = nil;
        _localizedName = localizedName;
        if (localizedName != nil)
            _allNames = @[_localizedName];
    }
    return self;
}

- (void) dealloc
{
    [self deinit];
}

- (void) commonInit
{
    _superregion = nil;
    _subregions = [[NSMutableArray alloc] init];
    _flattenedSubregions = [[NSMutableArray alloc] init];
}

- (void) deinit
{
}

- (double) calculateArea:(const QVector<OsmAnd::Point<int>> &)points31
{
    double area = 0.;
    for (int i = 1; i < points31.count(); i++)
    {
        double ax = points31.at(i - 1).x;
        double bx = points31.at(i).x;
        double ay = points31.at(i - 1).y;
        double by = points31.at(i).y;
        area += (bx + ax) * (by - ay) / 1.631E10;
    }
    return area;
}

- (double) getArea
{
    double area = 0.;
    if (_worldRegion != nullptr)
    {
        const auto &points31 = _worldRegion->polygon;
        if (_worldRegion->polygon.count() > 1)
            area += [self calculateArea:points31];
        for (const auto& additionalArea : _worldRegion->additionalPolygons)
        {
            if (additionalArea.count() > 0)
                area += [self calculateArea:additionalArea];
        }
    }
    return ABS(area);
}

- (BOOL)polygonContains:(double)lat lon:(double)lon polygon:(const QVector<OsmAnd::Point<int>> &)points
{
    if (points.count() > 1)
    {
        OsmAnd::PointI p31 = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(lat, lon));
        int t = 0;
        for (int i = 1; i < points.count(); i++) {
            int fx = [OANativeUtilities rayIntersectXWithPrevX:points.at(i - 1).x prevY:points.at(i - 1).y x:points.at(i).x y:points.at(i).y middleY:p31.y];
            if (INT_MIN != fx && p31.x >= fx)
                t++;
        }
        return t % 2 == 1;
    }
    return NO;
}

- (BOOL) contain:(double) lat lon:(double) lon
{
    if (_worldRegion == nullptr)
        return NO;

    int intersections = 0;

    if ([self polygonContains:lat lon:lon polygon:_worldRegion->polygon])
        intersections++;

    for (const auto &additional : _worldRegion->additionalPolygons)
    {
        if ([self polygonContains:lat lon:lon polygon:additional])
        {
            intersections++;
            if ((intersections % 2) == 0)
                break; // optimize
        }
    }

    return (intersections % 2) == 1;
}

- (NSArray<OAPointIContainer *> *) getAllPolygons
{
    NSMutableArray<OAPointIContainer *> *res = [NSMutableArray array];
    OAPointIContainer *mainPoly = [[OAPointIContainer alloc] init];
    mainPoly.qPoints = _worldRegion->polygon;
    [res addObject:mainPoly];
    for (const auto &additional : _worldRegion->additionalPolygons)
    {
        OAPointIContainer *poly = [[OAPointIContainer alloc] init];
        poly.qPoints = additional;
        [res addObject:poly];
    }
    return res;
}

- (QVector<OsmAnd::PointI>) getPoints31
{
    return _worldRegion->polygon;
}

@synthesize regionId = _regionId;
@synthesize downloadsIdPrefix = _downloadsIdPrefix;
@synthesize acceptedExtension = _acceptedExtension;
@synthesize nativeName = _nativeName;
@synthesize localizedName = _localizedName;
@synthesize allNames = _allNames;

@synthesize superregion = _superregion;
@synthesize subregions = _subregions;
@synthesize flattenedSubregions = _flattenedSubregions;
@synthesize resourceTypes = _resourceTypes;

- (NSString *) name
{
    return _localizedName != nil ? _localizedName : _nativeName;
}

- (NSComparisonResult) compare:(OAWorldRegion *)other
{
    return [self.name localizedCaseInsensitiveCompare:other.name];
}

- (void) addSubregion:(OAWorldRegion *)subregion
{
    [subregion setSuperregion:self];

    NSMutableArray<OAWorldRegion *> *subregions = (NSMutableArray<OAWorldRegion *> *)_subregions;
    [subregions addObject:subregion];

    [self propagateSubregionToFlattenedHierarchy:subregion];
}

- (void) propagateSubregionToFlattenedHierarchy:(OAWorldRegion *)subregion
{
    NSMutableArray<OAWorldRegion *> *flattenedSubregions = (NSMutableArray<OAWorldRegion *> *) _flattenedSubregions;
    [flattenedSubregions addObject:subregion];

    if (_superregion != nil)
        [_superregion propagateSubregionToFlattenedHierarchy:subregion];
}

- (void) setSuperregion:(OAWorldRegion *)superregion
{
    _superregion = superregion;
}

- (OAWorldRegion *) getPrimarySuperregion
{
    OAWorldRegion *primarySuperregion = _superregion;
    while (primarySuperregion.superregion.regionId)
    {
        primarySuperregion = primarySuperregion.superregion;
    }
    return primarySuperregion;
}

- (OAWorldRegion *) makeImmutable
{
    if (![_subregions isKindOfClass:[NSArray class]])
        _subregions = [NSArray arrayWithArray:_subregions];

    if (![_flattenedSubregions isKindOfClass:[NSArray class]])
        _flattenedSubregions = [NSArray arrayWithArray:_flattenedSubregions];

    for (OAWorldRegion *subregion in _subregions)
        [subregion makeImmutable];

    return self;
}

- (void) setWorldRegion:(const std::shared_ptr<const OsmAnd::WorldRegion>&)worldRegion
{
    _worldRegion = worldRegion;
    [self findBoundaries];
}

- (void) setNativeName:(NSString *)nativeName
{
    _nativeName = nativeName;
}

- (void)setLocalizedName:(NSString *)localizedName
{
    _localizedName = localizedName;
}

- (void) setLocalizedNamesFrom:(const QHash<QString, QString>&)localizedNames
{
    [self setLocalizedNamesFrom:localizedNames
                  withExtraName:nil];
}

- (void) setLocalizedNamesFrom:(const QHash<QString, QString>&)localizedNames withExtraName:(NSString*)extraLocalizedName
{
    const auto citLocalizedName = localizedNames.constFind(QString::fromNSString([OAUtilities currentLang]));
    if (citLocalizedName == localizedNames.cend())
        _localizedName = extraLocalizedName;
    else
        _localizedName = (*citLocalizedName).toNSString();
    
    if (!_localizedName)
    {
        const auto citLocalizedName = localizedNames.constFind(QString("en"));
        if (citLocalizedName != localizedNames.cend())
            _localizedName = (*citLocalizedName).toNSString();
    }
    
    NSMutableArray* allNames = (_nativeName != nil) ? [NSMutableArray arrayWithObject:_nativeName] : [NSMutableArray array];
    for (const auto& name_ : localizedNames)
    {
        NSString* name = name_.toNSString();

        if (![allNames containsObject:name])
            [allNames addObject:name];
    }
    if (extraLocalizedName != nil)
    {
        if (![allNames containsObject:extraLocalizedName])
            [allNames addObject:extraLocalizedName];
    }
    _allNames = [allNames copy];
}

+ (OAWorldRegion *) loadFrom:(NSString *)ocbfFilename
{
    OsmAnd::WorldRegions worldRegionsRegistry(QString::fromNSString(ocbfFilename));

    QList< std::shared_ptr< const OsmAnd::WorldRegion > > loadedWorldRegions;
    if (!worldRegionsRegistry.loadWorldRegions(&loadedWorldRegions, true))
        return nil;

    NSMutableDictionary<NSString *, OAWorldRegion *> *regionsLookupTable = [[NSMutableDictionary alloc] initWithCapacity:loadedWorldRegions.size()];

    // Create root region
    OAWorldRegion *entireWorld = [[OAWorldRegion alloc] initWorld];

    // Create main regions:

    OAWorldRegion *antarcticaRegion = [OAWorldRegion createRegionAs:OsmAnd::WorldRegions::AntarcticaRegionId
                                              withLocalizedName:OALocalizedString(@"index_name_antarctica")
                                                           from:loadedWorldRegions];
    [entireWorld addSubregion:antarcticaRegion];
    regionsLookupTable[antarcticaRegion.regionId] = antarcticaRegion;

    OAWorldRegion *africaRegion = [OAWorldRegion createRegionAs:OsmAnd::WorldRegions::AfricaRegionId
                                              withLocalizedName:OALocalizedString(@"index_name_africa")
                                                           from:loadedWorldRegions];
    [entireWorld addSubregion:africaRegion];
    regionsLookupTable[africaRegion.regionId] = africaRegion;

    OAWorldRegion* asiaRegion = [OAWorldRegion createRegionAs:OsmAnd::WorldRegions::AsiaRegionId
                                            withLocalizedName:OALocalizedString(@"index_name_asia")
                                                         from:loadedWorldRegions];
    [entireWorld addSubregion:asiaRegion];
    regionsLookupTable[asiaRegion.regionId] = asiaRegion;

    OAWorldRegion *australiaAndOceaniaRegion = [OAWorldRegion createRegionAs:OsmAnd::WorldRegions::AustraliaAndOceaniaRegionId
                                                           withLocalizedName:OALocalizedString(@"index_name_oceania")
                                                                        from:loadedWorldRegions];
    [entireWorld addSubregion:australiaAndOceaniaRegion];
    regionsLookupTable[australiaAndOceaniaRegion.regionId] = australiaAndOceaniaRegion;

    OAWorldRegion *centralAmericaRegion = [OAWorldRegion createRegionAs:OsmAnd::WorldRegions::CentralAmericaRegionId
                                                      withLocalizedName:OALocalizedString(@"index_name_central_america")
                                                                   from:loadedWorldRegions];
    [entireWorld addSubregion:centralAmericaRegion];
    regionsLookupTable[centralAmericaRegion.regionId] = centralAmericaRegion;

    OAWorldRegion *europeRegion = [OAWorldRegion createRegionAs:OsmAnd::WorldRegions::EuropeRegionId
                                              withLocalizedName:OALocalizedString(@"index_name_europe")
                                                           from:loadedWorldRegions];
    [entireWorld addSubregion:europeRegion];
    regionsLookupTable[europeRegion.regionId] = europeRegion;

    OAWorldRegion *northAmericaRegion = [OAWorldRegion createRegionAs:OsmAnd::WorldRegions::NorthAmericaRegionId
                                                    withLocalizedName:OALocalizedString(@"index_name_north_america")
                                                                 from:loadedWorldRegions];
    [entireWorld addSubregion:northAmericaRegion];
    regionsLookupTable[northAmericaRegion.regionId] = northAmericaRegion;

    OAWorldRegion *russiaRegion = [OAWorldRegion createRegionAs:OsmAnd::WorldRegions::RussiaRegionId
                                              withLocalizedName:OALocalizedString(@"index_name_russia")
                                                           from:loadedWorldRegions];
    [entireWorld addSubregion:russiaRegion];
    regionsLookupTable[russiaRegion.regionId] = russiaRegion;

    OAWorldRegion *southAmericaRegion = [OAWorldRegion createRegionAs:OsmAnd::WorldRegions::SouthAmericaRegionId
                                                    withLocalizedName:OALocalizedString(@"index_name_south_america")
                                                                 from:loadedWorldRegions];
    [entireWorld addSubregion:southAmericaRegion];
    regionsLookupTable[southAmericaRegion.regionId] = southAmericaRegion;

    OAWorldRegion *nauticalRegion = [[OAWorldRegion alloc] initWithId:OsmAnd::WorldRegions::NauticalRegionId.toNSString()
                                                 andAcceptedExtension:BINARY_DEPTH_MAP_INDEX_EXT
                                                     andLocalizedName:OALocalizedString(@"nautical_maps")];
    [entireWorld addSubregion:nauticalRegion];
    regionsLookupTable[nauticalRegion.regionId] = nauticalRegion;
    
    OAWorldRegion *travelRegion = [[OAWorldRegion alloc] initWithId:OsmAnd::WorldRegions::TravelRegionId.toNSString()
                                                 andAcceptedExtension:BINARY_TRAVEL_GUIDE_MAP_INDEX_EXT
                                                     andLocalizedName:OALocalizedString(@"shared_string_travel_guides")];
    [entireWorld addSubregion:travelRegion];
    regionsLookupTable[travelRegion.regionId] = travelRegion;
    
    OAWorldRegion *othersRegion = [[OAWorldRegion alloc] initWithId:OsmAnd::WorldRegions::OthersRegionId.toNSString()
                                                andDownloadIdPrefix:@"others_"
                                                   andLocalizedName:OALocalizedString(@"download_select_map_types")];
    [entireWorld addSubregion:othersRegion];
    regionsLookupTable[othersRegion.regionId] = othersRegion;

    // Process remaining regions
    for(;;)
    {
        unsigned int processedRegions = 0;
        QMutableListIterator< std::shared_ptr< const OsmAnd::WorldRegion > > itRegion(loadedWorldRegions);
        while (itRegion.hasNext())
        {
            const auto& region = itRegion.next();
            
            if (region->boundary)
            {
                // Remove
                processedRegions++;
                itRegion.remove();
                continue;
            }
            
            NSString* parentRegionId = region->parentRegionName.toNSString();

            // Try to find parent of this region
            OAWorldRegion *parentRegion = regionsLookupTable[parentRegionId];
            if (parentRegion == nil)
                continue;

            OAWorldRegion *newRegion = [[OAWorldRegion alloc] initFrom:region];
            [parentRegion addSubregion:newRegion];
            regionsLookupTable[newRegion.regionId] = newRegion;

            // Remove
            processedRegions++;
            itRegion.remove();
        }

        // If all remaining are orphans, that's all
        if (processedRegions == 0)
            break;
    }

    OALog(@"Found orphaned regions: %d", loadedWorldRegions.count());
    for (const auto& region : loadedWorldRegions)
    {
        OALog(@"Orphaned region '%s' in '%s'",
              qPrintable(region->fullRegionName),
              qPrintable(region->parentRegionName));

        if (!region->parentRegionName.isEmpty())
        {
            OAWorldRegion *newRegion = [[OAWorldRegion alloc] initFrom:region];
            [othersRegion addSubregion:newRegion];
            regionsLookupTable[newRegion.regionId] = newRegion;
        }
    }

    return [entireWorld makeImmutable];
}

+ (OAWorldRegion *) createRegionAs:(const QString&)regionId
                 withLocalizedName:(NSString*)localizedName
                              from:(QList< std::shared_ptr< const OsmAnd::WorldRegion > >&)regionsDb
{
    // First try to find this region in database
    for (const auto& region : regionsDb)
    {
        if (region->fullRegionName == regionId)
        {
            OAWorldRegion* worldRegion = [[OAWorldRegion alloc] initWithId:regionId.toNSString()
                                                       andDownloadIdPrefix:[region->downloadName.toNSString() stringByAppendingString:@"."]
                                                          andLocalizedName:nil];
            [worldRegion setWorldRegion:region];
            [worldRegion setNativeName:region->nativeName.toNSString()];
            [worldRegion setLocalizedNamesFrom:region->localizedNames
                                 withExtraName:localizedName];
            
            regionsDb.removeOne(region);
            
            return worldRegion;
        }
    }
    
    return [[OAWorldRegion alloc] initWithId:regionId.toNSString()
                         andDownloadIdPrefix:[regionId.toNSString() stringByAppendingString:@"."]
                            andLocalizedName:localizedName];
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"%@ (%@)", self.name, _regionId];
}

- (BOOL) purchased
{
    // world map or Antarctica
    if (_regionId == nil || [_regionId isEqualToString:OsmAnd::WorldRegions::AntarcticaRegionId.toNSString()])
        return YES;
    if ([[OAIAPHelper sharedInstance].allWorld isPurchased])
        return YES;
    
    OAProduct *product = [self getProduct];
    if (product)
        return [product isPurchased];
    else
        return NO;
}

- (OAProduct *) getProduct
{
    OAIAPHelper *iapHelper = [OAIAPHelper sharedInstance];
    if ([_regionId isEqualToString:OsmAnd::WorldRegions::AntarcticaRegionId.toNSString()]) {
        return iapHelper.antarctica;
    }
    if ([_regionId isEqualToString:OsmAnd::WorldRegions::AfricaRegionId.toNSString()]) {
        return iapHelper.africa;
    }
    if ([_regionId isEqualToString:OsmAnd::WorldRegions::AsiaRegionId.toNSString()]) {
        return iapHelper.asia;
    }
    if ([_regionId isEqualToString:OsmAnd::WorldRegions::AustraliaAndOceaniaRegionId.toNSString()]) {
        return iapHelper.australia;
    }
    if ([_regionId isEqualToString:OsmAnd::WorldRegions::CentralAmericaRegionId.toNSString()]) {
        return iapHelper.centralAmerica;
    }
    if ([_regionId isEqualToString:OsmAnd::WorldRegions::EuropeRegionId.toNSString()]) {
        return iapHelper.europe;
    }
    if ([_regionId isEqualToString:OsmAnd::WorldRegions::NorthAmericaRegionId.toNSString()]) {
        return iapHelper.northAmerica;
    }
    if ([_regionId isEqualToString:OsmAnd::WorldRegions::RussiaRegionId.toNSString()]) {
        return iapHelper.russia;
    }
    if ([_regionId isEqualToString:OsmAnd::WorldRegions::SouthAmericaRegionId.toNSString()]) {
        return iapHelper.southAmerica;
    }
    if ([_regionId isEqualToString:OsmAnd::WorldRegions::NauticalRegionId.toNSString()]) {
        return iapHelper.nautical;
    }
    return nil;
}

- (BOOL) isInPurchasedArea
{
    return [self purchased] || [self isInPurchasedArea:self];
}

- (BOOL) isInPurchasedArea:(OAWorldRegion *)region
{
    if (region.regionId == nil)
        return NO;
    
    if ([region purchased] || (region.superregion.regionId != nil && [region.superregion purchased]))
        return YES;
    if (region.superregion.regionId && [self isInPurchasedArea:region.superregion])
        return YES;
    return NO;
}

- (BOOL) isBoundary
{
    return _worldRegion != nullptr && _worldRegion->boundary;
}

- (NSArray<OAWorldRegion *> *) queryAtLat:(double)lat lon:(double)lon
{
    NSMutableArray<OAWorldRegion *> *res = [NSMutableArray array];
    for (OAWorldRegion *region in _flattenedSubregions)
    {
        if (lat <= region.bboxTopLeft.latitude && lat >= region.bboxBottomRight.latitude && lon >= region.bboxTopLeft.longitude && lon <= region.bboxBottomRight.longitude && ![self isBoundary])
        {
            [res addObject:region];
        }
    }
    return [NSArray arrayWithArray:res];
}

- (NSArray<OAWorldRegion *> *)getWorldRegionsAtWithoutSort:(double)latitude longitude:(double)longitude
{
    NSMutableArray<OAWorldRegion *> *mapRegions = [NSMutableArray arrayWithArray:[self queryAtLat:latitude lon:longitude]];
    if (mapRegions.count > 0)
    {
        [mapRegions.copy enumerateObjectsUsingBlock:^(OAWorldRegion * _Nonnull region, NSUInteger idx, BOOL * _Nonnull stop) {
            if (![region contain:latitude lon:longitude])
                [mapRegions removeObject:region];
        }];
    }
    return mapRegions;
}

- (NSArray<OAWorldRegion *> *)getWorldRegionsAt:(double)latitude longitude:(double)longitude
{
    NSMutableArray<OAWorldRegion *> *mapRegions = [NSMutableArray arrayWithArray:[self queryAtLat:latitude lon:longitude]];
    if (mapRegions.count > 0)
    {
        [mapRegions.copy enumerateObjectsUsingBlock:^(OAWorldRegion * _Nonnull region, NSUInteger idx, BOOL * _Nonnull stop) {
            if (![region contain:latitude lon:longitude])
                [mapRegions removeObject:region];
        }];

        [mapRegions sortUsingComparator:^NSComparisonResult(id a, id b) {
            NSNumber *first = [NSNumber numberWithDouble:[(OAWorldRegion *)a getArea]];
            NSNumber *second = [NSNumber numberWithDouble:[(OAWorldRegion *)b getArea]];
            return [first compare:second];
        }];
    }
    return mapRegions;
}

- (OAWorldRegion *) findAtLat:(double)latitude lon:(double)longitude
{
    NSArray<OAWorldRegion *> *mapRegions = [self getWorldRegionsAt:latitude longitude:longitude];
    return mapRegions.count > 0 ? mapRegions.firstObject : nil;
}

- (NSString *) getCountryNameAtLat:(double)latitude lon:(double)longitude
{
    OAWorldRegion *region = [self findAtLat:latitude lon:longitude];
    if (region && region.name && region.name.length > 0)
        return region.name;
    return nil;
}

- (NSInteger) getLevel
{
    NSInteger res = 0;
    OAWorldRegion *parent = _superregion;
    while (parent) {
        parent = parent.superregion;
        res++;
    }
    return res;
}

- (BOOL) containsSubregion:(NSString *)regionId
{
    for (OAWorldRegion *region in _subregions)
    {
        if ([region.regionId isEqualToString:regionId])
            return YES;
    }
    return NO;
}

- (OAWorldRegion *) getSubregion:(NSString *)regionId
{
    for (OAWorldRegion *region in _subregions)
    {
        if ([region.regionId isEqualToString:regionId])
            return region;
    }
    return nil;
}

- (OAWorldRegion *) getFlattenedSubregion:(NSString *)regionId
{
    for (OAWorldRegion *region in _flattenedSubregions)
        if ([region.regionId isEqualToString:regionId])
            return region;

    return nil;
}

- (NSArray<OAWorldRegion *> *) getFlattenedSubregions:(NSArray<NSString *> *)regionIds
{
    NSMutableArray<OAWorldRegion *> *res = [NSMutableArray array];
    for (OAWorldRegion *region in _flattenedSubregions)
        if ([regionIds containsObject:region.regionId])
            [res addObject:region];

    return res;
}

- (OAWorldRegion *) getRegionDataByDownloadName:(NSString *)downloadName
{
    if (!downloadName)
    {
        return nil;
    }
    else
    {
        for (OAWorldRegion *region in _flattenedSubregions)
        {
            NSString *regionDownloadId = region.downloadsIdPrefix;
            if ([regionDownloadId hasSuffix:@"."])
                regionDownloadId = [regionDownloadId substringToIndex:[regionDownloadId length] - 1];

            if ([regionDownloadId isEqualToString:downloadName])
                return region;
        }
        return nil;
    }
}

- (void)findBoundaries
{
    if (_worldRegion != nullptr)
    {
        const auto &polyPoints31 = _worldRegion->polygon;
        if (!polyPoints31.isEmpty())
        {
            int32_t x = polyPoints31.at(0).x;
            int32_t y = polyPoints31.at(0).y;
            double minX = x;
            double maxX = x;
            double minY = y;
            double maxY = y;

            if (polyPoints31.size() > 1)
            {
                for (int i = 1; i < polyPoints31.size(); i++)
                {
                    x = polyPoints31.at(i).x;
                    y = polyPoints31.at(i).y;
                    
                    if (x > maxX)
                        maxX = x;
                    else if (x < minX)
                        minX = x;
                    
                    if (y < maxY)
                        maxY = y;
                    else if (y > minY)
                        minY = y;
                }
            }
            _boundingBox = [[QuadRect alloc] initWithLeft:minX top:minY right:maxX bottom:maxY];
        }
    }
}

- (void)buildResourceGroupItem
{
    NSArray<OAWorldRegion *> *subregions = [self.class removeDuplicates:self.subregions];
    if (!subregions || subregions.count == 0)
        return;

    NSMutableArray<NSNumber *> *resourceGroupTypes = [[OAResourceType mapResourceTypes] mutableCopy];
    [resourceGroupTypes removeObjectsInArray:self.resourceTypes];
    
    if (![self hasGroupItems] && resourceGroupTypes.count > 0)
    {
        OAResourceGroupItem *group = [OAResourceGroupItem withParent:self];
        NSArray<OAResourceItem *> *items = [OAResourcesUIHelper requestMapDownloadInfo:subregions resourceTypes:resourceGroupTypes isGroup:YES];
        for (OAResourceItem *item in items)
        {
            if (item.worldRegion && item.worldRegion.regionMap && item.worldRegion.regionJoinMap && item.resourceType == OsmAndResourceType::MapRegion)
                continue;

            if ([item isKindOfClass:OARepositoryResourceItem.class])
                item.downloadTask = [[[OsmAndApp instance].downloadsManager downloadTasksWithKey:[@"resource:" stringByAppendingString:((OARepositoryResourceItem *) item).resource->id.toNSString()]] firstObject];

            [group addItem:item key:item.resourceType];
        }
        [group sort];
        self.groupItem = group;
    }

    for (OAWorldRegion *subregion in subregions)
    {
        [subregion buildResourceGroupItem];
        if ([subregion hasGroupItems] && [self.flattenedSubregions containsObject:subregion])
        {
            NSInteger indexOfSubregion = [self.flattenedSubregions indexOfObject:subregion];
            if (indexOfSubregion != NSNotFound)
            {
                if (![self.flattenedSubregions[indexOfSubregion] hasGroupItems])
                    self.flattenedSubregions[indexOfSubregion].groupItem = subregion.groupItem;
            }
        }
    }
}

- (void)updateGroupItems:(OAWorldRegion *)subregion type:(NSNumber *)type
{
    OsmAndResourceType key = [OAResourceType toResourceType:type isGroup:YES];
    if ([self hasGroupItems] && ![self.resourceTypes containsObject:[OAResourceType toValue:key]])
    {
        [self.groupItem removeItem:key subregion:subregion];

        NSArray<OAResourceItem *> *newItems = [OAResourcesUIHelper requestMapDownloadInfo:@[subregion] resourceTypes:@[type] isGroup:YES];
        [self.groupItem addItems:newItems key:key];
        [self.groupItem sort];
    }
    else
    {
        [self buildResourceGroupItem];
    }
}

- (BOOL)hasGroupItems
{
    return self.groupItem && ![self.groupItem isEmpty];
}

+ (NSArray<OAWorldRegion *> *)removeDuplicates:(NSArray<OAWorldRegion *> *)regions
{
    NSMutableArray<OAWorldRegion *> *copy = [regions mutableCopy];
    if (copy.count > 0)
    {
        NSMutableSet<OAWorldRegion *> *duplicates = [NSMutableSet new];
        for (int i = 0; i < copy.count - 1; i++)
        {
            OAWorldRegion *r1 = copy[i];
            for (int j = i + 1; j < copy.count; j++)
            {
                OAWorldRegion *r2 = copy[j];
                if ([r1 containsRegion:r2])
                    [duplicates addObject:r2];
                else if ([r2 containsRegion:r1])
                    [duplicates addObject:r1];
            }
        }
        [copy removeObjectsInArray:duplicates.allObjects];
    }
    return copy;
}

- (BOOL)containsRegion:(OAWorldRegion *)another
{
    // Firstly check rectangles for greater efficiency
    if (![self containsBoundingBox:another.boundingBox])
        return NO;

    // Secondly check whole polygons
    if (![self containsPolygon:[another getPoints31]])
        return NO;

    // Finally check inner point
    BOOL isInnerPoint = [another contain:another.regionCenter.latitude lon:another.regionCenter.longitude];
    if (isInnerPoint)
    {
        return [self contain:another.regionCenter.latitude lon:another.regionCenter.longitude];
    }
    else
    {
        // in this case we should find real inner point and check it
    }

    return YES;
}

- (BOOL)containsBoundingBox:(QuadRect *)rectangle
{
    return _boundingBox && rectangle && [_boundingBox contains:rectangle];
}

- (BOOL)containsPolygon:(QVector<OsmAnd::PointI>)another
{
    return (!_worldRegion->polygon.isEmpty() && !another.isEmpty()) &&
            [OAMapUtils isFirstPolygonInsideSecond:another secondPolygon:_worldRegion->polygon];
}

- (BOOL)isContinent
{
    if (_superregion)
    {
        NSString *superRegionId = _superregion.regionId;
        NSString *thisRegionId = _regionId;
        return [kWorld isEqualToString:superRegionId] && ![OsmAnd::WorldRegions::RussiaRegionId.toNSString() isEqualToString:thisRegionId];
    }
    return false;
}

- (BOOL)containsPoint:(CLLocation *)location
{
    return [self contain:location.coordinate.latitude lon:location.coordinate.longitude];
}

@end
