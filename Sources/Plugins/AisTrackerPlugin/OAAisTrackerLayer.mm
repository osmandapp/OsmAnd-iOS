//
//  OAAisTrackerLayer.m
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 11.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import "OAAisTrackerLayer.h"
#import "OAMapRendererView.h"
#import "OANativeUtilities.h"
#import "OAPluginsHelper.h"
#import "OATargetPoint.h"
#import "OAPointDescription.h"
#import "Localization.h"
#import "OAAppSettings.h"
#import "GeneratedAssetSymbols.h"
#import "OsmAnd_Maps-Swift.h"

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/MapMarkerBuilder.h>
#include <OsmAndCore/Map/MapMarkersCollection.h>
#include <OsmAndCore/Map/VectorLineBuilder.h>
#include <OsmAndCore/Map/VectorLinesCollection.h>
#include <OsmAndCore/SingleSkImage.h>
#include <cmath>

#define kAisTrackerLayerId @"ais_tracker_layer"

static const int kAisTrackerStartZoom = 6;
static const CGFloat kAisBaseIconSize = 48.0;
static const CGFloat kAisDirectionLineStartIconFactor = 0.42;
static const float kAisRenderZoomEpsilon = 0.02f;
static const NSTimeInterval kAisViewportRenderUpdateInterval = 0.2;
static int kAisIconKeyStorage;
static const OsmAnd::MapMarker::OnSurfaceIconKey kAisIconKey = &kAisIconKeyStorage;

static NSString *OAAisObjectTitle(AisObject *object)
{
    return [NSString stringWithFormat:OALocalizedString(@"ais_object_with_mmsi"), (long)object.mmsi];
}

@interface AisObjectDrawable : NSObject

@property (nonatomic) AisObject *object;
@property (nonatomic, copy) NSString *renderKey;

- (instancetype)initWithObject:(AisObject *)object;
- (instancetype)initWithObject:(AisObject *)object
                      textScale:(CGFloat)textScale
           displayDensityFactor:(CGFloat)displayDensityFactor;
- (void)set:(AisObject *)object;
- (void)setTextScale:(CGFloat)textScale
 displayDensityFactor:(CGFloat)displayDensityFactor;
- (BOOL)hasAisRenderData;
- (BOOL)hasAnyAisRenderData;
- (int)renderGroupId;
- (NSString *)currentRenderKey;
- (OsmAnd::PointI)markerLocation;
- (void)setAisRenderDataHidden:(BOOL)hidden;
- (void)setAisMarkersUpdateAfterCreated;
- (void)createAisRenderDataWithBaseOrder:(int)baseOrder
                       markersCollection:(const std::shared_ptr<OsmAnd::MapMarkersCollection> &)markersCollection
                    vectorLinesCollection:(const std::shared_ptr<OsmAnd::VectorLinesCollection> &)vectorLinesCollection;
- (void)updateAisRenderDataWithMapView:(OAMapRendererView *)mapView
                                plugin:(AisTrackerPlugin *)plugin;
- (void)clearAisRenderDataFromMarkersCollection:(const std::shared_ptr<OsmAnd::MapMarkersCollection> &)markersCollection
                          vectorLinesCollection:(const std::shared_ptr<OsmAnd::VectorLinesCollection> &)vectorLinesCollection;

@end

@implementation AisObjectDrawable
{
    std::shared_ptr<OsmAnd::MapMarker> _activeMarker;
    std::shared_ptr<OsmAnd::MapMarker> _restMarker;
    std::shared_ptr<OsmAnd::MapMarker> _lostMarker;
    std::shared_ptr<OsmAnd::VectorLine> _directionLine;
    CGFloat _textScale;
    CGFloat _displayDensityFactor;
    int _baseOrder;
}

- (instancetype)initWithObject:(AisObject *)object
{
    return [self initWithObject:object textScale:1.0 displayDensityFactor:UIScreen.mainScreen.scale];
}

- (instancetype)initWithObject:(AisObject *)object
                      textScale:(CGFloat)textScale
           displayDensityFactor:(CGFloat)displayDensityFactor
{
    self = [super init];
    if (self)
    {
        _object = object;
        [self setTextScale:textScale displayDensityFactor:displayDensityFactor];
    }
    return self;
}

- (void)set:(AisObject *)object
{
    _object = object;
}

- (void)setTextScale:(CGFloat)textScale displayDensityFactor:(CGFloat)displayDensityFactor
{
    _textScale = textScale > 0 ? textScale : 1.0;
    _displayDensityFactor = MAX(1.0, displayDensityFactor);
}

- (BOOL)hasAisRenderData
{
    return _activeMarker && _restMarker && _lostMarker && _directionLine;
}

- (BOOL)hasAnyAisRenderData
{
    return _activeMarker || _restMarker || _lostMarker || _directionLine;
}

