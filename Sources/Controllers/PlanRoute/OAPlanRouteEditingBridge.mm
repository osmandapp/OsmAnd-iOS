//
//  OAPlanRouteEditingBridge.mm
//  OsmAnd Maps
//
//  Created by OsmAnd on 17.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import "OAPlanRouteEditingBridge.h"
#import <CoreLocation/CoreLocation.h>
#import "Localization.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OAMapLayers.h"
#import "OAMeasurementToolLayer.h"
#import "OAMeasurementEditingContext.h"
#import "OAMeasurementCommandManager.h"
#import "OAApplicationMode.h"
#import "OAMapUtils.h"
#import "OAGpxData.h"
#import "OsmAndSharedWrapper.h"
#import "OAAddPointCommand.h"
#import "OASplitPointsCommand.h"
#import "OARemovePointCommand.h"
#import "OAReorderPointCommand.h"
#import "OAChangeRouteModeCommand.h"
#import "OAReversePointsCommand.h"
#import "OAClearPointsCommand.h"
#import "OAGPXDatabase.h"
#import "OAUtilities.h"
#import "OAAppVersion.h"
#import "OsmAndApp.h"
#import "OAMapActions.h"
#import "OAAppSettings.h"

@class OAMeasurementToolLayer, OAMeasurementEditingContext;

@interface OAPlanRoutePointData ()

- (instancetype)initWithGlobalIndex:(NSInteger)globalIndex
                               name:(NSString *)name
               distanceFromPrevious:(double)distanceFromPrevious
                            bearing:(double)bearing
                            isStart:(BOOL)isStart
                      isDestination:(BOOL)isDestination;

@end

@interface OAPlanRouteGroupData ()

- (instancetype)initWithAppMode:(nullable OAApplicationMode *)appMode
                       distance:(double)distance
                lastGlobalIndex:(NSInteger)lastGlobalIndex
                         points:(NSArray<OAPlanRoutePointData *> *)points;

@end

@interface OAPlanRouteSegmentData ()

- (instancetype)initWithIndex:(NSInteger)index
                       routed:(BOOL)routed
                    multiMode:(BOOL)multiMode
                   singleMode:(nullable OAApplicationMode *)singleMode
                     distance:(double)distance
                       groups:(NSArray<OAPlanRouteGroupData *> *)groups;

@end

@interface OAPlanRouteEditingBridge () <OAMeasurementLayerDelegate>
{
    double _distanceToMapCenter;
    double _bearingToMapCenter;
}

- (OAMeasurementToolLayer *)layer;
- (OAMeasurementEditingContext *)editingContext;
- (double)distanceFrom:(OASWptPt *)from to:(OASWptPt *)to;
- (double)bearingFrom:(OASWptPt *)from to:(OASWptPt *)to;
- (OAPlanRouteSegmentData *)buildSegmentWithIndex:(NSInteger)segmentIndex
                                     pointIndexes:(NSArray<NSNumber *> *)pointIndexes
                                        allPoints:(NSArray<OASWptPt *> *)allPoints;
- (OAPlanRouteGroupData *)buildGroupWithKey:(NSString *)key
                                    indexes:(NSArray<NSNumber *> *)indexes
                                  allPoints:(NSArray<OASWptPt *> *)allPoints;
- (void)performSaveWithFileName:(NSString *)fileName
                         folder:(nullable NSString *)folder
                      showOnMap:(BOOL)showOnMap
                     asCopy:(BOOL)asCopy
                     onComplete:(void (^)(BOOL success, NSString * _Nullable outPath))onComplete;

@end

@implementation OAPlanRoutePointData

- (instancetype)initWithGlobalIndex:(NSInteger)globalIndex
                               name:(NSString *)name
               distanceFromPrevious:(double)distanceFromPrevious
                            bearing:(double)bearing
                            isStart:(BOOL)isStart
                      isDestination:(BOOL)isDestination
{
    self = [super init];
    if (self)
    {
        _globalIndex = globalIndex;
        _name = [name copy];
        _distanceFromPrevious = distanceFromPrevious;
        _bearing = bearing;
        _isStart = isStart;
        _isDestination = isDestination;
    }
    return self;
}

