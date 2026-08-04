//
//  OAAisTrackerLayer.m
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 11.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import "OAAisTrackerLayer.h"
#import "AisObjectDrawable.h"
#import "OAMapRendererView.h"
#import "OAPluginsHelper.h"
#import "OATargetPoint.h"
#import "OAPointDescription.h"
#import "Localization.h"
#import "OAAppSettings.h"
#import "GeneratedAssetSymbols.h"
#import "OsmAnd_Maps-Swift.h"

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/MapMarkersCollection.h>
#include <OsmAndCore/Map/VectorLinesCollection.h>
#include <cmath>
#include <cstdint>
#include <unordered_map>
#include <unordered_set>
#include <vector>

static NSString * const kAisTrackerLayerId = @"ais_tracker_layer";
static const int kAisTrackerStartZoom = 6;
static const int kAisSpatialIndexZoom = 8;
static const int kAisMaxRenderedObjects = 1000;
static const int kAisMaxProjectionCandidates = 4000;
static const int kAisCoarseCandidatesPerCell = 4;
static const CGFloat kAisCollisionPadding = 4.0;
static const CGFloat kAisViewportMarginFactor = 0.2;
static const float kAisRenderZoomEpsilon = 0.02f;
static const NSTimeInterval kAisViewportRenderUpdateInterval = 0.2;

static NSInteger OAAisVisualState(OASAisObject *object, AisTrackerPlugin *plugin)
{
    if ([object isVesselAtRest])
        return 1;
    NSInteger lostTimeout = plugin ? [plugin vesselLostTimeoutInMinutes] : 0;
    return lostTimeout > 0 && [object isLostMaxAgeInMin:(int32_t)lostTimeout] ? 2 : 0;
}

static uint64_t OAAisSpatialBucketKey(const OsmAnd::PointI& position31)
{
    const uint32_t shift = OsmAnd::ZoomLevel::MaxZoomLevel - kAisSpatialIndexZoom;
    const uint64_t x = ((uint32_t)position31.x) >> shift;
    const uint64_t y = ((uint32_t)position31.y) >> shift;
    return (x << 32) | y;
}

static BOOL OAAisTypeEquals(OASAisObjType *type, OASAisObjType *expected)
{
    return type == expected || [type isEqual:expected];
}

static BOOL OAAisIsEmergencyObject(OASAisObject *object)
{
    return OAAisTypeEquals(object.objectClass, OASAisObjType.aisSart)
        || OAAisTypeEquals(object.objectClass, OASAisObjType.aisVesselSar);
}

static NSString *OAAisObjectTitle(OASAisObject *object)
{
    return [NSString stringWithFormat:OALocalizedString(@"ais_object_with_mmsi"), (long)object.mmsi];
}

static NSDate *OAAisLastUpdateDate(OASAisObject *object)
{
    return [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)object.lastUpdate / 1000.0];
}

static CLLocation *OAAisObjectLocation(OASAisObject *object)
{
    OASAisLocation *location = [object getAisLocation];
    if (!location)
        return nil;
    CLLocationDistance altitude = object.altitude == OASAisObjectConstants.shared.INVALID_ALTITUDE ? 0 : object.altitude;
    return [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(location.latitude, location.longitude)
                                        altitude:altitude
                              horizontalAccuracy:20
                                verticalAccuracy:-1
                                          course:location.hasBearing ? location.bearing : -1
                                           speed:location.hasSpeed ? location.speed : -1
                                       timestamp:OAAisLastUpdateDate(object)];
}

static NSString *OAAisMessageTypesString(OASAisObject *object)
{
    NSMutableArray<NSString *> *values = [NSMutableArray array];
    for (OASInt *type in object.msgTypes)
        [values addObject:[NSString stringWithFormat:@"%d", type.intValue]];
    [values sortUsingSelector:@selector(compare:)];
    return [values componentsJoinedByString:@", "];
}

static NSString *OAAisDebugSummary(OASAisObject *object)
{
    NSString *positionText = object.position
        ? [NSString stringWithFormat:@"%.6f,%.6f", object.position.latitude, object.position.longitude]
        : @"none";
    NSTimeInterval age = [[NSDate date] timeIntervalSinceDate:OAAisLastUpdateDate(object)];
    return [NSString stringWithFormat:@"mmsi=%d msg=%d msgs=%@ class=%@ shipType=%d rest=%@ movable=%@ nav=%d sog=%.1f cog=%.1f heading=%d pos=%@ age=%.1fs",
            object.mmsi,
            object.msgType,
            OAAisMessageTypesString(object),
            object.objectClass.name,
            object.shipType,
            [object isVesselAtRest] ? @"yes" : @"no",
            [object isMovable] ? @"yes" : @"no",
            object.navStatus,
            object.sog,
            object.cog,
            object.heading,
            positionText,
            age];
}

@interface AisObjectRenderRecord : NSObject

@property (nonatomic, strong) OASAisObject *object;
@property (nonatomic) OsmAnd::PointI position31;
@property (nonatomic) uint64_t bucketKey;
@property (nonatomic) uint64_t version;
@property (nonatomic) CGPoint screenPoint;
@property (nonatomic) BOOL hasScreenPoint;
@property (nonatomic) BOOL cpaWarning;
@property (nonatomic) NSInteger visualState;
@property (nonatomic) BOOL emergency;
@property (nonatomic) BOOL movable;
@property (nonatomic) int64_t lastUpdate;

@end

@implementation AisObjectRenderRecord
@end

@interface OAAisTrackerLayer ()

- (BOOL)shouldUpdateRenderDataForViewport;
- (void)scheduleFrameRefresh;

@end

@implementation OAAisTrackerLayer
{
    AisTrackerPlugin *_plugin;
    NSMutableDictionary<NSNumber *, AisObjectRenderRecord *> *_objectRecords;
    NSMutableDictionary<NSNumber *, NSMutableSet<NSNumber *> *> *_spatialBuckets;
    NSMutableDictionary<NSNumber *, AisObjectDrawable *> *_objectDrawables;
    NSMutableDictionary<NSNumber *, AisObjectRenderRecord *> *_renderedRecords;
    NSNumber *_selectedMmsi;
    std::shared_ptr<OsmAnd::MapMarkersCollection> _markersCollection;
    std::shared_ptr<OsmAnd::VectorLinesCollection> _vectorLinesCollection;
    BOOL _collectionsAdded;
    BOOL _indexLoaded;
    BOOL _dataDirty;
    BOOL _refreshScheduled;
    uint64_t _nextObjectVersion;
    NSUInteger _peakDrawableCount;
    CGFloat _textScale;
    CGFloat _displayDensityFactor;
    BOOL _hasLastRenderViewport;
    OsmAnd::AreaI _lastRenderBBox31;
    int _lastRenderZoom;
    float _lastRenderSurfaceZoom;
    NSTimeInterval _lastViewportRenderUpdateTime;
}

