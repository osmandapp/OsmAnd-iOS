//
//  MissingMapsCalculator.m
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 27.03.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import "MissingMapsCalculator.h"
#import "OAMapUtils.h"
#import "OsmAnd_Maps-Swift.h"
#import "OsmAndSharedWrapper.h"
#import "OAMissingMapsResult.h"
#import "OARoutingHelper.h"
#import "OARouteProvider.h"
#import "OARouteCalculationResult.h"
#import "OAWorldRegion.h"

#include <OsmAndCore/Utilities.h>
#include <binaryRead.h>

static const double kDISTANCE_SPLIT = 15000;
static const double DISTANCE_SKIP = 10000;

@interface MissingMapsCalculatorPoint : NSObject
@property (nonatomic, assign) BOOL isStartEnd;
@property (nonatomic, strong) NSMutableArray<NSString *> *regions;
// 0 means routing data present but no HH data, nil means no data at all
@property (nonatomic, strong) NSMutableArray<NSNumber *> *hhEditions;
@property (nonatomic, strong) NSMutableSet<NSNumber *> *editionsUnique;

@end

@implementation MissingMapsCalculatorPoint

@end

/** One installed map, read by whichever planner is in use. */
@interface RegisteredMap : NSObject

@property (nonatomic, assign) BinaryMapFile *reader;
@property (nonatomic, strong) OASBinaryMapIndexReader *sharedReader;
@property (nonatomic, assign) BOOL standard;
@property (nonatomic, assign) long edition;
@property (nonatomic, copy) NSString *downloadName;

- (BOOL)hasRouteDataAtX31:(int)x31 y31:(int)y31;

@end

@implementation RegisteredMap

- (BOOL)hasRouteDataAtX31:(int)x31 y31:(int)y31
{
    if (_sharedReader)
        return [_sharedReader containsRouteData] && [_sharedReader containsActualRouteDataX31:x31 y31:y31 checkedRegions:nil];

    int zoomToLoad = 14;
    int x = x31 >> zoomToLoad;
    int y = y31 >> zoomToLoad;
    SearchQuery q((uint32_t) (x << zoomToLoad), (uint32_t) ((x + 1) << zoomToLoad), (uint32_t) (y << zoomToLoad),
                  (uint32_t) ((y + 1) << zoomToLoad));
    return _reader->routingIndexes.size() > 0 && searchRouteSubregionsForBinaryMapFile(_reader, &q);
}

@end

// The two fast routing statuses the check can raise, in the words of each planner.
static FastRoutingState::Status OACppRoutingStatus(EOAMissingMapsState state)
{
    switch (state)
    {
        case EOAMissingMapsStateMissingAtStartOrEnd:
            return FastRoutingState::MISSING_MAPS_AT_START_OR_END;
        case EOAMissingMapsStateMissingIntermediates:
            return FastRoutingState::MISSING_MAPS_INTERMEDIATES;
        case EOAMissingMapsStateMixedAtStartOrEnd:
            return FastRoutingState::MIXED_MAPS_AT_START_OR_END;
        case EOAMissingMapsStateMixedIntermediates:
            return FastRoutingState::MIXED_MAPS_INTERMEDIATES;
        case EOAMissingMapsStateNone:
            return FastRoutingState::READY;
    }
}

static OASFastRoutingStateStatus *OASharedRoutingStatus(EOAMissingMapsState state)
{
    switch (state)
    {
        case EOAMissingMapsStateMissingAtStartOrEnd:
            return OASFastRoutingStateStatus.missingMapsAtStartOrEnd;
        case EOAMissingMapsStateMissingIntermediates:
            return OASFastRoutingStateStatus.missingMapsIntermediates;
        case EOAMissingMapsStateMixedAtStartOrEnd:
            return OASFastRoutingStateStatus.mixedMapsAtStartOrEnd;
        case EOAMissingMapsStateMixedIntermediates:
            return OASFastRoutingStateStatus.mixedMapsIntermediates;
        case EOAMissingMapsStateNone:
            return OASFastRoutingStateStatus.ready;
    }
}

@implementation MissingMapsCalculator
{
    OAWorldRegion *_or;
    NSMutableArray<NSString *> *_lastKeyNames;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _or = OsmAndApp.instance.worldRegion;
    }
    return self;
}

