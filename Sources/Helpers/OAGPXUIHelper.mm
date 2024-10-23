//
//  OAGPXUIHelper.m
//  OsmAnd Maps
//
//  Created by Paul on 9/12/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAGPXUIHelper.h"
#import "OARouteCalculationResult.h"
#import "OARoutingHelper.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAGPXDatabase.h"
#import "OAPOI.h"
#import "OAPOIHelper.h"
#import "OAPOIFiltersHelper.h"
#import "OACity.h"
#import "OsmAndApp.h"
#import "Localization.h"
#import "OAOsmAndFormatter.h"
#import "OASaveTrackViewController.h"
#import "OASelectedGPXHelper.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OASavingTrackHelper.h"
#import "OsmAnd_Maps-Swift.h"
#import "OAAppVersion.h"

#include <OsmAndCore/Utilities.h>

#define SECOND_IN_MILLIS 1000L

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


@interface OAGPXUIHelper() <UIDocumentInteractionControllerDelegate, OASaveTrackViewControllerDelegate>

@end

@implementation OAGPXUIHelper
{
    NSString *_exportFileName;
    NSString *_exportFilePath;
    OASGpxDataItem *_exportingGpx;
    OASGpxFile *_exportingGpxDoc;
    BOOL _isExportingCurrentTrack;
    UIDocumentInteractionController *_exportController;
    UIViewController __weak *_exportingHostVC;
    id<OATrackSavingHelperUpdatableDelegate> _exportingHostVCDelegate;
}

+ (OASGpxFile *)makeGpxFromRoute:(OARouteCalculationResult *)route
{
    OASGpxFile *gpx = [[OASGpxFile alloc] initWithAuthor:[OAAppVersion getFullVersionWithAppName]];
    
    NSArray<CLLocation *> *locations = [route getRouteLocations];
    OASTrack *track = [[OASTrack alloc] init];
    OASTrkSegment *seg = [[OASTrkSegment alloc] init];
    NSMutableArray<OASWptPt *> *pts = [NSMutableArray new];
    if (locations)
    {
        for (CLLocation *l in locations)
        {
            OASWptPt *point = [[OASWptPt alloc] init];
            point.lat = l.coordinate.latitude;
            point.lon = l.coordinate.longitude;
            if (!isnan(l.altitude) && l.altitude != 0)
            {
                if (gpx)
                    gpx.hasAltitude = YES;
                point.ele = l.altitude;
            }
            if (pts.count == 0)
            {
                point.time = (long) [[NSDate date] timeIntervalSince1970];
            }
            else
            {
                OASWptPt *prevPoint = pts[pts.count - 1];
                if (l.speed != 0)
                {
                    point.speed = l.speed;
                    double dist = getDistance(prevPoint.position.latitude,
                            prevPoint.position.longitude,
                            point.position.latitude,
                            point.position.longitude);
                    point.time = prevPoint.time + (long) (dist / point.speed) * SECOND_IN_MILLIS;
                } else {
                    point.time = prevPoint.time;
                }
            }
            [pts addObject:point];
        }
    }
    [OAGPXUIHelper interpolateEmptyElevationWpts:pts];
    seg.points = pts;
    track.segments = [@[seg] mutableCopy];
    gpx.tracks = [@[track] mutableCopy];
    return gpx;
}

+ (void)interpolateEmptyElevationWpts:(NSMutableArray<OASWptPt *> *)pts
{
    for (int i = 0; i < pts.count; )
    {
        int processedPoints = 0;
        OASWptPt *currentPt = pts[i];
        if (isnan(currentPt.ele))
        {
            int startIndex = i, prevValidIndex = -1, nextValidIndex = -1;
            double prevValidElevation = NAN, nextValidElevation = NAN;

            for (int j = startIndex - 1; j >= 0; j--)
            {
                OASWptPt *prevPt = pts[j];
                if (!isnan(prevPt.ele))
                {
                    prevValidElevation = prevPt.ele;
                    prevValidIndex = j;
                    break;
                }
            }

            for (int j = startIndex + 1; j < pts.count; j++)
            {
                OASWptPt *nextPt = pts[j];
                if (!isnan(nextPt.ele))
                {
                    nextValidElevation = nextPt.ele;
                    nextValidIndex = j;
                    break;
                }
            }

            if (prevValidIndex == -1 && nextValidIndex == -1)
            {
                return; // no elevation at all
            }

            if (prevValidIndex == -1 || nextValidIndex == -1)
            {
                // outermost section without interpolation
                for (int j = startIndex; j < pts.count; j++)
                {
                    OASWptPt *pt = pts[j];
                    if (isnan(pt.ele))
                    {
                        pt.ele = startIndex == 0 ? nextValidElevation : prevValidElevation;
                        processedPoints++;
                    } else
                    {
                        break;
                    }
                }
            } else
            {
                // inner section
                double totalDistance = 0;
                NSMutableArray<NSNumber *> *distanceArray = [NSMutableArray arrayWithCapacity:(nextValidIndex - prevValidIndex)];
                for (int j = prevValidIndex; j < nextValidIndex; j++)
                {
                    OASWptPt *thisPt = pts[j];
                    OASWptPt *nextPt = pts[j + 1];
                    double distance = getDistance(thisPt.position.latitude, thisPt.position.longitude,
                                                  nextPt.position.latitude, nextPt.position.longitude);
                    [distanceArray addObject:@(distance)];
                    totalDistance += distance;
                }
                double deltaElevation = pts[nextValidIndex].ele - pts[prevValidIndex].ele;
                for (int j = startIndex; totalDistance > 0 && j < nextValidIndex; j++)
                {
                    double currentDistance = [distanceArray[j - startIndex] doubleValue];
                    double increaseElevation = deltaElevation * (currentDistance / totalDistance);
                    pts[j].ele = pts[j - 1].ele + increaseElevation;
                    processedPoints++;
                }
            }
        }
        i += processedPoints > 0 ? processedPoints : 1;
    }
}