- (instancetype)initWithMapViewController:(OAMapViewController *)mapViewController baseOrder:(int)baseOrder
{
    self = [super initWithMapViewController:mapViewController baseOrder:baseOrder];
    if (self)
    {
        _plugin = (AisTrackerPlugin *)[OAPluginsHelper getPlugin:AisTrackerPlugin.class];
        _objectRecords = [NSMutableDictionary dictionary];
        _spatialBuckets = [NSMutableDictionary dictionary];
        _objectDrawables = [NSMutableDictionary dictionary];
        _renderedRecords = [NSMutableDictionary dictionary];
        _textScale = [OAAisTrackerLayer currentTextScale];
        _displayDensityFactor = MAX(1.0, mapViewController.displayDensityFactor);
        _nextObjectVersion = 1;
        _hasLastRenderViewport = NO;
        _lastRenderZoom = -1;
        _lastRenderSurfaceZoom = -1.0f;
        _lastViewportRenderUpdateTime = 0;
    }
    return self;
}

- (NSString *)layerId
{
    return kAisTrackerLayerId;
}

- (AisTrackerPlugin *)plugin
{
    if (!_plugin)
        _plugin = (AisTrackerPlugin *)[OAPluginsHelper getPlugin:AisTrackerPlugin.class];
    return _plugin;
}

- (void)ensureStorage
{
    if (!_objectRecords)
        _objectRecords = [NSMutableDictionary dictionary];
    if (!_spatialBuckets)
        _spatialBuckets = [NSMutableDictionary dictionary];
    if (!_objectDrawables)
        _objectDrawables = [NSMutableDictionary dictionary];
    if (!_renderedRecords)
        _renderedRecords = [NSMutableDictionary dictionary];
}

+ (CGFloat)currentTextScale
{
    CGFloat textScale = [[OAAppSettings sharedManager].textSize get];
    return textScale > 0 ? textScale : 1.0;
}

- (CGFloat)currentDisplayDensityFactor
{
    CGFloat displayDensityFactor = self.mapViewController.displayDensityFactor;
    if (displayDensityFactor <= 0)
        displayDensityFactor = UIScreen.mainScreen.scale;
    return MAX(1.0, displayDensityFactor);
}

- (CGFloat)currentIconSizeInPoints
{
    return [AisObjectDrawable baseIconSize] * _textScale;
}

- (BOOL)updateScaleCache
{
    CGFloat textScale = [OAAisTrackerLayer currentTextScale];
    CGFloat displayDensityFactor = [self currentDisplayDensityFactor];
    BOOL changed = fabs(_textScale - textScale) > 0.0001 || fabs(_displayDensityFactor - displayDensityFactor) > 0.0001;
    if (changed)
    {
        _textScale = textScale;
        _displayDensityFactor = displayDensityFactor;
    }
    return changed;
}

- (void)initLayer
{
    [super initLayer];
    [self ensureStorage];
    [self resetCollections];
    [self.app.data.mapLayersConfiguration setLayer:self.layerId
                                        Visibility:self.isVisible];
}

- (void)deinitLayer
{
    [self cleanupResources];
    [super deinitLayer];
}

- (BOOL)isVisible
{
    return [[self plugin] isActiveForCurrentProfile];
}

- (void)show
{
    [self addCollectionsToRenderer];
    if (!_indexLoaded)
        [self rebuildObjectIndex];
    _dataDirty = YES;
    [self scheduleFrameRefresh];
}

- (void)hide
{
    _selectedMmsi = nil;
    [self cleanupResources];
}

- (BOOL)updateLayer
{
    if (![super updateLayer])
        return NO;
    BOOL scaleChanged = [self updateScaleCache];
    if (scaleChanged)
    {
        [AisObjectDrawable clearImageCache];
        [self cleanupResources];
    }

    [self.app.data.mapLayersConfiguration setLayer:self.layerId
                                        Visibility:self.isVisible];
    if ([self isVisible])
    {
        [self addCollectionsToRenderer];
        if (!_indexLoaded)
            [self rebuildObjectIndex];
        _dataDirty = YES;
        [self scheduleFrameRefresh];
    }
    else
    {
        _selectedMmsi = nil;
        [self cleanupResources];
    }
    return YES;
}

- (void)onMapFrameRendered
{
    if (![self isVisible])
    {
        _selectedMmsi = nil;
        if (_collectionsAdded || _objectDrawables.count > 0 || _objectRecords.count > 0)
        {
            [AisObjectDrawable clearImageCache];
            [self cleanupResources];
        }
        return;
    }
    if (![self shouldUpdateRenderDataForViewport])
        return;
    [self updateRenderData];
}

- (void)didReceiveMemoryWarning
{
    [AisObjectDrawable clearImageCache];
    [self cleanupResources];
    if ([self isVisible])
    {
        [self addCollectionsToRenderer];
        [self rebuildObjectIndex];
        [self scheduleFrameRefresh];
    }
    [super didReceiveMemoryWarning];
}

- (void)resetCollections
{
    _markersCollection = std::make_shared<OsmAnd::MapMarkersCollection>();
    _vectorLinesCollection = std::make_shared<OsmAnd::VectorLinesCollection>();
}

- (void)addCollectionsToRenderer
{
    if (!_markersCollection || !_vectorLinesCollection)
        [self resetCollections];
    if (_collectionsAdded)
        return;

    [self.mapViewController runWithRenderSync:^{
        [self.mapView addKeyedSymbolsProvider:_markersCollection];
        [self.mapView addKeyedSymbolsProvider:_vectorLinesCollection];
        _collectionsAdded = YES;
    }];
}

- (void)cleanupResources
{
    [AisObjectDrawable clearImageCache];
    [self.mapViewController runWithRenderSync:^{
        if (_markersCollection)
            _markersCollection->removeAllMarkers();
        if (_vectorLinesCollection)
            _vectorLinesCollection->removeAllLines();
        if (_collectionsAdded)
        {
            if (_markersCollection)
                [self.mapView removeKeyedSymbolsProvider:_markersCollection];
            if (_vectorLinesCollection)
                [self.mapView removeKeyedSymbolsProvider:_vectorLinesCollection];
            _collectionsAdded = NO;
        }
    }];
    [_objectRecords removeAllObjects];
    [_spatialBuckets removeAllObjects];
    [_objectDrawables removeAllObjects];
    [_renderedRecords removeAllObjects];
    _indexLoaded = NO;
    _dataDirty = NO;
    _peakDrawableCount = 0;
    _hasLastRenderViewport = NO;
    _lastViewportRenderUpdateTime = 0;
    [self resetCollections];
}

