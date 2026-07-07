//
//  OAPlanRouteEditingBridge.mm
//  OsmAnd Maps
//
//  Created by OsmAnd on 17.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import "OAPlanRouteEditingBridge.h"
#import "OAPointOptionsBottomSheetViewController.h"
#import <CoreLocation/CoreLocation.h>
#import "Localization.h"
#import "OARootViewController.h"
#import "OAMapRendererView.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
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
#import "OAEditPointViewController.h"
#import "OAEditWaypointsGroupOptionsViewController.h"
#import "OANativeUtilities.h"
#import "OAGpxWptItem.h"
#import "OASelectedGPXHelper.h"
#import "OADefaultFavorite.h"
#import "OAGPXAppearanceCollection.h"
#import "OARouteStatistics.h"
#import "OARouteStatisticsHelper.h"
#import "OARoadSegmentData.h"
#import "OAGpxApproximationHelper.h"
#import "OAGpxApproximationParams.h"
#import "OALocationsHolder.h"
#import "OAApplyGpxApproximationCommand.h"

@class OAMeasurementToolLayer, OAMeasurementEditingContext;

@interface OAPlanRoutePoiStateSnapshot : NSObject

@property (nonatomic, readonly) NSArray<OASWptPt *> *gpxPoints;
@property (nonatomic, readonly) NSDictionary<NSString *, OASGpxUtilitiesPointsGroup *> *gpxGroups;
@property (nonatomic, readonly) BOOL hasDraftGpx;
@property (nonatomic, readonly) NSArray<OASWptPt *> *draftPoints;
@property (nonatomic, readonly) NSDictionary<NSString *, OASGpxUtilitiesPointsGroup *> *draftGroups;

- (instancetype)initWithGpxFile:(nullable OASGpxFile *)gpxFile draftGpxFile:(nullable OASGpxFile *)draftGpxFile;
+ (NSArray<OASWptPt *> *)copyPointsFromGpxFile:(nullable OASGpxFile *)gpxFile;
+ (NSDictionary<NSString *, OASGpxUtilitiesPointsGroup *> *)copyGroupsFromGpxFile:(nullable OASGpxFile *)gpxFile;
+ (OASGpxUtilitiesPointsGroup *)copyGroup:(OASGpxUtilitiesPointsGroup *)group;

@end

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

@interface OAPlanRouteEditingBridge () <OAMeasurementLayerDelegate, OAPointOptionsBottmSheetDelegate, OAGpxWptEditingHandlerDelegate, OAEditWaypointsGroupOptionsDelegate, OAGpxApproximationHelperDelegate, OASnapToRoadProgressDelegate>
{
    OASGpxFile *_draftGpxFile;
    NSString *_draftGpxPath;
    NSString *_editingPoiGroupName;
    OAPlanRoutePoiStateSnapshot *_initialPoiStateSnapshot;
    OAPlanRoutePoiStateSnapshot *_editingPoiStateSnapshot;
    double _distanceToMapCenter;
    double _bearingToMapCenter;
    OAGpxApproximationHelper *_elevationHelper;
    BOOL _isCalculatingElevation;
    BOOL _isCalculatingRoute;
    NSUInteger _elevationCalculationRequestId;
    OASGpxFile *_terrainElevationGpxFile;
    NSUInteger _pointsVersion;
    NSUInteger _terrainElevationVersion;
}

- (OAMeasurementToolLayer *)layer;
- (OAMeasurementEditingContext *)editingContext;
- (double)distanceFrom:(OASWptPt *)from to:(OASWptPt *)to;
- (double)bearingFrom:(OASWptPt *)from to:(OASWptPt *)to;
- (CLLocationCoordinate2D)crosshairLocation;
- (NSString *)absoluteGpxPathFromPath:(NSString *)filePath;
- (nullable OASGpxFile *)activeGpxFileForPath:(NSString *)path fallbackPath:(nullable NSString *)fallbackPath;
- (BOOL)isDraftGpxPath:(NSString *)filePath;
- (OASGpxFile *)gpxFileForWaypoints;
- (NSString *)poiGroupKeyForName:(NSString *)groupName;
- (void)addPoiGroupNamesFromGpx:(nullable OASGpxFile *)gpxFile toSet:(NSMutableOrderedSet<NSString *> *)groupNames;
- (BOOL)addPoiGroupToGpx:(nullable OASGpxFile *)gpxFile groupName:(NSString *)groupName;
- (BOOL)renamePoiGroupInGpx:(nullable OASGpxFile *)gpxFile
                    fromKey:(NSString *)oldKey
                      toKey:(NSString *)newKey
                displayName:(NSString *)displayName;
- (BOOL)deletePoiGroupInGpx:(nullable OASGpxFile *)gpxFile groupKey:(NSString *)groupKey;
- (BOOL)performAddPoiGroup:(NSString *)groupName;
- (BOOL)performRenamePoiGroupFromName:(NSString *)oldName toName:(NSString *)newName;
- (BOOL)performDeletePoiGroupWithName:(NSString *)groupName;
- (BOOL)performChangePoiGroupAppearanceForName:(NSString *)groupName color:(UIColor *)color;
- (BOOL)performSaveGpxWpt:(OAGpxWptItem *)gpxWpt gpxFileName:(NSString *)gpxFileName;
- (BOOL)performDeleteGpxWpt:(OAGpxWptItem *)gpxWptItem docPath:(NSString *)docPath;
- (void)executePoiStateCommandWithBeforeState:(nullable OAPlanRoutePoiStateSnapshot *)beforeState operation:(BOOL (^)(void))operation;
- (void)commitPoiStateCommandFromState:(nullable OAPlanRoutePoiStateSnapshot *)beforeState toState:(nullable OAPlanRoutePoiStateSnapshot *)afterState;
- (OAPlanRoutePoiStateSnapshot *)makePoiStateSnapshot;
- (void)restorePoiStateSnapshot:(OAPlanRoutePoiStateSnapshot *)state;
- (void)applyPoiStateSnapshot:(OAPlanRoutePoiStateSnapshot *)state toGpxFile:(OASGpxFile *)gpxFile draft:(BOOL)draft;
- (void)syncActiveGpxPoiStateFromGpxFile:(OASGpxFile *)gpxFile;
- (void)addPoiGroupsFromGpx:(nullable OASGpxFile *)sourceGpx toGpx:(OASGpxFile *)targetGpx;
- (void)ensurePoiGroupForPoint:(OASWptPt *)point inGpx:(OASGpxFile *)gpxFile;
- (NSInteger)getPoiGroupColor:(NSString *)groupName;
- (NSArray<OAGpxWptItem *> *)changePoiGroupAppearanceInGpx:(nullable OASGpxFile *)gpxFile
                                                  groupKey:(NSString *)groupKey
                                                     color:(UIColor *)color;
- (BOOL)changePoiGroupMetadataAppearanceInGpx:(nullable OASGpxFile *)gpxFile
                                     groupKey:(NSString *)groupKey
                                        color:(UIColor *)color;
- (void)refreshDraftGpx;
- (void)clearDraftGpx;
- (void)addDraftWaypointsToGpx:(OASGpxFile *)gpx;
- (OAPlanRouteSegmentData *)buildSegmentWithIndex:(NSInteger)segmentIndex
                                     pointIndexes:(NSArray<NSNumber *> *)pointIndexes
                                        allPoints:(NSArray<OASWptPt *> *)allPoints;
- (OAPlanRouteGroupData *)buildGroupWithKey:(NSString *)key
                                    indexes:(NSArray<NSNumber *> *)indexes
                                  allPoints:(NSArray<OASWptPt *> *)allPoints;
- (BOOL)shouldShowRouteCalculationStateForContext:(nullable OAMeasurementEditingContext *)ctx;
- (void)beginRouteCalculationIfNeededForContext:(nullable OAMeasurementEditingContext *)ctx;
- (void)performSaveWithFileName:(NSString *)fileName
                         folder:(nullable NSString *)folder
                      showOnMap:(BOOL)showOnMap
                     asCopy:(BOOL)asCopy
                     onComplete:(void (^)(BOOL success, NSString * _Nullable outPath))onComplete;

@end

@interface OAPlanRoutePoiStateCommand : OAMeasurementModeCommand

- (instancetype)initWithLayer:(OAMeasurementToolLayer *)measurementLayer
                       bridge:(OAPlanRouteEditingBridge *)bridge
                  beforeState:(OAPlanRoutePoiStateSnapshot *)beforeState
                   afterState:(OAPlanRoutePoiStateSnapshot *)afterState;

@end

@implementation OAPlanRoutePoiStateSnapshot

- (instancetype)initWithGpxFile:(nullable OASGpxFile *)gpxFile draftGpxFile:(nullable OASGpxFile *)draftGpxFile
{
    self = [super init];
    if (self)
    {
        _gpxPoints = [self.class copyPointsFromGpxFile:gpxFile];
        _gpxGroups = [self.class copyGroupsFromGpxFile:gpxFile];
        _hasDraftGpx = draftGpxFile != nil;
        _draftPoints = [self.class copyPointsFromGpxFile:draftGpxFile];
        _draftGroups = [self.class copyGroupsFromGpxFile:draftGpxFile];
    }
    
    return self;
}