+ (NSString *) getDescription:(OASGpxDataItem *)gpx
{
    NSString *dist = [OAOsmAndFormatter getFormattedDistance:gpx.totalDistance];
    NSString *wpts = [NSString stringWithFormat:@"%@: %d", OALocalizedString(@"shared_string_waypoints"), gpx.wptPoints];
    return [NSString stringWithFormat:@"%@ • %@", dist, wpts];
}

+ (long)getSegmentTime:(OASTrkSegment *)segment
{
    long startTime = LONG_MAX;
    long endTime = LONG_MIN;
    for (NSInteger i = 0; i < segment.points.count; i++)
    {
        OASWptPt *point = segment.points[i];
        long time = point.time;
        if (time != 0) {
            startTime = MIN(startTime, time);
            endTime = MAX(endTime, time);
        }
    }
    return endTime - startTime;
}

+ (double) getSegmentDistance:(OASTrkSegment *)segment
{
    double distance = 0;
    OASWptPt *prevPoint = nil;
    for (NSInteger i = 0; i < segment.points.count; i++)
    {
        OASWptPt *point = segment.points[i];
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

+ (void) addAppearanceToGpx:(OASGpxFile *)gpxFile gpxItem:(OASGpxDataItem *)gpxItem
{
    [gpxFile setShowArrowsShowArrows:gpxItem.showArrows];
    [gpxFile setShowStartFinishShowStartFinish:gpxItem.showStartFinish];
    if (gpxItem.visualization3dByType != EOAGPX3DLineVisualizationByTypeNone)
    {
        [gpxFile setAdditionalExaggerationAdditionalExaggeration:gpxItem.verticalExaggerationScale];
        [gpxFile setElevationMetersElevation:gpxItem.elevationMeters];
        
        [gpxFile set3DVisualizationTypeVisualizationType:[OAGPXDatabase lineVisualizationByTypeNameForType:(EOAGPX3DLineVisualizationByType)gpxItem.visualization3dByType]];
        [gpxFile set3DWallColoringTypeTrackWallColoringType:[OAGPXDatabase lineVisualizationWallColorTypeNameForType:(EOAGPX3DLineVisualizationWallColorType)gpxItem.visualization3dWallColorType]];
        [gpxFile set3DVisualizationTypeVisualizationType:[OAGPXDatabase lineVisualizationPositionTypeNameForType:(EOAGPX3DLineVisualizationPositionType)gpxItem.visualization3dPositionType]];
    }
    
    [gpxFile setSplitIntervalSplitInterval:gpxItem.splitInterval];
    [gpxFile setSplitTypeGpxSplitType:[OAGPXDatabase splitTypeNameByValue:gpxItem.splitType]];
    if (gpxItem.color != 0)
    {
        OASInt *color = [[OASInt alloc] initWithInt:(int)gpxItem.color];
        [gpxFile setColorColor:color];
    }
    
    if (gpxItem.width && gpxItem.width.length > 0)
        [gpxFile setWidthWidth:gpxItem.width];
    
    if (gpxItem.coloringType && gpxItem.coloringType.length > 0)
        [gpxFile setColoringTypeColoringType:gpxItem.coloringType];

    if (gpxItem.gradientPaletteName && gpxItem.gradientPaletteName.length > 0)
        [gpxFile setGradientColorPaletteGradientColorPaletteName:gpxItem.gradientPaletteName];
}

+ (CLLocationCoordinate2D)getSegmentPointByTime:(OASTrkSegment *)segment
                                        gpxFile:(OASGpxFile *)gpxFile
                                           time:(double)time
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
    for (OASTrack *track in gpxFile.tracks)
    {
        if (track.generalTrack)
            continue;

        for (OASTrkSegment *seg in track.segments)
        {
            CLLocationCoordinate2D latLon = [self getSegmentPointByTime:seg
                                                            timeToPoint:time
                                                     passedSegmentsTime:passedSegmentsTime
                                                        preciseLocation:preciseLocation];

            if (CLLocationCoordinate2DIsValid(latLon))
                return latLon;

            long segmentStartTime = !seg.points || seg.points.count == 0 ? 0 : seg.points.firstObject.time;
            long segmentEndTime = !seg.points || seg.points.count == 0 ?
                    0 : seg.points[seg.points.count - 1].time;
            passedSegmentsTime += segmentEndTime - segmentStartTime;
        }
    }

    return kCLLocationCoordinate2DInvalid;
}

+ (CLLocationCoordinate2D)getSegmentPointByTime:(OASTrkSegment *)segment
                                    timeToPoint:(double)timeToPoint
                             passedSegmentsTime:(long)passedSegmentsTime
                                preciseLocation:(BOOL)preciseLocation
{
    OASWptPt *previousPoint = nil;
    long segmentStartTime = segment.points.firstObject.time;
    for (OASWptPt *currentPoint in segment.points)
    {
        long totalPassedTime = passedSegmentsTime + currentPoint.time - segmentStartTime;
        if (totalPassedTime >= timeToPoint)
        {
            return preciseLocation && previousPoint
                    ? [self getIntermediatePointByTime:totalPassedTime
                                           timeToPoint:timeToPoint
                                             prevPoint:previousPoint
                                             currPoint:currentPoint]
                    : CLLocationCoordinate2DMake(currentPoint.position.latitude, currentPoint.position.longitude);
        }
        previousPoint = currentPoint;
    }
    return kCLLocationCoordinate2DInvalid;
}

+ (CLLocationCoordinate2D)getSegmentPointByDistance:(OASTrkSegment *)segment
                                            gpxFile:(OASGpxFile *)gpxFile
                                    distanceToPoint:(double)distanceToPoint
                                    preciseLocation:(BOOL)preciseLocation
                                       joinSegments:(BOOL)joinSegments
{
    double passedDistance = 0;

    if (!segment.generalSegment || joinSegments)
    {
        OASWptPt *prevPoint = nil;
        for (int i = 0; i < segment.points.count; i++)
        {
            OASWptPt *currPoint = segment.points[i];
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
                        : CLLocationCoordinate2DMake(currPoint.position.latitude, currPoint.position.longitude);
            }
            prevPoint = currPoint;
        }
    }

    double passedSegmentsPointsDistance = 0;
    OASWptPt *prevPoint = nil;
    for (OASTrack *track in gpxFile.tracks)
    {
        if (track.generalTrack)
            continue;

        for (OASTrkSegment *seg in track.segments)
        {
            if (!seg.points || seg.points.count == 0)
                continue;

            for (OASWptPt *currPoint in seg.points)
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
                            : CLLocationCoordinate2DMake(currPoint.position.latitude, currPoint.position.longitude);
                }
                prevPoint = currPoint;
            }
            prevPoint = nil;
            passedSegmentsPointsDistance += seg.points[seg.points.count - 1].distance;
        }
    }
    return kCLLocationCoordinate2DInvalid;
}

