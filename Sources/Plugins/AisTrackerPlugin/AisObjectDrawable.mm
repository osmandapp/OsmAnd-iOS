//
//  AisObjectDrawable.mm
//  OsmAnd
//
//  Created by OsmAnd on 27.07.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import "AisObjectDrawable.h"
#import "OAMapRendererView.h"
#import "OANativeUtilities.h"
#import "OsmAnd_Maps-Swift.h"

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/MapMarkerBuilder.h>
#include <OsmAndCore/Map/VectorLineBuilder.h>
#include <OsmAndCore/SingleSkImage.h>
#include <algorithm>
#include <cmath>
#include <string>
#include <unordered_map>

static const int kAisDirectionLineStartZoom = 10;
static const CGFloat kAisBaseIconSize = 48.0;
static const CGFloat kAisRestIconScale = 0.7;
static const CGFloat kAisDirectionLineStartIconFactor = 0.42;
static const OsmAnd::MapMarker::OnSurfaceIconKey kAisIconKey = reinterpret_cast<OsmAnd::MapMarker::OnSurfaceIconKey>(1);
static std::unordered_map<std::string, sk_sp<SkImage>> kAisImagesCache;

static BOOL AisDrawableTypeEquals(OASAisObjType *type, OASAisObjType *expected)
{
    return type == expected || [type isEqual:expected];
}

static std::string AisDrawableImageCacheKey(NSString *prefix, NSString *name, CGFloat iconSize)
{
    NSString *key = [NSString stringWithFormat:@"%@:%@:%d", prefix, name, (int)std::round(iconSize * 100.0)];
    return std::string(key.UTF8String);
}

static sk_sp<SkImage> AisDrawableCachedSvgImage(NSString *resourceName, CGFloat iconSize)
{
    std::string key = AisDrawableImageCacheKey(@"svg", resourceName, iconSize);
    const auto cachedImage = kAisImagesCache.find(key);
    if (cachedImage != kAisImagesCache.end())
        return cachedImage->second;

    sk_sp<SkImage> image = [OANativeUtilities skImageFromSvgResource:resourceName width:iconSize height:iconSize];
    if (image)
        kAisImagesCache[key] = image;
    return image;
}

@interface AisObjectDrawable ()

@property (nonatomic, strong) OASAisObject *object;
@property (nonatomic) NSInteger visualState;

- (int)renderGroupId;
- (OsmAnd::PointI)markerLocation;
- (void)setAisRenderDataHidden:(BOOL)hidden;
- (void)setAisMarkersUpdateAfterCreated;
- (sk_sp<SkImage>)iconImageForState:(NSInteger)state;
- (CGFloat)iconSize;
- (UIColor *)colorForType:(OASAisObjType *)type;
- (NSString *)iconResourceNameForType:(OASAisObjType *)type;
- (CGFloat)movementFactor;
- (BOOL)needRotation;

@end

@implementation AisObjectDrawable
{
    std::shared_ptr<OsmAnd::MapMarker> _marker;
    std::shared_ptr<OsmAnd::VectorLine> _directionLine;
    CGFloat _textScale;
    CGFloat _displayDensityFactor;
    int _baseOrder;
}

+ (void)clearImageCache
{
    kAisImagesCache.clear();
}

+ (CGFloat)baseIconSize
{
    return kAisBaseIconSize;
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
        _visualState = 0;
        _renderedSurfaceZoom = -1.0f;
        [self setTextScale:textScale displayDensityFactor:displayDensityFactor];
    }
    return self;
}

- (void)setObject:(OASAisObject *)object visualState:(NSInteger)visualState
{
    _object = object;
    _visualState = visualState;
}

- (void)setTextScale:(CGFloat)textScale displayDensityFactor:(CGFloat)displayDensityFactor
{
    _textScale = textScale > 0 ? textScale : 1.0;
    _displayDensityFactor = MAX(1.0, displayDensityFactor);
}

- (BOOL)hasAisRenderData
{
    return _marker != nullptr;
}

- (BOOL)hasAnyAisRenderData
{
    return _marker || _directionLine;
}

- (int)renderGroupId
{
    return (int)_object.mmsi;
}

- (NSString *)currentRenderKey
{
    NSString *iconName = _visualState == 0 ? [self iconResourceNameForType:_object.objectClass] : @"generated";
    return [NSString stringWithFormat:@"surface-v4-%ld-%@-%d",
            (long)_visualState,
            iconName,
            (int)std::round([self iconSize] * 100.0)];
}

- (OsmAnd::PointI)markerLocation
{
    if (!_object.position)
        return OsmAnd::PointI(0, 0);
    return OsmAnd::PointI(OsmAnd::Utilities::get31TileNumberX(_object.position.longitude),
                          OsmAnd::Utilities::get31TileNumberY(_object.position.latitude));
}

