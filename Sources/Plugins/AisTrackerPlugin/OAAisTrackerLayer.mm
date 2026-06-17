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
#include <string>
#include <unordered_map>

static NSString * const kAisTrackerLayerId = @"ais_tracker_layer";
static const int kAisTrackerStartZoom = 6;
static const CGFloat kAisBaseIconSize = 48.0;
static const CGFloat kAisDirectionLineStartIconFactor = 0.42;
static const float kAisRenderZoomEpsilon = 0.02f;
static const NSTimeInterval kAisViewportRenderUpdateInterval = 0.2;
static int kAisIconKeyStorage;
static const OsmAnd::MapMarker::OnSurfaceIconKey kAisIconKey = &kAisIconKeyStorage;
static std::unordered_map<std::string, sk_sp<SkImage>> kAisImagesCache;

static BOOL OAAisTypeEquals(OASAisObjType *type, OASAisObjType *expected)
{
    return type == expected || [type isEqual:expected];
}

static std::string OAAisImageCacheKey(NSString *prefix, NSString *name, CGFloat iconSize)
{
    NSString *key = [NSString stringWithFormat:@"%@:%@:%d", prefix, name, (int)std::round(iconSize * 100.0)];
    return std::string(key.UTF8String);
}

static sk_sp<SkImage> OAAisCachedSvgImage(NSString *resourceName, CGFloat iconSize)
{
    std::string key = OAAisImageCacheKey(@"svg", resourceName, iconSize);
    const auto cachedImage = kAisImagesCache.find(key);
    if (cachedImage != kAisImagesCache.end())
        return cachedImage->second;

    sk_sp<SkImage> image = [OANativeUtilities skImageFromSvgResource:resourceName width:iconSize height:iconSize];
    if (image)
        kAisImagesCache[key] = image;
    return image;
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

@interface AisObjectDrawable : NSObject

@property (nonatomic) OASAisObject *object;
@property (nonatomic, copy) NSString *renderKey;

- (instancetype)initWithObject:(OASAisObject *)object;
- (instancetype)initWithObject:(OASAisObject *)object
                      textScale:(CGFloat)textScale
           displayDensityFactor:(CGFloat)displayDensityFactor;
- (void)set:(OASAisObject *)object;
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

- (instancetype)initWithObject:(OASAisObject *)object
{
    return [self initWithObject:object textScale:1.0 displayDensityFactor:UIScreen.mainScreen.scale];
}

- (instancetype)initWithObject:(OASAisObject *)object
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

- (void)set:(OASAisObject *)object
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
    CLLocation *location = OAAisObjectLocation(_object);
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
    if (!mapView || (int)zoom < kAisTrackerStartZoom || !_object.position)
    {
        [self setAisRenderDataHidden:YES];
        return;
    }

    CLLocation *location = OAAisObjectLocation(_object);
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
    BOOL lostTimeout = vesselLostTimeout > 0 && [_object isLostMaxAgeInMin:(int32_t)vesselLostTimeout] && !vesselAtRest;
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

    float rotation = fmod([_object getVesselRotation] + 180.0, 360.0);
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
        sk_sp<SkImage> image = OAAisCachedSvgImage(resourceName, iconSize);
        if (image)
            return image;
    }

    NSString *drawnKeyName = [NSString stringWithFormat:@"%ld:%@", (long)state, _object.objectClass.name];
    std::string drawnKey = OAAisImageCacheKey(@"drawn", drawnKeyName, iconSize);
    const auto cachedImage = kAisImagesCache.find(drawnKey);
    if (cachedImage != kAisImagesCache.end())
        return cachedImage->second;

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
    else if (OAAisTypeEquals(_object.objectClass, OASAisObjType.aisAton) || OAAisTypeEquals(_object.objectClass, OASAisObjType.aisAtonVirtual))
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

    if (OAAisTypeEquals(_object.objectClass, OASAisObjType.aisAtonVirtual) && state != 1)
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
    sk_sp<SkImage> skImage = [OANativeUtilities skImageFromCGImage:image.CGImage];
    if (skImage)
        kAisImagesCache[drawnKey] = skImage;
    return skImage;
}

- (CGFloat)iconSize
{
    return kAisBaseIconSize * _textScale * _displayDensityFactor;
}