+ (CLLocationCoordinate2D)getIntermediatePointByTime:(double)passedTime
                                 timeToPoint:(double)timeToPoint
                                   prevPoint:(OASWptPt *)prevPoint
                                   currPoint:(OASWptPt *)currPoint
{
    double percent = 1 - (passedTime - timeToPoint) / (currPoint.time - prevPoint.time);
    double dLat = (currPoint.position.latitude - prevPoint.position.latitude) * percent;
    double dLon = (currPoint.position.longitude - prevPoint.position.longitude) * percent;
    return CLLocationCoordinate2DMake(prevPoint.position.latitude + dLat, prevPoint.position.longitude + dLon);
}

+ (CLLocationCoordinate2D)getIntermediatePointByDistance:(double)passedDistance
                                         distanceToPoint:(double)distanceToPoint
                                               currPoint:(OASWptPt *)currPoint
                                               prevPoint:(OASWptPt *)prevPoint
{
    double percent = 1 - (passedDistance - distanceToPoint) / (currPoint.distance - prevPoint.distance);
    double dLat = (currPoint.position.latitude - prevPoint.position.latitude) * percent;
    double dLon = (currPoint.position.longitude - prevPoint.position.longitude) * percent;
    return CLLocationCoordinate2DMake(prevPoint.position.latitude + dLat, prevPoint.position.longitude + dLon);
}