+ (NSArray<OASWptPt *> *)copyPointsFromGpxFile:(nullable OASGpxFile *)gpxFile
{
    if (gpxFile == nil)
        return @[];
    
    NSMutableArray<OASWptPt *> *points = [NSMutableArray array];
    for (OASWptPt *point in gpxFile.getPointsList)
    {
        [points addObject:[[OASWptPt alloc] initWithWptPt:point]];
    }
    
    return points;
}

+ (NSDictionary<NSString *, OASGpxUtilitiesPointsGroup *> *)copyGroupsFromGpxFile:(nullable OASGpxFile *)gpxFile
{
    if (gpxFile == nil)
        return @{};
    
    NSMutableDictionary<NSString *, OASGpxUtilitiesPointsGroup *> *groups = [NSMutableDictionary dictionary];
    [gpxFile.pointsGroups enumerateKeysAndObjectsUsingBlock:^(NSString *key, OASGpxUtilitiesPointsGroup *group, BOOL *stop) {
        groups[key] = [self copyGroup:group];
    }];

    return groups;
}

+ (OASGpxUtilitiesPointsGroup *)copyGroup:(OASGpxUtilitiesPointsGroup *)group
{
    OASGpxUtilitiesPointsGroup *copy = [[OASGpxUtilitiesPointsGroup alloc] initWithName:group.name iconName:group.iconName backgroundType:group.backgroundType color:group.color hidden:group.hidden];
    NSMutableArray<OASWptPt *> *points = [NSMutableArray array];
    for (OASWptPt *point in group.points)
    {
        [points addObject:[[OASWptPt alloc] initWithWptPt:point]];
    }
    
    copy.points = points;
    return copy;
}

@end

@implementation OAPlanRoutePoiStateCommand
{
    __weak OAPlanRouteEditingBridge *_bridge;
    OAPlanRoutePoiStateSnapshot *_beforeState;
    OAPlanRoutePoiStateSnapshot *_afterState;
}

- (instancetype)initWithLayer:(OAMeasurementToolLayer *)measurementLayer
                       bridge:(OAPlanRouteEditingBridge *)bridge
                  beforeState:(OAPlanRoutePoiStateSnapshot *)beforeState
                   afterState:(OAPlanRoutePoiStateSnapshot *)afterState
{
    self = [super initWithLayer:measurementLayer];
    if (self)
    {
        _bridge = bridge;
        _beforeState = beforeState;
        _afterState = afterState;
    }

    return self;
}

- (BOOL)execute
{
    return _bridge != nil && _beforeState != nil && _afterState != nil;
}

- (void)undo
{
    [_bridge restorePoiStateSnapshot:_beforeState];
}

- (void)redo
{
    [_bridge restorePoiStateSnapshot:_afterState];
}

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

- (void)invalidateTerrainElevationGpx
{
    _pointsVersion++;
    _terrainElevationGpxFile = nil;
}

- (OASGpxFile *)buildTerrainElevationGpx:(NSArray<OASWptPt *> *)densifiedPoints
{
    OASGpxFile *gpx = [[OASGpxFile alloc] initWithAuthor:[OAAppVersion getFullVersionWithAppName]];
    OASTrack *track = [[OASTrack alloc] init];
    track.segments = [NSMutableArray array];

    NSMutableArray<OASWptPt *> *trkPoints = [NSMutableArray array];
    OASTrkSegment *segment = [[OASTrkSegment alloc] init];
    OASWptPt *previousPoint = nil;
    double cumulativeDistance = 0;

    for (OASWptPt *point in densifiedPoints)
    {
        if (point.isGap)
        {
            if (trkPoints.count > 0)
            {
                segment.points = trkPoints;
                [track.segments addObject:segment];
            }
            trkPoints = [NSMutableArray array];
            segment = [[OASTrkSegment alloc] init];
            previousPoint = nil;
            cumulativeDistance = 0;
            continue;
        }
        OASWptPt *trkPoint = [[OASWptPt alloc] initWithWptPt:point];
        if (previousPoint != nil)
            cumulativeDistance += [self distanceFrom:previousPoint to:point];
        else
            cumulativeDistance = 0;
        trkPoint.distance = cumulativeDistance;
        [trkPoints addObject:trkPoint];
        previousPoint = point;
    }
    if (trkPoints.count > 0)
    {
        segment.points = trkPoints;
        [track.segments addObject:segment];
    }
    gpx.tracks = [@[track] mutableCopy];
    return gpx;
}

- (BOOL)hasContext
{
    return [self editingContext] != nil;
}

- (BOOL)hasPoints
{
    return [self editingContext].getPoints.count > 0;
}

- (OASGpxFile *)currentGpxFile
{
    return [self editingContext].gpxData.gpxFile;
}

- (OASGpxFile *)exportedGpxFile
{
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx == nil || ctx.getPointsCount == 0)
        return nil;
    if (_terrainElevationGpxFile != nil && _terrainElevationVersion == _pointsVersion)
        return _terrainElevationGpxFile;
    return [ctx exportGpx:@"tmp_analyze"];
}

- (BOOL)isAddNewSegmentAllowed
{
    OAMeasurementEditingContext *ctx = [self editingContext];
    return ctx != nil && [ctx isAddNewSegmentAllowed];
}

- (nullable OAApplicationMode *)defaultAppMode
{
    OAApplicationMode *mode = [self editingContext].appMode;
    return (mode == OAApplicationMode.DEFAULT) ? nil : mode;
}

- (void)clearAppMode
{
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx != nil)
        ctx.appMode = OAApplicationMode.DEFAULT;
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
        return mode != [OAApplicationMode DEFAULT] && ![@"public_transport" isEqualToString:[mode getRoutingProfile]];
    }]];
}

- (void)addCenterPoint
{
    OAMeasurementToolLayer *layer = [self layer];
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx == nil)
        return;
    [self invalidateTerrainElevationGpx];
    [self beginRouteCalculationIfNeededForContext:ctx];
    [ctx.commandManager execute:[[OAAddPointCommand alloc] initWithLayer:layer center:YES]];
    [layer updateLayer];
    if (self.onChange)
        self.onChange();
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
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx != nil && [ctx hasChanges] && _initialPoiStateSnapshot != nil)
        [self restorePoiStateSnapshot:_initialPoiStateSnapshot];
    
    _initialPoiStateSnapshot = nil;
    _editingPoiStateSnapshot = nil;
    [self clearDraftGpx];
    _isCalculatingRoute = NO;
    OAMeasurementToolLayer *layer = [self layer];
    if (layer == nil)
        return;
    ctx.progressDelegate = nil;
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
    ctx.progressDelegate = self;
    layer.editingCtx = ctx;
    layer.delegate = self;
    _initialPoiStateSnapshot = nil;
    _editingPoiStateSnapshot = nil;
    _isCalculatingRoute = NO;
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
        NSString *absolutePath = filePath.isAbsolutePath ? filePath : [OsmAndApp.instance.gpxPath stringByAppendingPathComponent:filePath];
        OASGpxFile *selectedFile = [OASelectedGPXHelper.instance activeGpx][absolutePath.lastPathComponent];
        if (selectedFile)
    {
            gpxFile = selectedFile;
        }
        else
        {
            OASKFile *file = [[OASKFile alloc] initWithFilePath:absolutePath];
        gpxFile = [OASGpxUtilities.shared loadGpxFileFile:file];
        }
        if (gpxFile)
        {
            if (!gpxFile.routes)
                gpxFile.routes = [NSMutableArray new];
            if (!gpxFile.tracks)
                gpxFile.tracks = [NSMutableArray new];
            if (!gpxFile.getPointsList)
                [gpxFile clearPoints];
        }
    }
    OAGpxData *gpxData = gpxFile != nil ? [[OAGpxData alloc] initWithFile:gpxFile] : nil;
    ctx.gpxData = gpxData;
    ctx.progressDelegate = self;
    _initialPoiStateSnapshot = gpxFile != nil ? [[OAPlanRoutePoiStateSnapshot alloc] initWithGpxFile:gpxFile draftGpxFile:nil] : nil;
    _editingPoiStateSnapshot = nil;
    _isCalculatingRoute = NO;

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

- (NSArray<OAGpxWptItem *> *)buildPoiItems
{
    NSMutableArray<OAGpxWptItem *> *items = [NSMutableArray array];
    OASGpxFile *gpxFile = [self editingContext].gpxData.gpxFile;
    NSString *gpxPath = [self absoluteGpxPathFromPath:gpxFile.path];
    for (OASWptPt *point in gpxFile.getPointsList)
    {
        OAGpxWptItem *item = [OAGpxWptItem withGpxWpt:point];
        item.docPath = gpxPath;
        [items addObject:item];
    }
    
    for (OASWptPt *point in _draftGpxFile.getPointsList)
    {
        OAGpxWptItem *item = [OAGpxWptItem withGpxWpt:point];
        item.docPath = _draftGpxPath;
        [items addObject:item];
    }
    
    return items;
}