- (UIColor *)colorForType:(OASAisObjType *)type
{
    if (OAAisTypeEquals(type, OASAisObjType.aisVessel)) return UIColor.greenColor;
    if (OAAisTypeEquals(type, OASAisObjType.aisVesselSport)) return UIColor.yellowColor;
    if (OAAisTypeEquals(type, OASAisObjType.aisVesselFast)) return UIColor.blueColor;
    if (OAAisTypeEquals(type, OASAisObjType.aisVesselPassenger)) return UIColor.cyanColor;
    if (OAAisTypeEquals(type, OASAisObjType.aisVesselFreight)) return UIColor.grayColor;
    if (OAAisTypeEquals(type, OASAisObjType.aisVesselCommercial)) return UIColor.lightGrayColor;
    if (OAAisTypeEquals(type, OASAisObjType.aisVesselAuthorities)) return [UIColor colorWithRed:0.33 green:0.42 blue:0.18 alpha:1.0];
    if (OAAisTypeEquals(type, OASAisObjType.aisVesselSar) || OAAisTypeEquals(type, OASAisObjType.aisSart)) return [UIColor colorWithRed:0.98 green:0.50 blue:0.45 alpha:1.0];
    if (OAAisTypeEquals(type, OASAisObjType.aisVesselOther)) return [UIColor colorWithRed:0.00 green:0.75 blue:1.00 alpha:1.0];
    if (OAAisTypeEquals(type, OASAisObjType.aisAirplane)) return [UIColor colorWithRed:0.45 green:0.27 blue:0.86 alpha:1.0];
    if (OAAisTypeEquals(type, OASAisObjType.aisAton) || OAAisTypeEquals(type, OASAisObjType.aisAtonVirtual)) return [UIColor colorWithRed:0.92 green:0.82 blue:0.14 alpha:1.0];
    if (OAAisTypeEquals(type, OASAisObjType.aisLandstation)) return [UIColor colorWithRed:0.45 green:0.45 blue:0.45 alpha:1.0];
    return [UIColor colorWithRed:0.04 green:0.62 blue:0.72 alpha:1.0];
}

- (NSString *)iconResourceNameForType:(OASAisObjType *)type
{
    if (OAAisTypeEquals(type, OASAisObjType.aisLandstation)) return @"c_mx_ais_land";
    if (OAAisTypeEquals(type, OASAisObjType.aisAirplane)) return @"c_mx_ais_plane";
    if (OAAisTypeEquals(type, OASAisObjType.aisSart)) return @"c_mx_ais_sar";
    if (OAAisTypeEquals(type, OASAisObjType.aisAton)) return @"c_mx_ais_aton";
    if (OAAisTypeEquals(type, OASAisObjType.aisAtonVirtual)) return @"c_mx_ais_aton_virt";
    return @"c_mx_ais_vessel";
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
    return (((_object.cog != OASAisObjectConstants.shared.INVALID_COG) && (_object.cog != 0.0)) ||
            ((_object.heading != OASAisObjectConstants.shared.INVALID_HEADING) && (_object.heading != 0))) && [_object isMovable];
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
    {
        kAisImagesCache.clear();
        [self cleanupResources];
    }

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
        if (_collectionsAdded || _objectDrawables.count > 0)
        {
            kAisImagesCache.clear();
            [self cleanupResources];
        }
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

- (void)reloadAisObjects
{
    [self cleanupResources];
    if ([self isVisible])
    {
        [self addCollectionsToRenderer];
        [self reloadObjects];
    }
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
    NSArray<OASAisObject *> *objects = [plugin getAisObjects];
    NSMutableSet<NSNumber *> *visibleMmsi = [NSMutableSet set];
    for (OASAisObject *object in objects)
    {
        if (!object.position)
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
}

- (void)onAisObjectReceived:(OASAisObject *)object
{
    if (![self isVisible] || !object.position)
        return;
    [[AisLogger shared] log:[NSString stringWithFormat:@"receive %@", OAAisDebugSummary(object)]];
    [self addCollectionsToRenderer];
    [self.mapViewController runWithRenderSync:^{
        [self updateAisObjectSync:object];
    }];
}

- (void)onAisObjectRemoved:(OASAisObject *)object
{
    if (!object)
        return;

    [self.mapViewController runWithRenderSync:^{
        NSNumber *key = @(object.mmsi);
        AisObjectDrawable *drawable = _objectDrawables[key];
        [[AisLogger shared] log:[NSString stringWithFormat:@"remove hasDrawable=%@ drawables=%lu %@",
                                 drawable ? @"yes" : @"no", (unsigned long)_objectDrawables.count, OAAisDebugSummary(object)]];
        if (drawable)
        {
            [drawable clearAisRenderDataFromMarkersCollection:_markersCollection vectorLinesCollection:_vectorLinesCollection];
            [_objectDrawables removeObjectForKey:key];
        }
    }];
}

- (void)updateAisObjectSync:(OASAisObject *)object
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

    [[AisLogger shared] log:[NSString stringWithFormat:@"update recreated=%@ drawables=%lu lines=%d %@", recreated ? @"yes" : @"no", (unsigned long)_objectDrawables.count, linesCount, OAAisDebugSummary(object)]];
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
    if (excludeUntouchableObjects || ![self isVisible] || (int)self.mapView.zoomLevel < kAisTrackerStartZoom)
        return;

    CGPoint point = result.point;
    int iconRadius = (int)ceil([self currentIconSize] * 0.55);
    int radius = MAX(iconRadius, (int)([self getScaledTouchRadius:[self getDefaultRadiusPoi]] * TOUCH_RADIUS_MULTIPLIER));
    QList<OsmAnd::PointI> touchPolygon31 =
        [OANativeUtilities getPolygon31FromScreenAreaLeft:point.x - radius
                                                      top:point.y - radius
                                                    right:point.x + radius
                                                   bottom:point.y + radius];
    if (touchPolygon31.isEmpty())
        return;

    NSArray<OASAisObject *> *objects = [[self plugin] getAisObjects];
    for (OASAisObject *object in objects)
    {
        CLLocation *location = OAAisObjectLocation(object);
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