- (OAMissingMapsResult *)checkIfThereAreMissingMaps:(std::shared_ptr<RoutingContext>)ctx
                                              start:(CLLocation *)start
                                            targets:(NSArray<CLLocation *> *)targets
                                    checkHHEditions:(BOOL)checkHHEditions
{
    NSString *profile = [NSString stringWithUTF8String:profileToString(ctx->config->router->getProfile()).c_str()];
    OAMissingMapsResult *result = [self checkMapsForProfile:profile
                                                  knownMaps:[self registeredMapsForProfile:profile]
                                                      start:start
                                                    targets:targets
                                            checkHHEditions:checkHHEditions];
    if (ctx->progress != nullptr)
    {
        if (result)
            ctx->progress->raiseFastRoutingStatus(OACppRoutingStatus(result.state));
        else
            ctx->progress->resetFastRoutingStatus();
    }
    return result;
}

- (OAMissingMapsResult *)checkIfThereAreMissingSharedMaps:(OASRoutingContext *)ctx
                                                    start:(CLLocation *)start
                                                  targets:(NSArray<CLLocation *> *)targets
                                          checkHHEditions:(BOOL)checkHHEditions
{
    NSString *profile = [[ctx.config.router getProfile] getBaseProfile];
    OAMissingMapsResult *result = [self checkMapsForProfile:profile
                                                  knownMaps:[self registeredSharedMaps:[ctx getMaps] profile:profile]
                                                      start:start
                                                    targets:targets
                                            checkHHEditions:checkHHEditions];
    OASRouteCalculationProgress *progress = ctx.calculationProgress;
    if (progress)
    {
        if (result)
            [progress raiseFastRoutingStatusStatus:OASharedRoutingStatus(result.state)];
        else
            [progress resetFastRoutingStatus];
    }
    return result;
}

- (OAMissingMapsResult *)checkIfThereAreMissingMapsForProfile:(NSString *)profile
                                                        start:(CLLocation *)start
                                                      targets:(NSArray<CLLocation *> *)targets
                                              checkHHEditions:(BOOL)checkHHEditions
{
    return [self checkMapsForProfile:profile
                           knownMaps:[self registeredMapsForProfile:profile]
                               start:start
                             targets:targets
                     checkHHEditions:checkHHEditions];
}

// The maps the C++ planner reads: every obf file the app has open. Both planners are handed the
// same files, so this answers for a check that has no routing context of its own either.
- (NSDictionary<NSString *, RegisteredMap *> *)registeredMapsForProfile:(NSString *)profile
{
    NSMutableDictionary<NSString *, RegisteredMap *> *knownMaps = [NSMutableDictionary new];
    const auto openFilesSnapshot = getOpenFilesSnapshot();
    for (const auto& fileRef : openFilesSnapshot)
    {
        auto* file = fileRef.get();
        NSString *regionName = [NSString stringWithCString:file->inputName.c_str()
                                                  encoding:[NSString defaultCStringEncoding]];
        RegisteredMap *rmap = [self registerMapNamed:regionName into:knownMaps];
        if (!rmap)
            continue;

        rmap.reader = file;
        for (const auto& rt : file->hhIndexes)
        {
            if (rt->profile == profile.UTF8String)
                rmap.edition = rt->edition;
        }
    }
    return knownMaps;
}

// The same maps as OsmAndShared readers, the ones its routing context searches.
- (NSDictionary<NSString *, RegisteredMap *> *)registeredSharedMaps:(NSArray<OASBinaryMapIndexReader *> *)readers
                                                            profile:(NSString *)profile
{
    NSMutableDictionary<NSString *, RegisteredMap *> *knownMaps = [NSMutableDictionary new];
    for (OASBinaryMapIndexReader *reader in readers)
    {
        RegisteredMap *rmap = [self registerMapNamed:[[reader getFile] name] into:knownMaps];
        if (!rmap)
            continue;

        rmap.sharedReader = reader;
        for (OASHHRouteRegion *rt in [reader getHHRoutingIndexes])
        {
            if ([rt.profile isEqualToString:profile])
                rmap.edition = rt.edition;
        }
    }
    return knownMaps;
}

