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
#import "CLLocation+Extension.h"
#import "OAMapLayers.h"
#import "OAMeasurementEditingContext.h"
#import "OAMeasurementCommandManager.h"
#import "OAGpxData.h"
#import "OAAddPointCommand.h"
#import "OAMovePointCommand.h"
#import "OAJoinPointsCommand.h"
#import "OASplitPointsCommand.h"
#import "OARemovePointCommand.h"
#import "OAReorderPointCommand.h"
#import "OAReorderSegmentCommand.h"
#import "OAChangeRouteModeCommand.h"
#import "OAReversePointsCommand.h"
#import "OAClearPointsCommand.h"
#import "OAEditWaypointsGroupOptionsViewController.h"
#import "OANativeUtilities.h"
#import "OASelectedGPXHelper.h"
#import "OADefaultFavorite.h"
#import "OARouteStatisticsHelper.h"
#import "OARoadSegmentData.h"
#import "OAGpxApproximationHelper.h"
#import "OAGpxApproximationParams.h"
#import "OAApplyGpxApproximationCommand.h"
#import "OASnapTrackWarningViewController.h"
#import "OARouteExporter.h"
#import "OAIAPHelper.h"
#import "OAAppSettings.h"
#import "OAWaypointHelper.h"
#import "OALocationPointWrapper.h"
#import "OsmAnd_Maps-Swift.h"

#include <routeSegmentResult.h>

static const NSTimeInterval kRouteInfoRefreshInterval = 0.25;

@implementation OAPlanRouteShowAlongSettingsBridge
{
    OAApplicationMode *_applicationMode;
    OAAppSettings *_settings;
}

- (instancetype)initWithApplicationMode:(OAApplicationMode *)applicationMode
{
    self = [super init];
    if (self)
    {
        _applicationMode = applicationMode;
        _settings = OAAppSettings.sharedManager;
    }
    return self;
}

- (BOOL)isEnabledForType:(EOAPlanRouteShowAlongType)type
{
    switch (type)
    {
    case EOAPlanRouteShowAlongTypePoi:
        return [_settings.showNearbyPoi get:_applicationMode];
    case EOAPlanRouteShowAlongTypeFavorites:
        return [_settings.showNearbyFavorites get:_applicationMode];
    case EOAPlanRouteShowAlongTypeTrafficWarnings:
        return [_settings.showScreenAlerts get:_applicationMode] && [_settings.showTrafficWarnings get:_applicationMode];
    default:
        return NO;
    }
}

- (void)setEnabled:(BOOL)enabled forType:(EOAPlanRouteShowAlongType)type
{
    NSInteger waypointType;
    switch (type)
    {
    case EOAPlanRouteShowAlongTypePoi:
        [_settings.showNearbyPoi set:enabled mode:_applicationMode];
        [_settings.announceNearbyPoi set:enabled mode:_applicationMode];
        waypointType = LPW_POI;
        break;
    case EOAPlanRouteShowAlongTypeFavorites:
        [_settings.showNearbyFavorites set:enabled mode:_applicationMode];
        [_settings.announceNearbyFavorites set:enabled mode:_applicationMode];
        waypointType = LPW_FAVORITES;
        break;
    case EOAPlanRouteShowAlongTypeTrafficWarnings:
        if (enabled)
            [_settings.showScreenAlerts set:YES mode:_applicationMode];
        [_settings.showTrafficWarnings set:enabled mode:_applicationMode];
        [_settings.speakTrafficWarnings set:enabled mode:_applicationMode];
        [_settings.showPedestrian set:enabled mode:_applicationMode];
        [_settings.speakPedestrian set:enabled mode:_applicationMode];
        [_settings.showTunnels set:enabled mode:_applicationMode];
        [_settings.speakTunnels set:enabled mode:_applicationMode];
        waypointType = LPW_ALARMS;
        break;
    default:
        return;
    }
    [OAWaypointHelper.sharedInstance recalculatePoints:(int)waypointType];
}

@end

@class OAMeasurementToolLayer;

@interface OAMeasurementEditingContext (PlanRouteSettings)

- (void)recalculateRouteSegmentsWithMode:(OAApplicationMode *)mode;

@end

@interface OAPlanRouteEditingBridge () <OAMeasurementLayerDelegate, OAPointOptionsBottmSheetDelegate, OAGpxWptEditingHandlerDelegate, OAEditWaypointsGroupOptionsDelegate, OAGpxApproximationHelperDelegate, OASnapToRoadProgressDelegate, OAPlanningPopupDelegate, PlanRoutePoiStateRestoring>
{
    OASGpxFile *_draftGpxFile;
    NSString *_draftGpxPath;
    NSString *_editingPoiGroupName;
    PlanRoutePoiStateSnapshot *_initialPoiStateSnapshot;
    PlanRoutePoiStateSnapshot *_editingPoiStateSnapshot;
    double _distanceToMapCenter;
    double _bearingToMapCenter;
    OAGpxApproximationHelper *_elevationHelper;
    BOOL _isCalculatingElevation;
    BOOL _isCalculatingRoute;
    NSUInteger _elevationCalculationRequestId;
    NSUInteger _elevationHelperRequestId;
    __weak OAMeasurementEditingContext *_elevationCalculationContext;
    OASGpxFile *_terrainElevationGpxFile;
    NSUInteger _pointsVersion;
    NSUInteger _terrainElevationVersion;
    NSTimeInterval _lastRouteInfoRefreshTime;
    OAPlanningPopupBaseViewController *_approximationPopupController;
}

- (void)finishPointEditCancelled:(BOOL)cancelled;
- (BOOL)beginRouteCalculationIfNeededForContext:(nullable OAMeasurementEditingContext *)ctx
                                           mode:(OAApplicationMode *)mode
                                     pointIndex:(NSInteger)pointIndex
                                     wholeRoute:(BOOL)wholeRoute;
- (BOOL)hasRoutePairForMovingPointInContext:(nullable OAMeasurementEditingContext *)ctx;

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

- (BOOL)isTrackReadyToCalculate
{
    OAMeasurementEditingContext *ctx = [self editingContext];
    return ctx != nil && (![ctx shouldCheckApproximation] || ![ctx isApproximationNeeded] || [ctx isNewData]);
}