+ (OAPOI *)searchNearestCity:(CLLocationCoordinate2D)latLon
{
    OsmAnd::PointI pointI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(latLon.latitude, latLon.longitude));
    const auto rect = OsmAnd::Utilities::boundingBox31FromAreaInMeters(50 * 1000, pointI);
    const auto top = OsmAnd::Utilities::get31LatitudeY(rect.top());
    const auto left = OsmAnd::Utilities::get31LongitudeX(rect.left());
    const auto bottom = OsmAnd::Utilities::get31LatitudeY(rect.bottom());
    const auto right = OsmAnd::Utilities::get31LongitudeX(rect.right());

    NSArray<NSString *> *cityTypes = @[
        [OACity getTypeStr:CITY_SUBTYPE_CITY],
        [OACity getTypeStr:CITY_SUBTYPE_TOWN],
        [OACity getTypeStr:CITY_SUBTYPE_VILLAGE],
        [OACity getTypeStr:CITY_SUBTYPE_HAMLET],
        [OACity getTypeStr:CITY_SUBTYPE_SUBURB],
        [OACity getTypeStr:CITY_SUBTYPE_DISTRICT],
        [OACity getTypeStr:CITY_SUBTYPE_NEIGHBOURHOOD]
    ];

    OASearchPoiTypeFilter *filter = [[OASearchPoiTypeFilter alloc] initWithAcceptFunc:^BOOL(OAPOICategory *type, NSString *subcategory) {
        return [cityTypes containsObject:subcategory];
    } emptyFunction:^BOOL{
        return NO;
    } getTypesFunction:nil];

    NSArray<OAPOI *> *amenities = [OAPOIHelper findPOIsByFilter:filter topLatitude:top leftLongitude:left bottomLatitude:bottom rightLongitude:right matcher:nil];
    return amenities.count > 0 ? [self sortAmenities:amenities cityTypes:cityTypes latLon:latLon].firstObject : nil;
}

+ (NSArray<OAPOI *> *)sortAmenities:(NSArray<OAPOI *> *)amenities cityTypes:(NSArray<NSString *> *)cityTypes latLon:(CLLocationCoordinate2D)latLon
{
    return [amenities sortedArrayUsingComparator:^NSComparisonResult(OAPOI * _Nonnull amenity1, OAPOI * _Nonnull amenity2) {
        CGFloat rad1 = 1000.;
        CGFloat rad2 = 1000.;
        if ([cityTypes containsObject:amenity1.subType])
            rad1 = [OACity getRadius:amenity1.subType];
        if ([cityTypes containsObject:amenity2.subType])
            rad2 = [OACity getRadius:amenity2.subType];
        double distance1 = OsmAnd::Utilities::distance(amenity1.longitude, amenity1.latitude, latLon.longitude, latLon.latitude) / rad1;
        double distance2 = OsmAnd::Utilities::distance(amenity2.longitude, amenity2.latitude, latLon.longitude, latLon.latitude) / rad2;
        if (distance1 == distance2)
            return NSOrderedSame;
        else
            return distance1 < distance2 ? NSOrderedAscending : NSOrderedDescending;
    }];
}

- (void)openExportForTrack:(OASGpxDataItem *)trackItem
                    gpxDoc:(id)gpxDoc
            isCurrentTrack:(BOOL)isCurrentTrack
          inViewController:(UIViewController *)hostViewController
