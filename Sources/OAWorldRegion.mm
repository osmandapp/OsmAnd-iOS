//
//  OAWorldRegion.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 4/27/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAWorldRegion.h"

#include <OsmAndCore/WorldRegion.h>
#include <OsmAndCore/WorldRegions.h>
#include <OsmAndCore/Data/MapObject.h>
#include <OsmAndCore/Data/BinaryMapObject.h>
#include <OsmAndCore/Data/ObfMapObject.h>
#include <OsmAndCore/KeyedEntriesCollection.h>

#import "Localization.h"
#import "OALog.h"
#import "OAIAPHelper.h"

@implementation OAWorldRegion
{
    std::shared_ptr<const OsmAnd::WorldRegion> _worldRegion;
}

- (instancetype)initWorld
{
    self = [super init];
    if (self) {
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

- (instancetype)initFrom:(const std::shared_ptr<const OsmAnd::WorldRegion>&)region
{
    self = [super init];
    if (self) {
        [self commonInit];
        _worldRegion = region;
        _regionId = _worldRegion->fullRegionName.toNSString();
        _downloadsIdPrefix = [_worldRegion->downloadName.toNSString() stringByAppendingString:@"."];
        _nativeName = _worldRegion->nativeName.toNSString();
        [self setLocalizedNamesFrom:region->localizedNames];
        
        if (!_localizedName && _nativeName.length == 0)
        {
            for(const auto& entry : OsmAnd::rangeOf(OsmAnd::constOf(region->mapObject->captions)))
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

- (instancetype)initWithId:(NSString*)regionId
          andLocalizedName:(NSString*)localizedName
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

- (instancetype)initWithId:(NSString*)regionId
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

- (void)dealloc
{
    [self deinit];
}

- (void)commonInit
{
    _superregion = nil;
    _subregions = [[NSMutableArray alloc] init];
    _flattenedSubregions = [[NSMutableArray alloc] init];
}

- (void)deinit
{
}

@synthesize regionId = _regionId;
@synthesize downloadsIdPrefix = _downloadsIdPrefix;
@synthesize nativeName = _nativeName;
@synthesize localizedName = _localizedName;
@synthesize allNames = _allNames;

@synthesize superregion = _superregion;
@synthesize subregions = _subregions;
@synthesize flattenedSubregions = _flattenedSubregions;

- (NSString*)name
{
    return _localizedName != nil ? _localizedName : _nativeName;
}

- (NSComparisonResult)compare:(OAWorldRegion*)other
{
    return [self.name localizedCaseInsensitiveCompare:other.name];
}

- (void)addSubregion:(OAWorldRegion*)subregion
{
    [subregion setSuperregion:self];

    NSMutableArray* subregions = (NSMutableArray*)_subregions;
    [subregions addObject:subregion];

    [self propagateSubregionToFlattenedHierarchy:subregion];
}

- (void)propagateSubregionToFlattenedHierarchy:(OAWorldRegion*)subregion
{
    NSMutableArray* flattenedSubregions = (NSMutableArray*)_flattenedSubregions;
    [flattenedSubregions addObject:subregion];

    if (_superregion != nil)
        [_superregion propagateSubregionToFlattenedHierarchy:subregion];
}

- (void)setSuperregion:(OAWorldRegion *)superregion
{
    _superregion = superregion;
}

- (OAWorldRegion*)makeImmutable
{
    if (![_subregions isKindOfClass:[NSArray class]])
        _subregions = [NSArray arrayWithArray:_subregions];

    if (![_flattenedSubregions isKindOfClass:[NSArray class]])
        _flattenedSubregions = [NSArray arrayWithArray:_flattenedSubregions];

    for(OAWorldRegion* subregion in _subregions)
        [subregion makeImmutable];

    return self;
}

- (void)setWorldRegion:(const std::shared_ptr<const OsmAnd::WorldRegion>&)worldRegion
{
    _worldRegion = worldRegion;
}

- (void)setNativeName:(NSString *)nativeName
{
    _nativeName = nativeName;
}

- (void)setLocalizedNamesFrom:(const QHash<QString, QString>&)localizedNames
{
    [self setLocalizedNamesFrom:localizedNames
                  withExtraName:nil];
}

- (void)setLocalizedNamesFrom:(const QHash<QString, QString>&)localizedNames withExtraName:(NSString*)extraLocalizedName
{
    const auto citLocalizedName = localizedNames.constFind(QString::fromNSString([[NSLocale preferredLanguages] firstObject]));
    if (citLocalizedName == localizedNames.cend())
        _localizedName = extraLocalizedName;
    else
        _localizedName = (*citLocalizedName).toNSString();
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

+ (OAWorldRegion*)loadFrom:(NSString*)ocbfFilename
{
    OsmAnd::WorldRegions worldRegionsRegistry(QString::fromNSString(ocbfFilename));

    QList< std::shared_ptr< const OsmAnd::WorldRegion > > loadedWorldRegions;
    if (!worldRegionsRegistry.loadWorldRegions(&loadedWorldRegions, true))
        return nil;

    NSMutableDictionary* regionsLookupTable = [[NSMutableDictionary alloc] initWithCapacity:loadedWorldRegions.size()];

    // Create root region
    OAWorldRegion* entireWorld = [[OAWorldRegion alloc] initWorld];

    // Create main regions:

    OAWorldRegion* africaRegion = [OAWorldRegion createRegionAs:OsmAnd::WorldRegions::AfricaRegionId
                                              withLocalizedName:OALocalizedString(@"region_africa")
                                                           from:loadedWorldRegions];
    [entireWorld addSubregion:africaRegion];
    [regionsLookupTable setValue:africaRegion forKey:africaRegion.regionId];

    OAWorldRegion* asiaRegion = [OAWorldRegion createRegionAs:OsmAnd::WorldRegions::AsiaRegionId
                                            withLocalizedName:OALocalizedString(@"region_asia")
                                                         from:loadedWorldRegions];
    [entireWorld addSubregion:asiaRegion];
    [regionsLookupTable setValue:asiaRegion forKey:asiaRegion.regionId];

    OAWorldRegion* australiaAndOceaniaRegion = [OAWorldRegion createRegionAs:OsmAnd::WorldRegions::AustraliaAndOceaniaRegionId
                                                           withLocalizedName:OALocalizedString(@"region_ausralia_and_oceania")
                                                                        from:loadedWorldRegions];
    [entireWorld addSubregion:australiaAndOceaniaRegion];
    [regionsLookupTable setValue:australiaAndOceaniaRegion forKey:australiaAndOceaniaRegion.regionId];

    OAWorldRegion* centralAmericaRegion = [OAWorldRegion createRegionAs:OsmAnd::WorldRegions::CentralAmericaRegionId
                                                      withLocalizedName:OALocalizedString(@"region_central_america")
                                                                   from:loadedWorldRegions];
    [entireWorld addSubregion:centralAmericaRegion];
    [regionsLookupTable setValue:centralAmericaRegion forKey:centralAmericaRegion.regionId];

    OAWorldRegion* europeRegion = [OAWorldRegion createRegionAs:OsmAnd::WorldRegions::EuropeRegionId
                                              withLocalizedName:OALocalizedString(@"region_europe")
                                                           from:loadedWorldRegions];
    [entireWorld addSubregion:europeRegion];
    [regionsLookupTable setValue:europeRegion forKey:europeRegion.regionId];

    OAWorldRegion* northAmericaRegion = [OAWorldRegion createRegionAs:OsmAnd::WorldRegions::NorthAmericaRegionId
                                                    withLocalizedName:OALocalizedString(@"region_north_america")
                                                                 from:loadedWorldRegions];
    [entireWorld addSubregion:northAmericaRegion];
    [regionsLookupTable setValue:northAmericaRegion forKey:northAmericaRegion.regionId];

    OAWorldRegion* russiaRegion = [OAWorldRegion createRegionAs:OsmAnd::WorldRegions::RussiaRegionId
                                              withLocalizedName:OALocalizedString(@"region_russia")
                                                           from:loadedWorldRegions];
    [entireWorld addSubregion:russiaRegion];
    [regionsLookupTable setValue:russiaRegion forKey:russiaRegion.regionId];

    OAWorldRegion* southAmericaRegion = [OAWorldRegion createRegionAs:OsmAnd::WorldRegions::SouthAmericaRegionId
                                                    withLocalizedName:OALocalizedString(@"region_south_america")
                                                                 from:loadedWorldRegions];
    [entireWorld addSubregion:southAmericaRegion];
    [regionsLookupTable setValue:southAmericaRegion forKey:southAmericaRegion.regionId];
    
    // Process remaining regions
    for(;;)
    {
        unsigned int processedRegions = 0;
        
        QMutableListIterator< std::shared_ptr< const OsmAnd::WorldRegion > > itRegion(loadedWorldRegions);
        while(itRegion.hasNext())
        {
            const auto& region = itRegion.next();
            NSString* parentRegionId = region->parentRegionName.toNSString();

            // Try to find parent of this region
            OAWorldRegion* parentRegion = [regionsLookupTable objectForKey:parentRegionId];
            if (parentRegion == nil)
                continue;

            OAWorldRegion* newRegion = [[OAWorldRegion alloc] initFrom:region];
            [parentRegion addSubregion:newRegion];
            [regionsLookupTable setValue:newRegion forKey:newRegion.regionId];
            
            // Remove
            processedRegions++;
            itRegion.remove();
        }

        // If all remaining are orphans, that's all
        if (processedRegions == 0)
            break;
    }

    for(const auto& orphanedRegion : loadedWorldRegions)
    {
        OALog(@"Found orphaned region '%s' in '%s'",
              qPrintable(orphanedRegion->fullRegionName),
              qPrintable(orphanedRegion->parentRegionName));
    }

    return [entireWorld makeImmutable];
}

+ (OAWorldRegion*)createRegionAs:(const QString&)regionId
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

- (NSString*)description
{
    return [NSString stringWithFormat:@"%@ (%@)", self.name, _regionId];
}

- (BOOL)purchased
{
    // world map
    if (_regionId == nil)
        return YES;
    
    OAIAPHelper *iapHelper = [OAIAPHelper sharedInstance];
    
    if ([iapHelper productPurchased:kInAppId_Region_All_World])
        return YES;
    
    if ([_regionId isEqualToString:OsmAnd::WorldRegions::AfricaRegionId.toNSString()]) {
        return [iapHelper productPurchased:kInAppId_Region_Africa];
    }
    if ([_regionId isEqualToString:OsmAnd::WorldRegions::AsiaRegionId.toNSString()]) {
        return [iapHelper productPurchased:kInAppId_Region_Asia];
    }
    if ([_regionId isEqualToString:OsmAnd::WorldRegions::AustraliaAndOceaniaRegionId.toNSString()]) {
        return [iapHelper productPurchased:kInAppId_Region_Australia];
    }
    if ([_regionId isEqualToString:OsmAnd::WorldRegions::CentralAmericaRegionId.toNSString()]) {
        return [iapHelper productPurchased:kInAppId_Region_Central_America];
    }
    if ([_regionId isEqualToString:OsmAnd::WorldRegions::EuropeRegionId.toNSString()]) {
        return [iapHelper productPurchased:kInAppId_Region_Europe];
    }
    if ([_regionId isEqualToString:OsmAnd::WorldRegions::NorthAmericaRegionId.toNSString()]) {
        return [iapHelper productPurchased:kInAppId_Region_North_America];
    }
    if ([_regionId isEqualToString:OsmAnd::WorldRegions::RussiaRegionId.toNSString()]) {
        return [iapHelper productPurchased:kInAppId_Region_Russia];
    }
    if ([_regionId isEqualToString:OsmAnd::WorldRegions::SouthAmericaRegionId.toNSString()]) {
        return [iapHelper productPurchased:kInAppId_Region_South_America];
    }
    return NO;
}


- (BOOL)isInPurchasedArea
{
    return [self purchased] || [self isInPurchasedArea:self];
}

- (BOOL)isInPurchasedArea:(OAWorldRegion *)region
{
    if (region.regionId == nil)
        return NO;
    
    if ([region purchased] || (region.superregion.regionId != nil && [region.superregion purchased]))
        return YES;
    if (region.superregion.regionId && [self isInPurchasedArea:region.superregion])
        return YES;
    return NO;
}

@end