@end

@implementation OAPlanRouteGroupData

- (instancetype)initWithAppMode:(OAApplicationMode *)appMode
                       distance:(double)distance
                lastGlobalIndex:(NSInteger)lastGlobalIndex
                         points:(NSArray<OAPlanRoutePointData *> *)points
{
    self = [super init];
    if (self)
    {
        _appMode = appMode;
        _distance = distance;
        _lastGlobalIndex = lastGlobalIndex;
        _points = points;
    }
    return self;
}

@end

@implementation OAPlanRouteSegmentData

- (instancetype)initWithIndex:(NSInteger)index
                       routed:(BOOL)routed
                    multiMode:(BOOL)multiMode
                   singleMode:(OAApplicationMode *)singleMode
                     distance:(double)distance
                       groups:(NSArray<OAPlanRouteGroupData *> *)groups
{
    self = [super init];
    if (self)
    {
        _index = index;
        _routed = routed;
        _multiMode = multiMode;
        _singleMode = singleMode;
        _distance = distance;
        _groups = groups;
    }
    return self;
}

@end

@implementation OAPlanRouteEditingBridge

- (OAMeasurementToolLayer *)layer
{
    return OARootViewController.instance.mapPanel.mapViewController.mapLayers.routePlanningLayer;
}

- (OAMeasurementEditingContext *)editingContext
{
    return [self layer].editingCtx;
}

- (BOOL)hasContext
{
    return [self editingContext] != nil;
}

- (BOOL)hasPoints
{
    return [self editingContext].getPoints.count > 0;
}

- (BOOL)isAddNewSegmentAllowed
{
    OAMeasurementEditingContext *ctx = [self editingContext];
    return ctx != nil && [ctx isAddNewSegmentAllowed];
}

- (BOOL)hasChanges
{
    OAMeasurementEditingContext *ctx = [self editingContext];
    return ctx != nil && [ctx hasChanges];
}

- (BOOL)canUndo
{
    OAMeasurementEditingContext *ctx = [self editingContext];
    return ctx != nil && [ctx.commandManager canUndo];
}

- (BOOL)canRedo
{
    OAMeasurementEditingContext *ctx = [self editingContext];
    return ctx != nil && [ctx.commandManager canRedo];
}

- (BOOL)hasRoute
{
    OAMeasurementEditingContext *ctx = [self editingContext];
    return ctx != nil && [ctx hasRoute];
}

- (double)routeDistance
{
    OAMeasurementEditingContext *ctx = [self editingContext];
    return ctx != nil ? [ctx getRouteDistance] : 0;
}

- (NSArray<OAApplicationMode *> *)availableModes
{
    return [[OAApplicationMode values] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(OAApplicationMode *mode, NSDictionary *bindings) {
        return mode != [OAApplicationMode DEFAULT];
    }]];
}

- (void)addCenterPoint
{
    OAMeasurementToolLayer *layer = [self layer];
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx == nil)
        return;
    [ctx.commandManager execute:[[OAAddPointCommand alloc] initWithLayer:layer center:YES]];
    [layer updateLayer];
}

- (void)setCrosshairScreenPoint:(CGPoint)point
{
    OAMeasurementToolLayer *layer = [self layer];
    if (layer == nil)
        return;
    layer.cursorScreenPoint = point;
    [layer updateLayer];
}

- (void)dismiss
{
    OAMeasurementToolLayer *layer = [self layer];
    if (layer == nil)
        return;
    layer.cursorScreenPoint = CGPointZero;
    layer.editingCtx = nil;
    [layer resetLayer];
}

- (void)prepareNewRoute
{
    OAMeasurementToolLayer *layer = [self layer];
    if (layer == nil)
        return;
    OAMeasurementEditingContext *ctx = [[OAMeasurementEditingContext alloc] init];
    layer.editingCtx = ctx;
    layer.delegate = self;
    [ctx.commandManager setMeasurementLayer:layer];
    [layer updateLayer];
}

