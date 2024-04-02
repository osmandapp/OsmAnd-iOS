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

- (BOOL)checkIfThereAreMissingMaps:(std::shared_ptr<RoutingContext>)ctx
                             start:(CLLocation *)start
                           targets:(NSArray<CLLocation *> *)targets
                   checkHHEditions:(BOOL)checkHHEditions
{
    NSTimeInterval tm = [NSDate timeIntervalSinceReferenceDate];
    _lastKeyNames = [NSMutableArray new];
    NSMutableArray<MissingMapsCalculatorPoint *> *pointsToCheck = [NSMutableArray new];
    string profile = profileToString(ctx->config->router->getProfile());
    NSMutableDictionary<NSString *, RegisteredMap *> *knownMaps = [NSMutableDictionary new];
    
    [OARoutingHelper.sharedInstance.getRouteProvider checkInitializedForZoomLevel14];
    
    for (auto* file : getOpenMapFiles())
    {
        RegisteredMap *rmap = [RegisteredMap new];
        NSString *regionName = [NSString stringWithCString:file->inputName.c_str()
                                                  encoding:[NSString defaultCStringEncoding]];
        rmap.downloadName = regionName.lastPathComponent;
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
        CLLocation *s = (i == 0) ? start : targets[i - 1];
        end = targets[i];
        [self split:ctx knownMaps:knownMaps pointsToCheck:pointsToCheck start:s end:end];
    }
    
    if (end != nil)
    {
        [self addPoint:ctx knownMaps:knownMaps pointsToCheck:pointsToCheck point:end];
    }
    
    NSMutableSet<NSString *> *mapsToDownload = [NSMutableSet set];
    NSMutableSet<NSString *> *mapsToUpdate = [NSMutableSet set];
    NSMutableSet<NSNumber *> *presentTimestamps = nil;
    
    for (MissingMapsCalculatorPoint *p in pointsToCheck)
    {
        if (p.hhEditions == NULL)
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
        }
    }
    
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
            for (int i = 0; p.hhEditions != NULL && i < p.hhEditions.count; i++)
            {
                if (p.hhEditions[i].intValue > 0)
                {
                    if (p.hhEditions[i].intValue != max)
                    {
                        region = [p.regions objectAtIndex:i];
                    }
                    else
                    {
                        region = nil;
                        break;
                    }
                }
            }
            
            if (region != nil)
            {
                [mapsToUpdate addObject:region];
            }
        }
    }
    
    if ([mapsToDownload count] == 0 && [mapsToUpdate count] == 0)
    {
        return NO;
    }
    self.missingMaps = [self convert:[mapsToDownload copy]];
    self.mapsToUpdate = [self convert:[mapsToUpdate copy]];
    
    NSLog(@"Check missing maps %lu points %.2f sec", [pointsToCheck count], ([NSDate timeIntervalSinceReferenceDate] - tm));
    
    return YES;
}

- (void)split:(std::shared_ptr<RoutingContext>)ctx
    knownMaps:(NSDictionary<NSString *, RegisteredMap *> *)knownMaps
pointsToCheck:(NSMutableArray<MissingMapsCalculatorPoint *> *)pointsToCheck
        start:(CLLocation *)s
          end:(CLLocation *)e
{
    double distance = [OAMapUtils getDistance:s.coordinate second:e.coordinate];
    
    if (distance < kDISTANCE_SPLIT)
    {
        [self addPoint:ctx knownMaps:knownMaps pointsToCheck:pointsToCheck point:s];
    }
    else
    {
        CLLocation *mid = [OAMapUtils calculateMidPoint:s s2:e];
        [self split:ctx knownMaps:knownMaps pointsToCheck:pointsToCheck start:s end:mid];
        [self split:ctx knownMaps:knownMaps pointsToCheck:pointsToCheck start:mid end:e];
    }
}

- (void)addPoint:(std::shared_ptr<RoutingContext>)ctx
       knownMaps:(NSDictionary<NSString *, RegisteredMap *> *)knownMaps
   pointsToCheck:(NSMutableArray<MissingMapsCalculatorPoint *> *)pointsToCheck
           point:(CLLocation *)s
{
    NSMutableArray<NSString *> *regions = [NSMutableArray array];
    
    NSArray<OAWorldRegion *> *regionsArray = [_or getWorldRegionsAt:s.coordinate.latitude longitude:s.coordinate.longitude];
    
    for (OAWorldRegion *region in regionsArray)
    {
        NSString *regionDownloadId = region.downloadsIdPrefix;
        if ([regionDownloadId hasSuffix:@"."])
        {
            regionDownloadId = [regionDownloadId substringToIndex:[regionDownloadId length] - 1];
        }
        [regions addObject:regionDownloadId];
    }
    
    NSArray *sortedRegionsNameArray = [regions sortedArrayUsingComparator:^NSComparisonResult(NSString *str1, NSString *str2) {
        if (str1.length < str2.length)
        {
            return NSOrderedAscending;
        }
        else if (str1.length > str2.length)
        {
            return NSOrderedDescending;
        }
        else
        {
            return NSOrderedSame;
        }
    }];
    
    regions = [sortedRegionsNameArray copy];
    
    if (pointsToCheck.count == 0 || ![regions isEqualToArray:_lastKeyNames])
    {
        MissingMapsCalculatorPoint *pnt = [MissingMapsCalculatorPoint new];
        _lastKeyNames = regions;
        pnt.regions = [[NSMutableArray alloc] initWithArray:regions];
        
        BOOL hasHHEdition = [self addMapEditions:knownMaps point:pnt];
        if (!hasHHEdition)
        {
            pnt.hhEditions = nil; // recreate
            
            // check non-standard maps
            int x31 = OsmAnd::Utilities::get31TileNumberX(s.coordinate.longitude);
            int y31 = OsmAnd::Utilities::get31TileNumberY(s.coordinate.latitude);
            
            int zoomToLoad = 14;
            
            for (RegisteredMap *r in knownMaps.allValues)
            {
                if (!r.standard)
                {
                    SearchQuery q((uint32_t)(x31 << zoomToLoad), (uint32_t)((x31 + 1) << zoomToLoad), (uint32_t)(y31 << zoomToLoad),
                                  (uint32_t)((y31 + 1) << zoomToLoad));
                    std::vector<RouteSubregion> tempResult;
                    if (r.reader->routingIndexes.size() > 0 && searchRouteSubregionsForBinaryMapFile(r.reader, &q, tempResult, false, false, false))
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
    return [[worldRegions sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]] copy];
}

- (BOOL)addMapEditions:(NSDictionary<NSString *, RegisteredMap *> *)knownMaps
                 point:(MissingMapsCalculatorPoint *)pnt
{
    BOOL hhEditionPresent = NO;
    
    for (int i = 0; i < pnt.regions.count; i++)
    {
        NSString *regionName = pnt.regions[i];
        
        if (knownMaps[regionName] != nil)
        {
            if (pnt.hhEditions == nil)
            {
                pnt.hhEditions = [[NSMutableArray alloc] initWithCapacity:pnt.regions.count];
                pnt.editionsUnique = [NSMutableSet set];
            }
            
            pnt.hhEditions[i] = @([knownMaps[regionName] edition]);
            hhEditionPresent |= pnt.hhEditions[i].intValue > 0;
            [pnt.editionsUnique addObject:@(pnt.hhEditions[i].intValue)];
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
