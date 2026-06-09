#import "OAAisTrackerLayer.h"
#import "OAMapRendererView.h"
#import "OANativeUtilities.h"
#import "OAPluginsHelper.h"
#import "OATargetPoint.h"
#import "OAPointDescription.h"
#import "Localization.h"
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
static int kAisIconKeyStorage;
static const OsmAnd::MapMarker::OnSurfaceIconKey kAisIconKey = &kAisIconKeyStorage;

@interface OAAisObjectRenderData : NSObject

@property (nonatomic) AisObject *object;

- (instancetype)initWithObject:(AisObject *)object;
- (BOOL)hasRenderData;
- (void)createRenderDataWithBaseOrder:(int)baseOrder
                    markersCollection:(const std::shared_ptr<OsmAnd::MapMarkersCollection> &)markersCollection
                 vectorLinesCollection:(const std::shared_ptr<OsmAnd::VectorLinesCollection> &)vectorLinesCollection;
- (void)updateRenderDataWithMapView:(OAMapRendererView *)mapView
                              plugin:(OAAisTrackerPlugin *)plugin;
- (void)clearRenderDataFromMarkersCollection:(const std::shared_ptr<OsmAnd::MapMarkersCollection> &)markersCollection
                       vectorLinesCollection:(const std::shared_ptr<OsmAnd::VectorLinesCollection> &)vectorLinesCollection;

@end

@implementation OAAisObjectRenderData
{
    std::shared_ptr<OsmAnd::MapMarker> _activeMarker;
    std::shared_ptr<OsmAnd::MapMarker> _restMarker;
    std::shared_ptr<OsmAnd::MapMarker> _lostMarker;
    std::shared_ptr<OsmAnd::VectorLine> _directionLine;
}

- (instancetype)initWithObject:(AisObject *)object
{
    self = [super init];
    if (self)
        _object = object;
    return self;
}

- (BOOL)hasRenderData
{
    return _activeMarker && _restMarker && _lostMarker && _directionLine;
}

- (void)createRenderDataWithBaseOrder:(int)baseOrder
                    markersCollection:(const std::shared_ptr<OsmAnd::MapMarkersCollection> &)markersCollection
                 vectorLinesCollection:(const std::shared_ptr<OsmAnd::VectorLinesCollection> &)vectorLinesCollection
{
    if (!markersCollection || !vectorLinesCollection)
        return;

    OsmAnd::MapMarkerBuilder markerBuilder;
    markerBuilder
        .setIsAccuracyCircleSupported(false)
        .setBaseOrder(baseOrder + 10)
        .setIsHidden(true)
        .addOnMapSurfaceIcon(kAisIconKey, OsmAnd::SingleSkImage([self iconImageForState:0]));
    _activeMarker = markerBuilder.buildAndAddToCollection(markersCollection);

    markerBuilder
        .clearOnMapSurfaceIcons()
        .addOnMapSurfaceIcon(kAisIconKey, OsmAnd::SingleSkImage([self iconImageForState:1]));
    _restMarker = markerBuilder.buildAndAddToCollection(markersCollection);

    markerBuilder
        .clearOnMapSurfaceIcons()
        .addOnMapSurfaceIcon(kAisIconKey, OsmAnd::SingleSkImage([self iconImageForState:2]));
    _lostMarker = markerBuilder.buildAndAddToCollection(markersCollection);

    QVector<OsmAnd::PointI> points;
    points.push_back(OsmAnd::PointI(0, 0));
    points.push_back(OsmAnd::PointI(1, 1));

    OsmAnd::VectorLineBuilder lineBuilder;
    lineBuilder
        .setLineId(_object.mmsi)
        .setBaseOrder(baseOrder + 9)
        .setIsHidden(true)
        .setLineWidth(6.0f)
        .setApproximationEnabled(false)
        .setFillColor(OsmAnd::FColorARGB(1.0f, 0.0f, 0.0f, 0.0f))
        .setPoints(points);
    _directionLine = lineBuilder.buildAndAddToCollection(vectorLinesCollection);

    [self updateRenderDataWithMapView:nil plugin:nil];
}