- (NSArray<NSString *> *)buildPoiGroupNames
{
    NSMutableOrderedSet<NSString *> *groupNames = [NSMutableOrderedSet orderedSet];
    [self addPoiGroupNamesFromGpx:[self editingContext].gpxData.gpxFile toSet:groupNames];
    [self addPoiGroupNamesFromGpx:_draftGpxFile toSet:groupNames];
    return groupNames.array;
}

- (void)addPoiGroup:(NSString *)groupName
{
    [self executePoiStateCommandWithBeforeState:nil operation:^BOOL{
        return [self performAddPoiGroup:groupName];
    }];
}

- (void)renamePoiGroupFromName:(NSString *)oldName toName:(NSString *)newName
{
    [self executePoiStateCommandWithBeforeState:nil operation:^BOOL{
        return [self performRenamePoiGroupFromName:oldName toName:newName];
    }];
}

- (void)openPoiGroupAppearanceForName:(NSString *)groupName presentingViewController:(UIViewController *)presentingViewController
{
    if (presentingViewController == nil || groupName.length == 0)
        return;
    
    _editingPoiGroupName = groupName;
    UIColor *groupColor = UIColorFromARGB([self getPoiGroupColor:groupName]);
    OAEditWaypointsGroupOptionsViewController *controller = [[OAEditWaypointsGroupOptionsViewController alloc] initWithScreenType:EOAEditWaypointsGroupColorScreen groupName:groupName groupColor:groupColor];
    controller.delegate = self;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
    [presentingViewController presentViewController:navigationController animated:YES completion:nil];
}

- (void)deletePoiGroupWithName:(NSString *)groupName
{
    [self executePoiStateCommandWithBeforeState:nil operation:^BOOL{
        return [self performDeletePoiGroupWithName:groupName];
    }];
}

- (void)deletePoiPoint:(OAGpxWptItem *)point
{
    [self deleteGpxWpt:point docPath:point.docPath];
}

- (void)openEditPoiPoint:(OAGpxWptItem *)point presentingViewController:(UIViewController *)presentingViewController
{
    if (point == nil || presentingViewController == nil)
        return;

    _editingPoiStateSnapshot = [self makePoiStateSnapshot];
    OAEditPointViewController *controller = [[OAEditPointViewController alloc] initWithGpxWpt:point];
    controller.gpxWptDelegate = self;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
    [presentingViewController presentViewController:navigationController animated:YES completion:nil];
}

- (BOOL)performAddPoiGroup:(NSString *)groupName
{
    NSString *trimmedName = [groupName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmedName.length == 0)
        return NO;
    
    OASGpxFile *gpxFile = [self editingContext].gpxData.gpxFile;
    if (gpxFile.path.length > 0)
    {
        if (![self addPoiGroupToGpx:gpxFile groupName:trimmedName])
            return NO;
        
        [self syncActiveGpxPoiStateFromGpxFile:gpxFile];
        return YES;
    }
    
    OASGpxFile *draftGpx = [self gpxFileForWaypoints];
    if (![self addPoiGroupToGpx:draftGpx groupName:trimmedName])
        return NO;
    
    [self refreshDraftGpx];
    return YES;
}

