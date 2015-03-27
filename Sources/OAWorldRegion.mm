//
//  OAWorldRegion.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 4/27/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAWorldRegion.h"

#include <OsmAndCore/WorldRegions.h>

#import "Localization.h"
#import "OALog.h"
#import "OAIAPHelper.h"

@implementation OAWorldRegion
{
    std::shared_ptr<const OsmAnd::WorldRegions::WorldRegion> _worldRegion;
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

- (instancetype)initFrom:(const std::shared_ptr<const OsmAnd::WorldRegions::WorldRegion>&)region
{
    self = [super init];
    if (self) {
        [self commonInit];
        _worldRegion = region;
        _regionId = _worldRegion->id.toNSString();
        _downloadsIdPrefix = [_worldRegion->downloadId.toNSString() stringByAppendingString:@"."];
        _nativeName = _worldRegion->name.toNSString();
        [self setLocalizedNamesFrom:region->localizedNames];
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

- (void)setWorldRegion:(const std::shared_ptr<const OsmAnd::WorldRegions::WorldRegion>&)worldRegion
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

    QHash< QString, std::shared_ptr< const OsmAnd::WorldRegions::WorldRegion > > loadedWorldRegions;
    if (!worldRegionsRegistry.loadWorldRegions(loadedWorldRegions))
        return nil;

    NSMutableDictionary* regionsLookupTable = [[NSMutableDictionary alloc] initWithCapacity:loadedWorldRegions.size()];

    // Create root region
    OAWorldRegion* entireWorld = [[OAWorldRegion alloc] initWorld];

    // Create main regions:

    OAWorldRegion* africaRegion = [OAWorldRegion createRegionAs:OsmAnd::WorldRegions::AfricaRegionId
                                              withLocalizedName:OALocalizedString(@"Africa")
                                                           from:loadedWorldRegions];
    [entireWorld addSubregion:africaRegion];
    [regionsLookupTable setValue:africaRegion forKey:africaRegion.regionId];
    loadedWorldRegions.remove(OsmAnd::WorldRegions::AfricaRegionId);

    OAWorldRegion* asiaRegion = [OAWorldRegion createRegionAs:OsmAnd::WorldRegions::AsiaRegionId
                                            withLocalizedName:OALocalizedString(@"Asia")
                                                         from:loadedWorldRegions];
    [entireWorld addSubregion:asiaRegion];
    [regionsLookupTable setValue:asiaRegion forKey:asiaRegion.regionId];
    loadedWorldRegions.remove(OsmAnd::WorldRegions::AsiaRegionId);

    OAWorldRegion* australiaAndOceaniaRegion = [OAWorldRegion createRegionAs:OsmAnd::WorldRegions::AustraliaAndOceaniaRegionId
                                                           withLocalizedName:OALocalizedString(@"Australia and Oceania")
                                                                        from:loadedWorldRegions];
    [entireWorld addSubregion:australiaAndOceaniaRegion];
    [regionsLookupTable setValue:australiaAndOceaniaRegion forKey:australiaAndOceaniaRegion.regionId];
    loadedWorldRegions.remove(OsmAnd::WorldRegions::AustraliaAndOceaniaRegionId);

    OAWorldRegion* centralAmericaRegion = [OAWorldRegion createRegionAs:OsmAnd::WorldRegions::CentralAmericaRegionId
                                                      withLocalizedName:OALocalizedString(@"Central America")
                                                                   from:loadedWorldRegions];
    [entireWorld addSubregion:centralAmericaRegion];
    [regionsLookupTable setValue:centralAmericaRegion forKey:centralAmericaRegion.regionId];
    loadedWorldRegions.remove(OsmAnd::WorldRegions::CentralAmericaRegionId);

    OAWorldRegion* europeRegion = [OAWorldRegion createRegionAs:OsmAnd::WorldRegions::EuropeRegionId
                                              withLocalizedName:OALocalizedString(@"Europe")
                                                           from:loadedWorldRegions];
    [entireWorld addSubregion:europeRegion];
    [regionsLookupTable setValue:europeRegion forKey:europeRegion.regionId];
    loadedWorldRegions.remove(OsmAnd::WorldRegions::EuropeRegionId);

    OAWorldRegion* northAmericaRegion = [OAWorldRegion createRegionAs:OsmAnd::WorldRegions::NorthAmericaRegionId
                                                    withLocalizedName:OALocalizedString(@"North America")
                                                                 from:loadedWorldRegions];
    [entireWorld addSubregion:northAmericaRegion];
    [regionsLookupTable setValue:northAmericaRegion forKey:northAmericaRegion.regionId];
    loadedWorldRegions.remove(OsmAnd::WorldRegions::NorthAmericaRegionId);

    OAWorldRegion* russiaRegion = [OAWorldRegion createRegionAs:OsmAnd::WorldRegions::RussiaRegionId
                                              withLocalizedName:OALocalizedString(@"Russia")
                                                           from:loadedWorldRegions];
    [entireWorld addSubregion:russiaRegion];
    [regionsLookupTable setValue:russiaRegion forKey:russiaRegion.regionId];
    loadedWorldRegions.remove(OsmAnd::WorldRegions::RussiaRegionId);

    OAWorldRegion* southAmericaRegion = [OAWorldRegion createRegionAs:OsmAnd::WorldRegions::SouthAmericaRegionId
                                                    withLocalizedName:OALocalizedString(@"South America")
                                                                 from:loadedWorldRegions];
    [entireWorld addSubregion:southAmericaRegion];
    [regionsLookupTable setValue:southAmericaRegion forKey:southAmericaRegion.regionId];
    loadedWorldRegions.remove(OsmAnd::WorldRegions::SouthAmericaRegionId);

    // Process remaining regions
    for(;;)
    {
        unsigned int processedRegions = 0;

        QMutableHashIterator< QString, std::shared_ptr< const OsmAnd::WorldRegions::WorldRegion > > itRegion(loadedWorldRegions);
        while(itRegion.hasNext())
        {
            const auto& region = itRegion.next().value();
            NSString* parentRegionId = region->parentId.toNSString();

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
              qPrintable(orphanedRegion->id),
              qPrintable(orphanedRegion->parentId));
    }

    return [entireWorld makeImmutable];
}

+ (OAWorldRegion*)createRegionAs:(const QString&)regionId
               withLocalizedName:(NSString*)localizedName
                            from:(const QHash< QString, std::shared_ptr< const OsmAnd::WorldRegions::WorldRegion > >&)regionsDb
{
    // First try to find this region in database
    const auto citRegion = regionsDb.constFind(regionId);
    if (citRegion != regionsDb.cend())
    {
        const auto& region = *citRegion;

        OAWorldRegion* worldRegion = [[OAWorldRegion alloc] initWithId:regionId.toNSString()
                                                   andDownloadIdPrefix:[region->downloadId.toNSString() stringByAppendingString:@"."]
                                                      andLocalizedName:nil];
        [worldRegion setWorldRegion:region];
        [worldRegion setNativeName:region->name.toNSString()];
        [worldRegion setLocalizedNamesFrom:region->localizedNames
                             withExtraName:localizedName];
        return worldRegion;
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