- (void)updateRenderDataWithMapView:(OAMapRendererView *)mapView
                              plugin:(OAAisTrackerPlugin *)plugin
{
    if (![self hasRenderData])
        return;

    const OsmAnd::ZoomLevel zoom = mapView ? mapView.zoomLevel : OsmAnd::ZoomLevel::MinZoomLevel;
    if (!mapView || (int)zoom < kAisTrackerStartZoom || !_object.hasPosition)
    {
        _activeMarker->setIsHidden(true);
        _restMarker->setIsHidden(true);
        _lostMarker->setIsHidden(true);
        _directionLine->setIsHidden(true);
        return;
    }

    CLLocation *location = _object.currentLocation ?: _object.location;
    if (!location)
    {
        _activeMarker->setIsHidden(true);
        _restMarker->setIsHidden(true);
        _lostMarker->setIsHidden(true);
        _directionLine->setIsHidden(true);
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
    OsmAnd::FColorARGB lineColor = [uiColor toFColorARGB];
    _activeMarker->setOnSurfaceIconModulationColor(iconColor);
    _restMarker->setOnSurfaceIconModulationColor(iconColor);
    _directionLine->setFillColor(lineColor);

    _activeMarker->setIsHidden(vesselAtRest || lostTimeout);
    _restMarker->setIsHidden(!vesselAtRest);
    _lostMarker->setIsHidden(!lostTimeout);

    float rotation = fmod(_object.vesselRotation + 180.0, 360.0);
    if (!vesselAtRest && [self needRotation])
    {
        _activeMarker->setOnMapSurfaceIconDirection(kAisIconKey, rotation);
        _lostMarker->setOnMapSurfaceIconDirection(kAisIconKey, rotation);
    }

    OsmAnd::PointI markerLocation(OsmAnd::Utilities::get31TileNumberX(location.coordinate.longitude),
                                  OsmAnd::Utilities::get31TileNumberY(location.coordinate.latitude));
    _activeMarker->setPosition(markerLocation);
    _restMarker->setPosition(markerLocation);
    _lostMarker->setPosition(markerLocation);

    if (drawDirectionLine)
    {
        int inverseZoom = (int)OsmAnd::ZoomLevel::MaxZoomLevel - (int)zoom;
        double lineLength = speedFactor * std::pow(2.0, inverseZoom) * 34.0 * 0.75;
        double theta = rotation * M_PI / 180.0;
        int dx = (int)ceil(-sin(theta) * lineLength);
        int dy = (int)ceil(cos(theta) * lineLength);

        QVector<OsmAnd::PointI> points;
        points.push_back(markerLocation);
        points.push_back(OsmAnd::PointI(markerLocation.x + dx, markerLocation.y + dy));
        _directionLine->setPoints(points);
    }
    _directionLine->setIsHidden(!drawDirectionLine);
}

- (void)clearRenderDataFromMarkersCollection:(const std::shared_ptr<OsmAnd::MapMarkersCollection> &)markersCollection
                       vectorLinesCollection:(const std::shared_ptr<OsmAnd::VectorLinesCollection> &)vectorLinesCollection
{
    if (markersCollection)
    {
        if (_activeMarker)
            markersCollection->removeMarker(_activeMarker);
        if (_restMarker)
            markersCollection->removeMarker(_restMarker);
        if (_lostMarker)
            markersCollection->removeMarker(_lostMarker);
    }
    if (vectorLinesCollection && _directionLine)
        vectorLinesCollection->removeLine(_directionLine);

    _activeMarker.reset();
    _restMarker.reset();
    _lostMarker.reset();
    _directionLine.reset();
}

- (sk_sp<SkImage>)iconImageForState:(NSInteger)state
{
    CGFloat scale = UIScreen.mainScreen.scale;
    CGSize size = CGSizeMake(34.0, 34.0);
    UIGraphicsBeginImageContextWithOptions(size, NO, scale);
    CGRect bounds = CGRectInset(CGRectMake(0, 0, size.width, size.height), 4, 4);

    UIBezierPath *path;
    if (state == 1)
    {
        path = [UIBezierPath bezierPathWithOvalInRect:bounds];
    }
    else if (_object.objectClass == AisObjTypeAton || _object.objectClass == AisObjTypeAtonVirtual)
    {
        path = [UIBezierPath bezierPathWithOvalInRect:bounds];
    }
    else if ([_object isMovable])
    {
        path = [UIBezierPath bezierPath];
        [path moveToPoint:CGPointMake(CGRectGetMidX(bounds), CGRectGetMinY(bounds))];
        [path addLineToPoint:CGPointMake(CGRectGetMaxX(bounds), CGRectGetMaxY(bounds))];
        [path addLineToPoint:CGPointMake(CGRectGetMidX(bounds), CGRectGetMaxY(bounds) - 6)];
        [path addLineToPoint:CGPointMake(CGRectGetMinX(bounds), CGRectGetMaxY(bounds))];
        [path closePath];
    }
    else
    {
        path = [UIBezierPath bezierPathWithRoundedRect:bounds cornerRadius:4];
    }

    [UIColor.whiteColor setFill];
    [UIColor.whiteColor setStroke];
    path.lineWidth = 2;
    [path fill];
    [path stroke];

    if (state == 2)
    {
        UIBezierPath *cross = [UIBezierPath bezierPath];
        [cross moveToPoint:CGPointMake(CGRectGetMinX(bounds) + 2, CGRectGetMinY(bounds) + 2)];
        [cross addLineToPoint:CGPointMake(CGRectGetMaxX(bounds) - 2, CGRectGetMaxY(bounds) - 2)];
        [cross moveToPoint:CGPointMake(CGRectGetMaxX(bounds) - 2, CGRectGetMinY(bounds) + 2)];
        [cross addLineToPoint:CGPointMake(CGRectGetMinX(bounds) + 2, CGRectGetMaxY(bounds) - 2)];
        [UIColor.blackColor setStroke];
        cross.lineWidth = 3;
        [cross stroke];
    }

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [OANativeUtilities skImageFromCGImage:image.CGImage];
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

@implementation OAAisTrackerLayer
{
    OAAisTrackerPlugin *_plugin;
    NSMutableDictionary<NSNumber *, OAAisObjectRenderData *> *_objectRenderData;
    std::shared_ptr<OsmAnd::MapMarkersCollection> _markersCollection;
    std::shared_ptr<OsmAnd::VectorLinesCollection> _vectorLinesCollection;
    id _objectsObserver;
    BOOL _collectionsAdded;
}

- (instancetype)initWithMapViewController:(OAMapViewController *)mapViewController baseOrder:(int)baseOrder
{
    self = [super initWithMapViewController:mapViewController baseOrder:baseOrder];
    if (self)
    {
        _plugin = (OAAisTrackerPlugin *)[OAPluginsHelper getPlugin:OAAisTrackerPlugin.class];
        _objectRenderData = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSString *)layerId
{
    return kAisTrackerLayerId;
}

- (void)initLayer
{
    [super initLayer];
    [self resetCollections];
    [self.app.data.mapLayersConfiguration setLayer:self.layerId
                                        Visibility:self.isVisible];

    __weak OAAisTrackerLayer *weakSelf = self;
    _objectsObserver = [NSNotificationCenter.defaultCenter addObserverForName:@"OAAisObjectsChanged"
                                                                       object:nil
                                                                        queue:NSOperationQueue.mainQueue
                                                                   usingBlock:^(NSNotification * _Nonnull note) {
        [weakSelf reloadObjects];
    }];
}

- (void)deinitLayer
{
    if (_objectsObserver)
    {
        [NSNotificationCenter.defaultCenter removeObserver:_objectsObserver];
        _objectsObserver = nil;
    }
    [self cleanupResources];
    [super deinitLayer];
}

- (BOOL)isVisible
{
    return [_plugin isEnabled];
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
    [self removeCollectionsFromRenderer];
    if (_markersCollection)
        _markersCollection->removeAllMarkers();
    if (_vectorLinesCollection)
        _vectorLinesCollection->removeAllLines();
    [_objectRenderData removeAllObjects];
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
    NSArray<AisObject *> *objects = [_plugin getAisObjects];
    NSMutableSet<NSNumber *> *visibleMmsi = [NSMutableSet set];
    for (AisObject *object in objects)
    {
        if (!object.hasPosition)
            continue;

        NSNumber *key = @(object.mmsi);
        [visibleMmsi addObject:key];
        OAAisObjectRenderData *renderData = _objectRenderData[key];
        if (!renderData)
        {
            renderData = [[OAAisObjectRenderData alloc] initWithObject:object];
            _objectRenderData[key] = renderData;
        }
        renderData.object = object;
        if (![renderData hasRenderData])
            [renderData createRenderDataWithBaseOrder:self.baseOrder markersCollection:_markersCollection vectorLinesCollection:_vectorLinesCollection];
        [renderData updateRenderDataWithMapView:self.mapView plugin:_plugin];
    }

    for (NSNumber *key in [_objectRenderData.allKeys copy])
    {
        if (![visibleMmsi containsObject:key])
        {
            [_objectRenderData[key] clearRenderDataFromMarkersCollection:_markersCollection vectorLinesCollection:_vectorLinesCollection];
            [_objectRenderData removeObjectForKey:key];
        }
    }
}

- (void)updateRenderData
{
    if (![self isVisible])
        return;

    for (NSNumber *key in _objectRenderData)
        [_objectRenderData[key] updateRenderDataWithMapView:self.mapView plugin:_plugin];
}

#pragma mark - OAContextMenuProvider

- (OATargetPoint *)getTargetPoint:(id)obj touchLocation:(CLLocation *)touchLocation
{
    if (![obj isKindOfClass:AisObject.class] || !((AisObject *)obj).hasPosition)
        return nil;

    AisObject *object = obj;
    CLLocation *location = object.currentLocation ?: object.location;
    if (!location)
        return nil;

    OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
    targetPoint.type = OATargetAisObject;
    targetPoint.targetObj = object;
    targetPoint.title = object.title;
    targetPoint.titleSecond = [self objectTypeName:object.objectClass];
    targetPoint.location = location.coordinate;
    targetPoint.icon = [UIImage imageNamed:@"ic_plugin_nautical"];
    targetPoint.sortIndex = OATargetAisObject;
    targetPoint.centerMap = YES;
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
    return object.currentLocation ?: object.location;
}

- (OAPointDescription *)getObjectName:(id)obj
{
    if (![obj isKindOfClass:AisObject.class])
        return nil;
    AisObject *object = obj;
    return [[OAPointDescription alloc] initWithType:POINT_TYPE_LOCATION typeName:OALocalizedString(@"plugin_ais_tracker_name") name:object.title];
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
    int radius = MAX(28, (int)([self getScaledTouchRadius:[self getDefaultRadiusPoi]] * TOUCH_RADIUS_MULTIPLIER));
    QList<OsmAnd::PointI> touchPolygon31 =
        [OANativeUtilities getPolygon31FromScreenAreaLeft:point.x - radius
                                                      top:point.y - radius
                                                    right:point.x + radius
                                                   bottom:point.y + radius];
    if (touchPolygon31.isEmpty())
        return;

    for (AisObject *object in [_plugin getAisObjects])
    {
        CLLocation *location = object.currentLocation ?: object.location;
        if (!location)
            continue;

        if ([OANativeUtilities isPointInsidePolygonLat:location.coordinate.latitude
                                                   lon:location.coordinate.longitude
                                             polygon31:touchPolygon31])
            [result collect:object provider:self];
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
