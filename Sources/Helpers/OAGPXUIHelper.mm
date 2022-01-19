//
//  OAGPXUIHelper.m
//  OsmAnd Maps
//
//  Created by Paul on 9/12/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAGPXUIHelper.h"
#import "OAGPXDocument.h"
#import "OARouteCalculationResult.h"
#import "OARoutingHelper.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAGPXDatabase.h"
#import "OsmAndApp.h"
#import "Localization.h"
#import "OAOsmAndFormatter.h"

@implementation OAGpxFileInfo

- (instancetype) initWithFileName:(NSString *)fileName lastModified:(long)lastModified fileSize:(long)fileSize
{
    self = [super init];
    if (self) {
        _fileName = fileName;
        _lastModified = lastModified;
        _fileSize = fileSize;
    }
    return self;
}

@end

@implementation OAGPXUIHelper

+ (OAGPXDocument *) makeGpxFromRoute:(OARouteCalculationResult *)route
{
    double lastHeight = RouteDataObject::HEIGHT_UNDEFINED;
    OAGPXDocument *gpx = [[OAGPXDocument alloc] init];
    NSArray<CLLocation *> *locations = route.getRouteLocations;
    if (locations)
    {
        OAGpxTrk *track = [[OAGpxTrk alloc] init];
        OAGpxTrkSeg *seg = [[OAGpxTrkSeg alloc] init];
        NSMutableArray<OAGpxTrkPt *> *segPoints = [NSMutableArray new];
        for (CLLocation *l in locations)
        {
            OAGpxTrkPt *point = [[OAGpxTrkPt alloc] init];
            [point setPosition:l.coordinate];
            if (l.altitude != 0)
            {
                gpx.hasAltitude = YES;
                CLLocationDistance h = l.altitude;
                point.elevation = h;
                if (lastHeight == RouteDataObject::HEIGHT_UNDEFINED && seg.points.count > 0)
                {
                    for (OAGpxTrkPt *pt in seg.points)
                    {
                        if (pt.elevation == NAN)
                            pt.elevation = h;
                    }
                }
                lastHeight = h;
            }
            [segPoints addObject:point];
        }
        seg.points = segPoints;
        track.segments = @[seg];
        gpx.tracks = @[track];
    }
    return gpx;
}

+ (NSString *) getDescription:(OAGPX *)gpx
{
    NSString *dist = [OAOsmAndFormatter getFormattedDistance:gpx.totalDistance];
    NSString *wpts = [NSString stringWithFormat:@"%@: %d", OALocalizedString(@"gpx_waypoints"), gpx.wptPoints];
    return [NSString stringWithFormat:@"%@ • %@", dist, wpts];
}

+ (long) getSegmentTime:(OAGpxTrkSeg *)segment
{
    long startTime = LONG_MAX;
    long endTime = LONG_MIN;
    for (NSInteger i = 0; i < segment.points.count; i++)
    {
        OAGpxTrkPt *point = segment.points[i];
        long time = point.time;
        if (time != 0) {
            startTime = MIN(startTime, time);
            endTime = MAX(endTime, time);
        }
    }
    return endTime - startTime;
}

+ (double) getSegmentDistance:(OAGpxTrkSeg *)segment
{
    double distance = 0;
    OAGpxTrkPt *prevPoint = nil;
    for (NSInteger i = 0; i < segment.points.count; i++)
    {
        OAGpxTrkPt *point = segment.points[i];
        if (prevPoint != nil)
            distance += getDistance(prevPoint.getLatitude, prevPoint.getLongitude, point.getLatitude, point.getLongitude);
        prevPoint = point;
    }
    return distance;
}

+ (NSArray<OAGpxFileInfo *> *) getSortedGPXFilesInfo:(NSString *)dir selectedGpxList:(NSArray<NSString *> *)selectedGpxList absolutePath:(BOOL)absolutePath
{
    NSMutableArray<OAGpxFileInfo *> *list = [NSMutableArray new];
    [self readGpxDirectory:dir list:list parent:@"" absolutePath:absolutePath];
    if (selectedGpxList)
    {
        for (OAGpxFileInfo *info in list)
        {
            for (NSString *fileName in selectedGpxList)
            {
                if ([fileName hasSuffix:info.fileName])
                {
                    info.selected = YES;
                    break;
                }
            }
        }
    }
    
    [list sortUsingComparator:^NSComparisonResult(OAGpxFileInfo *i1, OAGpxFileInfo *i2) {
        NSComparisonResult res = (NSComparisonResult) (i1.selected == i2.selected ? 0 : i1.selected ? -1 : 1);
        if (res != NSOrderedSame)
            return res;
        
        NSString *name1 = i1.fileName;
        NSString *name2 = i2.fileName;
        NSInteger d1 = [self depth:name1];
        NSInteger d2 = [self depth:name2];
        if (d1 != d2)
            return d1 - d2 > 0 ? NSOrderedDescending : NSOrderedAscending;
        
        NSInteger lastSame = 0;
        for (NSInteger i = 0; i < name1.length && i < name2.length; i++)
        {
            if ([name1 characterAtIndex:i] != [name2 characterAtIndex:i])
                break;
            
            if ([name1 characterAtIndex:i] == '/')
                lastSame = i + 1;
        }
        
        BOOL isDigitStarts1 = [self isLastSameStartsWithDigit:name1 lastSame:lastSame];
        BOOL isDigitStarts2 = [self isLastSameStartsWithDigit:name2 lastSame:lastSame];
        res = (NSComparisonResult) (isDigitStarts1 == isDigitStarts2 ? 0 : isDigitStarts1 ? -1 : 1);
        if (res != NSOrderedSame)
            return res;

        if (isDigitStarts1)
            return (NSComparisonResult) -([name1 caseInsensitiveCompare:name2]);
        
        return [name1 caseInsensitiveCompare:name2];
    }];
    
    return list;
}