- (int)renderGroupId
{
    return (int)_object.mmsi;
}

- (NSString *)currentRenderKey
{
    return [NSString stringWithFormat:@"surface-v3-%@-%d", [self iconResourceNameForType:_object.objectClass], (int)std::round([self iconSize] * 100.0)];
}

- (OsmAnd::PointI)markerLocation
{
    CLLocation *location = _object.location;
    if (!location)
        return OsmAnd::PointI(0, 0);
    return OsmAnd::PointI(OsmAnd::Utilities::get31TileNumberX(location.coordinate.longitude),
                          OsmAnd::Utilities::get31TileNumberY(location.coordinate.latitude));
}

- (void)setAisRenderDataHidden:(BOOL)hidden
{
    if (_activeMarker)
        _activeMarker->setIsHidden(hidden);
    if (_restMarker)
        _restMarker->setIsHidden(hidden);
    if (_lostMarker)
        _lostMarker->setIsHidden(hidden);
    if (_directionLine)
        _directionLine->setIsHidden(hidden);
    [self setAisMarkersUpdateAfterCreated];
}

- (void)setAisMarkersUpdateAfterCreated
{
    if (_activeMarker)
        _activeMarker->setUpdateAfterCreated(true);
    if (_restMarker)
        _restMarker->setUpdateAfterCreated(true);
    if (_lostMarker)
        _lostMarker->setUpdateAfterCreated(true);
}

- (void)createAisRenderDataWithBaseOrder:(int)baseOrder
                       markersCollection:(const std::shared_ptr<OsmAnd::MapMarkersCollection> &)markersCollection
                    vectorLinesCollection:(const std::shared_ptr<OsmAnd::VectorLinesCollection> &)vectorLinesCollection
{
    if (!markersCollection || !vectorLinesCollection)
        return;

    [self clearAisRenderDataFromMarkersCollection:markersCollection vectorLinesCollection:vectorLinesCollection];
    _baseOrder = baseOrder;

    sk_sp<SkImage> activeIcon = [self iconImageForState:0];
    sk_sp<SkImage> restIcon = [self iconImageForState:1];
    sk_sp<SkImage> lostIcon = [self iconImageForState:2];
    if (!activeIcon || !restIcon || !lostIcon)
        return;

    OsmAnd::MapMarkerBuilder markerBuilder;
    OsmAnd::PointI markerLocation = [self markerLocation];
    markerBuilder
        .setGroupId([self renderGroupId])
        .setMarkerId(0)
        .setBaseOrder(baseOrder)
        .setIsHidden(true)
        .setUpdateAfterCreated(true)
        .setPosition(markerLocation)
        .addOnMapSurfaceIcon(kAisIconKey, OsmAnd::SingleSkImage(activeIcon));
    _activeMarker = markerBuilder.buildAndAddToCollection(markersCollection);

    markerBuilder
        .setMarkerId(1)
        .clearOnMapSurfaceIcons()
        .addOnMapSurfaceIcon(kAisIconKey, OsmAnd::SingleSkImage(restIcon));
    _restMarker = markerBuilder.buildAndAddToCollection(markersCollection);

    markerBuilder
        .setMarkerId(2)
        .clearOnMapSurfaceIcons()
        .addOnMapSurfaceIcon(kAisIconKey, OsmAnd::SingleSkImage(lostIcon));
    _lostMarker = markerBuilder.buildAndAddToCollection(markersCollection);
    [self setAisMarkersUpdateAfterCreated];

    QVector<OsmAnd::PointI> points;
    points.push_back(markerLocation);
    points.push_back(OsmAnd::PointI(markerLocation.x + 1, markerLocation.y + 1));

    OsmAnd::VectorLineBuilder lineBuilder;
    lineBuilder
        .setLineId([self renderGroupId])
        .setBaseOrder(baseOrder + 10)
        .setIsHidden(true)
        .setLineWidth(6.0)
        .setApproximationEnabled(false)
        .setFillColor(OsmAnd::FColorARGB(1.0f, 0.0f, 0.0f, 0.0f))
        .setPoints(points);
    _directionLine = lineBuilder.buildAndAddToCollection(vectorLinesCollection);

    _renderKey = [self currentRenderKey];
    if (![self hasAisRenderData])
    {
        [self clearAisRenderDataFromMarkersCollection:markersCollection vectorLinesCollection:vectorLinesCollection];
        return;
    }
    [self updateAisRenderDataWithMapView:nil plugin:nil];
}

