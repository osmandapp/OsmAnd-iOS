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
#import "OARoutingHelper.h"
#import "OARouteProvider.h"

#include <OsmAndCore/Utilities.h>
#include <binaryRead.h>

static const double kDISTANCE_SPLIT = 50000;
static const double DISTANCE_SKIP = 10000;

@interface MissingMapsCalculatorPoint : NSObject
@property (nonatomic, strong) NSMutableArray<NSString *> *regions;
// 0 means routing data present but no HH data, nil means no data at all
@property (nonatomic, strong) NSMutableArray<NSNumber *> *hhEditions;
@property (nonatomic, strong) NSMutableSet<NSNumber *> *editionsUnique;

@end

@implementation MissingMapsCalculatorPoint

@end

@interface RegisteredMap : NSObject

@property (nonatomic, assign) BinaryMapFile *reader;
@property (nonatomic, assign) BOOL standard;
@property (nonatomic, assign) long edition;
@property (nonatomic, copy) NSString *downloadName;

@end

@implementation RegisteredMap

@end

@implementation MissingMapsCalculator
{
    OAWorldRegion *_or;
    NSMutableArray<NSString *> *_lastKeyNames;
    std::shared_ptr<RoutingContext> _ctx;
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

- (BOOL)checkIfThereAreMissingMapsWithStart:(CLLocation *)start
                                    targets:(NSArray<CLLocation *> *)targets
{
    bool oldRouting = [[OAAppSettings sharedManager].useOldRouting get];
    return [self checkIfThereAreMissingMaps:_ctx start:start targets:targets checkHHEditions:!oldRouting];
}

- (BOOL)checkIfThereAreMissingMaps:(std::shared_ptr<RoutingContext>)ctx
                             start:(CLLocation *)start
                           targets:(NSArray<CLLocation *> *)targets
                   checkHHEditions:(BOOL)checkHHEditions
{
    _ctx = ctx;
    self.startPoint = start;
    if (targets.count > 0)
    {
        self.endPoint = targets.lastObject;
    }
    
    NSTimeInterval tm = [NSDate timeIntervalSinceReferenceDate];
    _lastKeyNames = [NSMutableArray new];
    NSMutableArray<MissingMapsCalculatorPoint *> *pointsToCheck = [NSMutableArray new];
    string profile = profileToString(ctx->config->router->getProfile());
    NSMutableDictionary<NSString *, RegisteredMap *> *knownMaps = [NSMutableDictionary new];
    
    [OARoutingHelper.sharedInstance.getRouteProvider checkInitializedForZoomLevelWithEmptyRect:OsmAnd::ZoomLevel14];
    
    for (auto* file : getOpenMapFiles())
    {
        NSString *regionName = [NSString stringWithCString:file->inputName.c_str()
                                                  encoding:[NSString defaultCStringEncoding]];
        NSString *downloadName = regionName.lastPathComponent;
        if ([downloadName isEqualToString:kWorldMiniBasemapKey])
        {
            continue;
        }
        RegisteredMap *rmap = [RegisteredMap new];
        NSString *rmapDownloadName = [[downloadName stringByDeletingPathExtension] lowerCase];
    
        rmap.downloadName = rmapDownloadName;
        rmap.reader = file;
        rmap.standard = [_or getRegionDataByDownloadName:[rmap downloadName]] != nil;
        [knownMaps setObject:rmap forKey:[rmap downloadName]];
        
        for (const auto& rt : file->hhIndexes)
        {
            if (rt->profile == profile)
            {
                rmap.edition = rt->edition;
            }
        }
    }
    
    CLLocation *end = nil;
    for (int i = 0; i < [targets count]; i++)
    {
        CLLocation *prev = (i == 0) ? start : targets[i - 1];
        end = targets[i];
        [self split:ctx knownMaps:knownMaps pointsToCheck:pointsToCheck pnt:prev next:end];
    }
    
    if (end != nil)
    {
        [self addPoint:ctx knownMaps:knownMaps pointsToCheck:pointsToCheck point:end];
    }
    
    NSMutableSet<NSString *> *usedMaps = [NSMutableSet set];
    NSMutableSet<NSString *> *mapsToDownload = [NSMutableSet set];
    NSMutableSet<NSString *> *mapsToUpdate = [NSMutableSet set];
    NSMutableSet<NSNumber *> *presentTimestamps = nil;
    
    for (MissingMapsCalculatorPoint *p in pointsToCheck)
    {
        if (p.hhEditions == nil)
        {
            if ([p.regions count] > 0)
            {
                [mapsToDownload addObject:[p.regions objectAtIndex:0]];
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
                [usedMaps addObject:p.regions.firstObject];
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
                if (p.hhEditions[i].intValue > 0)
                {
                    region = p.regions[i];
                    fresh = p.hhEditions[i].intValue == max;
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
                    [mapsToUpdate addObject:region];
                }
                else
                {
                    [usedMaps addObject:region];
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
                        [usedMaps addObject:p.regions[i]];
                        break;
                    }
                }
            }
        }
    }
    
    if ([mapsToDownload count] == 0 && [mapsToUpdate count] == 0)
    {
        return NO;
    }
    self.missingMaps = [self convert:[mapsToDownload copy]];
    self.mapsToUpdate = [self convert:[mapsToUpdate copy]];
    self.potentiallyUsedMaps = [self convert:[usedMaps copy]];
    
    NSLog(@"Check missing maps %lu points %.2f sec", [pointsToCheck count], ([NSDate timeIntervalSinceReferenceDate] - tm));
    
    return YES;
}

- (void)clearResult
{
    self.missingMaps = @[];
    self.mapsToUpdate = @[];
    self.potentiallyUsedMaps = @[];
}