- (BOOL)isApproximationNeeded
{
    OAMeasurementEditingContext *ctx = [self editingContext];
    return ctx != nil && [ctx isApproximationNeeded];
}

- (BOOL)shouldShowApproximationWarning
{
    OAMeasurementEditingContext *ctx = [self editingContext];
    return ctx != nil && [ctx shouldCheckApproximation] && [ctx isApproximationNeeded] && [ctx hasTimestamps];
}

- (UIViewController *)approximationWarningViewController
{
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx == nil || ctx.getPointsCount == 0)
        return nil;
    OASnapTrackWarningViewController *warningController = [[OASnapTrackWarningViewController alloc] init];
    warningController.delegate = self;
    _approximationPopupController = warningController;
    return warningController;
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

- (NSTimeInterval)routeDuration
{
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx == nil)
        return 0;

    NSTimeInterval duration = 0;
    for (OARoadSegmentData *data in ctx.orderedRoadSegmentData)
    {
        for (const auto &segment : data.segments)
            duration += segment->segmentTime;
    }
    return duration;
}

- (NSArray<OAApplicationMode *> *)availableModes
{
    return [[OAApplicationMode values] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(OAApplicationMode *mode, NSDictionary *bindings) {
        return mode != [OAApplicationMode DEFAULT] && ![mode isDerivedRoutingFrom:OAApplicationMode.PUBLIC_TRANSPORT];
    }]];
}

- (void)addCenterPoint
{
    OAMeasurementToolLayer *layer = [self layer];
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx == nil)
        return;
    [self invalidateTerrainElevationGpx];
    if (!ctx.getPoints.lastObject.isGap)
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

+ (void)moveMapToCoordinate:(CLLocationCoordinate2D)coordinate
{
    OAMeasurementToolLayer *layer = OARootViewController.instance.mapPanel.mapViewController.mapLayers.routePlanningLayer;
    if (layer == nil)
        return;
    [layer moveMapToCoordinate:coordinate];
}

- (void)dismiss
{
    [self invalidateElevationCalculationShouldNotify:NO];
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
    [self prepareNewRouteWithApplicationMode:OAApplicationMode.DEFAULT];
}

- (void)prepareNewRouteWithApplicationMode:(OAApplicationMode *)applicationMode
{
    OAMeasurementToolLayer *layer = [self layer];
    if (layer == nil)
        return;
    OAMeasurementEditingContext *ctx = [[OAMeasurementEditingContext alloc] init];
    ctx.appMode = applicationMode;
    ctx.progressDelegate = self;
    layer.editingCtx = ctx;
    layer.delegate = self;
    _initialPoiStateSnapshot = nil;
    _editingPoiStateSnapshot = nil;
    _isCalculatingRoute = NO;
    [ctx.commandManager setMeasurementLayer:layer];
    [layer updateLayer];
}