hostViewControllerDelegate:(id)hostViewControllerDelegate
            touchPointArea:(CGRect)touchPointArea
{
    _isExportingCurrentTrack = isCurrentTrack;
    _exportingHostVC = hostViewController;
    _exportingHostVCDelegate = hostViewControllerDelegate;
    _exportingGpx = trackItem;
    _exportingGpxDoc = gpxDoc;
    if (isCurrentTrack)
    {
        NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
        [fmt setDateFormat:@"yyyy-MM-dd"];

        NSDateFormatter *simpleFormat = [[NSDateFormatter alloc] init];
        [simpleFormat setDateFormat:@"HH-mm_EEE"];

        _exportFileName = [NSString stringWithFormat:@"%@_%@",
                                                     [fmt stringFromDate:[NSDate date]],
                                                     [simpleFormat stringFromDate:[NSDate date]]];
        _exportFilePath = [NSString stringWithFormat:@"%@/%@.gpx",
                                                     NSTemporaryDirectory(),
                                                     _exportFileName];

        [OASavingTrackHelper.sharedInstance saveCurrentTrack:_exportFilePath];
        _exportingGpxDoc = OASavingTrackHelper.sharedInstance.currentTrack;
    }
    else
    {
        _exportFileName = trackItem.gpxFileName;
        _exportFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:trackItem.gpxFileName];
        if (!_exportingGpxDoc || ![_exportingGpxDoc isKindOfClass:OASGpxFile.class])
        {
            NSString *absoluteGpxFilepath = [OsmAndApp.instance.gpxPath stringByAppendingPathComponent:_exportFileName];
            
            OASKFile *file = [[OASKFile alloc] initWithFilePath:absoluteGpxFilepath];
            _exportingGpxDoc = [OASGpxUtilities.shared loadGpxFileFile:file];
        }
        else
        {
            _exportingGpxDoc = gpxDoc;
        }
        [OAGPXUIHelper addAppearanceToGpx:_exportingGpxDoc gpxItem:_exportingGpx];
        
        OASKFile *file = [[OASKFile alloc] initWithFilePath:_exportFilePath];
        [OASGpxUtilities.shared writeGpxFileFile:file gpxFile:_exportingGpxDoc];
    }

    _exportController = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:_exportFilePath]];
    _exportController.UTI = @"com.topografix.gpx";
    _exportController.delegate = self;
    _exportController.name = _exportFileName;
    [_exportController presentOptionsMenuFromRect:touchPointArea inView:_exportingHostVC.view animated:YES];
}

- (void)copyNewGPXToNewFolder:(NSString *)newFolderName
           renameToNewName:(NSString *)newFileName
        deleteOriginalFile:(BOOL)deleteOriginalFile
                 openTrack:(BOOL)openTrack
                       gpx:(OASGpxDataItem *)gpx
{
    NSString *oldPath = gpx.gpxFilePath;
    NSString *sourcePath = [OsmAndApp.instance.gpxPath stringByAppendingPathComponent:oldPath];

    NSString *newFolder = [newFolderName isEqualToString:OALocalizedString(@"shared_string_gpx_tracks")] ? @"" : newFolderName;
    NSString *newFolderPath = [OsmAndApp.instance.gpxPath stringByAppendingPathComponent:newFolder];
    NSString *newName = gpx.gpxFileName;
    
    NSString *subfolderPath = OsmAndApp.instance.gpxPath;
    for (NSString *component in [newFolder pathComponents])
    {
        subfolderPath = [subfolderPath stringByAppendingPathComponent:component];
        if (![[NSFileManager defaultManager] fileExistsAtPath:subfolderPath])
        {
            [[NSFileManager defaultManager] createDirectoryAtPath:subfolderPath withIntermediateDirectories:YES attributes:nil error:nil];
        }
    }

    if (newFileName)
    {
        newName = newFileName;
        while ([[NSFileManager defaultManager]
                fileExistsAtPath:[newFolderPath stringByAppendingPathComponent:newName]])
        {
            newName = [OAUtilities createNewFileName:newName];
        }
    }

    NSString *newStoringPath = [newFolder stringByAppendingPathComponent:newName];
    NSString *destinationPath = [newFolderPath stringByAppendingPathComponent:newName];

    [[NSFileManager defaultManager] copyItemAtPath:sourcePath toPath:destinationPath error:nil];

    OAGPXDatabase *gpxDatabase = [OAGPXDatabase sharedDb];
    if (deleteOriginalFile)
    {
        [gpx updateFolderNameWithNewFilePath:newStoringPath];
        [[NSFileManager defaultManager] removeItemAtPath:sourcePath error:nil];

        [OASelectedGPXHelper renameVisibleTrack:oldPath newPath:newStoringPath];
    }
    else
    {
        [gpxDatabase addGPXFileToDBIfNeeded:destinationPath];
        
        if ([OAAppSettings.sharedManager.mapSettingVisibleGpx.get containsObject:oldPath])
            [OAAppSettings.sharedManager showGpx:@[newStoringPath]];
    }
    if (openTrack)
    {
        OASGpxDataItem *gpx = [[OAGPXDatabase sharedDb] getGPXItem:[newFolderName stringByAppendingPathComponent:newFileName]];
        if (gpx && _exportingHostVC)
        {
            [_exportingHostVC dismissViewControllerAnimated:YES completion:^{
                [OARootViewController.instance.mapPanel targetHideContextPinMarker];
                auto trackItem = [[OASTrackItem alloc] initWithFile:gpx.file];
                trackItem.dataItem = gpx;
                [OARootViewController.instance.mapPanel openTargetViewWithGPX:trackItem];
            }];
        }
    }
}