- (BOOL)performRenamePoiGroupFromName:(NSString *)oldName toName:(NSString *)newName
{
    NSString *trimmedName = [newName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (oldName.length == 0 || trimmedName.length == 0)
        return NO;
    
    NSString *oldKey = [self poiGroupKeyForName:oldName];
    NSString *newKey = [self poiGroupKeyForName:trimmedName];
    if ([oldKey isEqualToString:newKey])
        return NO;
    
    OASGpxFile *gpxFile = [self editingContext].gpxData.gpxFile;
    BOOL gpxChanged = [self renamePoiGroupInGpx:gpxFile fromKey:oldKey toKey:newKey displayName:trimmedName];
    BOOL draftChanged = [self renamePoiGroupInGpx:_draftGpxFile fromKey:oldKey toKey:newKey displayName:trimmedName];
    if (gpxChanged && gpxFile.path.length > 0)
        [self syncActiveGpxPoiStateFromGpxFile:gpxFile];
    if (draftChanged)
        [self refreshDraftGpx];
    
    return gpxChanged || draftChanged;
}

- (BOOL)performDeletePoiGroupWithName:(NSString *)groupName
{
    NSString *groupKey = [self poiGroupKeyForName:groupName];
    OASGpxFile *gpxFile = [self editingContext].gpxData.gpxFile;
    BOOL gpxChanged = [self deletePoiGroupInGpx:gpxFile groupKey:groupKey];
    if (gpxChanged && gpxFile.path.length > 0)
        [self syncActiveGpxPoiStateFromGpxFile:gpxFile];
    
    BOOL draftChanged = [self deletePoiGroupInGpx:_draftGpxFile groupKey:groupKey];
    if (draftChanged)
        [self refreshDraftGpx];

    return gpxChanged || draftChanged;
}

- (BOOL)performChangePoiGroupAppearanceForName:(NSString *)groupName color:(UIColor *)color
{
    NSString *groupKey = [self poiGroupKeyForName:groupName];
    OASGpxFile *gpxFile = [self editingContext].gpxData.gpxFile;
    BOOL gpxChanged = [self changePoiGroupAppearanceInGpx:gpxFile groupKey:groupKey color:color].count > 0;
    gpxChanged = [self changePoiGroupMetadataAppearanceInGpx:gpxFile groupKey:groupKey color:color] || gpxChanged;
    BOOL draftChanged = [self changePoiGroupAppearanceInGpx:_draftGpxFile groupKey:groupKey color:color].count > 0;
    draftChanged = [self changePoiGroupMetadataAppearanceInGpx:_draftGpxFile groupKey:groupKey color:color] || draftChanged;
    if (!gpxChanged && !draftChanged)
        return NO;

    OAGPXAppearanceCollection *appearanceCollection = [OAGPXAppearanceCollection sharedInstance];
    [appearanceCollection selectColor:[appearanceCollection getColorItemWithValue:[color toARGBNumber]]];
    if (gpxChanged && gpxFile.path.length > 0)
        [self syncActiveGpxPoiStateFromGpxFile:gpxFile];
    if (draftChanged)
        [self refreshDraftGpx];
    
    return YES;
}

- (BOOL)performSaveGpxWpt:(OAGpxWptItem *)gpxWpt gpxFileName:(NSString *)gpxFileName
{
    if (gpxWpt.point == nil)
        return NO;
    
    if (![self isDraftGpxPath:gpxFileName])
    {
        OASGpxFile *gpxFile = [self editingContext].gpxData.gpxFile;
        if (gpxFile == nil)
            return NO;
        
        [self ensurePoiGroupForPoint:gpxWpt.point inGpx:gpxFile];
        [gpxFile addPointPoint:[[OASWptPt alloc] initWithWptPt:gpxWpt.point]];
        [self syncActiveGpxPoiStateFromGpxFile:gpxFile];
        return YES;
    }
    
    OASGpxFile *gpxFile = [self gpxFileForWaypoints];
    if (gpxFile == nil)
        return NO;
    
    [self ensurePoiGroupForPoint:gpxWpt.point inGpx:gpxFile];
    [gpxFile addPointPoint:[[OASWptPt alloc] initWithWptPt:gpxWpt.point]];
    [self refreshDraftGpx];
    return YES;
}

- (BOOL)performDeleteGpxWpt:(OAGpxWptItem *)gpxWptItem docPath:(NSString *)docPath
{
    if (gpxWptItem.point == nil)
        return NO;
    
    if (![self isDraftGpxPath:docPath])
    {
        OASGpxFile *gpxFile = [self editingContext].gpxData.gpxFile;
        if (gpxFile == nil)
            return NO;
        
        NSInteger pointsCount = gpxFile.getPointsList.count;
        [gpxFile deleteWptPtPoint:gpxWptItem.point];
        if (gpxFile.getPointsList.count == pointsCount)
            return NO;
        
        [self syncActiveGpxPoiStateFromGpxFile:gpxFile];
        return YES;
    }
    
    NSInteger pointsCount = _draftGpxFile.getPointsList.count;
    [_draftGpxFile deleteWptPtPoint:gpxWptItem.point];
    if (_draftGpxFile.getPointsList.count == pointsCount)
        return NO;
    
    [self refreshDraftGpx];
    return YES;
}

- (NSString *)poiGroupKeyForName:(NSString *)groupName
{
    return [groupName isEqualToString:OALocalizedString(@"shared_string_gpx_points")] ? @"" : (groupName ?: @"");
}

- (void)addPoiGroupNamesFromGpx:(OASGpxFile *)gpxFile toSet:(NSMutableOrderedSet<NSString *> *)groupNames
{
    if (gpxFile == nil || groupNames == nil)
        return;
    
    [gpxFile.pointsGroups enumerateKeysAndObjectsUsingBlock:^(NSString *key, OASGpxUtilitiesPointsGroup *group, BOOL *stop) {
        NSString *name = key.length == 0 ? OALocalizedString(@"shared_string_gpx_points") : group.name.length > 0 ? group.name : key;
        if (name.length > 0)
            [groupNames addObject:name];
    }];
}

- (BOOL)addPoiGroupToGpx:(OASGpxFile *)gpxFile groupName:(NSString *)groupName
{
    if (gpxFile == nil || groupName.length == 0)
        return NO;
    
    NSString *groupKey = [self poiGroupKeyForName:groupName];
    if (gpxFile.pointsGroups[groupKey] != nil)
        return NO;
    
    OASGpxUtilitiesPointsGroup *group = [[OASGpxUtilitiesPointsGroup alloc] initWithName:groupKey iconName:@"" backgroundType:@"" color:[[OADefaultFavorite getDefaultColor] toARGBNumber] hidden:NO];
    [gpxFile addPointsGroupGroup:group];
    return YES;
}

- (BOOL)renamePoiGroupInGpx:(OASGpxFile *)gpxFile
                    fromKey:(NSString *)oldKey
                      toKey:(NSString *)newKey
                displayName:(NSString *)displayName
{
    if (gpxFile == nil)
        return NO;
    
    BOOL changed = NO;
    for (OASWptPt *point in gpxFile.getPointsList)
    {
        NSString *pointKey = [self poiGroupKeyForName:point.category];
        if ([pointKey isEqualToString:oldKey])
        {
            point.category = newKey;
            changed = YES;
        }
    }
    
    if (gpxFile.pointsGroups.count > 0)
    {
        OASGpxUtilitiesPointsGroup *metaGroup = gpxFile.pointsGroups[oldKey];
        if (metaGroup)
        {
            metaGroup.name = displayName;
            [gpxFile.pointsGroups removeObjectForKey:oldKey];
            if (gpxFile.pointsGroups[newKey] == nil)
                gpxFile.pointsGroups[newKey] = metaGroup;
            
            changed = YES;
        }
    }
    
    return changed;
}

- (BOOL)deletePoiGroupInGpx:(OASGpxFile *)gpxFile groupKey:(NSString *)groupKey
{
    if (gpxFile == nil)
        return NO;

    NSArray<OASWptPt *> *points = [gpxFile.getPointsList copy];
    for (OASWptPt *point in points)
    {
        if ([[self poiGroupKeyForName:point.category] isEqualToString:groupKey])
            [gpxFile deleteWptPtPoint:point];
    }

    BOOL changed = points.count != gpxFile.getPointsList.count;
    for (NSString *key in [gpxFile.pointsGroups.allKeys copy])
    {
        OASGpxUtilitiesPointsGroup *group = gpxFile.pointsGroups[key];
        NSString *name = key.length == 0 ? OALocalizedString(@"shared_string_gpx_points") : group.name.length > 0 ? group.name : key;
        if ([[self poiGroupKeyForName:key] isEqualToString:groupKey] || [[self poiGroupKeyForName:name] isEqualToString:groupKey])
        {
            [gpxFile.pointsGroups removeObjectForKey:key];
            changed = YES;
        }
    }

    return changed;
}

- (NSInteger)getPoiGroupColor:(NSString *)groupName
{
    NSString *groupKey = [self poiGroupKeyForName:groupName];
    for (OASWptPt *point in [self editingContext].gpxData.gpxFile.getPointsList)
    {
        if ([[self poiGroupKeyForName:point.category] isEqualToString:groupKey])
            return [point getColor];
    }
    
    for (OASWptPt *point in _draftGpxFile.getPointsList)
    {
        if ([[self poiGroupKeyForName:point.category] isEqualToString:groupKey])
            return [point getColor];
    }

    OASGpxUtilitiesPointsGroup *gpxGroup = [self editingContext].gpxData.gpxFile.pointsGroups[groupKey];
    if (gpxGroup)
        return gpxGroup.color;

    OASGpxUtilitiesPointsGroup *draftGroup = _draftGpxFile.pointsGroups[groupKey];
    if (draftGroup)
        return draftGroup.color;
    
    return [[OADefaultFavorite getDefaultColor] toARGBNumber];
}

- (NSArray<OAGpxWptItem *> *)changePoiGroupAppearanceInGpx:(OASGpxFile *)gpxFile groupKey:(NSString *)groupKey color:(UIColor *)color
{
    if (gpxFile == nil || color == nil)
        return @[];
    
    NSMutableArray<OAGpxWptItem *> *changedItems = [NSMutableArray array];
    int colorValue = [color toARGBNumber];
    OASInt *colorToSave = [[OASInt alloc] initWithInt:colorValue];
    for (OASWptPt *point in gpxFile.getPointsList)
    {
        if ([[self poiGroupKeyForName:point.category] isEqualToString:groupKey] && [point getColor] != colorValue)
        {
            [point setColorColor:colorToSave];
            [changedItems addObject:[OAGpxWptItem withGpxWpt:point]];
        }
    }
    
    return changedItems;
}

- (BOOL)changePoiGroupMetadataAppearanceInGpx:(OASGpxFile *)gpxFile groupKey:(NSString *)groupKey color:(UIColor *)color
{
    OASGpxUtilitiesPointsGroup *group = gpxFile.pointsGroups[groupKey];
    int colorValue = [color toARGBNumber];
    if (group == nil || group.color == colorValue)
        return NO;
    
    OASGpxUtilitiesPointsGroup *updatedGroup = [[OASGpxUtilitiesPointsGroup alloc] initWithName:group.name iconName:group.iconName backgroundType:group.backgroundType color:colorValue hidden:group.hidden];
    updatedGroup.points = group.points;
    gpxFile.pointsGroups[groupKey] = updatedGroup;
    return YES;
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
    BOOL multiMode = groups.count > 1;
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
    {
        OAApplicationMode *mode = [OAApplicationMode valueOfStringKey:key def:OAApplicationMode.DEFAULT];
        if (mode != [OAApplicationMode DEFAULT])
            appMode = mode;
    }

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
    [self invalidateTerrainElevationGpx];
    [ctx.commandManager execute:[[OARemovePointCommand alloc] initWithLayer:layer position:index]];
    [layer updateLayer];
    if (self.onChange)
        self.onChange();
}

- (void)movePointFrom:(NSInteger)from to:(NSInteger)to
{
    OAMeasurementToolLayer *layer = [self layer];
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx == nil || from == to)
        return;
    [self invalidateTerrainElevationGpx];
    [ctx.commandManager execute:[[OAReorderPointCommand alloc] initWithLayer:layer from:from to:to]];
    [layer updateLayer];
    if (self.onChange)
        self.onChange();
}

- (void)deleteSegmentWithPointIndexes:(NSArray<NSNumber *> *)indexes
{
    OAMeasurementToolLayer *layer = [self layer];
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx == nil)
        return;
    [self invalidateTerrainElevationGpx];
    NSArray<NSNumber *> *sorted = [indexes sortedArrayUsingComparator:^NSComparisonResult(NSNumber *a, NSNumber *b) {
        return [b compare:a];
    }];
    for (NSNumber *indexNumber in sorted)
        [ctx.commandManager execute:[[OARemovePointCommand alloc] initWithLayer:layer position:indexNumber.integerValue]];
    [layer updateLayer];
    if (self.onChange)
        self.onChange();
}

- (void)startNewSegment
{
    OAMeasurementToolLayer *layer = [self layer];
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx == nil || ctx.getPointsCount == 0)
        return;
    [self invalidateTerrainElevationGpx];
    ctx.selectedPointPosition = ctx.getPointsCount - 1;
    [ctx.commandManager execute:[[OASplitPointsCommand alloc] initWithLayer:layer after:YES]];
    ctx.selectedPointPosition = -1;
    [layer updateLayer];
    if (self.onChange)
        self.onChange();
}

- (void)undo
{
    OAMeasurementToolLayer *layer = [self layer];
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx == nil || ![ctx.commandManager canUndo])
        return;
    [self invalidateTerrainElevationGpx];
    [ctx.commandManager undo];
    [layer updateLayer];
    if (self.onChange)
        self.onChange();
}

- (void)redo
{
    OAMeasurementToolLayer *layer = [self layer];
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx == nil || ![ctx.commandManager canRedo])
        return;
    [self invalidateTerrainElevationGpx];
    [ctx.commandManager redo];
    [layer updateLayer];
    if (self.onChange)
        self.onChange();
}

- (void)applyMode:(OAApplicationMode *)mode pointIndex:(NSInteger)pointIndex wholeRoute:(BOOL)wholeRoute
{
    OAMeasurementToolLayer *layer = [self layer];
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx == nil)
        return;
    [self invalidateTerrainElevationGpx];
    _isCalculatingRoute = YES;
    if (self.onChange)
        self.onChange();
    ctx.appMode = mode;
    EOAChangeRouteType type = wholeRoute ? EOAChangeRouteWhole : EOAChangeRouteNextSegment;
    [ctx.commandManager execute:[[OAChangeRouteModeCommand alloc] initWithLayer:layer appMode:mode changeRouteType:type pointIndex:pointIndex]];
    [layer updateLayer];
}

- (void)applyModeAllNextFromIndex:(NSInteger)pointIndex appMode:(nullable OAApplicationMode *)appMode
{
    OAApplicationMode *mode = appMode ?: OAApplicationMode.DEFAULT;
    OAMeasurementToolLayer *layer = [self layer];
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx == nil)
        return;
    [self invalidateTerrainElevationGpx];
    _isCalculatingRoute = YES;
    if (self.onChange)
        self.onChange();
    ctx.appMode = mode;
    [ctx.commandManager execute:[[OAChangeRouteModeCommand alloc] initWithLayer:layer appMode:mode changeRouteType:EOAChangeRouteAllNextSegments pointIndex:pointIndex]];
    [layer updateLayer];
}

