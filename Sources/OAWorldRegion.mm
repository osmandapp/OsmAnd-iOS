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
}

- (id)init
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

- (id)initFrom:(const std::shared_ptr<const OsmAnd::WorldRegions::WorldRegion>&)region
{
    self = [super init];
    if (self) {
        [self ctor];
        _regionId = region->id.toNSString();
        _nativeName = region->name.toNSString();
        _localizedName = nil;
        for(NSString* lang in [NSLocale preferredLanguages])
        {
            const auto citLocalizedName = region->localizedNames.constFind(QString::fromNSString(lang));
            if(citLocalizedName == region->localizedNames.cend())
                continue;

            _localizedName = (*citLocalizedName).toNSString();
            break;
        }
        _superregion = nil;
    }
    return self;
}

- (id)initWithId:(NSString*)regionId andLocalizedName:(NSString*)localizedName
{
    self = [super init];
    if (self) {
        [self ctor];
        _regionId = regionId;
        _nativeName = nil;
        _localizedName = localizedName;
        _superregion = nil;
    }
    return self;
}

- (void)dealloc
{
    [self dtor];
}

- (void)ctor
{
    _subregions = [[NSMutableArray alloc] init];
}

- (void)dtor
{
}

@synthesize regionId = _regionId;
@synthesize nativeName = _nativeName;
@synthesize localizedName = _localizedName;
@synthesize superregion = _superregion;
@synthesize subregions = _subregions;

- (void)addSubregion:(OAWorldRegion*)subregion
{
    NSMutableArray* subregions = (NSMutableArray*)_subregions;
    [subregions addObject:subregion];
}

- (OAWorldRegion*)makeImmutable
{
    if([_subregions isKindOfClass:[NSArray class]])
        return self;
    _subregions = [NSArray arrayWithArray:_subregions];

    for(OAWorldRegion* subregion in _subregions)
        [subregion makeImmutable];

    return self;
}

+ (OAWorldRegion*)loadFrom:(NSString*)ocbfFilename
{
    OsmAnd::WorldRegions worldRegionsRegistry(QString::fromNSString(ocbfFilename));

    QHash< QString, std::shared_ptr< const OsmAnd::WorldRegions::WorldRegion > > loadedWorldRegions;
    if(!worldRegionsRegistry.loadWorldRegions(loadedWorldRegions))
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
            if(parentRegion == nil)
                continue;

            OAWorldRegion* newRegion = [[OAWorldRegion alloc] initFrom:region];
            [parentRegion addSubregion:newRegion];
            [regionsLookupTable setValue:newRegion forKey:newRegion.regionId];
            
            // Remove
            processedRegions++;
            itRegion.remove();
        }

        // If all remaining are orphans, that's all
        if(processedRegions == 0)
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