- (void)openTrackWithFilePath:(NSString *)filePath
{
    OAMeasurementToolLayer *layer = [self layer];
    if (layer == nil)
        return;

    OAMeasurementEditingContext *ctx = [[OAMeasurementEditingContext alloc] init];

    OASGpxFile *gpxFile = nil;
    if (filePath.length > 0)
    {
        OASKFile *file = [[OASKFile alloc] initWithFilePath:filePath];
        gpxFile = [OASGpxUtilities.shared loadGpxFileFile:file];
    }
    OAGpxData *gpxData = gpxFile != nil ? [[OAGpxData alloc] initWithFile:gpxFile] : nil;
    ctx.gpxData = gpxData;

    NSArray<OASWptPt *> *routePoints = gpxData.gpxFile.getRoutePoints;
    if (routePoints.count > 0)
    {
        OAApplicationMode *appMode = [OAApplicationMode valueOfStringKey:routePoints.lastObject.getProfileType def:nil];
        if (appMode != nil)
            ctx.appMode = appMode;
    }

    layer.editingCtx = ctx;
    layer.delegate = self;
    [ctx.commandManager setMeasurementLayer:layer];
    [ctx addPoints];
    [layer updateLayer];
}

- (double)distanceFrom:(OASWptPt *)from to:(OASWptPt *)to
{
    return [OAMapUtils getDistance:from.lat lon1:from.lon lat2:to.lat lon2:to.lon];
}

- (double)bearingFrom:(OASWptPt *)from to:(OASWptPt *)to
{
    double lat1 = from.lat * M_PI / 180.0;
    double lat2 = to.lat * M_PI / 180.0;
    double deltaLon = (to.lon - from.lon) * M_PI / 180.0;
    double y = sin(deltaLon) * cos(lat2);
    double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon);
    double degrees = atan2(y, x) * 180.0 / M_PI;
    return fmod(degrees + 360.0, 360.0);
}

- (NSArray<OAPlanRouteSegmentData *> *)buildSegments
{
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx == nil)
        return @[];
    NSArray<OASWptPt *> *points = ctx.getPoints;
    if (points.count == 0)
        return @[];

    NSMutableArray<OAPlanRouteSegmentData *> *result = [NSMutableArray array];
    NSMutableArray<NSNumber *> *segmentIndexes = [NSMutableArray array];
    NSInteger segmentNumber = 0;
    for (NSInteger i = 0; i < (NSInteger) points.count; i++)
    {
        [segmentIndexes addObject:@(i)];
        OASWptPt *point = points[i];
        BOOL last = i == (NSInteger) points.count - 1;
        if (point.isGap || last)
        {
            [result addObject:[self buildSegmentWithIndex:segmentNumber pointIndexes:segmentIndexes allPoints:points]];
            segmentIndexes = [NSMutableArray array];
            segmentNumber++;
        }
    }
    return result;
}

- (OAPlanRouteSegmentData *)buildSegmentWithIndex:(NSInteger)segmentIndex
                                     pointIndexes:(NSArray<NSNumber *> *)pointIndexes
                                        allPoints:(NSArray<OASWptPt *> *)allPoints
{
    NSMutableArray<OAPlanRouteGroupData *> *groups = [NSMutableArray array];
    NSMutableArray<NSNumber *> *currentIndexes = [NSMutableArray array];
    NSString *currentKey = nil;
    BOOL hasCurrent = NO;

    for (NSNumber *indexNumber in pointIndexes)
    {
        NSInteger index = indexNumber.integerValue;
        NSString *key = allPoints[index].getProfileType ?: @"";
        if (!hasCurrent)
        {
            currentKey = key;
            hasCurrent = YES;
        }
        if (![key isEqualToString:currentKey] && currentIndexes.count > 0)
        {
            [groups addObject:[self buildGroupWithKey:currentKey indexes:currentIndexes allPoints:allPoints]];
            currentIndexes = [NSMutableArray array];
            currentKey = key;
        }
        [currentIndexes addObject:indexNumber];
    }
    if (currentIndexes.count > 0)
        [groups addObject:[self buildGroupWithKey:currentKey indexes:currentIndexes allPoints:allPoints]];

    NSInteger routedCount = 0;
    OAApplicationMode *singleMode = nil;
    double distance = 0;
    for (OAPlanRouteGroupData *group in groups)
    {
        distance += group.distance;
        if (group.appMode != nil)
        {
            routedCount++;
            if (singleMode == nil)
                singleMode = group.appMode;
        }
    }
    BOOL routed = routedCount > 0;
    BOOL multiMode = routedCount > 1;
    return [[OAPlanRouteSegmentData alloc] initWithIndex:segmentIndex
                                                  routed:routed
                                               multiMode:multiMode
                                              singleMode:multiMode ? nil : singleMode
                                                distance:distance
                                                  groups:groups];
}