- (void)setAisRenderDataHidden:(BOOL)hidden
{
    if (_marker)
        _marker->setIsHidden(hidden);
    if (_directionLine)
        _directionLine->setIsHidden(hidden);
    [self setAisMarkersUpdateAfterCreated];
}

- (void)setAisMarkersUpdateAfterCreated
{
    if (_marker)
        _marker->setUpdateAfterCreated(true);
}

- (void)createAisRenderDataWithBaseOrder:(int)baseOrder
                       markersCollection:(const std::shared_ptr<OsmAnd::MapMarkersCollection> &)markersCollection
{
    if (!markersCollection)
        return;

    _baseOrder = baseOrder;

    sk_sp<SkImage> icon = [self iconImageForState:_visualState];
    if (!icon)
        return;

    OsmAnd::MapMarkerBuilder markerBuilder;
    OsmAnd::PointI markerLocation = [self markerLocation];
    markerBuilder
        .setGroupId([self renderGroupId])
        .setMarkerId(0)
        .setBaseOrder(baseOrder)
        .setIsHidden(false)
        .setUpdateAfterCreated(true)
        .setPosition(markerLocation)
        .addOnMapSurfaceIcon(kAisIconKey, OsmAnd::SingleSkImage(icon));
    _marker = markerBuilder.buildAndAddToCollection(markersCollection);
    [self setAisMarkersUpdateAfterCreated];

    _renderKey = [self currentRenderKey];
}

- (void)updateAisRenderDataWithMapView:(OAMapRendererView *)mapView
                            cpaWarning:(BOOL)cpaWarning
                               visible:(BOOL)visible
                 vectorLinesCollection:(const std::shared_ptr<OsmAnd::VectorLinesCollection> &)vectorLinesCollection
{
    if (![self hasAisRenderData])
        return;

    const OsmAnd::ZoomLevel zoom = mapView ? mapView.zoomLevel : OsmAnd::ZoomLevel::MinZoomLevel;
    if (!mapView || !visible || !_object.position)
    {
        [self setAisRenderDataHidden:YES];
        return;
    }

    OsmAnd::PointI markerLocation = [self markerLocation];
    BOOL vesselAtRest = _visualState == 1;
    BOOL lostTimeout = _visualState == 2;
    CGFloat speedFactor = [self movementFactor];
    BOOL drawDirectionLine = (int)zoom >= kAisDirectionLineStartZoom
        && speedFactor > 0
        && !lostTimeout
        && !vesselAtRest;

    UIColor *uiColor = cpaWarning ? UIColor.redColor : [self colorForType:_object.objectClass];
    OsmAnd::ColorARGB iconColor = [uiColor toColorARGB];
    if (_visualState != 2)
        _marker->setOnSurfaceIconModulationColor(iconColor);
    _marker->setIsHidden(false);

    BOOL rotateMarker = !vesselAtRest && [self needRotation];
    float rotation = rotateMarker ? fmod([_object getVesselRotation] + 180.0, 360.0) : 0.0f;
    _marker->setOnMapSurfaceIconDirection(kAisIconKey, rotation);
    _marker->setPosition(markerLocation);
    [self setAisMarkersUpdateAfterCreated];

    if (drawDirectionLine && !_directionLine && vectorLinesCollection)
    {
        QVector<OsmAnd::PointI> points;
        points.push_back(markerLocation);
        points.push_back(OsmAnd::PointI(markerLocation.x + 1, markerLocation.y + 1));

        OsmAnd::VectorLineBuilder lineBuilder;
        lineBuilder
            .setLineId([self renderGroupId])
            .setBaseOrder(_baseOrder + 10)
            .setIsHidden(false)
            .setLineWidth(6.0)
            .setApproximationEnabled(false)
            .setFillColor(OsmAnd::FColorARGB(1.0f, 0.0f, 0.0f, 0.0f))
            .setPoints(points);
        _directionLine = lineBuilder.buildAndAddToCollection(vectorLinesCollection);
    }
    else if (!drawDirectionLine && _directionLine && vectorLinesCollection)
    {
        _directionLine->setIsHidden(true);
        vectorLinesCollection->removeLine(_directionLine);
        _directionLine.reset();
    }

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
        _directionLine->setIsHidden(false);
    }
    _cpaWarning = cpaWarning;
    _renderedSurfaceZoom = mapView.zoom;
}

- (void)clearAisRenderDataFromMarkersCollection:(const std::shared_ptr<OsmAnd::MapMarkersCollection> &)markersCollection
                          vectorLinesCollection:(const std::shared_ptr<OsmAnd::VectorLinesCollection> &)vectorLinesCollection
{
    if (markersCollection && _marker)
        markersCollection->removeMarker(_marker);
    if (vectorLinesCollection && _directionLine)
    {
        _directionLine->setIsHidden(true);
        vectorLinesCollection->removeLine(_directionLine);
    }

    _marker.reset();
    _directionLine.reset();
    _renderKey = nil;
    _renderedVersion = 0;
    _renderedSurfaceZoom = -1.0f;
}