- (void)addPointAtCoordinate:(CLLocationCoordinate2D)coordinate
{
    OAMeasurementToolLayer *layer = [self layer];
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (layer == nil || ctx == nil)
        return;
    CLLocation *latLon = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
    [ctx.commandManager execute:[[OAAddPointCommand alloc] initWithLayer:layer coordinate:latLon]];
    [layer updateLayer];
    if (self.onChange)
        self.onChange();
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
        OASGpxFile *selectedFile = [OASelectedGPXHelper.instance activeGpxFileForPath:absolutePath fallbackPath:filePath];
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
    NSArray<OASWptPt *> *routePoints = gpxFile.getRoutePoints;
    if (routePoints.count > 0)
    {
        OAApplicationMode *appMode = [OAApplicationMode valueOfStringKey:routePoints.lastObject.getProfileType
                                                                     def:nil];
        if (appMode != nil)
            ctx.appMode = appMode;
    }
    ctx.progressDelegate = self;
    _initialPoiStateSnapshot = gpxFile != nil ? [[PlanRoutePoiStateSnapshot alloc] initWithGpxFile:gpxFile draftGpxFile:nil] : nil;
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

- (double)routeDistanceFrom:(OASWptPt *)from to:(OASWptPt *)to
{
    OARoadSegmentData *routeSegment = [self editingContext].roadSegmentData[@[from, to]];
    return routeSegment != nil ? routeSegment.distance : [self distanceFrom:from to:to];
}

- (NSArray<PlanRouteSegmentData *> *)buildSegments
{
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx == nil)
        return @[];
    NSArray<OASWptPt *> *points = ctx.getPoints;
    if (points.count == 0)
        return @[];

    NSMutableArray<PlanRouteSegmentData *> *result = [NSMutableArray array];
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
    NSString *gpxPath = [OAUtilities absoluteGpxPathForPath:gpxFile.path];
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
    
    return [items copy];
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
    for (NSString *key in gpxFile.pointsGroups.allKeys)
    {
        OASGpxUtilitiesPointsGroup *group = gpxFile.pointsGroups[key];
        NSString *name = key.length == 0 ? OALocalizedString(@"shared_string_gpx_points") : group.name.length > 0 ? group.name : key;
        NSString *keyGroupKey = [self poiGroupKeyForName:key];
        NSString *nameGroupKey = [self poiGroupKeyForName:name];
        if ([keyGroupKey isEqualToString:groupKey] || [nameGroupKey isEqualToString:groupKey])
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

- (PlanRouteSegmentData *)buildSegmentWithIndex:(NSInteger)segmentIndex
                                     pointIndexes:(NSArray<NSNumber *> *)pointIndexes
                                        allPoints:(NSArray<OASWptPt *> *)allPoints
{
    NSMutableArray<PlanRouteGroupData *> *groups = [NSMutableArray array];
    NSMutableArray<NSNumber *> *currentIndexes = [NSMutableArray array];
    NSInteger segmentStartIndex = pointIndexes.firstObject.integerValue;
    NSInteger segmentEndIndex = pointIndexes.lastObject.integerValue;
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
        BOOL isGap = allPoints[index].isGap;
        if (!isGap && ![key isEqualToString:currentKey] && currentIndexes.count > 0)
        {
            [groups addObject:[self buildGroupWithKey:currentKey
                                              indexes:currentIndexes
                                            allPoints:allPoints
                                    segmentStartIndex:segmentStartIndex
                                      segmentEndIndex:segmentEndIndex]];
            currentIndexes = [NSMutableArray array];
            currentKey = key;
        }
        [currentIndexes addObject:indexNumber];
    }
    if (currentIndexes.count > 0)
        [groups addObject:[self buildGroupWithKey:currentKey
                                          indexes:currentIndexes
                                        allPoints:allPoints
                                segmentStartIndex:segmentStartIndex
                                  segmentEndIndex:segmentEndIndex]];

    NSMutableArray<PlanRouteGroupData *> *mergedGroups = [NSMutableArray array];
    for (PlanRouteGroupData *group in groups)
    {
        PlanRouteGroupData *last = mergedGroups.lastObject;
        BOOL sameMode = last != nil &&
            ((last.appMode == nil && group.appMode == nil) ||
             (last.appMode != nil && group.appMode != nil &&
              [last.appMode.stringKey isEqualToString:group.appMode.stringKey]));
        if (sameMode)
        {
            NSMutableArray<PlanRoutePointData *> *combinedPoints = [NSMutableArray arrayWithArray:last.points];
            [combinedPoints addObjectsFromArray:group.points];
            PlanRouteGroupData *merged = [[PlanRouteGroupData alloc] initWithAppMode:last.appMode
                                                                                distance:last.distance + group.distance
                                                                         lastGlobalIndex:group.lastGlobalIndex
                                                                                  points:combinedPoints];
            [mergedGroups replaceObjectAtIndex:mergedGroups.count - 1 withObject:merged];
        }
        else
        {
            [mergedGroups addObject:group];
        }
    }
    groups = mergedGroups;

    NSInteger routedCount = 0;
    OAApplicationMode *singleMode = nil;
    double distance = 0;
    for (PlanRouteGroupData *group in groups)
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
    return [[PlanRouteSegmentData alloc] initWithIndex:segmentIndex
                                                  routed:routed
                                               multiMode:multiMode
                                              singleMode:multiMode ? nil : singleMode
                                                distance:distance
                                                  groups:groups];
}

- (PlanRouteGroupData *)buildGroupWithKey:(NSString *)key
                                    indexes:(NSArray<NSNumber *> *)indexes
                                  allPoints:(NSArray<OASWptPt *> *)allPoints
                          segmentStartIndex:(NSInteger)segmentStartIndex
                            segmentEndIndex:(NSInteger)segmentEndIndex
{
    OAApplicationMode *appMode = nil;
    if (key.length > 0)
    {
        OAApplicationMode *mode = [OAApplicationMode valueOfStringKey:key def:OAApplicationMode.DEFAULT];
        if (mode != [OAApplicationMode DEFAULT])
            appMode = mode;
    }

    NSMutableArray<PlanRoutePointData *> *points = [NSMutableArray array];
    double groupDistance = 0;
    for (NSNumber *indexNumber in indexes)
    {
        NSInteger index = indexNumber.integerValue;
        NSInteger indexInSegment = index - segmentStartIndex;
        OASWptPt *point = allPoints[index];
        BOOL isStart = index == segmentStartIndex;
        BOOL isDestination = index == segmentEndIndex;
        double legDistance = 0;
        double bearing = 0;
        if (index > 0)
        {
            OASWptPt *previous = allPoints[index - 1];
            if (!previous.isGap)
            {
                legDistance = [self routeDistanceFrom:previous to:point];
                CLLocation *previousLocation = [[CLLocation alloc] initWithLatitude:previous.lat longitude:previous.lon];
                CLLocation *pointLocation = [[CLLocation alloc] initWithLatitude:point.lat longitude:point.lon];
                bearing = [OAMapUtils normalizeDegrees360:[previousLocation bearingTo:pointLocation]];
                groupDistance += legDistance;
            }
        }
        NSString *name = point.name.length > 0 ? point.name : [NSString stringWithFormat:@"%@ - %ld", OALocalizedString(@"shared_string_point"), (long) (indexInSegment + 1)];
        [points addObject:[[PlanRoutePointData alloc] initWithGlobalIndex:index
                                                          indexInSegment:indexInSegment
                                                                       name:name
                                                       distanceFromPrevious:legDistance
                                                                    bearing:bearing
                                                                    isStart:isStart
                                                              isDestination:isDestination]];
    }
    NSInteger lastIndex = indexes.lastObject.integerValue;
    return [[PlanRouteGroupData alloc] initWithAppMode:appMode distance:groupDistance lastGlobalIndex:lastIndex points:points];
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
    [ctx.commandManager execute:[[OAReorderPointCommand alloc] initWithLayer:layer from:from to:to move:YES]];
    [layer updateLayer];
    if (self.onChange)
        self.onChange();
}

- (void)reorderSegmentFrom:(NSInteger)from to:(NSInteger)to
{
    OAMeasurementToolLayer *layer = [self layer];
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx == nil || from == to)
        return;
    [self invalidateTerrainElevationGpx];
    [ctx.commandManager execute:[[OAReorderSegmentCommand alloc] initWithLayer:layer from:from to:to]];
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
    BOOL started = [ctx.commandManager execute:[[OASplitPointsCommand alloc] initWithLayer:layer after:YES]];
    ctx.selectedPointPosition = -1;
    [layer updateLayer];
    if (started && self.onNewSegmentStarted)
        self.onNewSegmentStarted();
    if (started && self.onChange)
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
    BOOL startsRouteCalculation = [self beginRouteCalculationIfNeededForContext:ctx
                                                                           mode:mode
                                                                     pointIndex:pointIndex
                                                                     wholeRoute:wholeRoute];
    ctx.appMode = mode;
    EOAChangeRouteType type = wholeRoute ? EOAChangeRouteWhole : EOAChangeRouteNextSegment;
    [ctx.commandManager execute:[[OAChangeRouteModeCommand alloc] initWithLayer:layer appMode:mode changeRouteType:type pointIndex:pointIndex]];
    [layer updateLayer];
    if (!startsRouteCalculation && self.onChange)
        self.onChange();
}