- (void)split:(std::shared_ptr<RoutingContext>)ctx
    knownMaps:(NSDictionary<NSString *, RegisteredMap *> *)knownMaps
pointsToCheck:(NSMutableArray<MissingMapsCalculatorPoint *> *)pointsToCheck
          pnt:(CLLocation *)pnt
         next:(CLLocation *)next
{
    double distance = [OAMapUtils getDistance:pnt.coordinate second:next.coordinate];
    if (distance < DISTANCE_SKIP) {
        // skip point they too close
    }
    else if (distance < kDISTANCE_SPLIT)
    {
        [self addPoint:ctx knownMaps:knownMaps pointsToCheck:pointsToCheck point:pnt];
    }
    else
    {
        CLLocation *mid = [OAMapUtils calculateMidPoint:pnt s2:next];
        [self split:ctx knownMaps:knownMaps pointsToCheck:pointsToCheck pnt:pnt next:mid];
        [self split:ctx knownMaps:knownMaps pointsToCheck:pointsToCheck pnt:mid next:next];
    }
}

- (void)addPoint:(std::shared_ptr<RoutingContext>)ctx
       knownMaps:(NSDictionary<NSString *, RegisteredMap *> *)knownMaps
   pointsToCheck:(NSMutableArray<MissingMapsCalculatorPoint *> *)pointsToCheck
           point:(CLLocation *)loc
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
        [regions addObject:regionDownloadId];
        if (!region.regionJoinMap && !region.regionJoinRoads) {
            onlyJointMap = NO;
        }
    }
    [regions sortUsingComparator:^NSComparisonResult(NSString * _Nonnull o1, NSString * _Nonnull o2) {
        NSInteger lengthComparisonResult = [@(o1.length) compare:@(o2.length)];
        return (NSComparisonResult)(-lengthComparisonResult);
    }];
    if ((pointsToCheck.count == 0 || ![regions isEqualToArray:_lastKeyNames]) && !onlyJointMap)
    {
        MissingMapsCalculatorPoint *pnt = [MissingMapsCalculatorPoint new];
        _lastKeyNames = regions;
        pnt.regions = [[NSMutableArray alloc] initWithArray:regions];
        
        BOOL hasHHEdition = [self addMapEditions:knownMaps point:pnt];
        if (!hasHHEdition)
        {
            pnt.hhEditions = nil; // recreate
            
            // check non-standard maps
            int x31 = OsmAnd::Utilities::get31TileNumberX(loc.coordinate.longitude);
            int y31 = OsmAnd::Utilities::get31TileNumberY(loc.coordinate.latitude);
            
            int zoomToLoad = 14;
            int x = x31 >> zoomToLoad;
            int y = y31 >> zoomToLoad;
            
            for (RegisteredMap *r in knownMaps.allValues)
            {
                if (!r.standard)
                {
                    SearchQuery q((uint32_t)(x << zoomToLoad), (uint32_t)((x + 1) << zoomToLoad), (uint32_t)(y << zoomToLoad),
                                  (uint32_t)((y + 1) << zoomToLoad));
                    if (r.reader->routingIndexes.size() > 0 && searchRouteSubregionsForBinaryMapFile(r.reader, &q))
                    {
                        [pnt.regions insertObject:r.downloadName atIndex:0];
                    }
                }
            }
            
            [self addMapEditions:knownMaps point:pnt];
        }
        
        [pointsToCheck addObject:pnt];
    }
}

- (NSArray<OAWorldRegion *> *)convert:(NSOrderedSet<NSString *> *)mapsToDownload
{
    if (mapsToDownload.count == 0)
    {
        return nil;
    }
    
    NSMutableArray<OAWorldRegion *> *worldRegions = [NSMutableArray array];
    
    for (NSString *mapName in mapsToDownload)
    {
        OAWorldRegion *worldRegion = [_or getRegionDataByDownloadName:mapName];
        if (worldRegion != nil)
        {
            [worldRegions addObject:worldRegion];
        }
    }
    return [[self getSortedByDistanceRegions:worldRegions lat:self.startPoint.coordinate.latitude lon:self.startPoint.coordinate.longitude] copy];
}

- (NSArray<OAWorldRegion *> *) getSortedByDistanceRegions:(NSArray<OAWorldRegion *> *)array lat:(double)lat lon:(double)lon
{
    return [array sortedArrayUsingComparator:^NSComparisonResult(OAWorldRegion *obj1, OAWorldRegion *obj2)
            {
        const auto distance1 = OsmAnd::Utilities::distance(lon, lat, obj1.regionCenter.longitude, obj1.regionCenter.latitude);
        const auto distance2 = OsmAnd::Utilities::distance(lon, lat, obj2.regionCenter.longitude, obj2.regionCenter.latitude);
        return distance1 > distance2 ? NSOrderedDescending : distance1 < distance2 ? NSOrderedAscending : NSOrderedSame;
    }];
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
            hhEditionPresent |= editionNumber.intValue != 0;
            [pnt.editionsUnique addObject:editionNumber];
        }
    }
    
    return hhEditionPresent;
}

- (NSString *)getErrorMessage
{
    NSString *msg = @"";
    
    if (self.mapsToUpdate != nil)
    {
        msg = [NSString stringWithFormat:@"%@ need to be updated", self.mapsToUpdate];
    }
    
    if (self.missingMaps != nil)
    {
        if ([msg length] > 0)
        {
            msg = [msg stringByAppendingString:@" and "];
        }
        msg = [NSString stringWithFormat:@"%@ need to be downloaded", self.missingMaps];
    }
    
    msg = [NSString stringWithFormat:@"To calculate the route maps %@", msg];
    
    return msg;
}

@end