+ (void) readGpxDirectory:(NSString *)dir
                     list:(NSMutableArray<OAGpxFileInfo *> *)list
                   parent:(NSString *)parent
             absolutePath:(BOOL)absolutePath
{
    if (dir)
    {
        NSFileManager *fileManager = NSFileManager.defaultManager;
        NSArray<NSString *> *files = [fileManager contentsOfDirectoryAtPath:dir error:nil];
        if (files)
        {
            for (NSString *f in files)
            {
                NSString *fullPath = [dir stringByAppendingPathComponent:f];
                if ([f.pathExtension.lowerCase isEqualToString:@"gpx"])
                {
                    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:fullPath error:nil];
                    [list addObject:[[OAGpxFileInfo alloc] initWithFileName:absolutePath ? fullPath : [parent stringByAppendingPathComponent:f] lastModified:[attributes fileModificationDate].timeIntervalSince1970 * 1000 fileSize:[attributes fileSize]]];
                }
                BOOL isDir = NO;
                [fileManager fileExistsAtPath:fullPath isDirectory:&isDir];
                if (isDir)
                    [self readGpxDirectory:fullPath list:list parent:[parent stringByAppendingPathComponent:f] absolutePath:absolutePath];
            }
        }
    }
}

+ (NSInteger) depth:(NSString *)name
{
    return name.pathComponents.count;
}

+ (BOOL) isLastSameStartsWithDigit:(NSString *)name lastSame:(NSInteger)lastSame
{
    if (name.length > lastSame)
    {
        return isdigit([name characterAtIndex:lastSame]);
    }
    
    return NO;
}

+ (void) addAppearanceToGpx:(OAGPXDocument *)gpxFile gpxItem:(OAGPX *)gpxItem
{
    [gpxFile setShowArrows:gpxItem.showArrows];
    [gpxFile setShowStartFinish:gpxItem.showStartFinish];
    [gpxFile setSplitInterval:gpxItem.splitInterval];
    [gpxFile setSplitType:[OAGPXDatabase splitTypeNameByValue:gpxItem.splitType]];
    if (gpxItem.color != 0)
        [gpxFile setColor:(int)gpxItem.color];
    
    if (gpxItem.width && gpxItem.width.length > 0)
        [gpxFile setWidth:gpxItem.width];
    
    if (gpxItem.coloringType && gpxItem.coloringType.length > 0)
        [gpxFile setColoringType:gpxItem.coloringType];
}

+ (OsmAnd::LatLon)getSegmentPointByTime:(OAGpxTrkSeg *)segment
                                gpxFile:(OAGPXDocument *)gpxFile
                                   time:(float)time
                        preciseLocation:(BOOL)preciseLocation
                           joinSegments:(BOOL)joinSegments
{
    if (!segment.generalSegment || joinSegments)
    {
        return [self getSegmentPointByTime:segment
                               timeToPoint:time
                        passedSegmentsTime:0
                           preciseLocation:preciseLocation];
    }

    long passedSegmentsTime = 0;
    for (OAGpxTrk *track in gpxFile.tracks)
    {
        if (track.generalTrack)
            continue;

        for (OAGpxTrkSeg *seg in track.segments)
        {
            OsmAnd::LatLon latLon = [self
                    getSegmentPointByTime:seg
                              timeToPoint:time
                       passedSegmentsTime:passedSegmentsTime
                          preciseLocation:preciseLocation];

            if (latLon.latitude != 0 && latLon.longitude != 0)
                return latLon;

            long segmentStartTime = !seg.points || seg.points.count == 0 ? 0 : seg.points.firstObject.time;
            long segmentEndTime = !seg.points || seg.points.count == 0 ?
                    0 : seg.points[seg.points.count - 1].time;
            passedSegmentsTime += segmentEndTime - segmentStartTime;
        }
    }

    return OsmAnd::LatLon(0, 0);
}