- (void)copyGPXToNewFolder:(NSString *)newFolderName
           renameToNewName:(NSString *)newFileName
        deleteOriginalFile:(BOOL)deleteOriginalFile
                 openTrack:(BOOL)openTrack
                       gpx:(OASGpxDataItem *)gpx
{
    NSString *gpxFilepath = [OsmAndApp.instance.gpxPath stringByAppendingPathComponent:gpx.gpxFilePath];
    
    OASKFile *file = [[OASKFile alloc] initWithFilePath:gpxFilepath];
    OASGpxFile *doc = [OASGpxUtilities.shared loadGpxFileFile:file];
    if (doc)
        [self copyGPXToNewFolder:newFolderName renameToNewName:newFileName deleteOriginalFile:deleteOriginalFile openTrack:openTrack gpx:gpx doc:doc];
}

- (void)copyGPXToNewFolder:(NSString *)newFolderName
           renameToNewName:(NSString *)newFileName
        deleteOriginalFile:(BOOL)deleteOriginalFile
                 openTrack:(BOOL)openTrack
                       gpx:(OASGpxDataItem *)gpx
                       doc:(OASGpxFile *)doc
{
    NSString *oldPath = gpx.gpxFilePath;
    NSString *sourcePath = [OsmAndApp.instance.gpxPath stringByAppendingPathComponent:oldPath];

    NSString *newFolder = [newFolderName isEqualToString:OALocalizedString(@"shared_string_gpx_tracks")] ? @"" : newFolderName;
    NSString *newFolderPath = [OsmAndApp.instance.gpxPath stringByAppendingPathComponent:newFolder];
    NSString *newName = gpx.gpxFileName;
    
    NSString *subfolderPath = OsmAndApp.instance.gpxPath;
    for (NSString *component in [newFolder pathComponents])
    {
        subfolderPath = [subfolderPath stringByAppendingPathComponent:component];
        if (![[NSFileManager defaultManager] fileExistsAtPath:subfolderPath])
        {
            [[NSFileManager defaultManager] createDirectoryAtPath:subfolderPath withIntermediateDirectories:YES attributes:nil error:nil];
        }
    }

    if (newFileName)
    {
        newName = newFileName;
        while ([[NSFileManager defaultManager]
                fileExistsAtPath:[newFolderPath stringByAppendingPathComponent:newName]])
        {
            newName = [OAUtilities createNewFileName:newName];
        }
    }

    NSString *newStoringPath = [newFolder stringByAppendingPathComponent:newName];
    NSString *destinationPath = [newFolderPath stringByAppendingPathComponent:newName];
    [[NSFileManager defaultManager] copyItemAtPath:sourcePath toPath:destinationPath error:nil];

    OAGPXDatabase *gpxDatabase = [OAGPXDatabase sharedDb];
    if (deleteOriginalFile)
    {
        doc.path = [[OsmAndApp instance].gpxPath stringByAppendingPathComponent:gpx.gpxFilePath];
        [gpxDatabase save];
        [[NSFileManager defaultManager] removeItemAtPath:sourcePath error:nil];

        [OASelectedGPXHelper renameVisibleTrack:oldPath newPath:newStoringPath];
    }
    else
    {
        OAGPXDatabase *gpxDb = [OAGPXDatabase sharedDb];
        OASGpxDataItem *gpx = [gpxDb getGPXItem:sourcePath];
        if (!gpx)
        {
            gpx = [gpxDb addGPXFileToDBIfNeeded:sourcePath];
        }
        if (gpx)
        {
            OASGpxTrackAnalysis *analysis = [gpx getAnalysis];
            
            if (analysis.locationStart)
            {
                OAPOI *nearestCityPOI = [OAGPXUIHelper searchNearestCity:analysis.locationStart.position];
                NSString *nearestCityString = nearestCityPOI ? nearestCityPOI.nameLocalized : @"";
                [[OASGpxDbHelper shared] updateDataItemParameterItem:gpx
                                                           parameter:OASGpxParameter.nearestCityName
                                                               value:nearestCityString];
            }
        }

        if ([OAAppSettings.sharedManager.mapSettingVisibleGpx.get containsObject:oldPath])
            [OAAppSettings.sharedManager showGpx:@[newStoringPath]];
    }
    if (openTrack)
    {
        OASGpxDataItem *gpx = [[OAGPXDatabase sharedDb] getGPXItem:[newFolderName stringByAppendingPathComponent:newFileName]];
        if (gpx && _exportingHostVC)
        {
            [_exportingHostVC dismissViewControllerAnimated:YES completion:^{
                [OARootViewController.instance.mapPanel targetHideContextPinMarker];
                auto trackItem = [[OASTrackItem alloc] initWithFile:gpx.file];
                trackItem.dataItem = gpx;
                [OARootViewController.instance.mapPanel openTargetViewWithGPX:trackItem];
            }];
        }
    }
}