- (OAPlanRouteGroupData *)buildGroupWithKey:(NSString *)key
                                    indexes:(NSArray<NSNumber *> *)indexes
                                  allPoints:(NSArray<OASWptPt *> *)allPoints
{
    OAApplicationMode *appMode = nil;
    if (key.length > 0)
        appMode = [OAApplicationMode valueOfStringKey:key def:OAApplicationMode.DEFAULT];

    NSMutableArray<OAPlanRoutePointData *> *points = [NSMutableArray array];
    double groupDistance = 0;
    for (NSNumber *indexNumber in indexes)
    {
        NSInteger index = indexNumber.integerValue;
        OASWptPt *point = allPoints[index];
        BOOL isStart = index == 0;
        BOOL isDestination = index == (NSInteger) allPoints.count - 1;
        double legDistance = 0;
        double bearing = 0;
        if (index > 0)
        {
            OASWptPt *previous = allPoints[index - 1];
            if (!previous.isGap)
            {
                legDistance = [self distanceFrom:previous to:point];
                bearing = [self bearingFrom:previous to:point];
                groupDistance += legDistance;
            }
        }
        NSString *name = point.name.length > 0 ? point.name : [NSString stringWithFormat:@"%@ - %ld", OALocalizedString(@"shared_string_point"), (long) (index + 1)];
        [points addObject:[[OAPlanRoutePointData alloc] initWithGlobalIndex:index
                                                                       name:name
                                                       distanceFromPrevious:legDistance
                                                                    bearing:bearing
                                                                    isStart:isStart
                                                              isDestination:isDestination]];
    }
    NSInteger lastIndex = indexes.lastObject.integerValue;
    return [[OAPlanRouteGroupData alloc] initWithAppMode:appMode distance:groupDistance lastGlobalIndex:lastIndex points:points];
}

- (void)deletePointAtIndex:(NSInteger)index
{
    OAMeasurementToolLayer *layer = [self layer];
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx == nil)
        return;
    [ctx.commandManager execute:[[OARemovePointCommand alloc] initWithLayer:layer position:index]];
    [layer updateLayer];
}

- (void)movePointFrom:(NSInteger)from to:(NSInteger)to
{
    OAMeasurementToolLayer *layer = [self layer];
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx == nil || from == to)
        return;
    [ctx.commandManager execute:[[OAReorderPointCommand alloc] initWithLayer:layer from:from to:to]];
    [layer updateLayer];
}

- (void)deleteSegmentWithPointIndexes:(NSArray<NSNumber *> *)indexes
{
    OAMeasurementToolLayer *layer = [self layer];
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx == nil)
        return;
    NSArray<NSNumber *> *sorted = [indexes sortedArrayUsingComparator:^NSComparisonResult(NSNumber *a, NSNumber *b) {
        return [b compare:a];
    }];
    for (NSNumber *indexNumber in sorted)
        [ctx.commandManager execute:[[OARemovePointCommand alloc] initWithLayer:layer position:indexNumber.integerValue]];
    [layer updateLayer];
}

- (void)startNewSegment
{
    OAMeasurementToolLayer *layer = [self layer];
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx == nil || ctx.getPointsCount == 0)
        return;
    ctx.selectedPointPosition = ctx.getPointsCount - 1;
    [ctx.commandManager execute:[[OASplitPointsCommand alloc] initWithLayer:layer after:YES]];
    ctx.selectedPointPosition = -1;
    [layer updateLayer];
}