// The map under a file name, added to the known ones; nil for the maps the check ignores.
- (RegisteredMap *)registerMapNamed:(NSString *)regionName into:(NSMutableDictionary<NSString *, RegisteredMap *> *)knownMaps
{
    NSString *downloadName = regionName.lastPathComponent;
    if ([downloadName isEqualToString:kWorldMiniBasemapKey])
        return nil;

    RegisteredMap *rmap = [RegisteredMap new];
    rmap.downloadName = [[downloadName stringByDeletingPathExtension] lowerCase];
    rmap.standard = [_or getRegionDataByDownloadName:[rmap downloadName]] != nil;

    if ([[rmap.downloadName lowercaseString] hasPrefix:@"world_"])
        return nil; // avoid including World_seamarks

    [knownMaps setObject:rmap forKey:[rmap downloadName]];
    return rmap;
}

- (OAMissingMapsResult *)checkMapsForProfile:(NSString *)profile
                                   knownMaps:(NSDictionary<NSString *, RegisteredMap *> *)knownMaps
                                       start:(CLLocation *)start
                                     targets:(NSArray<CLLocation *> *)targets
                             checkHHEditions:(BOOL)checkHHEditions
{
    NSTimeInterval tm = [NSDate timeIntervalSinceReferenceDate];
    NSMutableArray<CLLocation *> *missingMapsPoints = [NSMutableArray arrayWithObject:start];
    [missingMapsPoints addObjectsFromArray:targets];
    OAMissingMapsResult *calculationResult = [[OAMissingMapsResult alloc] initWithPoints:missingMapsPoints profile:profile];

    _lastKeyNames = [NSMutableArray new];
    NSMutableArray<MissingMapsCalculatorPoint *> *pointsToCheck = [NSMutableArray new];

    CLLocation *end = nil;
    CLLocation *prev = start;
    for (int i = 0; i < [targets count]; i++)
    {
        end = targets[i];
        if (i > 0 && [OAMapUtils getDistance:prev.coordinate second:end.coordinate] < DISTANCE_SKIP) {
            // skip intermediate points that are too close together
            continue;
        }
        
        [self split:knownMaps pointsToCheck:pointsToCheck pnt:prev isStartEnd:i == 0 next:end];
        prev = end;
    }
    
    if (end != nil)
    {
        [self addPoint:knownMaps pointsToCheck:pointsToCheck point:end isStartEnd:YES];
    }
    
    NSMutableSet<NSNumber *> *presentTimestamps = nil;
    BOOL mixedMapsAtStartOrEnd = NO;
    BOOL missingMapsAtStartOrEnd = NO;
    BOOL mixedMapsIntermediates = NO;
    BOOL missingMapsIntermediates = NO;
    
    for (MissingMapsCalculatorPoint *p in pointsToCheck)
    {
        if (p.hhEditions == nil)
        {
            for (NSString * r in p.regions)
            {
                if (![self isRoadOnlyMap:r])
                {
                    if (p.isStartEnd)
                    {
                        missingMapsAtStartOrEnd = YES;
                    }
                    else
                    {
                        missingMapsIntermediates = YES;
                    }
                    [calculationResult addMissingMap:r];
                    break;
                }
            }
        }
        else if (checkHHEditions)
        {
            if (presentTimestamps == nil)
            {
                presentTimestamps = [p.editionsUnique mutableCopy];
            }
            else if ([presentTimestamps count] > 0)
            {
                [presentTimestamps intersectSet:p.editionsUnique];
            }
        } else {
            if (p.regions.count > 0) {
                [calculationResult addUsedMap:p.regions.firstObject];
            }
        }
    }
    // maps to update
    if (presentTimestamps != nil && [presentTimestamps count] == 0)
    {
        long max = 0;
        for (MissingMapsCalculatorPoint *p in pointsToCheck)
        {
            if (p.editionsUnique != nil && p.editionsUnique.count > 0)
            {
                NSNumber *maxNumber = [[p.editionsUnique allObjects] valueForKeyPath:@"@max.self"];
                max = MAX([maxNumber longValue], max);
            }
        }
        
        for (MissingMapsCalculatorPoint *p in pointsToCheck)
        {
            NSString *region = nil;
            BOOL fresh = false;
            for (int i = 0; p.hhEditions != nil && i < p.hhEditions.count; i++)
            {
                if (p.hhEditions[i].longValue > 0)
                {
                    region = p.regions[i];
                    fresh = p.hhEditions[i].longValue == max;
                    if (fresh)
                    {
                        break;
                    }
                }
            }
            
            if (region != nil)
            {
                if (!fresh)
                {
                    if (p.isStartEnd)
                    {
                        mixedMapsAtStartOrEnd = YES;
                    }
                    else
                    {
                        mixedMapsIntermediates = YES;
                    }
                    [calculationResult addMapToUpdate:region];
                }
                else
                {
                    [calculationResult addUsedMap:region];
                }
            }
        }
    }
    else
    {
        long selectedEdition = [[presentTimestamps objectEnumerator].nextObject longValue];
        
        for (MissingMapsCalculatorPoint *p in pointsToCheck)
        {
            if (p.hhEditions != nil)
            {
                for (int i = 0; i < p.hhEditions.count; i++)
                {
                    if ([p.hhEditions[i] longValue] == selectedEdition)
                    {
                        [calculationResult addUsedMap:p.regions[i]];
                        break;
                    }
                }
            }
        }
    }
    
    if (![calculationResult hasMissingMaps])
    {
        return nil;
    }
    if (missingMapsAtStartOrEnd)
    {
        [calculationResult setState:EOAMissingMapsStateMissingAtStartOrEnd];
    }
    else if (missingMapsIntermediates)
    {
        [calculationResult setState:EOAMissingMapsStateMissingIntermediates];
    }
    else if (mixedMapsAtStartOrEnd)
    {
        [calculationResult setState:EOAMissingMapsStateMixedAtStartOrEnd];
    }
    else if (mixedMapsIntermediates)
    {
        [calculationResult setState:EOAMissingMapsStateMixedIntermediates];
    }
    NSLog(@"Check missing maps %lu points %.2f sec", [pointsToCheck count], ([NSDate timeIntervalSinceReferenceDate] - tm));
    
    return calculationResult;
}