- (void)reloadAisObjects
{
    [self cleanupResources];
    if ([self isVisible])
    {
        [self addCollectionsToRenderer];
        [self rebuildObjectIndex];
        [self scheduleFrameRefresh];
    }
}

- (void)addRecordToSpatialIndex:(AisObjectRenderRecord *)record
{
    NSNumber *bucketKey = @(record.bucketKey);
    NSMutableSet<NSNumber *> *bucket = _spatialBuckets[bucketKey];
    if (!bucket)
    {
        bucket = [NSMutableSet set];
        _spatialBuckets[bucketKey] = bucket;
    }
    [bucket addObject:@(record.object.mmsi)];
}

- (void)removeRecordFromSpatialIndex:(AisObjectRenderRecord *)record
{
    NSNumber *bucketKey = @(record.bucketKey);
    NSMutableSet<NSNumber *> *bucket = _spatialBuckets[bucketKey];
    [bucket removeObject:@(record.object.mmsi)];
    if (bucket.count == 0)
        [_spatialBuckets removeObjectForKey:bucketKey];
}

- (void)upsertObjectInIndex:(OASAisObject *)object
{
    if (!object.position)
        return;

    [self ensureStorage];
    NSNumber *key = @(object.mmsi);
    AisObjectRenderRecord *record = _objectRecords[key];
    if (!record)
    {
        record = [AisObjectRenderRecord new];
        _objectRecords[key] = record;
    }
    else
    {
        [self removeRecordFromSpatialIndex:record];
    }

    record.object = object;
    record.position31 = OsmAnd::PointI(OsmAnd::Utilities::get31TileNumberX(object.position.longitude),
                                       OsmAnd::Utilities::get31TileNumberY(object.position.latitude));
    record.bucketKey = OAAisSpatialBucketKey(record.position31);
    record.version = _nextObjectVersion++;
    record.hasScreenPoint = NO;
    record.emergency = OAAisIsEmergencyObject(object);
    record.movable = [object isMovable];
    record.lastUpdate = object.lastUpdate;
    [self addRecordToSpatialIndex:record];
}

- (void)removeObjectFromIndex:(OASAisObject *)object
{
    NSNumber *key = @(object.mmsi);
    AisObjectRenderRecord *record = _objectRecords[key];
    if (record)
    {
        [self removeRecordFromSpatialIndex:record];
        [_objectRecords removeObjectForKey:key];
    }
}

- (void)rebuildObjectIndex
{
    [self ensureStorage];
    [_objectRecords removeAllObjects];
    [_spatialBuckets removeAllObjects];
    for (OASAisObject *object in [[self plugin] getAisObjects])
    {
        if (object.position)
            [self upsertObjectInIndex:object];
    }
    _indexLoaded = YES;
    _dataDirty = YES;
}

- (void)onAisObjectReceived:(OASAisObject *)object
{
    if (![self isVisible] || !object)
        return;
    if ([AisLogger shared].isEnabled)
        [[AisLogger shared] log:[NSString stringWithFormat:@"receive %@", OAAisDebugSummary(object)]];
    [self addCollectionsToRenderer];
    if (object.position)
        [self upsertObjectInIndex:object];
    else
        [self removeObjectFromIndex:object];
    _indexLoaded = YES;
    _dataDirty = YES;
    [self scheduleFrameRefresh];
}

- (void)onAisObjectRemoved:(OASAisObject *)object
{
    if (!object)
        return;

    NSNumber *key = @(object.mmsi);
    if ([_selectedMmsi isEqualToNumber:key])
        _selectedMmsi = nil;
    if ([AisLogger shared].isEnabled)
        [[AisLogger shared] log:[NSString stringWithFormat:@"remove hasDrawable=%@ drawables=%lu %@",
                                 _objectDrawables[key] ? @"yes" : @"no",
                                 (unsigned long)_objectDrawables.count,
                                 OAAisDebugSummary(object)]];
    [self removeObjectFromIndex:object];
    _dataDirty = YES;
    [self scheduleFrameRefresh];
}

- (NSArray<AisObjectRenderRecord *> *)recordsInArea:(const OsmAnd::AreaI&)area
{
    if (area.width() <= 0 || area.height() <= 0)
        return @[];

    const uint32_t shift = OsmAnd::ZoomLevel::MaxZoomLevel - kAisSpatialIndexZoom;
    const uint32_t minX = ((uint32_t)area.left()) >> shift;
    const uint32_t maxX = ((uint32_t)area.right()) >> shift;
    const uint32_t minY = ((uint32_t)area.top()) >> shift;
    const uint32_t maxY = ((uint32_t)area.bottom()) >> shift;
    NSMutableArray<AisObjectRenderRecord *> *records = [NSMutableArray array];

    for (uint32_t x = minX; x <= maxX; x++)
    {
        for (uint32_t y = minY; y <= maxY; y++)
        {
            NSNumber *bucketKey = @(((uint64_t)x << 32) | y);
            for (NSNumber *mmsi in _spatialBuckets[bucketKey])
            {
                AisObjectRenderRecord *record = _objectRecords[mmsi];
                if (record && area.contains(record.position31))
                    [records addObject:record];
            }
        }
    }
    return records;
}

- (NSArray<AisObjectRenderRecord *> *)recordsInVisibleTilesAtZoom:(int)zoom
{
    const QVector<OsmAnd::TileId> visibleTiles = self.mapView.visibleTiles;
    if (visibleTiles.isEmpty())
        return @[];

    const int sourceZoom = MAX(0, MIN(30, zoom));
    const int64_t sourceTileCount = (int64_t)1 << sourceZoom;
    NSMutableSet<NSNumber *> *bucketKeys = [NSMutableSet set];
    for (const OsmAnd::TileId& tile : visibleTiles)
    {
        for (int offsetX = -1; offsetX <= 1; offsetX++)
        {
            int64_t sourceX = ((int64_t)tile.x + offsetX) % sourceTileCount;
            if (sourceX < 0)
                sourceX += sourceTileCount;
            for (int offsetY = -1; offsetY <= 1; offsetY++)
            {
                const int64_t sourceY = (int64_t)tile.y + offsetY;
                if (sourceY < 0 || sourceY >= sourceTileCount)
                    continue;

                if (sourceZoom >= kAisSpatialIndexZoom)
                {
                    const int shift = sourceZoom - kAisSpatialIndexZoom;
                    const uint64_t bucketX = (uint64_t)sourceX >> shift;
                    const uint64_t bucketY = (uint64_t)sourceY >> shift;
                    [bucketKeys addObject:@((bucketX << 32) | bucketY)];
                }
                else
                {
                    const int shift = kAisSpatialIndexZoom - sourceZoom;
                    const uint32_t firstX = (uint32_t)sourceX << shift;
                    const uint32_t firstY = (uint32_t)sourceY << shift;
                    const uint32_t childCount = 1u << shift;
                    for (uint32_t childX = 0; childX < childCount; childX++)
                    {
                        for (uint32_t childY = 0; childY < childCount; childY++)
                            [bucketKeys addObject:@(((uint64_t)(firstX + childX) << 32) | (firstY + childY))];
                    }
                }
            }
        }
    }

    NSMutableArray<AisObjectRenderRecord *> *records = [NSMutableArray array];
    for (NSNumber *bucketKey in bucketKeys)
    {
        for (NSNumber *mmsi in _spatialBuckets[bucketKey])
        {
            AisObjectRenderRecord *record = _objectRecords[mmsi];
            if (record)
                [records addObject:record];
        }
    }
    return records;
}