- (void)undo
{
    OAMeasurementToolLayer *layer = [self layer];
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx == nil || ![ctx.commandManager canUndo])
        return;
    [ctx.commandManager undo];
    [layer updateLayer];
}

- (void)redo
{
    OAMeasurementToolLayer *layer = [self layer];
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx == nil || ![ctx.commandManager canRedo])
        return;
    [ctx.commandManager redo];
    [layer updateLayer];
}

- (void)applyMode:(OAApplicationMode *)mode pointIndex:(NSInteger)pointIndex wholeRoute:(BOOL)wholeRoute
{
    OAMeasurementToolLayer *layer = [self layer];
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx == nil)
        return;
    ctx.appMode = mode;
    EOAChangeRouteType type = wholeRoute ? EOAChangeRouteWhole : EOAChangeRouteNextSegment;
    [ctx.commandManager execute:[[OAChangeRouteModeCommand alloc] initWithLayer:layer appMode:mode changeRouteType:type pointIndex:pointIndex]];
    [layer updateLayer];
}

- (void)selectPointAtIndex:(NSInteger)index
{
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx == nil)
        return;
    ctx.selectedPointPosition = index;
}

- (double)distanceToMapCenter
{
    return _distanceToMapCenter;
}

- (double)bearingToMapCenter
{
    return _bearingToMapCenter;
}

- (void)reverseRoute
{
    OAMeasurementToolLayer *layer = [self layer];
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx == nil || ctx.getPointsCount < 2)
        return;
    [ctx.commandManager execute:[[OAReversePointsCommand alloc] initWithLayer:layer]];
    [layer updateLayer];
    if (self.onChange)
        self.onChange();
}

- (void)clearAllPoints
{
    OAMeasurementToolLayer *layer = [self layer];
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx == nil)
        return;
    [ctx.commandManager execute:[[OAClearPointsCommand alloc] initWithMeasurementLayer:layer mode:EOAClearPointsModeAll]];
    [ctx cancelSnapToRoad];
    [layer updateLayer];
    if (self.onChange)
        self.onChange();
}

- (void)saveAs:(NSString *)fileName
        folder:(nullable NSString *)folder
     showOnMap:(BOOL)showOnMap
    onComplete:(void (^)(BOOL success, NSString * _Nullable outPath))onComplete
{
    [self performSaveWithFileName:fileName folder:folder showOnMap:showOnMap asCopy:NO onComplete:onComplete];
}

- (void)saveAsCopy:(NSString *)fileName
            folder:(nullable NSString *)folder
         showOnMap:(BOOL)showOnMap
        onComplete:(void (^)(BOOL success, NSString * _Nullable outPath))onComplete
{
    [self performSaveWithFileName:fileName folder:folder showOnMap:showOnMap asCopy:YES onComplete:onComplete];
}

- (void)performSaveWithFileName:(NSString *)fileName
                         folder:(nullable NSString *)folder
                      showOnMap:(BOOL)showOnMap
                         asCopy:(BOOL)asCopy
                     onComplete:(void (^)(BOOL success, NSString * _Nullable outPath))onComplete
{
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx == nil)
    {
        if (onComplete) onComplete(NO, nil);
        return;
    }
    NSString *trackName = fileName.length > 0 ? fileName : OALocalizedString(@"quick_action_new_route");
    OASGpxFile *gpx = [ctx exportGpx:trackName];
    if (gpx == nil)
    {
        if (onComplete) onComplete(NO, nil);
        return;
    }
    NSString *gpxRootPath = OsmAndApp.instance.gpxPath;
    NSString *folderPath = (folder.length > 0) ? [gpxRootPath stringByAppendingPathComponent:folder] : gpxRootPath;
    NSString *outFile = [[folderPath stringByAppendingPathComponent:trackName] stringByAppendingPathExtension:@"gpx"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        OASKFile *file = [[OASKFile alloc] initWithFilePath:outFile];
        OASKException *exception = [OASGpxUtilities.shared writeGpxFileFile:file gpxFile:gpx];
        BOOL success = (exception == nil);
        if (success)
        {
            gpx.path = outFile;
            OAGPXDatabase *gpxDb = OAGPXDatabase.sharedDb;
            NSString *gpxFilePath = [OAUtilities getGpxShortPath:outFile];
            OASGpxDataItem *item = [gpxDb getGPXItem:gpxFilePath];
            if (!item)
                item = [gpxDb addGPXFileToDBIfNeeded:gpxFilePath];
            [gpxDb updateDataItem:item];
            if (!asCopy)
            {
                OAGpxData *gpxData = [[OAGpxData alloc] initWithFile:gpx];
                ctx.gpxData = gpxData;
                [ctx setChangesSaved];
            }
            if (showOnMap)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[OAAppSettings sharedManager] showGpx:@[gpxFilePath]];
                });
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (onComplete) onComplete(success, success ? outFile : nil);
        });
    });
}