- (void)selectPointAtIndex:(NSInteger)index
{
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx == nil)
        return;
    ctx.selectedPointPosition = index;
    if (self.onPointSelected)
        self.onPointSelected(index);
}

- (void)showPointOptionsAtIndex:(NSInteger)index
{
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx == nil || index < 0 || index >= ctx.getPointsCount)
        return;
    ctx.selectedPointPosition = index;
    OASWptPt *pt = ctx.getPoints[index];
    OAPointOptionsBottomSheetViewController *sheet = [[OAPointOptionsBottomSheetViewController alloc]
                                                      initWithPoint:pt
                                                      index:index
                                                      editingContext:ctx];
    sheet.delegate = self;
    UIViewController *presenter = self.presenterViewController;
    if (presenter)
        [sheet presentInViewController:presenter];
}

- (NSInteger)findNearestPointToCoordinate:(CLLocationCoordinate2D)coordinate
{
    OAMapRendererView *mapView = [OARootViewController instance].mapPanel.mapViewController.mapView;
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx == nil || ctx.getPointsCount == 0 || mapView == nil)
        return -1;

    CGPoint p0 = CGPointZero;
    CGPoint p1 = CGPointMake(0., 44.);
    OsmAnd::PointI ip0, ip1;
    [mapView convert:p0 toLocation:&ip0];
    [mapView convert:p1 toLocation:&ip1];
    OsmAnd::LatLon ll0 = OsmAnd::Utilities::convert31ToLatLon(ip0);
    OsmAnd::LatLon ll1 = OsmAnd::Utilities::convert31ToLatLon(ip1);
    double hitRadius = [OAMapUtils getDistance:ll0.latitude lon1:ll0.longitude lat2:ll1.latitude lon2:ll1.longitude];

    NSInteger nearest = -1;
    double lowestDist = hitRadius;
    for (NSInteger i = 0; i < ctx.getPointsCount; i++)
    {
        OASWptPt *pt = ctx.getPoints[i];
        double dist = [OAMapUtils getDistance:coordinate.latitude
                                         lon1:coordinate.longitude
                                         lat2:pt.getLatitude
                                         lon2:pt.getLongitude];
        if (dist < lowestDist)
        {
            lowestDist = dist;
            nearest = i;
        }
    }
    return nearest;
}

- (void)addPointBeforeIndex:(NSInteger)index
{
    OAMeasurementToolLayer *layer = [self layer];
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx == nil)
        return;
    [self invalidateTerrainElevationGpx];
    [self beginRouteCalculationIfNeededForContext:ctx];
    ctx.selectedPointPosition = index;
    [layer addCenterPoint:YES];
    if (self.onChange)
        self.onChange();
}

- (void)addPointAfterIndex:(NSInteger)index
{
    OAMeasurementToolLayer *layer = [self layer];
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx == nil)
        return;
    [self invalidateTerrainElevationGpx];
    [self beginRouteCalculationIfNeededForContext:ctx];
    ctx.selectedPointPosition = index;
    [layer addCenterPoint:NO];
    if (self.onChange)
        self.onChange();
}

- (void)trimBeforeIndex:(NSInteger)index
{
    OAMeasurementToolLayer *layer = [self layer];
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx == nil)
        return;
    [self invalidateTerrainElevationGpx];
    ctx.selectedPointPosition = index;
    [ctx.commandManager execute:[[OAClearPointsCommand alloc] initWithMeasurementLayer:layer mode:EOAClearPointsModeBefore]];
    [layer updateLayer];
    if (self.onChange)
        self.onChange();
}

- (void)trimAfterIndex:(NSInteger)index
{
    OAMeasurementToolLayer *layer = [self layer];
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx == nil)
        return;
    [self invalidateTerrainElevationGpx];
    ctx.selectedPointPosition = index;
    [ctx.commandManager execute:[[OAClearPointsCommand alloc] initWithMeasurementLayer:layer mode:EOAClearPointsModeAfter]];
    [layer updateLayer];
    if (self.onChange)
        self.onChange();
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
    [self invalidateTerrainElevationGpx];
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
    [self invalidateTerrainElevationGpx];
    [ctx.commandManager execute:[[OAClearPointsCommand alloc] initWithMeasurementLayer:layer mode:EOAClearPointsModeAll]];
    [ctx cancelSnapToRoad];
    [layer updateLayer];
    if (self.onChange)
        self.onChange();
}

- (void)openAddPoiWithFilePath:(NSString *)filePath presentingViewController:(UIViewController *)presentingViewController
{
    if (presentingViewController == nil)
        return;

    _editingPoiStateSnapshot = nil;
    CLLocationCoordinate2D location = [self crosshairLocation];
    if (!CLLocationCoordinate2DIsValid(location))
        return;
    
    NSString *gpxFilePath = filePath.length == 0 ? [self gpxFileForWaypoints].path : [self absoluteGpxPathFromPath:filePath];
    if (gpxFilePath.length == 0)
        return;

    OASGpxFile *gpxFile = filePath.length == 0 ? _draftGpxFile : [self editingContext].gpxData.gpxFile;
    OAEditPointViewController *controller = [[OAEditPointViewController alloc] initWithLocation:location title:OALocalizedString(@"shared_string_waypoint") address:nil customParam:gpxFilePath pointType:EOAEditPointTypeWaypoint targetMenuState:nil poi:nil gpxDocument:gpxFile];
    controller.gpxWptDelegate = self;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
    [presentingViewController presentViewController:navigationController animated:YES completion:nil];
}

- (OASGpxFile *)gpxFileForWaypoints
{
    if ([self editingContext] == nil)
        return nil;
    
    if (_draftGpxFile == nil)
    {
        _draftGpxFile = [[OASGpxFile alloc] initWithAuthor:[OAAppVersion getFullVersionWithAppName]];
        NSString *folderPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"OsmAndPlanRoute"];
        NSFileManager *fileManager = NSFileManager.defaultManager;
        [fileManager removeItemAtPath:folderPath error:nil];
        [fileManager createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:nil];
        _draftGpxPath = [folderPath stringByAppendingPathComponent:[[NSString stringWithFormat:@"plan_route_%@", [NSUUID UUID].UUIDString] stringByAppendingPathExtension:@"gpx"]];
        _draftGpxFile.path = _draftGpxPath;
        OASKFile *file = [[OASKFile alloc] initWithFilePath:_draftGpxPath];
        [OASGpxUtilities.shared writeGpxFileFile:file gpxFile:_draftGpxFile];
    }
    
    return _draftGpxFile;
}

- (BOOL)isDraftGpxPath:(NSString *)filePath
{
    return _draftGpxFile != nil && (filePath.length == 0 || [_draftGpxPath isEqualToString:filePath]);
}

- (NSString *)absoluteGpxPathFromPath:(NSString *)filePath
{
    if (filePath.length == 0 || filePath.isAbsolutePath)
        return filePath;

    return [OsmAndApp.instance.gpxPath stringByAppendingPathComponent:filePath];
}

- (nullable OASGpxFile *)activeGpxFileForPath:(NSString *)path fallbackPath:(nullable NSString *)fallbackPath
{
    NSDictionary<NSString *, OASGpxFile *> *activeGpx = OASelectedGPXHelper.instance.activeGpx;
    OASGpxFile *activeGpxFile = activeGpx[path];
    if (activeGpxFile == nil && fallbackPath.length > 0)
        activeGpxFile = activeGpx[fallbackPath];
    if (activeGpxFile == nil && path.lastPathComponent.length > 0)
        activeGpxFile = activeGpx[path.lastPathComponent];
    if (activeGpxFile == nil && fallbackPath.lastPathComponent.length > 0)
        activeGpxFile = activeGpx[fallbackPath.lastPathComponent];
    return activeGpxFile;
}

- (void)executePoiStateCommandWithBeforeState:(nullable OAPlanRoutePoiStateSnapshot *)beforeState operation:(BOOL (^)(void))operation
{
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx == nil || operation == nil)
        return;
    
    OAPlanRoutePoiStateSnapshot *stateBefore = beforeState ?: [self makePoiStateSnapshot];
    if (!operation())
        return;
    
    [self commitPoiStateCommandFromState:stateBefore toState:[self makePoiStateSnapshot]];
}

- (void)commitPoiStateCommandFromState:(nullable OAPlanRoutePoiStateSnapshot *)beforeState toState:(nullable OAPlanRoutePoiStateSnapshot *)afterState
{
    OAMeasurementEditingContext *ctx = [self editingContext];
    OAMeasurementToolLayer *layer = [self layer];
    if (ctx == nil || layer == nil || beforeState == nil || afterState == nil)
        return;
    
    [ctx.commandManager execute:[[OAPlanRoutePoiStateCommand alloc] initWithLayer:layer bridge:self beforeState:beforeState afterState:afterState]];
    if (self.onChange)
        self.onChange();
}