+ (OsmAnd::LatLon)getSegmentPointByTime:(OAGpxTrkSeg *)segment
                            timeToPoint:(float)timeToPoint
                     passedSegmentsTime:(long)passedSegmentsTime
                        preciseLocation:(BOOL)preciseLocation
{
    OAGpxTrkPt *previousPoint = nil;
    long segmentStartTime = segment.points.firstObject.time;
    for (OAGpxTrkPt *currentPoint in segment.points)
    {
        long totalPassedTime = passedSegmentsTime + currentPoint.time - segmentStartTime;
        if (totalPassedTime >= timeToPoint)
        {
            return preciseLocation && previousPoint
                    ? [self getIntermediatePointByTime:totalPassedTime
                                           timeToPoint:timeToPoint
                                             prevPoint:previousPoint
                                             currPoint:currentPoint]
                    : OsmAnd::LatLon(currentPoint.position.latitude, currentPoint.position.longitude);
        }
        previousPoint = currentPoint;
    }
    return OsmAnd::LatLon(0, 0);
}

+ (OsmAnd::LatLon)getSegmentPointByDistance:(OAGpxTrkSeg *)segment
                                    gpxFile:(OAGPXDocument *)gpxFile
                            distanceToPoint:(float)distanceToPoint
                            preciseLocation:(BOOL)preciseLocation
                               joinSegments:(BOOL)joinSegments
{
    double passedDistance = 0;

    if (!segment.generalSegment || joinSegments)
    {
        OAGpxTrkPt *prevPoint = nil;
        for (int i = 0; i < segment.points.count; i++)
        {
            OAGpxTrkPt *currPoint = segment.points[i];
            if (prevPoint)
            {
                passedDistance += getDistance(
                        prevPoint.position.latitude,
                        prevPoint.position.longitude,
                        currPoint.position.latitude,
                        currPoint.position.longitude
                );
            }
            if (currPoint.distance >= distanceToPoint || ABS(passedDistance - distanceToPoint) < 0.1)
            {
                return preciseLocation && prevPoint && currPoint.distance >= distanceToPoint
                        ? [self getIntermediatePointByDistance:passedDistance
                                               distanceToPoint:distanceToPoint
                                                     currPoint:currPoint
                                                     prevPoint:prevPoint]
                        : OsmAnd::LatLon(currPoint.position.latitude, currPoint.position.longitude);
            }
            prevPoint = currPoint;
        }
    }

    double passedSegmentsPointsDistance = 0;
    OAGpxTrkPt *prevPoint = nil;
    for (OAGpxTrk *track in gpxFile.tracks)
    {
        if (track.generalTrack)
            continue;

        for (OAGpxTrkSeg *seg in track.segments)
        {
            if (!seg.points || seg.points.count == 0)
                continue;

            for (OAGpxTrkPt *currPoint in seg.points)
            {
                if (prevPoint)
                {
                    passedDistance += getDistance(prevPoint.position.latitude, prevPoint.position.longitude,
                            currPoint.position.latitude, currPoint.position.longitude);
                }

                if (passedSegmentsPointsDistance + currPoint.distance >= distanceToPoint
                        || ABS(passedDistance - distanceToPoint) < 0.1)
                {
                    return preciseLocation && prevPoint
                            && currPoint.distance + passedSegmentsPointsDistance >= distanceToPoint
                            ? [self getIntermediatePointByDistance:passedDistance
                                                         distanceToPoint:distanceToPoint
                                                               currPoint:currPoint
                                                               prevPoint:prevPoint]
                            : OsmAnd::LatLon(currPoint.position.latitude, currPoint.position.longitude);
                }
                prevPoint = currPoint;
            }
            prevPoint = nil;
            passedSegmentsPointsDistance += seg.points[seg.points.count - 1].distance;
        }
    }
    return OsmAnd::LatLon(0, 0);
}

+ (OsmAnd::LatLon)getIntermediatePointByTime:(double)passedTime
                                 timeToPoint:(double)timeToPoint
                                   prevPoint:(OAGpxTrkPt *)prevPoint
                                   currPoint:(OAGpxTrkPt *)currPoint
{
    double percent = 1 - (passedTime - timeToPoint) / (currPoint.time - prevPoint.time);
    double dLat = (currPoint.position.latitude - prevPoint.position.latitude) * percent;
    double dLon = (currPoint.position.longitude - prevPoint.position.longitude) * percent;

    OsmAnd::LatLon latLon(prevPoint.position.latitude + dLat, prevPoint.position.longitude + dLon);
    return latLon;
}

+ (OsmAnd::LatLon)getIntermediatePointByDistance:(double)passedDistance
                                 distanceToPoint:(double)distanceToPoint
                                       currPoint:(OAGpxTrkPt *)currPoint
                                       prevPoint:(OAGpxTrkPt *)prevPoint
{
    double percent = 1 - (passedDistance - distanceToPoint) / (currPoint.distance - prevPoint.distance);
    double dLat = (currPoint.position.latitude - prevPoint.position.latitude) * percent;
    double dLon = (currPoint.position.longitude - prevPoint.position.longitude) * percent;

    OsmAnd::LatLon latLon(prevPoint.position.latitude + dLat, prevPoint.position.longitude + dLon);
    return latLon;
}

@end
