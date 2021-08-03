//
//  OAWorldRegion.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 4/27/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAWorldRegion.h"

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/WorldRegion.h>
#include <OsmAndCore/WorldRegions.h>
#include <OsmAndCore/Data/MapObject.h>
#include <OsmAndCore/Data/BinaryMapObject.h>
#include <OsmAndCore/Data/ObfMapObject.h>
#include <OsmAndCore/Data/ObfMapSectionInfo.h>
#include <OsmAndCore/KeyedEntriesCollection.h>

#import "Localization.h"
#import "OALog.h"
#import "OAIAPHelper.h"
#import "OAUtilities.h"

#import "OAWorldRegion+Protected.h"
#import "OAResourcesUIHelper.h"

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
        _regionId = _worldRegion->fullRegionName.toNSString();
        _downloadsIdPrefix = [_worldRegion->downloadName.toNSString() stringByAppendingString:@"."];
        _nativeName = _worldRegion->nativeName.toNSString();
        
        _regionLeftHandDriving = _worldRegion->regionLeftHandDriving.toNSString();
        _regionLang = _worldRegion->regionLang.toNSString();
        _regionMetric = _worldRegion->regionMetric.toNSString();
        _regionRoadSigns = _worldRegion->regionRoadSigns.toNSString();
        _wikiLink = _worldRegion->wikiLink.toNSString();
        _population = _worldRegion->population.toNSString();
        
        OsmAnd::LatLon latLonTopLeft = OsmAnd::Utilities::convert31ToLatLon(region->mapObject->bbox31.topLeft);
        OsmAnd::LatLon latLonBottomRight = OsmAnd::Utilities::convert31ToLatLon(region->mapObject->bbox31.bottomRight);
        _bboxTopLeft = CLLocationCoordinate2DMake(latLonTopLeft.latitude, latLonTopLeft.longitude);
        _bboxBottomRight = CLLocationCoordinate2DMake(latLonBottomRight.latitude, latLonBottomRight.longitude);
        
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

- (double) getArea
{
    double area = 0.0;
    if (_worldRegion != nullptr && _worldRegion->mapObject != nullptr && _worldRegion->mapObject->points31.count() > 1)
    {
        for (int i = 1; i < _worldRegion->mapObject->points31.count(); i++)
        {
            double ax = _worldRegion->mapObject->points31.at(i - 1).x;
            double bx = _worldRegion->mapObject->points31.at(i).x;
            double ay = _worldRegion->mapObject->points31.at(i - 1).y;
            double by = _worldRegion->mapObject->points31.at(i).y;
            area += (bx + ax) * (by - ay) / 1.631E10;
        }
    }
    return ABS(area);
}

- (BOOL) contain:(double) lat lon:(double) lon
{
    BOOL res = NO;
    if (_worldRegion != nullptr && _worldRegion->mapObject != nullptr && _worldRegion->mapObject->points31.count() > 1)
    {
        OsmAnd::PointI p31 = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(lat, lon));
        int t = 0;
        for (int i = 1; i < _worldRegion->mapObject->points31.count(); i++) {
            int fx = [self.class ray_intersect_x:_worldRegion->mapObject->points31.at(i).x y:_worldRegion->mapObject->points31.at(i).y middleY:p31.y prevX:_worldRegion->mapObject->points31.at(i - 1).x prevY:_worldRegion->mapObject->points31.at(i - 1).y];
            if (INT_MIN != fx && p31.x >= fx)
                t++;
        }
        return t % 2 == 1;
    }
    return res;
}

+ (int) ray_intersect_x:(int) x y:(int) y middleY:(int) middleY prevX:(int) prevX prevY:(int) prevY
{
    // prev node above line
    // x,y node below line
    if (prevY > y)
    {
        int tx = x;
        int ty = y;
        x = prevX;
        y = prevY;
        prevX = tx;
        prevY = ty;
    }
    if (y == middleY || prevY == middleY)
        middleY -= 1;

    if (prevY > middleY || y < middleY)
    {
        return INT_MIN;
    }
    else
    {
        if (y == prevY)
        {
            // the node on the boundary !!!
            return x;
        }
        // that tested on all cases (left/right)
        double rx = x + ((double) middleY - y) * ((double) x - prevX) / (((double) y - prevY));
        return (int) rx;
    }
}