- (OAPlanRoutePoiStateSnapshot *)makePoiStateSnapshot
{
    return [[OAPlanRoutePoiStateSnapshot alloc] initWithGpxFile:[self editingContext].gpxData.gpxFile draftGpxFile:_draftGpxFile];
}

- (void)restorePoiStateSnapshot:(OAPlanRoutePoiStateSnapshot *)state
{
    if (state == nil)
        return;
    
    OASGpxFile *gpxFile = [self editingContext].gpxData.gpxFile;
    if (gpxFile != nil)
    {
        [self applyPoiStateSnapshot:state toGpxFile:gpxFile draft:NO];
        if (gpxFile.path.length > 0)
            [self syncActiveGpxPoiStateFromGpxFile:gpxFile];
    }
    
    if (state.hasDraftGpx)
    {
        OASGpxFile *draftGpx = [self gpxFileForWaypoints];
        [self applyPoiStateSnapshot:state toGpxFile:draftGpx draft:YES];
        [self refreshDraftGpx];
    }
    else
    {
        [self clearDraftGpx];
    }
}

- (void)applyPoiStateSnapshot:(OAPlanRoutePoiStateSnapshot *)state toGpxFile:(OASGpxFile *)gpxFile draft:(BOOL)draft
{
    if (state == nil || gpxFile == nil)
        return;
    
    NSArray<OASWptPt *> *existingPoints = [gpxFile.getPointsList copy];
    for (OASWptPt *point in existingPoints)
    {
        [gpxFile deleteWptPtPoint:point];
    }
    
    [gpxFile.pointsGroups removeAllObjects];
    NSDictionary<NSString *, OASGpxUtilitiesPointsGroup *> *groups = draft ? state.draftGroups : state.gpxGroups;
    [groups enumerateKeysAndObjectsUsingBlock:^(NSString *key, OASGpxUtilitiesPointsGroup *group, BOOL *stop) {
        gpxFile.pointsGroups[key] = [OAPlanRoutePoiStateSnapshot copyGroup:group];
    }];
    
    NSArray<OASWptPt *> *points = draft ? state.draftPoints : state.gpxPoints;
    for (OASWptPt *point in points)
    {
        [gpxFile addPointPoint:[[OASWptPt alloc] initWithWptPt:point]];
    }
}

- (void)syncActiveGpxPoiStateFromGpxFile:(OASGpxFile *)gpxFile
{
    if (gpxFile.path.length == 0)
        return;
    
    NSString *path = [self absoluteGpxPathFromPath:gpxFile.path];
    OASGpxFile *activeGpxFile = [self activeGpxFileForPath:path fallbackPath:gpxFile.path];
    if (activeGpxFile != nil && activeGpxFile != gpxFile)
        [self applyPoiStateSnapshot:[[OAPlanRoutePoiStateSnapshot alloc] initWithGpxFile:gpxFile draftGpxFile:nil] toGpxFile:activeGpxFile draft:NO];
    
    OAMapViewController *mapViewController = OARootViewController.instance.mapPanel.mapViewController;
    dispatch_async(dispatch_get_main_queue(), ^{
        [mapViewController.mapLayers.gpxMapLayer updateCachedGpxItem:path];
        [mapViewController.mapLayers.gpxMapLayer refreshGpxWaypoints];
    });
}

- (void)addPoiGroupsFromGpx:(nullable OASGpxFile *)sourceGpx toGpx:(OASGpxFile *)targetGpx
{
    if (sourceGpx == nil || targetGpx == nil)
        return;
    
    [sourceGpx.pointsGroups enumerateKeysAndObjectsUsingBlock:^(NSString *key, OASGpxUtilitiesPointsGroup *group, BOOL *stop) {
        if (targetGpx.pointsGroups[key] == nil)
            targetGpx.pointsGroups[key] = [[OASGpxUtilitiesPointsGroup alloc] initWithName:group.name iconName:group.iconName backgroundType:group.backgroundType color:group.color hidden:group.hidden];
    }];
}

- (void)ensurePoiGroupForPoint:(OASWptPt *)point inGpx:(OASGpxFile *)gpxFile
{
    if (point == nil || gpxFile == nil || point.category.length == 0)
        return;
    
    NSString *groupKey = [self poiGroupKeyForName:point.category];
    if (gpxFile.pointsGroups[groupKey] != nil)
        return;
    
    OASGpxUtilitiesPointsGroup *group = [[OASGpxUtilitiesPointsGroup alloc] initWithName:groupKey iconName:@"" backgroundType:@"" color:[point getColor] hidden:NO];
    [gpxFile addPointsGroupGroup:group];
}

- (void)refreshDraftGpx
{
    if (_draftGpxPath.length == 0 || _draftGpxFile == nil)
        return;
    
    OAMapViewController *mapViewController = OARootViewController.instance.mapPanel.mapViewController;
    [mapViewController hideTempGpxTrack:NO];
    OASKFile *file = [[OASKFile alloc] initWithFilePath:_draftGpxPath];
    [OASGpxUtilities.shared writeGpxFileFile:file gpxFile:_draftGpxFile];
    [mapViewController showTempGpxTrackFromGpxFile:_draftGpxFile];
}

- (void)clearDraftGpx
{
    if (_draftGpxPath.length == 0)
        return;

    NSString *draftGpxPath = _draftGpxPath;
    _draftGpxPath = nil;
    _draftGpxFile = nil;
    [OARootViewController.instance.mapPanel.mapViewController hideTempGpxTrack];
    [NSFileManager.defaultManager removeItemAtPath:draftGpxPath.stringByDeletingLastPathComponent error:nil];
}

- (void)addDraftWaypointsToGpx:(OASGpxFile *)gpx
{
    [self addPoiGroupsFromGpx:_draftGpxFile toGpx:gpx];

    if (_draftGpxFile.getPointsList.count > 0)
        [gpx addPointsCollection:_draftGpxFile.getPointsList];
}

#pragma mark - OAEditWaypointsGroupOptionsDelegate

- (void)updateWaypointsGroup:(NSString *)groupName color:(UIColor *)color
{
    if (_editingPoiGroupName.length == 0 || color == nil)
    {
        _editingPoiGroupName = nil;
        return;
    }

    NSString *editingGroupName = _editingPoiGroupName;
    [self executePoiStateCommandWithBeforeState:nil operation:^BOOL{
        return [self performChangePoiGroupAppearanceForName:editingGroupName color:color];
    }];
    
    _editingPoiGroupName = nil;
}

#pragma mark - OAGpxWptEditingHandlerDelegate

- (void)saveGpxWpt:(OAGpxWptItem *)gpxWpt gpxFileName:(NSString *)gpxFileName
{
    [self executePoiStateCommandWithBeforeState:nil operation:^BOOL{
        return [self performSaveGpxWpt:gpxWpt gpxFileName:gpxFileName];
    }];
}

- (void)updateGpxWpt:(OAGpxWptItem *)gpxWptItem docPath:(NSString *)docPath updateMap:(BOOL)updateMap
{
    OAPlanRoutePoiStateSnapshot *beforeState = _editingPoiStateSnapshot ?: [self makePoiStateSnapshot];
    OAPlanRoutePoiStateSnapshot *afterState = [self makePoiStateSnapshot];
    [self restorePoiStateSnapshot:afterState];
    [self commitPoiStateCommandFromState:beforeState toState:afterState];
    _editingPoiStateSnapshot = nil;
}

- (void)deleteGpxWpt:(OAGpxWptItem *)gpxWptItem docPath:(NSString *)docPath
{
    [self executePoiStateCommandWithBeforeState:nil operation:^BOOL{
        return [self performDeleteGpxWpt:gpxWptItem docPath:docPath];
    }];
}

- (void)saveItemToStorage:(OAGpxWptItem *)gpxWptItem
{
    if (_editingPoiStateSnapshot == nil)
        return;

    OAPlanRoutePoiStateSnapshot *beforeState = _editingPoiStateSnapshot;
    OAPlanRoutePoiStateSnapshot *afterState = [self makePoiStateSnapshot];
    [self restorePoiStateSnapshot:afterState];
    [self commitPoiStateCommandFromState:beforeState toState:afterState];
    _editingPoiStateSnapshot = afterState;
}

