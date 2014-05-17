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

@implementation OAWorldRegion
{
    std::shared_ptr<const OsmAnd::WorldRegions::WorldRegion> _worldRegion;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self ctor];
        _regionId = nil;
        _nativeName = nil;
        _localizedName = nil;
        _superregion = nil;
    }
    return self;
}

- (instancetype)initFrom:(const std::shared_ptr<const OsmAnd::WorldRegions::WorldRegion>&)region
{
    self = [super init];
    if (self) {
        [self ctor];
        _worldRegion = region;
        _regionId = _worldRegion->id.toNSString();
        _nativeName = _worldRegion->name.toNSString();
        const auto citLocalizedName = _worldRegion->localizedNames.constFind(QString::fromNSString([[NSLocale preferredLanguages] firstObject]));
        if (citLocalizedName == _worldRegion->localizedNames.cend())
            _localizedName = nil;
        else
            _localizedName = (*citLocalizedName).toNSString();
    }
    return self;
}

- (instancetype)initWithId:(NSString*)regionId andLocalizedName:(NSString*)localizedName
{
    self = [super init];
    if (self) {
        [self ctor];
        _regionId = regionId;
        _nativeName = nil;
        _localizedName = localizedName;
    }
    return self;
}

- (void)dealloc
{
    [self dtor];
}

- (void)ctor
{
    _superregion = nil;
    _subregions = [[NSMutableArray alloc] init];
    _flattenedSubregions = [[NSMutableArray alloc] init];
}

- (void)dtor
{
}

@synthesize regionId = _regionId;
@synthesize nativeName = _nativeName;
@synthesize localizedName = _localizedName;
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

+ (OAWorldRegion*)loadFrom:(NSString*)ocbfFilename
{
    OsmAnd::WorldRegions worldRegionsRegistry(QString::fromNSString(ocbfFilename));

    QHash< QString, std::shared_ptr< const OsmAnd::WorldRegions::WorldRegion > > loadedWorldRegions;
    if (!worldRegionsRegistry.loadWorldRegions(loadedWorldRegions))
        return nil;

    NSMutableDictionary* regionsLookupTable = [[NSMutableDictionary alloc] initWithCapacity:loadedWorldRegions.size()];

    // Create root region
    OAWorldRegion* entireWorld = [[OAWorldRegion alloc] init];

    // Create main regions:

    OAWorldRegion* africaRegion = [[OAWorldRegion alloc] initWithId:OsmAnd::WorldRegions::AfricaRegionId.toNSString()
                                                   andLocalizedName:OALocalizedString(@"Africa")];
    [entireWorld addSubregion:africaRegion];
    [regionsLookupTable setValue:africaRegion forKey:africaRegion.regionId];
    loadedWorldRegions.remove(OsmAnd::WorldRegions::AfricaRegionId);

    OAWorldRegion* asiaRegion = [[OAWorldRegion alloc] initWithId:OsmAnd::WorldRegions::AsiaRegionId.toNSString()
                                                 andLocalizedName:OALocalizedString(@"Asia")];
    [entireWorld addSubregion:asiaRegion];
    [regionsLookupTable setValue:asiaRegion forKey:asiaRegion.regionId];
    loadedWorldRegions.remove(OsmAnd::WorldRegions::AsiaRegionId);

    OAWorldRegion* australiaAndOceaniaRegion = [[OAWorldRegion alloc] initWithId:OsmAnd::WorldRegions::AustraliaAndOceaniaRegionId.toNSString()
                                                                andLocalizedName:OALocalizedString(@"Australia and Oceania")];
    [entireWorld addSubregion:australiaAndOceaniaRegion];
    [regionsLookupTable setValue:australiaAndOceaniaRegion forKey:australiaAndOceaniaRegion.regionId];
    loadedWorldRegions.remove(OsmAnd::WorldRegions::AustraliaAndOceaniaRegionId);

    OAWorldRegion* centralAmericaRegion = [[OAWorldRegion alloc] initWithId:OsmAnd::WorldRegions::CentralAmericaRegionId.toNSString()
                                                           andLocalizedName:OALocalizedString(@"Central America")];
    [entireWorld addSubregion:centralAmericaRegion];
    [regionsLookupTable setValue:centralAmericaRegion forKey:centralAmericaRegion.regionId];
    loadedWorldRegions.remove(OsmAnd::WorldRegions::CentralAmericaRegionId);

    OAWorldRegion* europeRegion = [[OAWorldRegion alloc] initWithId:OsmAnd::WorldRegions::EuropeRegionId.toNSString()
                                                   andLocalizedName:OALocalizedString(@"Europe")];
    [entireWorld addSubregion:europeRegion];
    [regionsLookupTable setValue:europeRegion forKey:europeRegion.regionId];
    loadedWorldRegions.remove(OsmAnd::WorldRegions::EuropeRegionId);

    OAWorldRegion* northAmericaRegion = [[OAWorldRegion alloc] initWithId:OsmAnd::WorldRegions::NorthAmericaRegionId.toNSString()
                                                         andLocalizedName:OALocalizedString(@"North America")];
    [entireWorld addSubregion:northAmericaRegion];
    [regionsLookupTable setValue:northAmericaRegion forKey:northAmericaRegion.regionId];
    loadedWorldRegions.remove(OsmAnd::WorldRegions::NorthAmericaRegionId);

    OAWorldRegion* southAmericaRegion = [[OAWorldRegion alloc] initWithId:OsmAnd::WorldRegions::SouthAmericaRegionId.toNSString()
                                                         andLocalizedName:OALocalizedString(@"South America")];
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

@end