- (void)refreshRouteForMode:(OAApplicationMode *)mode
{
    OAMeasurementToolLayer *layer = [self layer];
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (layer == nil || ctx == nil || ctx.getPointsCount == 0 || mode == nil)
        return;
    [self invalidateTerrainElevationGpx];
    [ctx recalculateRouteSegmentsWithMode:mode];
    [layer updateLayer];
    if (self.onChange)
        self.onChange();
}

- (void)selectPointAtIndex:(NSInteger)index
{
    OAMeasurementToolLayer *layer = [self layer];
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx == nil || index < 0 || index >= ctx.getPointsCount)
        return;
    [self invalidateTerrainElevationGpx];
    ctx.selectedPointPosition = index;
    if (self.onPointEditModeRequested)
        self.onPointEditModeRequested(EOAPlanRoutePointEditModeMove);
    ctx.originalPointToMove = ctx.getPoints[index];
    [layer enterMovingPointMode];
    if (self.onChange)
        self.onChange();
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

- (void)addPointBeforeIndex:(NSInteger)index
{
    OAMeasurementToolLayer *layer = [self layer];
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx == nil || index < 0 || index >= ctx.getPointsCount)
        return;
    [self invalidateTerrainElevationGpx];
    ctx.selectedPointPosition = index;
    if (self.onPointEditModeRequested)
        self.onPointEditModeRequested(EOAPlanRoutePointEditModeAddBefore);
    [layer moveMapToPoint:index];
    ctx.addPointMode = EOAAddPointModeBefore;
    [ctx splitSegments:index];
    [layer updateLayer];
    if (self.onChange)
        self.onChange();
}

- (void)addPointAfterIndex:(NSInteger)index
{
    OAMeasurementToolLayer *layer = [self layer];
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx == nil || index < 0 || index >= ctx.getPointsCount)
        return;
    [self invalidateTerrainElevationGpx];
    ctx.selectedPointPosition = index;
    if (self.onPointEditModeRequested)
        self.onPointEditModeRequested(EOAPlanRoutePointEditModeAddAfter);
    [layer moveMapToPoint:index];
    ctx.addPointMode = EOAAddPointModeAfter;
    [ctx splitSegments:index + 1];
    [layer updateLayer];
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
    ctx.selectedPointPosition = -1;
    [ctx splitSegments:ctx.getBeforePoints.count + ctx.getAfterPoints.count];
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
    ctx.selectedPointPosition = -1;
    [ctx splitSegments:ctx.getBeforePoints.count + ctx.getAfterPoints.count];
    [layer updateLayer];
    if (self.onChange)
        self.onChange();
}

- (void)applyPointEdit
{
    OAMeasurementToolLayer *layer = [self layer];
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx == nil)
        return;
    [self invalidateTerrainElevationGpx];
    if (ctx.originalPointToMove != nil)
    {
        if ([self hasRoutePairForMovingPointInContext:ctx])
            [self beginRouteCalculationIfNeededForContext:ctx];
        OASWptPt *newPoint = [layer getMovedPointToApply];
        [ctx.commandManager execute:[[OAMovePointCommand alloc] initWithLayer:layer
                                                                        oldPoint:ctx.originalPointToMove
                                                                        newPoint:newPoint
                                                                        position:ctx.selectedPointPosition]];
        [ctx addPoint:newPoint];
    }
    else if (ctx.isInAddPointMode)
    {
        [self addAnotherPoint];
    }
    [self finishPointEditCancelled:NO];
}

- (void)cancelPointEdit
{
    [self finishPointEditCancelled:YES];
}

- (void)addAnotherPoint
{
    OAMeasurementToolLayer *layer = [self layer];
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx == nil || !ctx.isInAddPointMode)
        return;
    [self invalidateTerrainElevationGpx];
    [self beginRouteCalculationIfNeededForContext:ctx];
    NSInteger selectedPoint = ctx.selectedPointPosition;
    NSInteger pointsCount = ctx.getPointsCount;
    if ([ctx.commandManager execute:[[OAAddPointCommand alloc] initWithLayer:layer center:YES]])
    {
        if (selectedPoint == pointsCount)
            [ctx splitSegments:ctx.getPointsCount - 1];
        else
            ctx.selectedPointPosition = selectedPoint + 1;
        if (self.onChange)
            self.onChange();
    }
}

- (void)finishPointEditCancelled:(BOOL)cancelled
{
    OAMeasurementToolLayer *layer = [self layer];
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx == nil)
        return;
    if (ctx.originalPointToMove != nil)
    {
        if (cancelled)
            [ctx addPoint:ctx.originalPointToMove];
        ctx.originalPointToMove = nil;
        [layer exitMovingMode];
    }
    ctx.selectedPointPosition = -1;
    ctx.addPointMode = EOAAddPointModeUndefined;
    [ctx splitSegments:ctx.getBeforePoints.count + ctx.getAfterPoints.count];
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
    OAMeasurementToolLayer *layer = [self layer];
    CLLocationCoordinate2D location = layer != nil ? [layer crosshairLocation] : kCLLocationCoordinate2DInvalid;
    if (!CLLocationCoordinate2DIsValid(location))
        return;
    
    NSString *gpxFilePath = filePath.length == 0 ? [self gpxFileForWaypoints].path : [OAUtilities absoluteGpxPathForPath:filePath];
    if (gpxFilePath.length == 0)
        return;

    OASGpxFile *gpxFile = filePath.length == 0 ? _draftGpxFile : [self editingContext].gpxData.gpxFile;
    OAEditPointViewController *controller = [[OAEditPointViewController alloc] initWithLocation:location title:OALocalizedString(@"shared_string_waypoint") address:nil customParam:gpxFilePath pointType:EOAEditPointTypeWaypoint targetMenuState:nil poi:nil gpxFile:gpxFile];
    controller.gpxWptDelegate = self;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
    [presentingViewController presentViewController:navigationController animated:YES completion:nil];
}

- (nullable OASGpxFile *)gpxFileForWaypoints
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