- (NSComparisonResult)compareCoarseRecord:(AisObjectRenderRecord *)first
                                 toRecord:(AisObjectRenderRecord *)second
{
    if (first.emergency != second.emergency)
        return first.emergency ? NSOrderedAscending : NSOrderedDescending;
    BOOL firstMoving = first.visualState == 0 && first.movable;
    BOOL secondMoving = second.visualState == 0 && second.movable;
    if (firstMoving != secondMoving)
        return firstMoving ? NSOrderedAscending : NSOrderedDescending;
    if (first.lastUpdate != second.lastUpdate)
        return first.lastUpdate > second.lastUpdate ? NSOrderedAscending : NSOrderedDescending;
    if (first.object.mmsi == second.object.mmsi)
        return NSOrderedSame;
    return first.object.mmsi < second.object.mmsi ? NSOrderedAscending : NSOrderedDescending;
}

- (NSComparisonResult)compareSafetyRecord:(AisObjectRenderRecord *)first
                                 toRecord:(AisObjectRenderRecord *)second
{
    if (first.cpaWarning != second.cpaWarning)
        return first.cpaWarning ? NSOrderedAscending : NSOrderedDescending;
    if (first.emergency != second.emergency)
        return first.emergency ? NSOrderedAscending : NSOrderedDescending;
    BOOL firstRendered = _objectDrawables[@(first.object.mmsi)] != nil;
    BOOL secondRendered = _objectDrawables[@(second.object.mmsi)] != nil;
    if (firstRendered != secondRendered)
        return firstRendered ? NSOrderedAscending : NSOrderedDescending;
    BOOL firstMoving = first.visualState == 0 && first.movable;
    BOOL secondMoving = second.visualState == 0 && second.movable;
    if (firstMoving != secondMoving)
        return firstMoving ? NSOrderedAscending : NSOrderedDescending;
    if (first.lastUpdate != second.lastUpdate)
        return first.lastUpdate > second.lastUpdate ? NSOrderedAscending : NSOrderedDescending;
    if (first.object.mmsi == second.object.mmsi)
        return NSOrderedSame;
    return first.object.mmsi < second.object.mmsi ? NSOrderedAscending : NSOrderedDescending;
}

- (NSComparisonResult)compareIncumbentRecord:(AisObjectRenderRecord *)first
                                    toRecord:(AisObjectRenderRecord *)second
{
    BOOL firstMoving = first.visualState == 0 && first.movable;
    BOOL secondMoving = second.visualState == 0 && second.movable;
    if (firstMoving != secondMoving)
        return firstMoving ? NSOrderedAscending : NSOrderedDescending;
    if (first.object.mmsi == second.object.mmsi)
        return NSOrderedSame;
    return first.object.mmsi < second.object.mmsi ? NSOrderedAscending : NSOrderedDescending;
}

- (NSComparisonResult)compareNewRecord:(AisObjectRenderRecord *)first
                              toRecord:(AisObjectRenderRecord *)second
{
    BOOL firstMoving = first.visualState == 0 && first.movable;
    BOOL secondMoving = second.visualState == 0 && second.movable;
    if (firstMoving != secondMoving)
        return firstMoving ? NSOrderedAscending : NSOrderedDescending;
    if (first.lastUpdate != second.lastUpdate)
        return first.lastUpdate > second.lastUpdate ? NSOrderedAscending : NSOrderedDescending;
    if (first.object.mmsi == second.object.mmsi)
        return NSOrderedSame;
    return first.object.mmsi < second.object.mmsi ? NSOrderedAscending : NSOrderedDescending;
}