- (void)enterNavigationWithTrackName:(NSString *)trackName
{
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx == nil)
        return;
    NSString *name = trackName.length > 0 ? trackName : OALocalizedString(@"quick_action_new_route");
    OASGpxFile *gpx = [ctx exportGpx:name];
    if (gpx == nil)
        return;
    NSString *outFile = [[OsmAndApp.instance.gpxPath stringByAppendingPathComponent:name] stringByAppendingPathExtension:@"gpx"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        OASKFile *file = [[OASKFile alloc] initWithFilePath:outFile];
        [OASGpxUtilities.shared writeGpxFileFile:file gpxFile:gpx];
        gpx.path = outFile;
        dispatch_async(dispatch_get_main_queue(), ^{
            [OARootViewController.instance.mapPanel.mapActions enterRoutePlanningModeGivenGpx:gpx
                                                                                         path:outFile
                                                                                         from:nil
                                                                                     fromName:nil
                                                                 useIntermediatePointsByDefault:YES
                                                                                   showDialog:YES];
        });
    });
}

- (void)sortSegmentDoorToDoorWithPointIndexes:(NSArray<NSNumber *> *)indexes
{
    OAMeasurementToolLayer *layer = [self layer];
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx == nil || indexes.count < 3)
        return;

    NSArray<OASWptPt *> *points = ctx.getPoints;
    NSMutableArray<NSNumber *> *remaining = [NSMutableArray arrayWithArray:[indexes subarrayWithRange:NSMakeRange(1, indexes.count - 1)]];
    NSMutableArray<NSNumber *> *ordered = [NSMutableArray arrayWithObject:indexes.firstObject];
    NSInteger currentIndex = indexes.firstObject.integerValue;
    while (remaining.count > 0)
    {
        NSInteger bestPosition = 0;
        double bestDistance = DBL_MAX;
        for (NSInteger i = 0; i < (NSInteger) remaining.count; i++)
        {
            double dist = [self distanceFrom:points[currentIndex] to:points[remaining[i].integerValue]];
            if (dist < bestDistance)
            {
                bestDistance = dist;
                bestPosition = i;
            }
        }
        NSNumber *next = remaining[bestPosition];
        [remaining removeObjectAtIndex:bestPosition];
        [ordered addObject:next];
        currentIndex = next.integerValue;
    }

    NSInteger base = indexes.firstObject.integerValue;
    for (NSInteger target = 0; target < (NSInteger) ordered.count; target++)
    {
        NSInteger from = ordered[target].integerValue;
        NSInteger to = base + target;
        if (from != to)
            [ctx.commandManager execute:[[OAReorderPointCommand alloc] initWithLayer:layer from:from to:to]];
    }
    [layer updateLayer];
}

#pragma mark - OAMeasurementLayerDelegate

- (void)onMeasure:(double)distance bearing:(double)bearing
{
    _distanceToMapCenter = distance;
    _bearingToMapCenter = bearing;
    if (self.onChange)
        self.onChange();
}

- (void)onTouch:(CLLocationCoordinate2D)coordinate longPress:(BOOL)longPress
{
    if (longPress)
        return;
    OAMeasurementToolLayer *layer = [self layer];
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx == nil)
        return;
    layer.pressPointLocation = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
    [ctx.commandManager execute:[[OAAddPointCommand alloc] initWithLayer:layer center:NO]];
    [layer updateLayer];
    if (self.onChange)
        self.onChange();
}

@end