- (CLLocationCoordinate2D)crosshairLocation
{
    OAMapRendererView *mapView = [OARootViewController instance].mapPanel.mapViewController.mapView;
    if (mapView == nil)
        return kCLLocationCoordinate2DInvalid;
    
    OAMeasurementToolLayer *layer = [self layer];
    OsmAnd::PointI location31;
    if (layer != nil && !CGPointEqualToPoint(layer.cursorScreenPoint, CGPointZero))
    {
        CGFloat scale = mapView.contentScaleFactor;
        CGPoint scaledPoint = CGPointMake(layer.cursorScreenPoint.x * scale, layer.cursorScreenPoint.y * scale);
        [mapView convert:scaledPoint toLocation:&location31];
    }
    else
    {
        const auto center = [mapView getCenterPixel];
        location31 = [OANativeUtilities get31FromElevatedPixel:center];
    }
    
    const auto latLon = OsmAnd::Utilities::convert31ToLatLon(location31);
    return CLLocationCoordinate2DMake(latLon.latitude, latLon.longitude);
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

    NSString *originalGpxPath = [self absoluteGpxPathFromPath:ctx.gpxData.gpxFile.path].stringByStandardizingPath;
    OAPlanRoutePoiStateSnapshot *originalPoiStateSnapshot = _initialPoiStateSnapshot;
    NSString *trackName = fileName.length > 0 ? fileName : OALocalizedString(@"quick_action_new_route");
    OASGpxFile *gpx = [ctx exportGpx:trackName];
    if (gpx == nil)
    {
        if (onComplete) onComplete(NO, nil);
        return;
    }
    [self addPoiGroupsFromGpx:ctx.gpxData.gpxFile toGpx:gpx];
    [self addDraftWaypointsToGpx:gpx];
    NSString *gpxRootPath = OsmAndApp.instance.gpxPath;
    NSString *folderPath = (folder.length > 0) ? [gpxRootPath stringByAppendingPathComponent:folder] : gpxRootPath;
    NSString *outFile = [[[folderPath stringByAppendingPathComponent:trackName] stringByAppendingPathExtension:@"gpx"] stringByStandardizingPath];
    BOOL restoreOriginalActiveGpx = originalGpxPath.length > 0 && originalPoiStateSnapshot != nil && ![originalGpxPath isEqualToString:outFile];
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
                _initialPoiStateSnapshot = [[OAPlanRoutePoiStateSnapshot alloc] initWithGpxFile:gpx draftGpxFile:nil];
                _editingPoiStateSnapshot = nil;
            }
            if (showOnMap)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[OAAppSettings sharedManager] showGpx:@[gpxFilePath]];
                });
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success && restoreOriginalActiveGpx)
            {
                OASGpxFile *activeGpxFile = [self activeGpxFileForPath:originalGpxPath fallbackPath:nil];
                if (activeGpxFile != nil)
                {
                    [self applyPoiStateSnapshot:originalPoiStateSnapshot toGpxFile:activeGpxFile draft:NO];
                    OAMapViewController *mapViewController = OARootViewController.instance.mapPanel.mapViewController;
                    [mapViewController.mapLayers.gpxMapLayer updateCachedGpxItem:originalGpxPath];
                    [mapViewController.mapLayers.gpxMapLayer refreshGpxWaypoints];
                }
            }
            if (success)
                [self clearDraftGpx];
            if (onComplete) onComplete(success, success ? outFile : nil);
        });
    });
}

- (void)saveSegmentWithPointIndexes:(NSArray<NSNumber *> *)indexes
                           fileName:(NSString *)fileName
                          showOnMap:(BOOL)showOnMap
                         onComplete:(void (^)(BOOL success, NSString * _Nullable outPath))onComplete
{
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx == nil)
    {
        if (onComplete) onComplete(NO, nil);
        return;
    }

    NSArray<OASWptPt *> *allPoints = ctx.getPoints;
    NSArray<NSNumber *> *sortedIndexes = [indexes sortedArrayUsingSelector:@selector(compare:)];

    OASGpxFile *gpx = [[OASGpxFile alloc] initWithAuthor:[OAAppVersion getFullVersionWithAppName]];
    OASTrack *track = [[OASTrack alloc] init];
    track.segments = [NSMutableArray array];
    OASTrkSegment *segment = [[OASTrkSegment alloc] init];
    NSMutableArray<OASWptPt *> *trkPoints = [NSMutableArray array];

    for (NSNumber *indexNum in sortedIndexes)
    {
        NSInteger idx = indexNum.integerValue;
        if (idx >= 0 && idx < (NSInteger)allPoints.count)
        {
            OASWptPt *pt = allPoints[idx];
            OASWptPt *trkPoint = [[OASWptPt alloc] initWithWptPt:pt];
            [trkPoints addObject:trkPoint];
        }
    }

    if (trkPoints.count == 0)
    {
        if (onComplete) onComplete(NO, nil);
        return;
    }

    segment.points = trkPoints;
    [track.segments addObject:segment];
    gpx.tracks = [@[track] mutableCopy];

    NSString *trackName = fileName.length > 0 ? fileName : OALocalizedString(@"quick_action_new_route");
    NSString *folderPath = OsmAndApp.instance.gpxPath;
    NSString *outFile = [[[folderPath stringByAppendingPathComponent:trackName] stringByAppendingPathExtension:@"gpx"] stringByStandardizingPath];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        OASKFile *file = [[OASKFile alloc] initWithFilePath:outFile];
        OASKException *exception = [OASGpxUtilities.shared writeGpxFileFile:file gpxFile:gpx];
        BOOL success = exception == nil;
        if (success)
        {
            NSString *gpxFilePath = [OAUtilities getGpxShortPath:outFile];
            OASGpxDataItem *item = [OAGPXDatabase.sharedDb getGPXItem:gpxFilePath];
            if (!item)
                item = [OAGPXDatabase.sharedDb addGPXFileToDBIfNeeded:gpxFilePath];
            [OAGPXDatabase.sharedDb updateDataItem:item];
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

- (void)appendToTrack:(NSString *)filePath
           onComplete:(void (^)(BOOL success))onComplete
{
    OAMeasurementEditingContext *ctx = [self editingContext];
    OASGpxFile *currentGpx = ctx != nil ? [ctx exportGpx:@"tmp_append"] : nil;
    if (currentGpx == nil || currentGpx.tracks.count == 0)
    {
        if (onComplete) onComplete(NO);
        return;
    }
    NSString *absPath = filePath.isAbsolutePath ? filePath : [OsmAndApp.instance.gpxPath stringByAppendingPathComponent:filePath];
    NSArray<OASTrack *> *tracksToAppend = [currentGpx.tracks copy];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        OASKFile *file = [[OASKFile alloc] initWithFilePath:absPath];
        OASGpxFile *existingGpx = [OASGpxUtilities.shared loadGpxFileFile:file];
        BOOL success = NO;
        if (existingGpx != nil)
        {
            NSMutableArray *allTracks = existingGpx.tracks ? [existingGpx.tracks mutableCopy] : [NSMutableArray array];
            [allTracks addObjectsFromArray:tracksToAppend];
            existingGpx.tracks = allTracks;
            OASKException *exception = [OASGpxUtilities.shared writeGpxFileFile:file gpxFile:existingGpx];
            success = exception == nil;
            if (success)
            {
                NSString *gpxFilePath = [OAUtilities getGpxShortPath:absPath];
                OASGpxDataItem *item = [OAGPXDatabase.sharedDb getGPXItem:gpxFilePath];
                if (!item)
                    item = [OAGPXDatabase.sharedDb addGPXFileToDBIfNeeded:gpxFilePath];
                [OAGPXDatabase.sharedDb updateDataItem:item];
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (onComplete) onComplete(success);
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

    [self addPoiGroupsFromGpx:ctx.gpxData.gpxFile toGpx:gpx];
    [self addDraftWaypointsToGpx:gpx];
    NSString *outFile = [[OsmAndApp.instance.gpxPath stringByAppendingPathComponent:name] stringByAppendingPathExtension:@"gpx"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        OASKFile *file = [[OASKFile alloc] initWithFilePath:outFile];
        [OASGpxUtilities.shared writeGpxFileFile:file gpxFile:gpx];
        gpx.path = outFile;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self clearDraftGpx];
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
    [self invalidateTerrainElevationGpx];

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
    if (self.onChange)
        self.onChange();
}

#pragma mark - OAMeasurementLayerDelegate

- (void)onMeasure:(double)distance bearing:(double)bearing
{
    _distanceToMapCenter = distance;
    _bearingToMapCenter = bearing;
    if (self.onRouteInfoChanged)
        self.onRouteInfoChanged();
}

- (void)onTouch:(CLLocationCoordinate2D)coordinate longPress:(BOOL)longPress
{
    if (longPress)
        return;
    OAMeasurementToolLayer *layer = [self layer];
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx == nil)
        return;

    NSInteger hitIndex = [self findNearestPointToCoordinate:coordinate];
    if (hitIndex != -1)
    {
        [self showPointOptionsAtIndex:hitIndex];
        return;
    }

    layer.pressPointLocation = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
    [ctx.commandManager execute:[[OAAddPointCommand alloc] initWithLayer:layer center:NO]];
    [layer updateLayer];
    if (self.onChange)
        self.onChange();
}

#pragma mark - OAPointOptionsBottmSheetDelegate

- (void)onMovePoint:(NSInteger)point
{
    if (self.onPointSelected)
        self.onPointSelected(point);
}

- (void)onClearPoints:(EOAClearPointsMode)mode
{
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx == nil)
        return;
    NSInteger idx = ctx.selectedPointPosition;
    if (mode == EOAClearPointsModeBefore)
        [self trimBeforeIndex:idx];
    else
        [self trimAfterIndex:idx];
}

- (void)onAddPoints:(EOAAddPointMode)type
{
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx == nil)
        return;
    NSInteger idx = ctx.selectedPointPosition;
    if (type == EOAAddPointModeBefore)
        [self addPointBeforeIndex:idx];
    else
        [self addPointAfterIndex:idx];
}