- (NSMutableDictionary<NSNumber *, AisObjectRenderRecord *> *)selectRecordsForVisibleArea:(const OsmAnd::AreaI&)visibleArea
                                                                                     zoom:(int)zoom
                                                                           candidateCount:(NSUInteger *)candidateCount
                                                                          projectionCount:(NSUInteger *)projectionCount
                                                                   collisionRejectedCount:(NSUInteger *)collisionRejectedCount
                                                          safetyDisplacersByIncumbent:(NSMutableDictionary<NSNumber *, NSMutableSet<NSNumber *> *> **)safetyDisplacersByIncumbent
{
    NSMutableDictionary<NSNumber *, AisObjectRenderRecord *> *selected = [NSMutableDictionary dictionary];
    NSMutableDictionary<NSNumber *, NSMutableSet<NSNumber *> *> *safetyDisplacers = [NSMutableDictionary dictionary];
    if (safetyDisplacersByIncumbent)
        *safetyDisplacersByIncumbent = safetyDisplacers;
    const int64_t visibleWidth = (int64_t)visibleArea.right() - visibleArea.left();
    const int64_t visibleHeight = (int64_t)visibleArea.bottom() - visibleArea.top();
    if (visibleWidth <= 0 || visibleHeight <= 0)
        return selected;

    AisObjectRenderRecord *selectedRecord = _selectedMmsi ? _objectRecords[_selectedMmsi] : nil;
    const BOOL detailZoom = zoom >= kAisTrackerStartZoom;
    const int64_t marginX = (int64_t)std::round(visibleWidth * kAisViewportMarginFactor);
    const int64_t marginY = (int64_t)std::round(visibleHeight * kAisViewportMarginFactor);
    const int32_t expandedLeft = (int32_t)MAX((int64_t)0, (int64_t)visibleArea.left() - marginX);
    const int32_t expandedTop = (int32_t)MAX((int64_t)0, (int64_t)visibleArea.top() - marginY);
    const int32_t expandedRight = (int32_t)MIN((int64_t)INT32_MAX, (int64_t)visibleArea.right() + marginX);
    const int32_t expandedBottom = (int32_t)MIN((int64_t)INT32_MAX, (int64_t)visibleArea.bottom() + marginY);
    const OsmAnd::AreaI expandedArea(expandedTop, expandedLeft, expandedBottom, expandedRight);
    const BOOL wrappedViewport = visibleWidth > INT32_MAX / 2;
    NSArray<AisObjectRenderRecord *> *candidates = detailZoom
        ? (wrappedViewport ? [self recordsInVisibleTilesAtZoom:zoom] : [self recordsInArea:expandedArea])
        : @[];
    if (candidateCount)
        *candidateCount = candidates.count;

    AisTrackerPlugin *plugin = [self plugin];
    for (AisObjectRenderRecord *record in candidates)
    {
        record.visualState = OAAisVisualState(record.object, plugin);
        record.cpaWarning = NO;
        record.hasScreenPoint = NO;
    }
    if (selectedRecord)
    {
        selectedRecord.visualState = OAAisVisualState(selectedRecord.object, plugin);
        selectedRecord.cpaWarning = NO;
        selectedRecord.hasScreenPoint = NO;
    }

    const CGFloat footprint = [self currentIconSizeInPoints] + kAisCollisionPadding;
    CGRect viewportBounds = self.mapView.bounds;
    CGRect renderBounds = CGRectInset(viewportBounds,
                                      -viewportBounds.size.width * kAisViewportMarginFactor,
                                      -viewportBounds.size.height * kAisViewportMarginFactor);
    const NSUInteger columns = MAX(1, (NSUInteger)ceil(renderBounds.size.width / footprint));
    const NSUInteger rows = MAX(1, (NSUInteger)ceil(renderBounds.size.height / footprint));
    const NSUInteger renderBudget = detailZoom
        ? MIN((NSUInteger)kAisMaxRenderedObjects, columns * rows)
        : (selectedRecord ? 1 : 0);
    const double referenceTileSize = MAX(1u, self.mapViewController.referenceTileSizeRasterOrigInPixels);
    const double tileSize31 = std::pow(2.0, OsmAnd::ZoomLevel::MaxZoomLevel - self.mapView.zoom);
    const double coarseCellSize31 = MAX(1.0,
        footprint * _displayDensityFactor * tileSize31 / referenceTileSize);
    // Incumbents bypass coarse reduction so ordinary freshness updates cannot evict them
    // before exact screen-space collision checks.
    NSMutableArray<AisObjectRenderRecord *> *incumbents = [NSMutableArray array];
    NSMutableSet<NSNumber *> *incumbentKeys = [NSMutableSet set];
    for (AisObjectRenderRecord *record in candidates)
    {
        NSNumber *key = @(record.object.mmsi);
        if ([_selectedMmsi isEqualToNumber:key])
            continue;
        if (_objectDrawables[key])
        {
            [incumbents addObject:record];
            [incumbentKeys addObject:key];
        }
    }
    [incumbents sortUsingComparator:^NSComparisonResult(AisObjectRenderRecord *first, AisObjectRenderRecord *second) {
        if (first.object.mmsi == second.object.mmsi)
            return NSOrderedSame;
        return first.object.mmsi < second.object.mmsi ? NSOrderedAscending : NSOrderedDescending;
    }];

    NSMutableDictionary<NSNumber *, NSMutableArray<AisObjectRenderRecord *> *> *coarseCells = [NSMutableDictionary dictionary];

    for (AisObjectRenderRecord *record in candidates)
    {
        NSNumber *key = @(record.object.mmsi);
        if ([_selectedMmsi isEqualToNumber:key] || [incumbentKeys containsObject:key])
            continue;
        const int64_t cellX = (int64_t)floor(record.position31.x / coarseCellSize31);
        const int64_t cellY = (int64_t)floor(record.position31.y / coarseCellSize31);
        NSNumber *cellKey = @(((uint64_t)(uint32_t)cellX << 32) | (uint32_t)cellY);
        NSMutableArray<AisObjectRenderRecord *> *cell = coarseCells[cellKey];
        if (!cell)
        {
            cell = [NSMutableArray arrayWithCapacity:kAisCoarseCandidatesPerCell];
            coarseCells[cellKey] = cell;
        }
        NSUInteger insertionIndex = cell.count;
        for (NSUInteger index = 0; index < cell.count; index++)
        {
            if ([self compareCoarseRecord:record toRecord:cell[index]] == NSOrderedAscending)
            {
                insertionIndex = index;
                break;
            }
        }
        if (insertionIndex < kAisCoarseCandidatesPerCell)
            [cell insertObject:record atIndex:insertionIndex];
        else if (cell.count < kAisCoarseCandidatesPerCell)
            [cell addObject:record];
        if (cell.count > kAisCoarseCandidatesPerCell)
            [cell removeLastObject];
    }

    const NSUInteger reservedCount = incumbents.count + (selectedRecord ? 1 : 0);
    const NSUInteger projectionBudget = MIN((NSUInteger)kAisMaxProjectionCandidates,
                                            MAX(reservedCount,
                                                MAX(renderBudget, renderBudget * kAisCoarseCandidatesPerCell)));
    NSMutableArray<AisObjectRenderRecord *> *shortlist = [NSMutableArray arrayWithCapacity:projectionBudget];
    if (selectedRecord)
        [shortlist addObject:selectedRecord];
    [shortlist addObjectsFromArray:incumbents];
    NSArray<NSNumber *> *orderedCellKeys = [coarseCells.allKeys sortedArrayUsingSelector:@selector(compare:)];
    for (NSUInteger rank = 0; rank < kAisCoarseCandidatesPerCell && shortlist.count < projectionBudget; rank++)
    {
        for (NSNumber *cellKey in orderedCellKeys)
        {
            NSArray<AisObjectRenderRecord *> *cell = coarseCells[cellKey];
            if (rank < cell.count)
                [shortlist addObject:cell[rank]];
            if (shortlist.count >= projectionBudget)
                break;
        }
    }

    for (AisObjectRenderRecord *record in shortlist)
        record.cpaWarning = [plugin hasCpaWarningFor:record.object];

    NSMutableArray<AisObjectRenderRecord *> *safetyRecords = [NSMutableArray array];
    NSMutableArray<AisObjectRenderRecord *> *incumbentRecords = [NSMutableArray array];
    NSMutableArray<AisObjectRenderRecord *> *newRecords = [NSMutableArray array];
    for (AisObjectRenderRecord *record in shortlist)
    {
        if (record == selectedRecord)
            continue;
        if (record.cpaWarning || record.emergency)
            [safetyRecords addObject:record];
        else if ([incumbentKeys containsObject:@(record.object.mmsi)])
            [incumbentRecords addObject:record];
        else
            [newRecords addObject:record];
    }
    [safetyRecords sortUsingComparator:^NSComparisonResult(AisObjectRenderRecord *first, AisObjectRenderRecord *second) {
        return [self compareSafetyRecord:first toRecord:second];
    }];
    [incumbentRecords sortUsingComparator:^NSComparisonResult(AisObjectRenderRecord *first, AisObjectRenderRecord *second) {
        return [self compareIncumbentRecord:first toRecord:second];
    }];
    [newRecords sortUsingComparator:^NSComparisonResult(AisObjectRenderRecord *first, AisObjectRenderRecord *second) {
        return [self compareNewRecord:first toRecord:second];
    }];

    std::unordered_map<int64_t, std::vector<size_t>> occupiedCells;
    std::vector<CGRect> acceptedRects;
    std::vector<bool> acceptedSafety;
    NSMutableArray<NSNumber *> *acceptedKeys = [NSMutableArray array];
    NSUInteger projected = 0;
    NSUInteger collisionRejected = 0;
    auto trySelectRecord = [&](AisObjectRenderRecord *record, BOOL forceAdmission) {
        if (selected.count >= renderBudget)
            return;

        NSNumber *recordKey = @(record.object.mmsi);
        CGPoint screenPoint;
        OsmAnd::PointI position31 = record.position31;
        projected++;
        if (![self.mapView obtainScreenPointFromPosition:&position31 toScreen:&screenPoint checkOffScreen:YES]
            || !CGRectContainsPoint(renderBounds, screenPoint))
        {
            if (forceAdmission)
                selected[recordKey] = record;
            return;
        }

        CGRect iconRect = CGRectMake(screenPoint.x - footprint * 0.5,
                                     screenPoint.y - footprint * 0.5,
                                     footprint,
                                     footprint);
        record.screenPoint = screenPoint;
        record.hasScreenPoint = YES;
        const int minCellX = (int)floor((CGRectGetMinX(iconRect) - CGRectGetMinX(renderBounds)) / footprint);
        const int maxCellX = (int)floor((CGRectGetMaxX(iconRect) - CGRectGetMinX(renderBounds)) / footprint);
        const int minCellY = (int)floor((CGRectGetMinY(iconRect) - CGRectGetMinY(renderBounds)) / footprint);
        const int maxCellY = (int)floor((CGRectGetMaxY(iconRect) - CGRectGetMinY(renderBounds)) / footprint);
        BOOL overlaps = NO;
        std::unordered_set<size_t> inspectedRects;
        const BOOL incumbent = [incumbentKeys containsObject:recordKey];
        NSMutableSet<NSNumber *> *overlappingSafetyKeys = incumbent ? [NSMutableSet set] : nil;
        for (int cellX = minCellX; cellX <= maxCellX; cellX++)
        {
            for (int cellY = minCellY; cellY <= maxCellY; cellY++)
            {
                const int64_t cellKey = (int64_t)(((uint64_t)(uint32_t)cellX << 32) | (uint32_t)cellY);
                const auto found = occupiedCells.find(cellKey);
                if (found == occupiedCells.end())
                    continue;
                for (size_t rectIndex : found->second)
                {
                    if (!inspectedRects.insert(rectIndex).second)
                        continue;
                    if (CGRectIntersectsRect(iconRect, acceptedRects[rectIndex]))
                    {
                        overlaps = YES;
                        if (incumbent && acceptedSafety[rectIndex])
                            [overlappingSafetyKeys addObject:acceptedKeys[rectIndex]];
                    }
                }
            }
        }
        if (overlaps)
        {
            collisionRejected++;
            if (forceAdmission)
            {
                selected[recordKey] = record;
                return;
            }
            if (overlappingSafetyKeys.count > 0)
                safetyDisplacers[recordKey] = overlappingSafetyKeys;
            return;
        }

        const size_t rectIndex = acceptedRects.size();
        acceptedRects.push_back(iconRect);
        acceptedSafety.push_back(record.cpaWarning || record.emergency);
        [acceptedKeys addObject:recordKey];
        for (int cellX = minCellX; cellX <= maxCellX; cellX++)
        {
            for (int cellY = minCellY; cellY <= maxCellY; cellY++)
            {
                const int64_t cellKey = (int64_t)(((uint64_t)(uint32_t)cellX << 32) | (uint32_t)cellY);
                occupiedCells[cellKey].push_back(rectIndex);
            }
        }
        selected[recordKey] = record;
    };

    // A selected vessel is pinned before decluttering and remains admitted even
    // when its center is outside the retained viewport or the detail zoom range.
    if (selectedRecord)
        trySelectRecord(selectedRecord, YES);

    // Safety targets can displace ordinary incumbents. Ordinary newcomers only
    // fill space left after every still-valid incumbent has been considered.
    for (AisObjectRenderRecord *record in safetyRecords)
    {
        if (selected.count >= renderBudget)
            break;
        trySelectRecord(record, NO);
    }
    for (AisObjectRenderRecord *record in incumbentRecords)
    {
        if (selected.count >= renderBudget)
            break;
        trySelectRecord(record, NO);
    }
    for (AisObjectRenderRecord *record in newRecords)
    {
        if (selected.count >= renderBudget)
            break;
        trySelectRecord(record, NO);
    }
    if (projectionCount)
        *projectionCount = projected;
    if (collisionRejectedCount)
        *collisionRejectedCount = collisionRejected;
    return selected;
}