- (void)updateAisRenderDataWithMapView:(OAMapRendererView *)mapView
                                plugin:(AisTrackerPlugin *)plugin
{
    if (![self hasAisRenderData])
        return;

    const OsmAnd::ZoomLevel zoom = mapView ? mapView.zoomLevel : OsmAnd::ZoomLevel::MinZoomLevel;
    if (!mapView || (int)zoom < kAisTrackerStartZoom || !_object.hasPosition)
    {
        [self setAisRenderDataHidden:YES];
        return;
    }

    CLLocation *location = _object.location;
    if (!location)
    {
        [self setAisRenderDataHidden:YES];
        return;
    }

    OsmAnd::PointI markerLocation = [self markerLocation];
    if (![mapView isPositionVisible:markerLocation])
    {
        [self setAisRenderDataHidden:YES];
        return;
    }

    NSInteger vesselLostTimeout = plugin ? [plugin vesselLostTimeoutInMinutes] : 0;
    BOOL vesselAtRest = [_object isVesselAtRest];
    BOOL lostTimeout = vesselLostTimeout > 0 && [_object isLostWithMaxAgeMinutes:vesselLostTimeout] && !vesselAtRest;
    CGFloat speedFactor = [self movementFactor];
    BOOL drawDirectionLine = speedFactor > 0 && !lostTimeout && !vesselAtRest;

    BOOL cpaWarning = plugin ? [plugin hasCpaWarningFor:_object] : NO;
    UIColor *uiColor = cpaWarning ? UIColor.redColor : [self colorForType:_object.objectClass];
    OsmAnd::ColorARGB iconColor = [uiColor toColorARGB];
    _activeMarker->setOnSurfaceIconModulationColor(iconColor);
    _restMarker->setOnSurfaceIconModulationColor(iconColor);

    _activeMarker->setIsHidden(vesselAtRest || lostTimeout);
    _restMarker->setIsHidden(!vesselAtRest);
    _lostMarker->setIsHidden(!lostTimeout);

    float rotation = fmod(_object.vesselRotation + 180.0, 360.0);
    if (!vesselAtRest && [self needRotation])
    {
        _activeMarker->setOnMapSurfaceIconDirection(kAisIconKey, rotation);
        _lostMarker->setOnMapSurfaceIconDirection(kAisIconKey, rotation);
    }
    _activeMarker->setPosition(markerLocation);
    _restMarker->setPosition(markerLocation);
    _lostMarker->setPosition(markerLocation);
    [self setAisMarkersUpdateAfterCreated];

    if (drawDirectionLine && _directionLine)
    {
        double inverseZoom = mapView.maxZoom - mapView.zoom;
        double zoomFactor = std::pow(2.0, inverseZoom);
        CGFloat iconSize = [self iconSize];
        double lineStartOffset = zoomFactor * iconSize * kAisDirectionLineStartIconFactor;
        double lineLength = std::max(speedFactor * zoomFactor * iconSize * 0.75, lineStartOffset + zoomFactor * iconSize * 0.25);
        double theta = rotation * M_PI / 180.0;
        int startDx = (int)ceil(-sin(theta) * lineStartOffset);
        int startDy = (int)ceil(cos(theta) * lineStartOffset);
        int dx = (int)ceil(-sin(theta) * lineLength);
        int dy = (int)ceil(cos(theta) * lineLength);

        QVector<OsmAnd::PointI> points;
        points.push_back(OsmAnd::PointI(markerLocation.x + startDx, markerLocation.y + startDy));
        points.push_back(OsmAnd::PointI(markerLocation.x + dx, markerLocation.y + dy));
        _directionLine->setPoints(points);
    }
    if (_directionLine)
        _directionLine->setIsHidden(!drawDirectionLine);
}

- (void)clearAisRenderDataFromMarkersCollection:(const std::shared_ptr<OsmAnd::MapMarkersCollection> &)markersCollection
                          vectorLinesCollection:(const std::shared_ptr<OsmAnd::VectorLinesCollection> &)vectorLinesCollection
{
    if (markersCollection)
    {
        markersCollection->removeMarkersByGroupId([self renderGroupId]);
        if (_activeMarker)
            markersCollection->removeMarker(_activeMarker);
        if (_restMarker)
            markersCollection->removeMarker(_restMarker);
        if (_lostMarker)
            markersCollection->removeMarker(_lostMarker);
    }
    if (vectorLinesCollection)
    {
        const int lineId = [self renderGroupId];
        for (const auto& line : vectorLinesCollection->getLines())
        {
            if (line && line->lineId == lineId)
            {
                line->setIsHidden(true);
                vectorLinesCollection->removeLine(line);
            }
        }
        if (_directionLine)
        {
            _directionLine->setIsHidden(true);
            vectorLinesCollection->removeLine(_directionLine);
        }
    }

    _activeMarker.reset();
    _restMarker.reset();
    _lostMarker.reset();
    _directionLine.reset();
    _renderKey = nil;
}