- (void)onDeletePoint
{
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx == nil)
        return;
    [self deletePointAtIndex:ctx.selectedPointPosition];
}

- (void)onChangeRouteTypeBefore
{
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (_onChangeRouteTypeBefore && ctx != nil)
        _onChangeRouteTypeBefore(ctx.selectedPointPosition);
}

- (void)onChangeRouteTypeAfter
{
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (_onChangeRouteTypeAfter && ctx != nil)
        _onChangeRouteTypeAfter(ctx.selectedPointPosition);
}

- (void)onSplitPointsBefore {}
- (void)onSplitPointsAfter {}
- (void)onJoinPoints {}
- (void)onCloseMenu {}

- (void)onClearSelection
{
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx)
        ctx.selectedPointPosition = -1;
}

// MARK: - Route statistics

- (NSArray<OARouteStatistics *> *)calculateRouteStatistics
{
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx == nil || ctx.roadSegmentData.count == 0)
        return @[];

    std::vector<std::shared_ptr<RouteSegmentResult>> combined;
    for (OARoadSegmentData *data in ctx.roadSegmentData.allValues)
    {
        const auto &segs = data.segments;
        combined.insert(combined.end(), segs.begin(), segs.end());
    }

    if (combined.empty())
        return @[];

    return [OARouteStatisticsHelper calculateRouteStatistic:combined];
}

// MARK: - Elevation calculation

- (BOOL)shouldShowRouteCalculationStateForContext:(nullable OAMeasurementEditingContext *)ctx
{
    return ctx != nil && ctx.getPointsCount > 0 && ctx.appMode != OAApplicationMode.DEFAULT;
}

- (void)beginRouteCalculationIfNeededForContext:(nullable OAMeasurementEditingContext *)ctx
{
    if (![self shouldShowRouteCalculationStateForContext:ctx] || _isCalculatingRoute)
        return;
    _isCalculatingRoute = YES;
    if (self.onChange)
        self.onChange();
}

- (BOOL)isCalculatingElevation
{
    return _isCalculatingElevation;
}

- (BOOL)isCalculatingRoute
{
    return _isCalculatingRoute;
}

- (void)startElevationCalculationWithNearbyRoads:(BOOL)useNearbyRoads
{
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx == nil || ctx.getPointsCount == 0)
        return;

    _elevationCalculationRequestId++;
    [self invalidateTerrainElevationGpx];
    _elevationHelper = nil;

    if (useNearbyRoads)
    {
        NSArray<NSArray<OASWptPt *> *> *segments = [ctx getPointsSegments:YES route:YES];
        if (segments.count == 0)
            return;

        OAGpxApproximationParams *params = [[OAGpxApproximationParams alloc] init];
        params.appMode = ctx.appMode ?: [OAApplicationMode DEFAULT];
        params.distanceThreshold = 50;
        [params setTrackPoints:segments];

        _elevationHelper = [[OAGpxApproximationHelper alloc] initWithLocations:params.locationsHolders
                                                               initialAppMode:params.appMode
                                                             initialThreshold:params.distanceThreshold];
        _elevationHelper.delegate = self;
        _isCalculatingElevation = YES;
        if (self.onChange)
            self.onChange();
        [_elevationHelper calculateGpxApproximationAsync];
        return;
    }

    NSArray<OASWptPt *> *points = [ctx.getPoints copy];
    if (points.count == 0)
        return;

    double totalDistance = 0;
    OASWptPt *prevNonGap = nil;
    for (OASWptPt *pt in points)
    {
        if (!pt.isGap && prevNonGap != nil)
            totalDistance += [self distanceFrom:prevNonGap to:pt];
        if (!pt.isGap)
            prevNonGap = pt;
    }

    double interval = MAX(100.0, totalDistance / 500.0);

    NSMutableArray<OASWptPt *> *densifiedPoints = [NSMutableArray array];
    NSMutableArray<NSNumber *> *originalIndexMap = [NSMutableArray array];

    for (NSInteger i = 0; i < (NSInteger)points.count; i++)
    {
        OASWptPt *current = points[i];
        [originalIndexMap addObject:@(densifiedPoints.count)];
        [densifiedPoints addObject:[[OASWptPt alloc] initWithWptPt:current]];

        if (current.isGap || i + 1 >= (NSInteger)points.count)
            continue;

        OASWptPt *next = points[i + 1];
        if (next.isGap)
            continue;

        double segDist = [self distanceFrom:current to:next];
        NSInteger steps = (NSInteger)floor(segDist / interval);
        for (NSInteger s = 1; s < steps; s++)
        {
            double frac = (double)s / (double)steps;
            OASWptPt *interp = [[OASWptPt alloc] init];
            interp.lat = current.lat + (next.lat - current.lat) * frac;
            interp.lon = current.lon + (next.lon - current.lon) * frac;
            [densifiedPoints addObject:interp];
        }
    }

    NSMutableArray<OASWptPt *> *updatedPoints = [NSMutableArray arrayWithCapacity:points.count];
    for (OASWptPt *point in points)
        [updatedPoints addObject:[[OASWptPt alloc] initWithWptPt:point]];

    OAMapViewController *mapViewController = OARootViewController.instance.mapPanel.mapViewController;
    if (mapViewController == nil)
        return;

    NSUInteger requestId = _elevationCalculationRequestId;
    NSUInteger snapshotVersion = _pointsVersion;

    NSMutableArray<NSValue *> *coordinates = [NSMutableArray arrayWithCapacity:densifiedPoints.count];
    NSMutableArray<NSNumber *> *nonGapIndices = [NSMutableArray array];
    for (NSUInteger i = 0; i < densifiedPoints.count; i++)
    {
        OASWptPt *point = densifiedPoints[i];
        if (point.isGap)
            continue;
        CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(point.getLatitude, point.getLongitude);
        [coordinates addObject:[NSValue value:&coord withObjCType:@encode(CLLocationCoordinate2D)]];
        [nonGapIndices addObject:@(i)];
    }

    _isCalculatingElevation = YES;
    if (self.onChange)
        self.onChange();

    [mapViewController getAltitudesForCoordinates:coordinates callback:^(NSArray<NSNumber *> *heights) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (requestId != self->_elevationCalculationRequestId)
                return;

            BOOL hasUpdatedElevations = NO;
            for (NSUInteger j = 0; j < nonGapIndices.count && j < heights.count; j++)
            {
                float height = heights[j].floatValue;
                if (height > kMinAltitudeValue)
                {
                    densifiedPoints[nonGapIndices[j].unsignedIntegerValue].ele = height;
                    hasUpdatedElevations = YES;
                }
            }

            if (hasUpdatedElevations)
            {
                for (NSInteger i = 0; i < (NSInteger)originalIndexMap.count; i++)
                {
                    NSInteger dIdx = originalIndexMap[i].integerValue;
                    if (dIdx < (NSInteger)densifiedPoints.count)
                        updatedPoints[i].ele = densifiedPoints[dIdx].ele;
                }
                [ctx setPoints:updatedPoints];
                [[self layer] updateLayer];

                if (snapshotVersion == self->_pointsVersion)
                {
                    self->_terrainElevationGpxFile = [self buildTerrainElevationGpx:densifiedPoints];
                    self->_terrainElevationVersion = self->_pointsVersion;
                }
            }
            self->_isCalculatingElevation = NO;
            if (self.onChange)
                self.onChange();
        });
    }];
}

- (void)cancelElevationCalculation
{
    _elevationCalculationRequestId++;
    [_elevationHelper updateAppMode:nil];
    _elevationHelper = nil;
    _isCalculatingElevation = NO;
    if (self.onChange)
        self.onChange();
}

// MARK: - OASnapToRoadProgressDelegate

- (void)showProgressBar
{
    _isCalculatingRoute = YES;
    if (self.onChange)
        self.onChange();
}

- (void)updateProgress:(int)progress
{
}

- (void)hideProgressBar
{
    _isCalculatingRoute = NO;
    if (self.onChange)
        self.onChange();
}

- (void)refresh
{
    if (self.onChange)
        self.onChange();
}

// MARK: - OAGpxApproximationHelperDelegate

- (void)didStartProgress {}
- (void)didApproximationStarted {}
- (void)didUpdateProgress:(NSInteger)progress {}

- (void)didFinishAllApproximationsWithResults:(NSArray<OAGpxRouteApproximation *> *)approximations
                                       points:(NSArray<NSArray<OASWptPt *> *> *)points
{
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx != nil && approximations.count > 0 && points.count == approximations.count)
    {
        OAApplicationMode *appMode = ctx.appMode ?: [OAApplicationMode DEFAULT];
        OAApplyGpxApproximationCommand *command = [[OAApplyGpxApproximationCommand alloc]
                                                   initWithLayer:[self layer]
                                                   approximations:approximations
                                                   segmentPointsList:points
                                                   appMode:appMode];
        BOOL wasApproximationMode = ctx.approximationMode;
        ctx.approximationMode = YES;
        if (!wasApproximationMode || ![ctx.commandManager update:command])
            [ctx.commandManager execute:command];
    }
    _elevationHelper = nil;
    _isCalculatingElevation = NO;
    if (self.onChange)
        self.onChange();
}

@end