- (void)updateRenderData
{
    if (![self isVisible])
        return;

    const CFAbsoluteTime started = CFAbsoluteTimeGetCurrent();
    const OsmAnd::AreaI visibleArea = [self.mapView getVisibleBBox31];
    const int zoom = (int)self.mapView.zoomLevel;
    const float surfaceZoom = self.mapView.zoom;
    NSUInteger candidateCount = 0;
    NSUInteger projectionCount = 0;
    NSUInteger collisionRejectedCount = 0;
    NSMutableDictionary<NSNumber *, NSMutableSet<NSNumber *> *> *safetyDisplacers = nil;
    NSMutableDictionary<NSNumber *, AisObjectRenderRecord *> *desiredRecords =
        [self selectRecordsForVisibleArea:visibleArea
                                    zoom:zoom
                          candidateCount:&candidateCount
                         projectionCount:&projectionCount
                  collisionRejectedCount:&collisionRejectedCount
            safetyDisplacersByIncumbent:&safetyDisplacers];
    NSSet<NSNumber *> *previousKeys = [NSSet setWithArray:_objectDrawables.allKeys];
    NSMutableSet<NSNumber *> *failedKeys = [NSMutableSet set];
    [self.mapViewController runWithRenderSync:^{
        // Stage desired drawables first so the renderer never observes an empty
        // replacement interval between removing an incumbent and adding its successor.
        for (NSNumber *key in [desiredRecords.allKeys copy])
        {
            AisObjectRenderRecord *record = desiredRecords[key];
            AisObjectDrawable *drawable = _objectDrawables[key];
            if (!drawable)
            {
                drawable = [[AisObjectDrawable alloc] initWithObject:record.object
                                                           textScale:_textScale
                                                displayDensityFactor:_displayDensityFactor];
                _objectDrawables[key] = drawable;
            }
            [drawable setTextScale:_textScale displayDensityFactor:_displayDensityFactor];
            [drawable setObject:record.object visualState:record.visualState];
            BOOL renderKeyChanged = [drawable hasAisRenderData]
                && ![drawable.renderKey isEqualToString:[drawable currentRenderKey]];
            BOOL partialRenderData = [drawable hasAnyAisRenderData] && ![drawable hasAisRenderData];
            BOOL recreated = renderKeyChanged || partialRenderData;
            if (recreated)
                [drawable clearAisRenderDataFromMarkersCollection:_markersCollection
                                            vectorLinesCollection:_vectorLinesCollection];
            if (![drawable hasAisRenderData])
            {
                [drawable createAisRenderDataWithBaseOrder:self.baseOrder
                                         markersCollection:_markersCollection];
                recreated = YES;
            }
            if (![drawable hasAisRenderData])
            {
                [_objectDrawables removeObjectForKey:key];
                [failedKeys addObject:key];
                continue;
            }

            BOOL needsUpdate = recreated
                || drawable.renderedVersion != record.version
                || drawable.cpaWarning != record.cpaWarning
                || std::fabs(drawable.renderedSurfaceZoom - surfaceZoom) > kAisRenderZoomEpsilon;
            if (needsUpdate)
            {
                [drawable updateAisRenderDataWithMapView:self.mapView
                                              cpaWarning:record.cpaWarning
                                                  visible:zoom >= kAisTrackerStartZoom || [_selectedMmsi isEqualToNumber:key]
                                    vectorLinesCollection:_vectorLinesCollection];
                drawable.renderedVersion = record.version;
            }
        }

        [desiredRecords removeObjectsForKeys:failedKeys.allObjects];
        NSMutableSet<NSNumber *> *actualDesiredKeys = [NSMutableSet setWithArray:desiredRecords.allKeys];
        for (NSNumber *incumbentKey in safetyDisplacers)
        {
            if ([actualDesiredKeys containsObject:incumbentKey] || ![previousKeys containsObject:incumbentKey])
                continue;

            BOOL everyReplacementFailed = YES;
            for (NSNumber *safetyKey in safetyDisplacers[incumbentKey])
            {
                if (![failedKeys containsObject:safetyKey])
                {
                    everyReplacementFailed = NO;
                    break;
                }
            }
            AisObjectDrawable *drawable = _objectDrawables[incumbentKey];
            AisObjectRenderRecord *record = _objectRecords[incumbentKey];
            if (everyReplacementFailed && drawable && [drawable hasAisRenderData] && record && record.hasScreenPoint)
            {
                desiredRecords[incumbentKey] = record;
                [actualDesiredKeys addObject:incumbentKey];
            }
        }

        for (NSNumber *key in previousKeys)
        {
            if (![actualDesiredKeys containsObject:key])
            {
                [_objectDrawables[key] clearAisRenderDataFromMarkersCollection:_markersCollection
                                                         vectorLinesCollection:_vectorLinesCollection];
                [_objectDrawables removeObjectForKey:key];
            }
        }
    }];

    _renderedRecords = desiredRecords;
    _peakDrawableCount = MAX(_peakDrawableCount, _objectDrawables.count);
    _lastRenderBBox31 = visibleArea;
    _lastRenderZoom = zoom;
    _lastRenderSurfaceZoom = surfaceZoom;
    _hasLastRenderViewport = YES;
    _lastViewportRenderUpdateTime = [[NSDate date] timeIntervalSince1970];
    _dataDirty = NO;

    if ([AisLogger shared].isEnabled)
    {
        NSSet<NSNumber *> *actualKeys = [NSSet setWithArray:desiredRecords.allKeys];
        NSMutableSet<NSNumber *> *retainedKeys = [previousKeys mutableCopy];
        [retainedKeys intersectSet:actualKeys];
        NSMutableSet<NSNumber *> *admittedKeys = [actualKeys mutableCopy];
        [admittedKeys minusSet:previousKeys];
        NSMutableSet<NSNumber *> *removedKeys = [previousKeys mutableCopy];
        [removedKeys minusSet:actualKeys];
        NSUInteger safetyDisplacedCount = 0;
        for (NSNumber *incumbentKey in safetyDisplacers)
        {
            if (![actualKeys containsObject:incumbentKey])
                safetyDisplacedCount++;
        }
        const NSUInteger markerCount = _markersCollection ? (NSUInteger)_markersCollection->getMarkers().size() : 0;
        const int lineCount = _vectorLinesCollection ? _vectorLinesCollection->getLinesCount() : 0;
        const double elapsedMs = (CFAbsoluteTimeGetCurrent() - started) * 1000.0;
        [[AisLogger shared] log:[NSString stringWithFormat:
            @"render candidates=%lu projected=%lu visible=%lu retained=%lu admitted=%lu removed=%lu collisionRejected=%lu safetyDisplaced=%lu markers=%lu lines=%d peak=%lu time=%.1fms",
            (unsigned long)candidateCount,
            (unsigned long)projectionCount,
            (unsigned long)desiredRecords.count,
            (unsigned long)retainedKeys.count,
            (unsigned long)admittedKeys.count,
            (unsigned long)removedKeys.count,
            (unsigned long)collisionRejectedCount,
            (unsigned long)safetyDisplacedCount,
            (unsigned long)markerCount,
            lineCount,
            (unsigned long)_peakDrawableCount,
            elapsedMs]];
    }
}