- (void)renameTrackNew:(OASGpxDataItem *)gpx
               newName:(NSString *)newName
                hostVC:(UIViewController*)hostVC
{
    if (newName.length > 0)
    {
        NSString *oldFilePath = gpx.gpxFilePath;
        NSString *newFileName = newName;
        NSString *newFilePath = [[gpx.gpxFilePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:newFileName];
        NSString *newPath = [OsmAndApp.instance.gpxPath stringByAppendingPathComponent:newFilePath];
        if (![NSFileManager.defaultManager fileExistsAtPath:newPath])
        {
            [[OAGPXDatabase sharedDb] renameGPX:gpx newFilePath:newPath];
            [OASelectedGPXHelper renameVisibleTrack:oldFilePath newPath:newFilePath];
        }
        else
        {
            [self showAlertWithText:OALocalizedString(@"gpx_already_exsists") inViewController:hostVC];
        }
    }
    else
    {
        [self showAlertWithText:OALocalizedString(@"empty_filename") inViewController:hostVC];
    }
}

- (void)renameTrack:(OASGpxDataItem *)gpx newName:(NSString *)newName hostVC:(UIViewController*)hostVC
{
    NSString *docPath = [[OsmAndApp instance].gpxPath stringByAppendingPathComponent:gpx.gpxFilePath];
    OASKFile *file = [[OASKFile alloc] initWithFilePath:docPath];
    OASGpxFile *doc = [OASGpxUtilities.shared loadGpxFileFile:file];
    [self renameTrack:gpx doc:doc newName:newName hostVC:hostVC];
}

- (void)renameTrack:(OASGpxDataItem *)gpx doc:(OASGpxFile *)doc newName:(NSString *)newName hostVC:(UIViewController*)hostVC
{
    if (newName.length > 0)
    {
        NSString *oldFilePath = gpx.gpxFilePath;
        NSString *oldPath = [OsmAndApp.instance.gpxPath stringByAppendingPathComponent:oldFilePath];
        NSString *newFileName = [newName stringByAppendingPathExtension:@"gpx"];
        NSString *newFilePath = [[gpx.gpxFilePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:newFileName]; // 2023-10-22_11-34_Sun 2.gpx
        NSString *newPath = [OsmAndApp.instance.gpxPath stringByAppendingPathComponent:newFilePath];
        if (![NSFileManager.defaultManager fileExistsAtPath:newPath])
        {
            gpx.gpxTitle = newName;
            gpx.gpxFileName = newFileName;
            [[OAGPXDatabase sharedDb] updateDataItem:gpx];

            OASMetadata *metadata;
            if (doc.metadata)
            {
                metadata = doc.metadata;
            }
            else
            {
                metadata = [[OASMetadata alloc] init];
                long time = 0;
                if (doc.getPointsList.count > 0)
                    time = doc.getPointsList[0].time;
                if (doc.tracks.count > 0)
                {
                    OASTrack *track = doc.tracks[0];
                    track.name = newName;
                    if (track.segments.count > 0)
                    {
                        OASTrkSegment *seg = track.segments[0];
                        if (seg.points.count > 0)
                         {
                            OASWptPt *p = seg.points[0];
                            if (time > p.time)
                                time = p.time;
                        }
                    }
                }
                metadata.time = time == 0 ? (long) [[NSDate date] timeIntervalSince1970] : time;
            }

            if (doc.author && [doc.author containsString:@"OsmAnd"])
                metadata.name = newName;

            if ([NSFileManager.defaultManager fileExistsAtPath:oldPath])
                [NSFileManager.defaultManager removeItemAtPath:oldPath error:nil];

            BOOL gpxSaved = [OARootViewController.instance.mapPanel.mapViewController updateMetadata:metadata oldPath:oldPath docPath:newPath];
            doc.path = newPath;
            doc.metadata = metadata;
            if (!gpxSaved)
            {
                OASKFile *file = [[OASKFile alloc] initWithFilePath:newPath];
                [OASGpxUtilities.shared writeGpxFileFile:file gpxFile:doc];
            }
            [OASelectedGPXHelper renameVisibleTrack:oldFilePath newPath:newFilePath];
        }
        else
        {
            [self showAlertWithText:OALocalizedString(@"gpx_already_exsists") inViewController:hostVC];
        }
    }
    else
    {
        [self showAlertWithText:OALocalizedString(@"empty_filename") inViewController:hostVC];
    }
}

- (void) onCloseShareMenu
{
    _exportFileName = nil;
    _exportFilePath = nil;
    _exportingGpx = nil;
    _exportingGpxDoc = nil;
    _exportingHostVC = nil;
    _exportController = nil;
    if (_exportingHostVCDelegate)
    {
        [_exportingHostVCDelegate onNeedUpdateHostData];
        _exportingHostVCDelegate = nil;
    }
}

- (void)showAlertWithText:(NSString *)text inViewController:(UIViewController *)viewController
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:text
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok")
                                              style:UIAlertActionStyleDefault
                                            handler:nil]];
    [viewController presentViewController:alert animated:YES completion:nil];
}