- (void)executePoiStateCommandWithBeforeState:(nullable PlanRoutePoiStateSnapshot *)beforeState operation:(BOOL (^)(void))operation
{
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx == nil || operation == nil)
        return;
    
    PlanRoutePoiStateSnapshot *stateBefore = beforeState ?: [self makePoiStateSnapshot];
    if (!operation())
        return;
    
    [self commitPoiStateCommandFromState:stateBefore toState:[self makePoiStateSnapshot]];
}

- (void)commitPoiStateCommandFromState:(nullable PlanRoutePoiStateSnapshot *)beforeState toState:(nullable PlanRoutePoiStateSnapshot *)afterState
{
    OAMeasurementEditingContext *ctx = [self editingContext];
    OAMeasurementToolLayer *layer = [self layer];
    if (ctx == nil || layer == nil || beforeState == nil || afterState == nil)
        return;
    
    [ctx.commandManager execute:[[PlanRoutePoiStateCommand alloc] initWithLayer:layer restorer:self beforeState:beforeState afterState:afterState]];
    if (self.onChange)
        self.onChange();
}

- (PlanRoutePoiStateSnapshot *)makePoiStateSnapshot
{
    return [[PlanRoutePoiStateSnapshot alloc] initWithGpxFile:[self editingContext].gpxData.gpxFile draftGpxFile:_draftGpxFile];
}

- (void)restorePoiStateSnapshot:(PlanRoutePoiStateSnapshot *)state
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