- (void)split:(NSDictionary<NSString *, RegisteredMap *> *)knownMaps
pointsToCheck:(NSMutableArray<MissingMapsCalculatorPoint *> *)pointsToCheck
          pnt:(CLLocation *)pnt
   isStartEnd:(BOOL)isStartEnd
         next:(CLLocation *)next
{
    double distance = [OAMapUtils getDistance:pnt.coordinate second:next.coordinate];
    if (distance < kDISTANCE_SPLIT)
    {
        [self addPoint:knownMaps pointsToCheck:pointsToCheck point:pnt isStartEnd:isStartEnd];
    }
    else
    {
        CLLocation *mid = [OAMapUtils calculateMidPoint:pnt s2:next];
        [self split:knownMaps pointsToCheck:pointsToCheck pnt:pnt isStartEnd:isStartEnd next:mid];
        [self split:knownMaps pointsToCheck:pointsToCheck pnt:mid isStartEnd:NO next:next];
    }
}

- (void)addPoint:(NSDictionary<NSString *, RegisteredMap *> *)knownMaps
   pointsToCheck:(NSMutableArray<MissingMapsCalculatorPoint *> *)pointsToCheck
           point:(CLLocation *)loc
      isStartEnd:(BOOL)isStartEnd
{
    NSMutableArray<NSString *> *regions = [NSMutableArray array];
    
    NSArray<OAWorldRegion *> *regionsArray = [_or getWorldRegionsAtWithoutSort:loc.coordinate.latitude longitude:loc.coordinate.longitude];
    BOOL onlyJointMap = YES;
    
    for (OAWorldRegion *region in regionsArray)
    {
        NSString *regionDownloadId = region.downloadsIdPrefix;
        if ([regionDownloadId hasSuffix:@"."])
        {
            regionDownloadId = [regionDownloadId substringToIndex:[regionDownloadId length] - 1];
        }
        BOOL hasMapType = region.regionMap;
        BOOL hasRoadsType = region.regionRoads;
        BOOL hasMapJoinType = region.regionJoinMap;
        BOOL hasRoadsJoinType = region.regionJoinRoads;
        if (hasMapType || hasRoadsType || hasMapJoinType || hasRoadsJoinType)
        {
            [regions addObject:regionDownloadId];
            if (!hasMapJoinType && !hasRoadsJoinType)
            {
                onlyJointMap = NO;
            }
        }
    }
    [regions sortUsingComparator:^NSComparisonResult(NSString * _Nonnull o1, NSString * _Nonnull o2) {
        NSInteger lengthComparisonResult = [@(o1.length) compare:@(o2.length)];
        return (NSComparisonResult)(-lengthComparisonResult);
    }];
    if ((pointsToCheck.count == 0 || isStartEnd || ![regions isEqualToArray:_lastKeyNames]) && !onlyJointMap)
    {
        MissingMapsCalculatorPoint *pnt = [MissingMapsCalculatorPoint new];
        _lastKeyNames = regions;
        pnt.isStartEnd = isStartEnd;
        pnt.regions = [[NSMutableArray alloc] initWithArray:regions];
        
        BOOL hasHHEdition = [self addMapEditions:knownMaps point:pnt];
        if (!hasHHEdition)
        {
            pnt.hhEditions = nil; // recreate
            
            // check non-standard maps
            int x31 = OsmAnd::Utilities::get31TileNumberX(loc.coordinate.longitude);
            int y31 = OsmAnd::Utilities::get31TileNumberY(loc.coordinate.latitude);
            
            for (RegisteredMap *r in knownMaps.allValues)
            {
                if (!r.standard && [r hasRouteDataAtX31:x31 y31:y31])
                {
                    [pnt.regions insertObject:r.downloadName atIndex:0];
                }
            }
            
            [self addMapEditions:knownMaps point:pnt];
        }
        
        [pointsToCheck addObject:pnt];
    }
}