- (sk_sp<SkImage>)iconImageForState:(NSInteger)state
{
    CGFloat iconSize = [self iconSize];
    if (state != 1)
    {
        NSString *resourceName = state == 2 ? @"c_mx_ais_vessel_cross" : [self iconResourceNameForType:_object.objectClass];
        sk_sp<SkImage> image = AisDrawableCachedSvgImage(resourceName, iconSize);
        if (image)
            return image;
    }

    NSString *drawnKeyName = [NSString stringWithFormat:@"%ld:%@", (long)state, _object.objectClass.name];
    std::string drawnKey = AisDrawableImageCacheKey(@"drawn", drawnKeyName, iconSize);
    const auto cachedImage = kAisImagesCache.find(drawnKey);
    if (cachedImage != kAisImagesCache.end())
        return cachedImage->second;

    CGSize size = CGSizeMake(iconSize, iconSize);
    UIGraphicsBeginImageContextWithOptions(size, NO, 1.0);
    CGFloat sizeFactor = iconSize / 72.0;
    CGRect bounds = CGRectInset(CGRectMake(0, 0, size.width, size.height), 6 * sizeFactor, 6 * sizeFactor);
    if (state == 1)
    {
        CGFloat restInset = CGRectGetWidth(bounds) * (1.0 - kAisRestIconScale) * 0.5;
        bounds = CGRectInset(bounds, restInset, restInset);
    }

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
    else if (AisDrawableTypeEquals(_object.objectClass, OASAisObjType.aisAton)
             || AisDrawableTypeEquals(_object.objectClass, OASAisObjType.aisAtonVirtual))
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

    if (AisDrawableTypeEquals(_object.objectClass, OASAisObjType.aisAtonVirtual) && state != 1)
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
    if (AisDrawableTypeEquals(type, OASAisObjType.aisVessel)) return UIColor.greenColor;
    if (AisDrawableTypeEquals(type, OASAisObjType.aisVesselSport)) return UIColor.yellowColor;
    if (AisDrawableTypeEquals(type, OASAisObjType.aisVesselFast)) return UIColor.blueColor;
    if (AisDrawableTypeEquals(type, OASAisObjType.aisVesselPassenger)) return UIColor.cyanColor;
    if (AisDrawableTypeEquals(type, OASAisObjType.aisVesselFreight)) return UIColor.grayColor;
    if (AisDrawableTypeEquals(type, OASAisObjType.aisVesselCommercial)) return UIColor.lightGrayColor;
    if (AisDrawableTypeEquals(type, OASAisObjType.aisVesselAuthorities)) return [UIColor colorWithRed:0.33 green:0.42 blue:0.18 alpha:1.0];
    if (AisDrawableTypeEquals(type, OASAisObjType.aisVesselSar) || AisDrawableTypeEquals(type, OASAisObjType.aisSart)) return [UIColor colorWithRed:0.98 green:0.50 blue:0.45 alpha:1.0];
    if (AisDrawableTypeEquals(type, OASAisObjType.aisVesselOther)) return [UIColor colorWithRed:0.00 green:0.75 blue:1.00 alpha:1.0];
    if (AisDrawableTypeEquals(type, OASAisObjType.aisAirplane)) return [UIColor colorWithRed:0.45 green:0.27 blue:0.86 alpha:1.0];
    if (AisDrawableTypeEquals(type, OASAisObjType.aisAton) || AisDrawableTypeEquals(type, OASAisObjType.aisAtonVirtual)) return [UIColor colorWithRed:0.92 green:0.82 blue:0.14 alpha:1.0];
    if (AisDrawableTypeEquals(type, OASAisObjType.aisLandstation)) return [UIColor colorWithRed:0.45 green:0.45 blue:0.45 alpha:1.0];
    return [UIColor colorWithRed:0.04 green:0.62 blue:0.72 alpha:1.0];
}

- (NSString *)iconResourceNameForType:(OASAisObjType *)type
{
    if (AisDrawableTypeEquals(type, OASAisObjType.aisLandstation)) return @"c_mx_ais_land";
    if (AisDrawableTypeEquals(type, OASAisObjType.aisAirplane)) return @"c_mx_ais_plane";
    if (AisDrawableTypeEquals(type, OASAisObjType.aisSart)) return @"c_mx_ais_sar";
    if (AisDrawableTypeEquals(type, OASAisObjType.aisAton)) return @"c_mx_ais_aton";
    if (AisDrawableTypeEquals(type, OASAisObjType.aisAtonVirtual)) return @"c_mx_ais_aton_virt";
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