- (void)applyPoiStateSnapshot:(PlanRoutePoiStateSnapshot *)state toGpxFile:(OASGpxFile *)gpxFile draft:(BOOL)draft
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
        gpxFile.pointsGroups[key] = [PlanRoutePoiStateSnapshot copyGroup:group];
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
    
    NSString *path = [OAUtilities absoluteGpxPathForPath:gpxFile.path];
    OASGpxFile *activeGpxFile = [OASelectedGPXHelper.instance activeGpxFileForPath:path fallbackPath:gpxFile.path];
    if (activeGpxFile != nil && activeGpxFile != gpxFile)
        [self applyPoiStateSnapshot:[[PlanRoutePoiStateSnapshot alloc] initWithGpxFile:gpxFile draftGpxFile:nil] toGpxFile:activeGpxFile draft:NO];
    
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
    PlanRoutePoiStateSnapshot *beforeState = _editingPoiStateSnapshot ?: [self makePoiStateSnapshot];
    PlanRoutePoiStateSnapshot *afterState = [self makePoiStateSnapshot];
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

    PlanRoutePoiStateSnapshot *beforeState = _editingPoiStateSnapshot;
    PlanRoutePoiStateSnapshot *afterState = [self makePoiStateSnapshot];
    [self restorePoiStateSnapshot:afterState];
    [self commitPoiStateCommandFromState:beforeState toState:afterState];
    _editingPoiStateSnapshot = afterState;
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

    NSString *originalGpxPath = [OAUtilities absoluteGpxPathForPath:ctx.gpxData.gpxFile.path].stringByStandardizingPath;
    PlanRoutePoiStateSnapshot *originalPoiStateSnapshot = _initialPoiStateSnapshot;
    NSString *trackName = (fileName.length > 0 ? fileName : OALocalizedString(@"quick_action_new_route")).decomposedStringWithCanonicalMapping;
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
    __weak __typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
        OASKFile *file = [[OASKFile alloc] initWithFilePath:outFile];
        OASKException *exception = [OASGpxUtilities.shared writeGpxFileFile:file gpxFile:gpx];
        BOOL success = (exception == nil);
        NSString *gpxFilePath = nil;
        if (success)
        {
            gpxFilePath = [OAUtilities getGpxShortPath:outFile];
            OAGPXDatabase *gpxDb = OAGPXDatabase.sharedDb;
            OASGpxDataItem *item = [gpxDb getGPXItem:gpxFilePath];
            if (!item)
                item = [gpxDb addGPXFileToDBIfNeeded:gpxFilePath];
            [gpxDb updateDataItem:item];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong __typeof(weakSelf) strongSelf = weakSelf;
            if (success)
            {
                gpx.path = outFile;
                BOOL isCurrentContext = strongSelf != nil && [strongSelf editingContext] == ctx;
                if (!asCopy && isCurrentContext)
                {
                    ctx.gpxData = [[OAGpxData alloc] initWithFile:gpx];
                    [ctx setChangesSaved];
                    strongSelf->_initialPoiStateSnapshot = [[PlanRoutePoiStateSnapshot alloc] initWithGpxFile:gpx draftGpxFile:nil];
                    strongSelf->_editingPoiStateSnapshot = nil;
                }
                OAAppSettings *settings = OAAppSettings.sharedManager;
                BOOL isVisible = gpxFilePath.length > 0 && [settings isGpxVisible:gpxFilePath];
                if (isVisible || showOnMap)
                {
                    [OASelectedGPXHelper.instance addGpxFile:gpx for:outFile];
                    if (isVisible)
                        [OsmAndApp.instance.updateGpxTracksOnMapObservable notifyEvent];
                    else if (gpxFilePath.length > 0)
                        [settings showGpx:@[gpxFilePath]];
                }
                if (restoreOriginalActiveGpx && strongSelf != nil)
                {
                    OASGpxFile *activeGpxFile = [OASelectedGPXHelper.instance activeGpxFileForPath:originalGpxPath fallbackPath:nil];
                    if (activeGpxFile != nil)
                    {
                        [strongSelf applyPoiStateSnapshot:originalPoiStateSnapshot toGpxFile:activeGpxFile draft:NO];
                        OAMapViewController *mapViewController = OARootViewController.instance.mapPanel.mapViewController;
                        [mapViewController.mapLayers.gpxMapLayer updateCachedGpxItem:originalGpxPath];
                        [mapViewController.mapLayers.gpxMapLayer refreshGpxWaypoints];
                    }
                }
                if (isCurrentContext)
                    [strongSelf clearDraftGpx];
            }
            if (onComplete)
                onComplete(success, success ? outFile : nil);
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

    NSArray<NSNumber *> *sortedIndexes = [indexes sortedArrayUsingSelector:@selector(compare:)];
    if (sortedIndexes.count == 0)
    {
        if (onComplete) onComplete(NO, nil);
        return;
    }

    NSInteger startPointIndex = sortedIndexes.firstObject.integerValue;
    NSInteger endPointIndex = sortedIndexes.lastObject.integerValue;
    for (NSInteger offset = 0; offset < (NSInteger)sortedIndexes.count; offset++)
    {
        if (sortedIndexes[offset].integerValue != startPointIndex + offset)
        {
            if (onComplete) onComplete(NO, nil);
            return;
        }
    }

    NSString *trackName = fileName.length > 0 ? fileName : OALocalizedString(@"quick_action_new_route");
    OASGpxFile *gpx = [ctx exportGpx:trackName startPointIndex:startPointIndex endPointIndex:endPointIndex];
    if (gpx == nil)
    {
        if (onComplete) onComplete(NO, nil);
        return;
    }

    NSString *folderPath = OsmAndApp.instance.gpxPath;
    NSString *outFile = [[[folderPath stringByAppendingPathComponent:trackName] stringByAppendingPathExtension:@"gpx"] stringByStandardizingPath];

    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
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
    if (ctx == nil || filePath.length == 0)
    {
        if (onComplete) onComplete(NO);
        return;
    }

    NSString *trackName = filePath.lastPathComponent.stringByDeletingPathExtension.decomposedStringWithCanonicalMapping;
    OASGpxFile *currentGpx = [ctx exportGpx:trackName];
    if (currentGpx == nil || currentGpx.tracks.count == 0)
    {
        if (onComplete) onComplete(NO);
        return;
    }

    [self addPoiGroupsFromGpx:ctx.gpxData.gpxFile toGpx:currentGpx];
    [self addDraftWaypointsToGpx:currentGpx];

    NSString *absPath = [OAUtilities absoluteGpxPathForPath:filePath].stringByStandardizingPath;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        OASKFile *file = [[OASKFile alloc] initWithFilePath:absPath];
        OASGpxFile *existingGpx = [OASGpxUtilities.shared loadGpxFileFile:file];
        BOOL success = NO;
        if (existingGpx != nil)
        {
            NSMutableArray<OASTrack *> *mergedTracks = currentGpx.tracks
                ? [currentGpx.tracks mutableCopy]
                : [NSMutableArray array];
            if (existingGpx.tracks.count > 0)
                [mergedTracks addObjectsFromArray:existingGpx.tracks];
            currentGpx.tracks = mergedTracks;

            NSMutableArray *mergedRoutes = currentGpx.routes
                ? [currentGpx.routes mutableCopy]
                : [NSMutableArray array];
            if (existingGpx.routes.count > 0)
                [mergedRoutes addObjectsFromArray:existingGpx.routes];
            currentGpx.routes = mergedRoutes;

            NSArray<OASWptPt *> *existingPoints = existingGpx.getPointsList;
            if (existingPoints.count > 0)
                [currentGpx addPointsCollection:existingPoints];

            OASKException *exception = [OASGpxUtilities.shared writeGpxFileFile:file gpxFile:currentGpx];
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
            if (success)
            {
                [OASelectedGPXHelper.instance markTrackForReload:absPath];
                [OsmAndApp.instance.updateGpxTracksOnMapObservable notifyEvent];
            }
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
    NSMutableArray<NSNumber *> *currentOrder = [NSMutableArray arrayWithCapacity:points.count];
    for (NSInteger i = 0; i < (NSInteger) points.count; i++)
        [currentOrder addObject:@(i)];
    for (NSInteger target = 0; target < (NSInteger) ordered.count; target++)
    {
        NSInteger to = base + target;
        NSInteger from = [currentOrder indexOfObject:ordered[target]];
        if (from != NSNotFound && from != to)
        {
            [ctx.commandManager execute:[[OAReorderPointCommand alloc] initWithLayer:layer from:from to:to move:YES]];
            NSNumber *moved = currentOrder[from];
            [currentOrder removeObjectAtIndex:from];
            [currentOrder insertObject:moved atIndex:to];
        }
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

    NSInteger hitIndex = [layer findNearestPointToCoordinate:coordinate];
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
    [self selectPointAtIndex:point];
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

- (void)onClearSelection
{
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx && ctx.originalPointToMove == nil && !ctx.isInAddPointMode)
        ctx.selectedPointPosition = -1;
}

- (void)onSplitPointsBefore
{
    OAMeasurementToolLayer *layer = [self layer];
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx == nil)
        return;
    [self invalidateTerrainElevationGpx];
    [ctx.commandManager execute:[[OASplitPointsCommand alloc] initWithLayer:layer after:NO]];
    ctx.selectedPointPosition = -1;
    [layer updateLayer];
    if (self.onChange)
        self.onChange();
}

- (void)onSplitPointsAfter
{
    OAMeasurementToolLayer *layer = [self layer];
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx == nil)
        return;
    BOOL startsNewSegment = ctx.selectedPointPosition == -1 || ctx.selectedPointPosition == ctx.getPointsCount - 1;
    [self invalidateTerrainElevationGpx];
    BOOL split = [ctx.commandManager execute:[[OASplitPointsCommand alloc] initWithLayer:layer after:YES]];
    ctx.selectedPointPosition = -1;
    [layer updateLayer];
    if (split && startsNewSegment && self.onNewSegmentStarted)
        self.onNewSegmentStarted();
    if (split && self.onChange)
        self.onChange();
}

- (void)onJoinPoints
{
    OAMeasurementToolLayer *layer = [self layer];
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx == nil)
        return;
    [self invalidateTerrainElevationGpx];
    [ctx.commandManager execute:[[OAJoinPointsCommand alloc] initWithLayer:layer]];
    ctx.selectedPointPosition = -1;
    [layer updateLayer];
    if (self.onChange)
        self.onChange();
}

// MARK: - Route statistics