- (sk_sp<SkImage>)iconImageForState:(NSInteger)state
{
    CGFloat iconSize = [self iconSize];
    if (state != 1)
    {
        NSString *resourceName = state == 2 ? @"c_mx_ais_vessel_cross" : [self iconResourceNameForType:_object.objectClass];
        sk_sp<SkImage> image = [OANativeUtilities skImageFromSvgResource:resourceName width:iconSize height:iconSize];
        if (image)
            return image;
    }

    CGSize size = CGSizeMake(iconSize, iconSize);
    UIGraphicsBeginImageContextWithOptions(size, NO, 1.0);
    CGFloat sizeFactor = iconSize / 72.0;
    CGRect bounds = CGRectInset(CGRectMake(0, 0, size.width, size.height), 6 * sizeFactor, 6 * sizeFactor);

    UIColor *baseColor = state == 2
        ? [UIColor colorWithWhite:0.75 alpha:1.0]
        : UIColor.whiteColor;
    UIColor *strokeColor = state == 2
        ? [UIColor colorWithWhite:0.47 alpha:1.0]
        : [UIColor colorWithWhite:0.37 alpha:1.0];

    UIBezierPath *path;
    if (state == 1)
    {
        UIBezierPath *outer = [UIBezierPath bezierPathWithOvalInRect:CGRectInset(bounds, 1, 1)];
        [[UIColor darkGrayColor] setFill];
        [outer fill];
        path = [UIBezierPath bezierPathWithOvalInRect:CGRectInset(bounds, 4 * sizeFactor, 4 * sizeFactor)];
    }
    else if (_object.objectClass == AisObjTypeAton || _object.objectClass == AisObjTypeAtonVirtual)
    {
        path = [UIBezierPath bezierPath];
        [path moveToPoint:CGPointMake(CGRectGetMidX(bounds), CGRectGetMinY(bounds))];
        [path addLineToPoint:CGPointMake(CGRectGetMaxX(bounds), CGRectGetMidY(bounds))];
        [path addLineToPoint:CGPointMake(CGRectGetMidX(bounds), CGRectGetMaxY(bounds))];
        [path addLineToPoint:CGPointMake(CGRectGetMinX(bounds), CGRectGetMidY(bounds))];
        [path closePath];
    }
    else if ([_object isMovable])
    {
        path = [UIBezierPath bezierPath];
        [path moveToPoint:CGPointMake(CGRectGetMidX(bounds), CGRectGetMinY(bounds))];
        [path addLineToPoint:CGPointMake(CGRectGetMaxX(bounds), CGRectGetMaxY(bounds))];
        [path addLineToPoint:CGPointMake(CGRectGetMidX(bounds), CGRectGetMaxY(bounds) - 9 * sizeFactor)];
        [path addLineToPoint:CGPointMake(CGRectGetMinX(bounds), CGRectGetMaxY(bounds))];
        [path closePath];
    }
    else
    {
        path = [UIBezierPath bezierPathWithRoundedRect:bounds cornerRadius:4];
    }

    [baseColor setFill];
    [strokeColor setStroke];
    path.lineWidth = 4 * sizeFactor;
    [path fill];
    [path stroke];

    if (_object.objectClass == AisObjTypeAtonVirtual && state != 1)
    {
        UIBezierPath *plus = [UIBezierPath bezierPath];
        [plus moveToPoint:CGPointMake(CGRectGetMidX(bounds), CGRectGetMinY(bounds) + 12 * sizeFactor)];
        [plus addLineToPoint:CGPointMake(CGRectGetMidX(bounds), CGRectGetMaxY(bounds) - 12 * sizeFactor)];
        [plus moveToPoint:CGPointMake(CGRectGetMinX(bounds) + 12 * sizeFactor, CGRectGetMidY(bounds))];
        [plus addLineToPoint:CGPointMake(CGRectGetMaxX(bounds) - 12 * sizeFactor, CGRectGetMidY(bounds))];
        [strokeColor setStroke];
        plus.lineWidth = 3 * sizeFactor;
        [plus stroke];
    }

    if (state == 2)
    {
        UIBezierPath *cross = [UIBezierPath bezierPath];
        [cross moveToPoint:CGPointMake(CGRectGetMinX(bounds) + 2 * sizeFactor, CGRectGetMinY(bounds) + 2 * sizeFactor)];
        [cross addLineToPoint:CGPointMake(CGRectGetMaxX(bounds) - 2 * sizeFactor, CGRectGetMaxY(bounds) - 2 * sizeFactor)];
        [cross moveToPoint:CGPointMake(CGRectGetMaxX(bounds) - 2 * sizeFactor, CGRectGetMinY(bounds) + 2 * sizeFactor)];
        [cross addLineToPoint:CGPointMake(CGRectGetMinX(bounds) + 2 * sizeFactor, CGRectGetMaxY(bounds) - 2 * sizeFactor)];
        [UIColor.blackColor setStroke];
        cross.lineWidth = 3 * sizeFactor;
        [cross stroke];
    }

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [OANativeUtilities skImageFromCGImage:image.CGImage];
}