#pragma mark - UIDocumentInteractionControllerDelegate

- (void)documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller
{
    if (controller == _exportController)
        _exportController = nil;
}

- (void)documentInteractionController:(UIDocumentInteractionController *)controller
            didEndSendingToApplication:(NSString *)application
{
    if (_isExportingCurrentTrack && _exportFilePath)
    {
        [[NSFileManager defaultManager] removeItemAtPath:_exportFilePath error:nil];
        _exportFilePath = nil;
    }
}

- (void)documentInteractionController:(UIDocumentInteractionController *)controller
        willBeginSendingToApplication:(NSString *)application
{
    if ([application isEqualToString:@"net.osmand.maps"] && _exportingHostVC)
    {
        [_exportController dismissMenuAnimated:YES];
        _exportFilePath = nil;
        _exportController = nil;

        OASaveTrackViewController *saveTrackViewController = [[OASaveTrackViewController alloc]
                initWithFileName:_exportFileName
                        filePath:_exportFilePath
                       showOnMap:YES
                 simplifiedTrack:YES
                       duplicate:NO];

        saveTrackViewController.delegate = self;
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:saveTrackViewController];
        [_exportingHostVC presentViewController:navigationController animated:YES completion:nil];
    }
}

- (void)documentInteractionControllerDidDismissOptionsMenu:(UIDocumentInteractionController *)controller
{
    [self onCloseShareMenu];
}

#pragma mark - OASaveTrackViewControllerDelegate

- (void)onSaveAsNewTrack:(NSString *)fileName
               showOnMap:(BOOL)showOnMap
         simplifiedTrack:(BOOL)simplifiedTrack
               openTrack:(BOOL)openTrack
{
    [self copyGPXToNewFolder:fileName.stringByDeletingLastPathComponent
             renameToNewName:[fileName.lastPathComponent stringByAppendingPathExtension:@"gpx"]
          deleteOriginalFile:NO
                   openTrack:YES
                         gpx:_exportingGpx
                         doc:_exportingGpxDoc];
    [self onCloseShareMenu];
}

+ (NSString *)buildTrackSegmentName:(OASGpxFile *)gpxFile track:(OASTrack *)track segment:(OASTrkSegment *)segment
{
    NSString *trackTitle = [self getTrackTitle:gpxFile track:track];
    NSString *segmentTitle = [self getSegmentTitle:segment segmentIdx:[track.segments indexOfObject:segment]];

    BOOL oneSegmentPerTrack =
            [gpxFile getNonEmptySegmentsCount] == [gpxFile getNonEmptyTracksCount];
    BOOL oneOriginalTrack = ([gpxFile hasGeneralTrack] && [gpxFile getNonEmptyTracksCount] == 2)
            || (![gpxFile hasGeneralTrack] && [gpxFile getNonEmptyTracksCount] == 1);

    if (oneSegmentPerTrack)
        return trackTitle;
    else if (oneOriginalTrack)
        return segmentTitle;
    else
        return [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_dash"), trackTitle, segmentTitle];
}

+ (NSString *)getSegmentTitle:(OASTrkSegment *)segment segmentIdx:(NSInteger)segmentIdx
{
    NSString *segmentName = !segment.name || segment.name.length == 0
            ? [NSString stringWithFormat:@"%li", segmentIdx + 1]
            : segment.name;
    NSString *segmentString = OALocalizedString(@"gpx_selection_segment_title");
    return [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_space"), segmentString, segmentName];
}

+ (NSString *)getTrackTitle:(OASGpxFile *)gpxFile track:(OASTrack *)track
{
    NSString *trackName;
    if (!track.name || track.name.length == 0)
    {
        NSInteger trackIdx = [gpxFile.tracks indexOfObject:track];
        NSInteger visibleTrackIdx = [gpxFile hasGeneralTrack] ? trackIdx : trackIdx + 1;
        trackName = [NSString stringWithFormat:@"%li", visibleTrackIdx];
    }
    else
    {
        trackName = track.name;
    }
    NSString *trackString = OALocalizedString(@"shared_string_gpx_track");
    return [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_colon"), trackString, trackName];
}

@end