- (NSArray<OARouteStatistics *> *)calculateRouteStatistics
{
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx == nil || ctx.orderedRoadSegmentData.count == 0)
        return @[];

    std::vector<std::shared_ptr<RouteSegmentResult>> combined;
    for (OARoadSegmentData *data in ctx.orderedRoadSegmentData)
    {
        const auto &segs = data.segments;
        combined.insert(combined.end(), segs.begin(), segs.end());
    }

    if (combined.empty())
        return @[];

    return [OARouteStatisticsHelper calculateRouteStatistic:combined];
}

// MARK: - Elevation calculation

- (BOOL)beginRouteCalculationIfNeededForContext:(nullable OAMeasurementEditingContext *)ctx
                                           mode:(OAApplicationMode *)mode
                                     pointIndex:(NSInteger)pointIndex
                                     wholeRoute:(BOOL)wholeRoute
{
    if (ctx == nil)
        return NO;
    BOOL hasRoutePair = wholeRoute
        ? ctx.getPointsCount > 1
        : pointIndex >= 0 && pointIndex < ctx.getPointsCount - 1 && !ctx.getPoints[pointIndex].isGap;
    if (!hasRoutePair || mode == OAApplicationMode.DEFAULT)
        return NO;
    _isCalculatingRoute = YES;
    if (self.onChange)
        self.onChange();
    return YES;
}

- (BOOL)hasRoutePairForMovingPointInContext:(nullable OAMeasurementEditingContext *)ctx
{
    if (ctx == nil)
        return NO;
    BOOL hasPreviousRoutePair = ctx.getBeforePoints.count > 0 && !ctx.getBeforePoints.lastObject.isGap;
    BOOL hasNextRoutePair = ctx.getAfterPoints.count > 0 && !ctx.originalPointToMove.isGap;
    return hasPreviousRoutePair || hasNextRoutePair;
}

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

- (BOOL)isTerrainElevationAvailable
{
    return [OAIAPHelper isOsmAndProAvailable];
}

- (void)startElevationCalculationWithNearbyRoads:(BOOL)useNearbyRoads
{
    OAMeasurementEditingContext *ctx = [self editingContext];
    if (ctx == nil || ctx.getPointsCount == 0)
        return;
    if (!useNearbyRoads && ![self isTerrainElevationAvailable])
        return;

    [self invalidateElevationCalculationShouldNotify:NO];
    [self invalidateTerrainElevationGpx];

    if (useNearbyRoads)
    {
        [self startNearbyRoadsApproximationForContext:ctx];
        return;
    }

    NSArray<OASWptPt *> *points = [ctx.getPoints copy];
    if (points.count == 0)
        return;

    NSMutableArray<NSNumber *> *originalIndexMap = [NSMutableArray array];
    NSMutableArray<OASWptPt *> *densifiedPoints = [self densifiedPointsFromPoints:points originalIndexMap:originalIndexMap];
    [self fetchAndApplyAltitudesForDensifiedPoints:densifiedPoints points:points originalIndexMap:originalIndexMap context:ctx];
}

- (void)startNearbyRoadsApproximationForContext:(OAMeasurementEditingContext *)ctx
{
    NSArray<NSArray<OASWptPt *> *> *segments = [ctx getPointsSegments:YES route:YES];
    if (segments.count == 0)
        return;

    OAGpxApproximationParams *params = [[OAGpxApproximationParams alloc] init];
    params.appMode = ctx.appMode ?: [OAApplicationMode DEFAULT];
    params.distanceThreshold = 50;
    [params setTrackPoints:segments];
    _elevationHelper = [[OAGpxApproximationHelper alloc] initWithLocations:params.locationsHolders initialAppMode:params.appMode initialThreshold:params.distanceThreshold];
    _elevationHelper.delegate = self;
    _elevationHelperRequestId = _elevationCalculationRequestId;
    _elevationCalculationContext = ctx;
    _isCalculatingElevation = YES;
    if (self.onChange)
        self.onChange();

    [_elevationHelper calculateGpxApproximationAsync];
}

- (NSMutableArray<OASWptPt *> *)densifiedPointsFromPoints:(NSArray<OASWptPt *> *)points originalIndexMap:(NSMutableArray<NSNumber *> *)originalIndexMap
{
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
        NSInteger steps = (NSInteger)ceil(segDist / interval);
        for (NSInteger s = 1; s < steps; s++)
        {
            double frac = (double)s / (double)steps;
            OASWptPt *interp = [[OASWptPt alloc] init];
            interp.lat = current.lat + (next.lat - current.lat) * frac;
            interp.lon = current.lon + (next.lon - current.lon) * frac;
            [densifiedPoints addObject:interp];
        }
    }

    return densifiedPoints;
}

- (void)fetchAndApplyAltitudesForDensifiedPoints:(NSMutableArray<OASWptPt *> *)densifiedPoints
                                          points:(NSArray<OASWptPt *> *)points
                                originalIndexMap:(NSMutableArray<NSNumber *> *)originalIndexMap
                                         context:(OAMeasurementEditingContext *)ctx
{
    NSMutableArray<OASWptPt *> *updatedPoints = [NSMutableArray arrayWithCapacity:points.count];
    for (OASWptPt *point in points)
    {
        [updatedPoints addObject:[[OASWptPt alloc] initWithWptPt:point]];
    }

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

    __weak __typeof(self) weakSelf = self;
    __weak OAMeasurementEditingContext *weakCtx = ctx;
    [mapViewController fetchAltitudesForCoordinates:coordinates callback:^(NSArray<NSNumber *> *heights) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong __typeof(weakSelf) strongSelf = weakSelf;
            OAMeasurementEditingContext *strongCtx = weakCtx;
            if (strongSelf == nil || strongCtx == nil)
                return;
            [strongSelf handleFetchedAltitudes:heights
                                     requestId:requestId
                               snapshotVersion:snapshotVersion
                               densifiedPoints:densifiedPoints
                                 updatedPoints:updatedPoints
                              originalIndexMap:originalIndexMap
                                 nonGapIndices:nonGapIndices
                                       context:strongCtx];
        });
    }];
}