- (CGFloat)iconSize
{
    return kAisBaseIconSize * _textScale * _displayDensityFactor;
}

- (UIColor *)colorForType:(AisObjType)type
{
    switch (type)
    {
        case AisObjTypeVessel: return UIColor.greenColor;
        case AisObjTypeVesselSport: return UIColor.yellowColor;
        case AisObjTypeVesselFast: return UIColor.blueColor;
        case AisObjTypeVesselPassenger: return UIColor.cyanColor;
        case AisObjTypeVesselFreight: return UIColor.grayColor;
        case AisObjTypeVesselCommercial: return UIColor.lightGrayColor;
        case AisObjTypeVesselAuthorities: return [UIColor colorWithRed:0.33 green:0.42 blue:0.18 alpha:1.0];
        case AisObjTypeVesselSar:
        case AisObjTypeSart: return [UIColor colorWithRed:0.98 green:0.50 blue:0.45 alpha:1.0];
        case AisObjTypeVesselOther: return [UIColor colorWithRed:0.00 green:0.75 blue:1.00 alpha:1.0];
        case AisObjTypeAirplane: return [UIColor colorWithRed:0.45 green:0.27 blue:0.86 alpha:1.0];
        case AisObjTypeAton:
        case AisObjTypeAtonVirtual: return [UIColor colorWithRed:0.92 green:0.82 blue:0.14 alpha:1.0];
        case AisObjTypeLandStation: return [UIColor colorWithRed:0.45 green:0.45 blue:0.45 alpha:1.0];
        default: return [UIColor colorWithRed:0.04 green:0.62 blue:0.72 alpha:1.0];
    }
}

- (NSString *)iconResourceNameForType:(AisObjType)type
{
    switch (type)
    {
        case AisObjTypeLandStation: return @"c_mx_ais_land";
        case AisObjTypeAirplane: return @"c_mx_ais_plane";
        case AisObjTypeSart: return @"c_mx_ais_sar";
        case AisObjTypeAton: return @"c_mx_ais_aton";
        case AisObjTypeAtonVirtual: return @"c_mx_ais_aton_virt";
        default: return @"c_mx_ais_vessel";
    }
}

- (CGFloat)movementFactor
{
    if (_object.sog <= 0 || ![_object isMovable])
        return 0;
    if (_object.sog < 2.0)
        return 0;
    if (_object.sog < 5.0)
        return 1.0;
    if (_object.sog < 10.0)
        return 3.0;
    if (_object.sog < 25.0)
        return 6.0;
    return 8.0;
}

- (BOOL)needRotation
{
    return (((_object.cog != 360.0) && (_object.cog != 0.0)) ||
            ((_object.heading != 511) && (_object.heading != 0))) && [_object isMovable];
}

@end

@interface OAAisTrackerLayer ()

- (BOOL)shouldUpdateRenderDataForViewport;

@end

