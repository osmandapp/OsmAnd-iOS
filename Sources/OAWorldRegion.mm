//
//  OAWorldRegion.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 4/27/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAWorldRegion.h"

#include <OsmAndCore/WorldRegions.h>

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

- (id)initFrom:(const std::shared_ptr<const OsmAnd::WorldRegions::WorldRegion>&)worldRegion
{
    self = [super init];
    if (self) {
        [self ctor];
        _regionId = worldRegion->id.toNSString();
        _nativeName = worldRegion->name.toNSString();
        //TODO: correct localized name work
        _localizedName = nil;
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

    // Collect main regions
    const auto& itAfrica = loadedWorldRegions.find(OsmAnd::WorldRegions::AfricaRegionId);
    if(itAfrica != loadedWorldRegions.end())
    {
        OAWorldRegion* newRegion = [[OAWorldRegion alloc] initFrom:*itAfrica];
        [entireWorld addSubregion:newRegion];
        [regionsLookupTable setValue:newRegion forKey:newRegion.regionId];
        loadedWorldRegions.erase(itAfrica);
    }

    const auto& itAsia = loadedWorldRegions.find(OsmAnd::WorldRegions::AsiaRegionId);
    if(itAsia != loadedWorldRegions.cend())
    {
        OAWorldRegion* newRegion = [[OAWorldRegion alloc] initFrom:*itAsia];
        [entireWorld addSubregion:newRegion];
        [regionsLookupTable setValue:newRegion forKey:newRegion.regionId];
        loadedWorldRegions.erase(itAsia);
    }

    const auto& itAustraliaAndOceania = loadedWorldRegions.find(OsmAnd::WorldRegions::AustraliaAndOceaniaRegionId);
    if(itAustraliaAndOceania != loadedWorldRegions.cend())
    {
        OAWorldRegion* newRegion = [[OAWorldRegion alloc] initFrom:*itAustraliaAndOceania];
        [entireWorld addSubregion:newRegion];
        [regionsLookupTable setValue:newRegion forKey:newRegion.regionId];
        loadedWorldRegions.erase(itAustraliaAndOceania);
    }

    const auto& itCentralAmerica = loadedWorldRegions.find(OsmAnd::WorldRegions::CentralAmericaRegionId);
    if(itCentralAmerica != loadedWorldRegions.cend())
    {
        OAWorldRegion* newRegion = [[OAWorldRegion alloc] initFrom:*itCentralAmerica];
        [entireWorld addSubregion:newRegion];
        [regionsLookupTable setValue:newRegion forKey:newRegion.regionId];
        loadedWorldRegions.erase(itCentralAmerica);
    }

    const auto& itEurope = loadedWorldRegions.find(OsmAnd::WorldRegions::EuropeRegionId);
    if(itEurope != loadedWorldRegions.cend())
    {
        OAWorldRegion* newRegion = [[OAWorldRegion alloc] initFrom:*itEurope];
        [entireWorld addSubregion:newRegion];
        [regionsLookupTable setValue:newRegion forKey:newRegion.regionId];
        loadedWorldRegions.erase(itEurope);
    }

    const auto& itNorthAmerica = loadedWorldRegions.find(OsmAnd::WorldRegions::NorthAmericaRegionId);
    if(itNorthAmerica != loadedWorldRegions.cend())
    {
        OAWorldRegion* newRegion = [[OAWorldRegion alloc] initFrom:*itNorthAmerica];
        [entireWorld addSubregion:newRegion];
        [regionsLookupTable setValue:newRegion forKey:newRegion.regionId];
        loadedWorldRegions.erase(itNorthAmerica);
    }

    const auto& itSouthAmerica = loadedWorldRegions.find(OsmAnd::WorldRegions::SouthAmericaRegionId);
    if(itSouthAmerica != loadedWorldRegions.cend())
    {
        OAWorldRegion* newRegion = [[OAWorldRegion alloc] initFrom:*itSouthAmerica];
        [entireWorld addSubregion:newRegion];
        [regionsLookupTable setValue:newRegion forKey:newRegion.regionId];
        loadedWorldRegions.erase(itSouthAmerica);
    }

    // Process remaining regions
    for(;;)
    {
        unsigned int processedRegions = 0;

        QMutableHashIterator< QString, std::shared_ptr< const OsmAnd::WorldRegions::WorldRegion > > itRegion(loadedWorldRegions);
        while(itRegion.hasNext())
        {
            const auto& regionEntry = itRegion.next();
            NSString* regionId = regionEntry.key().toNSString();

            // Try to find parent of this region
            OAWorldRegion* parentRegion = [regionsLookupTable objectForKey:regionId];
            if(parentRegion == nil)
                continue;

            OAWorldRegion* newRegion = [[OAWorldRegion alloc] initFrom:regionEntry.value()];
            [parentRegion addSubregion:newRegion];
            
            // Remove
            processedRegions++;
            itRegion.remove();
        }

        // If all remaining are orphans, that's all
        if(processedRegions == 0)
            break;
    }

    for(const auto& orphanedRegion : loadedWorldRegions)
        OALog(@"Found orphaned region '%s'", qPrintable(orphanedRegion->id));

    return [entireWorld makeImmutable];
}

@end