- (NSArray<OAWorldRegion *> *)convert:(NSArray<NSString *> *)maps
{
    if (maps.count == 0)
    {
        return nil;
    }
    
    NSMutableArray<OAWorldRegion *> *worldRegions = [NSMutableArray array];
    
    for (NSString *map in maps)
    {
        OAWorldRegion *worldRegion = [_or getRegionDataByDownloadName:map];
        if (worldRegion != nil)
        {
            [worldRegions addObject:worldRegion];
        }
    }
    return [worldRegions copy];
}

- (void)attachResult:(OAMissingMapsResult *)result
toRouteCalculationResult:(OARouteCalculationResult *)routeResult
{
    if (result == nil || routeResult == nil)
    {
        return;
    }
    [routeResult setMissingMaps:[self convert:result.missingMaps]
                   mapsToUpdate:[self convert:result.mapsToUpdate]
                       usedMaps:[self convert:result.usedMaps]
                         result:result];
}

- (BOOL)addMapEditions:(NSDictionary<NSString *, RegisteredMap *> *)knownMaps
                 point:(MissingMapsCalculatorPoint *)pnt
{
    BOOL hhEditionPresent = NO;
    
    for (int i = 0; i < pnt.regions.count; i++)
    {
        NSString *regionName = pnt.regions[i];
        
        RegisteredMap *map = knownMaps[regionName];
        
        if (map != nil)
        {
            if (pnt.hhEditions == nil)
            {
                pnt.hhEditions = [NSMutableArray array];
                for (int i = 0; i < pnt.regions.count; i++)
                {
                    [pnt.hhEditions addObject:@(0)];
                }
                pnt.editionsUnique = [NSMutableSet set];
            }
            
            NSNumber *editionNumber = @(map.edition);
            [pnt.hhEditions replaceObjectAtIndex:i withObject:editionNumber];
            hhEditionPresent |= editionNumber.longValue != 0;
            [pnt.editionsUnique addObject:editionNumber];
        }
    }
    
    return hhEditionPresent;
}

- (BOOL) isRoadOnlyMap:(NSString *)regionName
{
    if (_or != nil)
    {
        OAWorldRegion * wr = [_or getRegionDataByDownloadName:regionName];
        if (wr != nil)
        {
            return ![wr regionMap] && [wr regionRoads];
        }
    }
    return NO;
}

@end