@implementation OAAisTrackerLayer
{
    AisTrackerPlugin *_plugin;
    NSMutableDictionary<NSNumber *, AisObjectDrawable *> *_objectDrawables;
    std::shared_ptr<OsmAnd::MapMarkersCollection> _markersCollection;
    std::shared_ptr<OsmAnd::VectorLinesCollection> _vectorLinesCollection;
    id _objectsObserver;
    id _objectReceivedObserver;
    id _objectRemovedObserver;
    BOOL _collectionsAdded;
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
        _objectDrawables = [NSMutableDictionary dictionary];
        _textScale = [OAAisTrackerLayer currentTextScale];
        _displayDensityFactor = MAX(1.0, mapViewController.displayDensityFactor);
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

- (void)ensureObjectDrawables
{
    if (!_objectDrawables)
        _objectDrawables = [NSMutableDictionary dictionary];
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

- (CGFloat)currentIconSize
{
    return kAisBaseIconSize * _textScale * _displayDensityFactor;
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
    [self ensureObjectDrawables];
    [self resetCollections];
    [self.app.data.mapLayersConfiguration setLayer:self.layerId
                                        Visibility:self.isVisible];

    __weak OAAisTrackerLayer *weakSelf = self;
    _objectsObserver = [NSNotificationCenter.defaultCenter addObserverForName:@"OAAisObjectsChanged"
                                                                       object:nil
                                                                        queue:NSOperationQueue.mainQueue
                                                                   usingBlock:^(NSNotification * _Nonnull note) {
        OAAisTrackerLayer *strongSelf = weakSelf;
        if (!strongSelf)
            return;
        if ([note.object isKindOfClass:AisTrackerPlugin.class])
            strongSelf->_plugin = note.object;
        [strongSelf cleanupResources];
        if ([strongSelf isVisible])
        {
            [strongSelf addCollectionsToRenderer];
            [strongSelf reloadObjects];
        }
    }];
    _objectReceivedObserver = [NSNotificationCenter.defaultCenter addObserverForName:@"OAAisObjectReceived"
                                                                              object:nil
                                                                               queue:NSOperationQueue.mainQueue
                                                                          usingBlock:^(NSNotification * _Nonnull note) {
        OAAisTrackerLayer *strongSelf = weakSelf;
        if (!strongSelf)
            return;
        if ([note.object isKindOfClass:AisTrackerPlugin.class])
            strongSelf->_plugin = note.object;
        AisObject *object = note.userInfo[@"object"];
        if ([object isKindOfClass:AisObject.class])
            [strongSelf onAisObjectReceived:object];
    }];
    _objectRemovedObserver = [NSNotificationCenter.defaultCenter addObserverForName:@"OAAisObjectRemoved"
                                                                             object:nil
                                                                              queue:NSOperationQueue.mainQueue
                                                                         usingBlock:^(NSNotification * _Nonnull note) {
        OAAisTrackerLayer *strongSelf = weakSelf;
        if (!strongSelf)
            return;
        if ([note.object isKindOfClass:AisTrackerPlugin.class])
            strongSelf->_plugin = note.object;
        AisObject *object = note.userInfo[@"object"];
        if ([object isKindOfClass:AisObject.class])
            [strongSelf onAisObjectRemoved:object];
    }];
}

- (void)deinitLayer
{
    if (_objectsObserver)
    {
        [NSNotificationCenter.defaultCenter removeObserver:_objectsObserver];
        _objectsObserver = nil;
    }
    if (_objectReceivedObserver)
    {
        [NSNotificationCenter.defaultCenter removeObserver:_objectReceivedObserver];
        _objectReceivedObserver = nil;
    }
    if (_objectRemovedObserver)
    {
        [NSNotificationCenter.defaultCenter removeObserver:_objectRemovedObserver];
        _objectRemovedObserver = nil;
    }
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
    [self reloadObjects];
}

- (void)hide
{
    [self removeCollectionsFromRenderer];
}

- (BOOL)updateLayer
{
    if (![super updateLayer])
        return NO;

    BOOL scaleChanged = [self updateScaleCache];
    if (scaleChanged)
        [self cleanupResources];

    [self.app.data.mapLayersConfiguration setLayer:self.layerId
                                        Visibility:self.isVisible];
    if ([self isVisible])
    {
        [self addCollectionsToRenderer];
        [self reloadObjects];
    }
    else
    {
        [self removeCollectionsFromRenderer];
    }
    return YES;
}

- (void)onMapFrameRendered
{
    if (![self isVisible])
    {
        [self removeCollectionsFromRenderer];
        _hasLastRenderViewport = NO;
        _lastViewportRenderUpdateTime = 0;
        return;
    }
    if (![self shouldUpdateRenderDataForViewport])
        return;
    [self updateRenderData];
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

- (void)removeCollectionsFromRenderer
{
    if (!_collectionsAdded)
        return;

    [self.mapViewController runWithRenderSync:^{
        if (_markersCollection)
            [self.mapView removeKeyedSymbolsProvider:_markersCollection];
        if (_vectorLinesCollection)
            [self.mapView removeKeyedSymbolsProvider:_vectorLinesCollection];
        _collectionsAdded = NO;
    }];
}

- (void)cleanupResources
{
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
    [_objectDrawables removeAllObjects];
    _hasLastRenderViewport = NO;
    _lastViewportRenderUpdateTime = 0;
    [self resetCollections];
}

- (void)reloadObjects
{
    if (![self isVisible])
        return;

    [self.mapViewController runWithRenderSync:^{
        [self reloadObjectsSync];
    }];
}

- (void)reloadObjectsSync
{
    [self ensureObjectDrawables];
    AisTrackerPlugin *plugin = [self plugin];
    NSArray<AisObject *> *objects = [plugin getAisObjects];
    NSMutableSet<NSNumber *> *visibleMmsi = [NSMutableSet set];
    for (AisObject *object in objects)
    {
        if (!object.hasPosition)
            continue;

        NSNumber *key = @(object.mmsi);
        [visibleMmsi addObject:key];
        AisObjectDrawable *drawable = _objectDrawables[key];
        if (!drawable)
        {
            drawable = [[AisObjectDrawable alloc] initWithObject:object textScale:_textScale displayDensityFactor:_displayDensityFactor];
            _objectDrawables[key] = drawable;
        }
        [drawable setTextScale:_textScale displayDensityFactor:_displayDensityFactor];
        [drawable set:object];
        BOOL renderKeyChanged = [drawable hasAisRenderData] && ![drawable.renderKey isEqualToString:[drawable currentRenderKey]];
        BOOL partialRenderData = [drawable hasAnyAisRenderData] && ![drawable hasAisRenderData];
        if (renderKeyChanged || partialRenderData)
            [drawable clearAisRenderDataFromMarkersCollection:_markersCollection vectorLinesCollection:_vectorLinesCollection];
        if (![drawable hasAisRenderData])
            [drawable createAisRenderDataWithBaseOrder:self.baseOrder markersCollection:_markersCollection vectorLinesCollection:_vectorLinesCollection];
        [drawable updateAisRenderDataWithMapView:self.mapView plugin:plugin];
    }

    for (NSNumber *key in [_objectDrawables.allKeys copy])
    {
        if (![visibleMmsi containsObject:key])
        {
            [_objectDrawables[key] clearAisRenderDataFromMarkersCollection:_markersCollection vectorLinesCollection:_vectorLinesCollection];
            [_objectDrawables removeObjectForKey:key];
        }
    }
    [plugin updateSimulationRenderedObjects:_objectDrawables.count];
}

- (void)onAisObjectReceived:(AisObject *)object
{
    if (![self isVisible] || !object.hasPosition)
        return;
    [[AisLogger shared] log:[NSString stringWithFormat:@"receive %@", object.debugSummary]];
    [self addCollectionsToRenderer];
    [self.mapViewController runWithRenderSync:^{
        [self updateAisObjectSync:object];
    }];
}

- (void)onAisObjectRemoved:(AisObject *)object
{
    if (!object)
        return;

    [self.mapViewController runWithRenderSync:^{
        NSNumber *key = @(object.mmsi);
        AisObjectDrawable *drawable = _objectDrawables[key];
        [[AisLogger shared] log:[NSString stringWithFormat:@"remove hasDrawable=%@ drawables=%lu %@",
                                 drawable ? @"yes" : @"no", (unsigned long)_objectDrawables.count, object.debugSummary]];
        if (drawable)
        {
            [drawable clearAisRenderDataFromMarkersCollection:_markersCollection vectorLinesCollection:_vectorLinesCollection];
            [_objectDrawables removeObjectForKey:key];
        }
        [[self plugin] updateSimulationRenderedObjects:_objectDrawables.count];
    }];
}

- (void)updateAisObjectSync:(AisObject *)object
{
    [self ensureObjectDrawables];
    NSNumber *key = @(object.mmsi);
    AisObjectDrawable *drawable = _objectDrawables[key];
    if (!drawable)
    {
        drawable = [[AisObjectDrawable alloc] initWithObject:object textScale:_textScale displayDensityFactor:_displayDensityFactor];
        _objectDrawables[key] = drawable;
    }
    [drawable setTextScale:_textScale displayDensityFactor:_displayDensityFactor];
    [drawable set:object];
    BOOL renderKeyChanged = [drawable hasAisRenderData] && ![drawable.renderKey isEqualToString:[drawable currentRenderKey]];
    BOOL partialRenderData = [drawable hasAnyAisRenderData] && ![drawable hasAisRenderData];
    BOOL recreated = renderKeyChanged || partialRenderData;
    if (recreated)
        [drawable clearAisRenderDataFromMarkersCollection:_markersCollection vectorLinesCollection:_vectorLinesCollection];
    if (![drawable hasAisRenderData])
        [drawable createAisRenderDataWithBaseOrder:self.baseOrder markersCollection:_markersCollection vectorLinesCollection:_vectorLinesCollection];
    [drawable updateAisRenderDataWithMapView:self.mapView plugin:[self plugin]];
    int linesCount = _vectorLinesCollection ? _vectorLinesCollection->getLinesCount() : 0;

    [[AisLogger shared] log:[NSString stringWithFormat:@"update recreated=%@ drawables=%lu lines=%d %@", recreated ? @"yes" : @"no", (unsigned long)_objectDrawables.count, linesCount, object.debugSummary]];
    [[self plugin] updateSimulationRenderedObjects:_objectDrawables.count];
}

- (void)updateRenderData
{
    if (![self isVisible])
        return;

    AisTrackerPlugin *plugin = [self plugin];
    for (NSNumber *key in _objectDrawables)
        [_objectDrawables[key] updateAisRenderDataWithMapView:self.mapView plugin:plugin];
}

- (BOOL)shouldUpdateRenderDataForViewport
{
    OAMapRendererView *mapView = self.mapView;
    if (!mapView)
        return NO;

    const OsmAnd::AreaI visibleBBox31 = [mapView getVisibleBBox31];
    const int zoom = (int)mapView.zoomLevel;
    const float surfaceZoom = mapView.zoom;
    const BOOL surfaceZoomChanged = std::fabs(_lastRenderSurfaceZoom - surfaceZoom) > kAisRenderZoomEpsilon;
    if (!_hasLastRenderViewport
        || _lastRenderZoom != zoom
        || surfaceZoomChanged
        || _lastRenderBBox31.left() != visibleBBox31.left()
        || _lastRenderBBox31.top() != visibleBBox31.top()
        || _lastRenderBBox31.right() != visibleBBox31.right()
        || _lastRenderBBox31.bottom() != visibleBBox31.bottom())
    {
        NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
        if (!surfaceZoomChanged && _hasLastRenderViewport && now - _lastViewportRenderUpdateTime < kAisViewportRenderUpdateInterval)
            return NO;

        _lastRenderBBox31 = visibleBBox31;
        _lastRenderZoom = zoom;
        _lastRenderSurfaceZoom = surfaceZoom;
        _hasLastRenderViewport = YES;
        _lastViewportRenderUpdateTime = now;
        return YES;
    }
    return NO;
}

#pragma mark - OAContextMenuProvider

- (OATargetPoint *)getTargetPoint:(id)obj touchLocation:(CLLocation *)touchLocation
{
    if (![obj isKindOfClass:AisObject.class] || !((AisObject *)obj).hasPosition)
        return nil;

    AisObject *object = obj;
    CLLocation *location = object.location;
    if (!location)
        return nil;

    OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
    targetPoint.type = OATargetAisObject;
    targetPoint.targetObj = object;
    targetPoint.title = OAAisObjectTitle(object);
    targetPoint.titleSecond = nil;
    targetPoint.titleAddress = object.navStatusString.length > 0 ? object.navStatusString : nil;
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
    if (![obj isKindOfClass:AisObject.class] || !((AisObject *)obj).hasPosition)
        return nil;
    AisObject *object = obj;
    return object.location;
}

- (OAPointDescription *)getObjectName:(id)obj
{
    if (![obj isKindOfClass:AisObject.class])
        return nil;
    AisObject *object = obj;
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
    if (excludeUntouchableObjects || ![self isVisible] || (int)self.mapView.zoomLevel < kAisTrackerStartZoom)
        return;

    CGPoint point = result.point;
    //[self updateScaleCache];
    int iconRadius = (int)ceil([self currentIconSize] * 0.55);
    int radius = MAX(iconRadius, (int)([self getScaledTouchRadius:[self getDefaultRadiusPoi]] * TOUCH_RADIUS_MULTIPLIER));
    QList<OsmAnd::PointI> touchPolygon31 =
        [OANativeUtilities getPolygon31FromScreenAreaLeft:point.x - radius
                                                      top:point.y - radius
                                                    right:point.x + radius
                                                   bottom:point.y + radius];
    if (touchPolygon31.isEmpty())
        return;

    NSArray<AisObject *> *objects = [[self plugin] getAisObjects];
    for (AisObject *object in objects)
    {
        CLLocation *location = object.location;
        if (!location)
            continue;

        if ([OANativeUtilities isPointInsidePolygonLat:location.coordinate.latitude
                                                   lon:location.coordinate.longitude
                                             polygon31:touchPolygon31])
        {
            [result collect:object provider:self];
        }
    }
}

- (NSString *)objectTypeName:(AisObjType)type
{
    switch (type)
    {
        case AisObjTypeVessel: return OALocalizedString(@"ais_type_vessel");
        case AisObjTypeVesselSport: return OALocalizedString(@"ais_type_sport_vessel");
        case AisObjTypeVesselFast: return OALocalizedString(@"ais_type_high_speed_vessel");
        case AisObjTypeVesselPassenger: return OALocalizedString(@"ais_type_passenger_vessel");
        case AisObjTypeVesselFreight: return OALocalizedString(@"ais_type_cargo_tanker");
        case AisObjTypeVesselCommercial: return OALocalizedString(@"ais_type_commercial_vessel");
        case AisObjTypeVesselAuthorities: return OALocalizedString(@"ais_type_authorities_vessel");
        case AisObjTypeVesselSar: return OALocalizedString(@"ais_type_sar_vessel");
        case AisObjTypeLandStation: return OALocalizedString(@"ais_type_base_station");
        case AisObjTypeAirplane: return OALocalizedString(@"ais_type_sar_aircraft");
        case AisObjTypeSart: return OALocalizedString(@"ais_type_sart");
        case AisObjTypeAton: return OALocalizedString(@"ais_type_aid_to_navigation");
        case AisObjTypeAtonVirtual: return OALocalizedString(@"ais_type_virtual_aid_to_navigation");
        case AisObjTypeVesselOther: return OALocalizedString(@"ais_type_other_vessel");
        default: return OALocalizedString(@"ais_type_object");
    }
}

@end