- (void)scheduleFrameRefresh
{
    if (_refreshScheduled)
        return;
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval delay = MAX(0, kAisViewportRenderUpdateInterval - (now - _lastViewportRenderUpdateTime));
    _refreshScheduled = YES;
    __weak OAAisTrackerLayer *weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        OAAisTrackerLayer *strongSelf = weakSelf;
        if (!strongSelf)
            return;
        strongSelf->_refreshScheduled = NO;
        if ([strongSelf isVisible])
            [strongSelf.mapView invalidateFrame];
    });
}

- (BOOL)shouldUpdateRenderDataForViewport
{
    OAMapRendererView *mapView = self.mapView;
    if (!mapView)
        return NO;

    const OsmAnd::AreaI visibleBBox31 = [mapView getVisibleBBox31];
    const int zoom = (int)mapView.zoomLevel;
    const float surfaceZoom = mapView.zoom;
    const BOOL viewportChanged = !_hasLastRenderViewport
        || _lastRenderZoom != zoom
        || std::fabs(_lastRenderSurfaceZoom - surfaceZoom) > kAisRenderZoomEpsilon
        || _lastRenderBBox31.left() != visibleBBox31.left()
        || _lastRenderBBox31.top() != visibleBBox31.top()
        || _lastRenderBBox31.right() != visibleBBox31.right()
        || _lastRenderBBox31.bottom() != visibleBBox31.bottom();
    if (!_dataDirty && !viewportChanged)
        return NO;

    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    if (_hasLastRenderViewport && now - _lastViewportRenderUpdateTime < kAisViewportRenderUpdateInterval)
    {
        [self scheduleFrameRefresh];
        return NO;
    }
    return YES;
}