- (void)handleFetchedAltitudes:(NSArray<NSNumber *> *)heights
                     requestId:(NSUInteger)requestId
               snapshotVersion:(NSUInteger)snapshotVersion
               densifiedPoints:(NSMutableArray<OASWptPt *> *)densifiedPoints
                 updatedPoints:(NSMutableArray<OASWptPt *> *)updatedPoints
              originalIndexMap:(NSMutableArray<NSNumber *> *)originalIndexMap
                 nonGapIndices:(NSMutableArray<NSNumber *> *)nonGapIndices
                       context:(OAMeasurementEditingContext *)ctx
{
    if (requestId != self->_elevationCalculationRequestId)
        return;

    if (ctx != [self editingContext])
        return;

    if (snapshotVersion != self->_pointsVersion)
    {
        self->_isCalculatingElevation = NO;
        if (self.onChange)
            self.onChange();
        return;
    }
    
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
        self->_terrainElevationGpxFile = [OARouteExporter exportTrackWithPoints:densifiedPoints];
        self->_terrainElevationVersion = self->_pointsVersion;
    }
    
    self->_isCalculatingElevation = NO;
    if (self.onChange)
        self.onChange();
}

- (void)invalidateElevationCalculationShouldNotify:(BOOL)shouldNotify
{
    _elevationCalculationRequestId++;
    _elevationHelper.delegate = nil;
    [_elevationHelper cancelApproximation];
    _elevationHelper = nil;
    _elevationCalculationContext = nil;
    _isCalculatingElevation = NO;
    if (shouldNotify && self.onChange)
        self.onChange();
}

- (void)cancelElevationCalculation
{
    [self invalidateElevationCalculationShouldNotify:YES];
}

// MARK: - Chart highlight on map

- (OAGPXLayer *)gpxLayer
{
    return OARootViewController.instance.mapPanel.mapViewController.mapLayers.gpxMapLayer;
}

- (void)hideChartHighlight
{
    [self.gpxLayer hideCurrentStatisticsLocation];
}

- (void)showChartHighlightedLocation:(TrackChartPoints *)points
{
    [self.gpxLayer showCurrentHighlitedLocation:points];
}

- (void)showChartStatisticsLocation:(TrackChartPoints *)points
{
    [self.gpxLayer showCurrentStatisticsLocation:points];
}

// MARK: - OASnapToRoadProgressDelegate

- (void)showProgressBar
{
    _isCalculatingRoute = YES;
    _lastRouteInfoRefreshTime = 0;
    if (self.onChange)
        self.onChange();
}

- (void)hideProgressBar
{
    _isCalculatingRoute = NO;
    _lastRouteInfoRefreshTime = 0;
    if (self.onChange)
        self.onChange();
}

- (void)refresh
{
    NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];
    if (currentTime - _lastRouteInfoRefreshTime < kRouteInfoRefreshInterval)
        return;
    _lastRouteInfoRefreshTime = currentTime;
    if (self.onRouteInfoChanged)
        self.onRouteInfoChanged();
}

#pragma mark - OAPlanningPopupDelegate

- (void)onPopupDismissed
{
    UIViewController *controller = _approximationPopupController.navigationController ?: _approximationPopupController;
    _approximationPopupController = nil;
    if (controller.presentingViewController != nil)
        [controller dismissViewControllerAnimated:YES completion:nil];
    if (self.onApproximationPopupDismissed)
        self.onApproximationPopupDismissed();
}

- (void)onCancelSnapApproximation:(BOOL)hasApproximationStarted
{
    OAMeasurementEditingContext *ctx = [self editingContext];
    ctx.inApproximationMode = NO;
    if (hasApproximationStarted)
        [ctx.commandManager undo];
    [[self layer] updateLayer];
    [self invalidateTerrainElevationGpx];
    if (self.onChange)
        self.onChange();
}

- (void)onContinueSnapApproximation:(OAPlanningPopupBaseViewController *)approximationController
{
    _approximationPopupController = approximationController;
}

- (void)onApplyGpxApproximation
{
    [self editingContext].inApproximationMode = NO;
    _approximationPopupController = nil;
    [[self layer] updateLayer];
    [self invalidateTerrainElevationGpx];
    if (self.onChange)
        self.onChange();
    if (self.onApproximationPopupDismissed)
        self.onApproximationPopupDismissed();
}

- (void)onGpxApproximationDone:(NSArray<OAGpxRouteApproximation *> *)gpxApproximations
                    pointsList:(NSArray<NSArray<OASWptPt *> *> *)pointsList
                          mode:(OAApplicationMode *)mode
{
    OAMeasurementEditingContext *ctx = [self editingContext];
    OAMeasurementToolLayer *layer = [self layer];
    if (ctx == nil || layer == nil)
        return;
    if (gpxApproximations.count == 0 || pointsList.count != gpxApproximations.count)
        return;
    BOOL wasApproximationMode = ctx.approximationMode;
    ctx.approximationMode = YES;
    OAApplyGpxApproximationCommand *command = [[OAApplyGpxApproximationCommand alloc] initWithLayer:layer approximations:gpxApproximations segmentPointsList:pointsList appMode:mode];
    if (!wasApproximationMode || ![ctx.commandManager update:command])
        [ctx.commandManager execute:command];
    [layer updateLayer];
    [self invalidateTerrainElevationGpx];
    if (self.onChange)
        self.onChange();
}

- (OAMeasurementEditingContext *)getCurrentEditingContext
{
    return [self editingContext];
}

// MARK: - OAGpxApproximationHelperDelegate

- (void)didStartProgress {}
- (void)didApproximationStarted {}
- (void)didUpdateProgress:(NSInteger)progress {}

- (void)didFinishAllApproximationsWithResults:(NSArray<OAGpxRouteApproximation *> *)approximations
                                       points:(NSArray<NSArray<OASWptPt *> *> *)points
{
    if (_elevationHelperRequestId != _elevationCalculationRequestId)
        return;

    OAMeasurementEditingContext *ctx = _elevationCalculationContext;
    if (ctx == nil || ctx != [self editingContext])
    {
        _elevationHelper = nil;
        return;
    }

    if (approximations.count > 0 && points.count == approximations.count)
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
    _elevationCalculationContext = nil;
    if (self.onChange)
        self.onChange();
}

@end