@synthesize regionId = _regionId;
@synthesize downloadsIdPrefix = _downloadsIdPrefix;
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
                                              withLocalizedName:OALocalizedString(@"region_antarctica")
                                                           from:loadedWorldRegions];
    [entireWorld addSubregion:antarcticaRegion];
    regionsLookupTable[antarcticaRegion.regionId] = antarcticaRegion;

    OAWorldRegion *africaRegion = [OAWorldRegion createRegionAs:OsmAnd::WorldRegions::AfricaRegionId
                                              withLocalizedName:OALocalizedString(@"region_africa")
                                                           from:loadedWorldRegions];
    [entireWorld addSubregion:africaRegion];
    regionsLookupTable[africaRegion.regionId] = africaRegion;

    OAWorldRegion* asiaRegion = [OAWorldRegion createRegionAs:OsmAnd::WorldRegions::AsiaRegionId
                                            withLocalizedName:OALocalizedString(@"region_asia")
                                                         from:loadedWorldRegions];
    [entireWorld addSubregion:asiaRegion];
    regionsLookupTable[asiaRegion.regionId] = asiaRegion;

    OAWorldRegion *australiaAndOceaniaRegion = [OAWorldRegion createRegionAs:OsmAnd::WorldRegions::AustraliaAndOceaniaRegionId
                                                           withLocalizedName:OALocalizedString(@"region_ausralia_and_oceania")
                                                                        from:loadedWorldRegions];
    [entireWorld addSubregion:australiaAndOceaniaRegion];
    regionsLookupTable[australiaAndOceaniaRegion.regionId] = australiaAndOceaniaRegion;

    OAWorldRegion *centralAmericaRegion = [OAWorldRegion createRegionAs:OsmAnd::WorldRegions::CentralAmericaRegionId
                                                      withLocalizedName:OALocalizedString(@"region_central_america")
                                                                   from:loadedWorldRegions];
    [entireWorld addSubregion:centralAmericaRegion];
    regionsLookupTable[centralAmericaRegion.regionId] = centralAmericaRegion;

    OAWorldRegion *europeRegion = [OAWorldRegion createRegionAs:OsmAnd::WorldRegions::EuropeRegionId
                                              withLocalizedName:OALocalizedString(@"region_europe")
                                                           from:loadedWorldRegions];
    [entireWorld addSubregion:europeRegion];
    regionsLookupTable[europeRegion.regionId] = europeRegion;

    OAWorldRegion *northAmericaRegion = [OAWorldRegion createRegionAs:OsmAnd::WorldRegions::NorthAmericaRegionId
                                                    withLocalizedName:OALocalizedString(@"region_north_america")
                                                                 from:loadedWorldRegions];
    [entireWorld addSubregion:northAmericaRegion];
    regionsLookupTable[northAmericaRegion.regionId] = northAmericaRegion;

    OAWorldRegion *russiaRegion = [OAWorldRegion createRegionAs:OsmAnd::WorldRegions::RussiaRegionId
                                              withLocalizedName:OALocalizedString(@"region_russia")
                                                           from:loadedWorldRegions];
    [entireWorld addSubregion:russiaRegion];
    regionsLookupTable[russiaRegion.regionId] = russiaRegion;

    OAWorldRegion *southAmericaRegion = [OAWorldRegion createRegionAs:OsmAnd::WorldRegions::SouthAmericaRegionId
                                                    withLocalizedName:OALocalizedString(@"region_south_america")
                                                                 from:loadedWorldRegions];
    [entireWorld addSubregion:southAmericaRegion];
    regionsLookupTable[southAmericaRegion.regionId] = southAmericaRegion;

    OAWorldRegion *nauticalRegion = [[OAWorldRegion alloc] initWithId:OsmAnd::WorldRegions::NauticalRegionId.toNSString()
                                                andDownloadIdPrefix:@"depth_"
                                                   andLocalizedName:OALocalizedString(@"region_nautical")];
    [entireWorld addSubregion:nauticalRegion];
    regionsLookupTable[nauticalRegion.regionId] = nauticalRegion;
    
    OAWorldRegion *othersRegion = [[OAWorldRegion alloc] initWithId:OsmAnd::WorldRegions::OthersRegionId.toNSString()
                                                andDownloadIdPrefix:@"others_"
                                                   andLocalizedName:OALocalizedString(@"region_others")];
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

- (OAWorldRegion *) findAtLat:(double)latitude lon:(double)longitude
{
    NSMutableArray<OAWorldRegion *> *mapRegions = [[self queryAtLat:latitude lon:longitude] mutableCopy];
    
    OAWorldRegion *selectedRegion = nil;
    if (mapRegions.count > 0)
    {
        [mapRegions enumerateObjectsUsingBlock:^(OAWorldRegion * _Nonnull region, NSUInteger idx, BOOL * _Nonnull stop) {
            if (![region contain:latitude lon:longitude])
                [mapRegions removeObject:region];
        }];
        
        double smallestArea = DBL_MAX;
        for (OAWorldRegion *region : mapRegions)
        {
            double area = [region getArea];
            if (area < smallestArea)
            {
                smallestArea = area;
                selectedRegion = region;
            }
        }
    }
    return selectedRegion;
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

- (void)buildResourceGroupItem
{
    NSArray<OAWorldRegion *> *subregions = self.subregions;
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
    if ([self hasGroupItems])
    {
        OsmAndResourceType key = [OAResourceType toResourceType:type isGroup:YES];
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

-(BOOL)hasGroupItems
{
    return self.groupItem && ![self.groupItem isEmpty];
}

@end