#pragma mark - OAContextMenuProvider

- (void)updateSelectedMmsi:(NSNumber * _Nullable)selectedMmsi
{
    if (_selectedMmsi == selectedMmsi
        || (selectedMmsi != nil && [_selectedMmsi isEqualToNumber:selectedMmsi]))
        return;

    _selectedMmsi = selectedMmsi;
    _dataDirty = YES;
    [self scheduleFrameRefresh];
}

- (void)contextMenuDidShow:(id)targetObj
{
    NSNumber *selectedMmsi = [targetObj isKindOfClass:OASAisObject.class]
        ? @(((OASAisObject *)targetObj).mmsi)
        : nil;
    [self updateSelectedMmsi:selectedMmsi];
}

- (void)contextMenuDidHide
{
    [self updateSelectedMmsi:nil];
}

- (OATargetPoint *)getTargetPoint:(id)obj touchLocation:(CLLocation *)touchLocation
{
    if (![obj isKindOfClass:OASAisObject.class] || !((OASAisObject *)obj).position)
        return nil;

    OASAisObject *object = obj;
    CLLocation *location = OAAisObjectLocation(object);
    if (!location)
        return nil;

    OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
    targetPoint.type = OATargetAisObject;
    targetPoint.targetObj = object;
    targetPoint.title = OAAisObjectTitle(object);
    targetPoint.titleSecond = nil;
    NSString *navStatus = [object getNavStatusString];
    targetPoint.titleAddress = navStatus.length > 0 ? navStatus : nil;
    targetPoint.shouldFetchAddress = NO;
    targetPoint.location = location.coordinate;
    
    targetPoint.icon = [[UIImage imageNamed:ACImageNameIcActionSailBoatDark]
                        imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    targetPoint.sortIndex = OATargetAisObject;
    targetPoint.centerMap = NO;
    return targetPoint;
}

- (OATargetPoint *)getTargetPointCpp:(const void *)obj
{
    return nil;
}

- (BOOL)isSecondaryProvider
{
    return NO;
}

- (CLLocation *)getObjectLocation:(id)obj
{
    if (![obj isKindOfClass:OASAisObject.class] || !((OASAisObject *)obj).position)
        return nil;
    OASAisObject *object = obj;
    return OAAisObjectLocation(object);
}

- (OAPointDescription *)getObjectName:(id)obj
{
    if (![obj isKindOfClass:OASAisObject.class])
        return nil;
    OASAisObject *object = obj;
    return [[OAPointDescription alloc] initWithType:POINT_TYPE_LOCATION typeName:OALocalizedString(@"ais_type_object") name:OAAisObjectTitle(object)];
}

- (BOOL)showMenuAction:(id)object
{
    return NO;
}

- (BOOL)runExclusiveAction:(id)obj unknownLocation:(BOOL)unknownLocation
{
    return NO;
}

- (int64_t)getSelectionPointOrder:(id)selectedObject
{
    return self.pointsOrder;
}

- (void)collectObjectsFromPoint:(MapSelectionResult *)result unknownLocation:(BOOL)unknownLocation excludeUntouchableObjects:(BOOL)excludeUntouchableObjects
{
    if (excludeUntouchableObjects
        || ![self isVisible]
        || ((int)self.mapView.zoomLevel < kAisTrackerStartZoom && !_selectedMmsi))
        return;

    CGFloat contentScale = MAX(1.0, self.mapView.contentScaleFactor);
    CGPoint point = CGPointMake(result.point.x / contentScale, result.point.y / contentScale);
    int iconRadius = (int)ceil([self currentIconSizeInPoints] * 0.55);
    CGFloat density = MAX(1.0, _displayDensityFactor);
    int touchRadius = (int)ceil([self getScaledTouchRadius:[self getDefaultRadiusPoi]]
                                * TOUCH_RADIUS_MULTIPLIER / density);
    int radius = MAX(iconRadius, touchRadius);
    CGRect touchRect = CGRectMake(point.x - radius, point.y - radius, radius * 2.0, radius * 2.0);
    for (AisObjectRenderRecord *record in _renderedRecords.allValues)
    {
        if (record.hasScreenPoint && CGRectContainsPoint(touchRect, record.screenPoint))
            [result collect:record.object provider:self];
    }
}

- (NSString *)objectTypeName:(OASAisObjType *)type
{
    if (OAAisTypeEquals(type, OASAisObjType.aisVessel)) return OALocalizedString(@"ais_type_vessel");
    if (OAAisTypeEquals(type, OASAisObjType.aisVesselSport)) return OALocalizedString(@"ais_type_sport_vessel");
    if (OAAisTypeEquals(type, OASAisObjType.aisVesselFast)) return OALocalizedString(@"ais_type_high_speed_vessel");
    if (OAAisTypeEquals(type, OASAisObjType.aisVesselPassenger)) return OALocalizedString(@"ais_type_passenger_vessel");
    if (OAAisTypeEquals(type, OASAisObjType.aisVesselFreight)) return OALocalizedString(@"ais_type_cargo_tanker");
    if (OAAisTypeEquals(type, OASAisObjType.aisVesselCommercial)) return OALocalizedString(@"ais_type_commercial_vessel");
    if (OAAisTypeEquals(type, OASAisObjType.aisVesselAuthorities)) return OALocalizedString(@"ais_type_authorities_vessel");
    if (OAAisTypeEquals(type, OASAisObjType.aisVesselSar)) return OALocalizedString(@"ais_type_sar_vessel");
    if (OAAisTypeEquals(type, OASAisObjType.aisLandstation)) return OALocalizedString(@"ais_type_base_station");
    if (OAAisTypeEquals(type, OASAisObjType.aisAirplane)) return OALocalizedString(@"ais_type_sar_aircraft");
    if (OAAisTypeEquals(type, OASAisObjType.aisSart)) return OALocalizedString(@"ais_type_sart");
    if (OAAisTypeEquals(type, OASAisObjType.aisAton)) return OALocalizedString(@"ais_type_aid_to_navigation");
    if (OAAisTypeEquals(type, OASAisObjType.aisAtonVirtual)) return OALocalizedString(@"ais_type_virtual_aid_to_navigation");
    if (OAAisTypeEquals(type, OASAisObjType.aisVesselOther)) return OALocalizedString(@"ais_type_other_vessel");
    return OALocalizedString(@"ais_type_object");
}

@end
