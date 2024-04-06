//
//  OAPreviewRouteLineLayer.m
//  OsmAnd
//
//  Created by Alexey Kulish on 11/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAPreviewRouteLineLayer.h"
#import "OARootViewController.h"
#import "OAMapRendererView.h"
#import "OARoutingHelper.h"
#import "OARouteCalculationResult.h"
#import "OANativeUtilities.h"
#import "OARouteDirectionInfo.h"
#import "OAAutoObserverProxy.h"
#import "OAColors.h"
#import "OAPreviewRouteLineInfo.h"
#import "OAGPXAppearanceCollection.h"
#import "OARouteColorizationHelper.h"
#import "OAMapPresentationEnvironment.h"

#include <OsmAndCore/Map/VectorLineBuilder.h>
#include <OsmAndCore/Map/MapMarker.h>
#include <OsmAndCore/Map/MapMarkerBuilder.h>
#include <OsmAndCore/Map/MapMarkersCollection.h>
#include <OsmAndCore/SkiaUtilities.h>
#include <OsmAndCore/SingleSkImage.h>

#define kTurnArrowsColoringByAttr 0xffffffff
#define kOutlineId 1001

@implementation OAPreviewRouteLineLayer
{
    std::shared_ptr<OsmAnd::VectorLinesCollection> _collection;
    
    
    OARoutingHelper *_routingHelper;
    std::shared_ptr<OsmAnd::VectorLinesCollection> _actionLinesCollection;
    
    NSDictionary<NSString *, NSNumber *> *_routeAttributes;

    BOOL _initDone;

    CGFloat _lineWidth;
    OAPreviewRouteLineInfo *_previewRouteLineInfo;
    NSInteger _routeLineColor;
    NSInteger _customTurnArrowsColor;
    OAColoringType *_routeColoringType;
    NSString *_routeInfoAttribute;
    OAGPXAppearanceCollection *_appearanceCollection;

    OARouteCalculationResult *_route;
    int _colorizationScheme;
    QList<OsmAnd::FColorARGB> _colors;
    OAColoringType *_prevRouteColoringType;
    NSString *_prevRouteInfoAttribute;
    NSMutableDictionary<NSString *, NSNumber *> *_cachedRouteLineWidth;
    
    std::shared_ptr<OsmAnd::MapMarkersCollection> _centerMarkerCollection;
    std::shared_ptr<OsmAnd::MapMarker> _locationMarker;
    OsmAnd::MapMarker::OnSurfaceIconKey _locationMainIconKey;
}

- (NSString *) layerId
{
    return kRouteAppearanceLayerId;
}

- (void) initLayer
{
    [super initLayer];
    
    _routingHelper = OARoutingHelper.sharedInstance;
    
    _collection = std::make_shared<OsmAnd::VectorLinesCollection>();
    _actionLinesCollection = std::make_shared<OsmAnd::VectorLinesCollection>();
    [self refreshCenterIcon];
    
    _routeAttributes = [self.mapViewController getLineRenderingAttributes:@"route"];
    
    _initDone = YES;
    
    [self.mapView addKeyedSymbolsProvider:_collection];
    
    _lineWidth = kDefaultWidthMultiplier * kWidthCorrectionValue;
    _routeColoringType = OAColoringType.DEFAULT;
    _colorizationScheme = COLORIZATION_NONE;
    _cachedRouteLineWidth = [NSMutableDictionary dictionary];
}

- (void) resetLayer
{
    [super resetLayer];
    
    [self.mapView removeKeyedSymbolsProvider:_collection];
    [self.mapView removeKeyedSymbolsProvider:_actionLinesCollection];
    [self.mapView removeKeyedSymbolsProvider:_centerMarkerCollection];
    
    _collection = std::make_shared<OsmAnd::VectorLinesCollection>();
    _actionLinesCollection = std::make_shared<OsmAnd::VectorLinesCollection>();
    _centerMarkerCollection.reset();
    
    _routeAttributes = [self.mapViewController getLineRenderingAttributes:@"route"];
}

- (void) refreshCenterIcon
{
    if (!_centerMarkerCollection || !_locationMarker)
    {
        [self.mapView removeKeyedSymbolsProvider:_centerMarkerCollection];
        _centerMarkerCollection = std::make_shared<OsmAnd::MapMarkersCollection>();
        
        OAApplicationMode *appMode = OARoutingHelper.sharedInstance.getAppMode;
        OANavigationIcon *navIcon = [OANavigationIcon withNavigationIcon:appMode.getNavigationIcon];
        UIColor *iconColor = UIColorFromRGB(appMode.getIconColor);
        
        OsmAnd::MapMarkerBuilder locationMarkerBuilder;
        locationMarkerBuilder.setIsAccuracyCircleSupported(false);
        locationMarkerBuilder.setBaseOrder(self.pointsOrder - 1000);
        locationMarkerBuilder.setIsHidden(true);
        _locationMainIconKey = reinterpret_cast<OsmAnd::MapMarker::OnSurfaceIconKey>(1);
        locationMarkerBuilder.addOnMapSurfaceIcon(_locationMainIconKey,
                                                  OsmAnd::SingleSkImage([OANativeUtilities skImageFromCGImage:[navIcon iconWithColor:iconColor].CGImage]));
        _locationMarker = locationMarkerBuilder.buildAndAddToCollection(_centerMarkerCollection);
        [self.mapView addKeyedSymbolsProvider:_centerMarkerCollection];
    }
    _locationMarker->setOnMapSurfaceIconDirection(_locationMainIconKey, 270.);
}

- (BOOL) updateLayer
{
    [super updateLayer];

    dispatch_async(dispatch_get_main_queue(), ^{
        _appearanceCollection = [OAGPXAppearanceCollection sharedInstance];
    });
    return YES;
}

- (NSInteger)getCustomRouteWidthMin
{
    return 1;
}

- (NSInteger)getCustomRouteWidthMax
{
    return 36;
}

- (BOOL)isVisible
{
    return !_collection->getLines().isEmpty();
}

- (void) drawRouteSegment:(const QVector<OsmAnd::PointI> &)points addToExisting:(BOOL)addToExisting colors:(const QList<OsmAnd::FColorARGB> &)colors colorizationScheme:(int)colorizationScheme
{
    [self.mapViewController runWithRenderSync:^{
        _lineWidth = [self getLineWidth];
        const auto& lines = _collection->getLines();
        if (lines.empty() || addToExisting)
        {
            BOOL isFirstLine = lines.empty() && !addToExisting;
            if (isFirstLine)
            {
                [self.mapView removeKeyedSymbolsProvider:_collection];
                _collection = std::make_shared<OsmAnd::VectorLinesCollection>();
            }

            int baseOrder = self.baseOrder;

            OsmAnd::VectorLineBuilder builder;
            builder.setBaseOrder(baseOrder--)
                   .setIsHidden(points.size() < 2)
                   .setLineId(1)
                   .setLineWidth(_lineWidth)
                   .setPoints(points);

            // Add outline for colorized lines
            if (!colors.isEmpty())
            {
                builder.setOutlineWidth(_lineWidth + kOutlineWidth)
                       .setOutlineColor(kOutlineColor);
            }

            UIColor *color = _routeLineColor == kDefaultRouteLineDayColor || _routeLineColor == kDefaultRouteLineNightColor
                    ? UIColorFromARGB(_routeLineColor)
                    : UIColorFromRGB(_routeLineColor);

            OsmAnd::ColorARGB lineColor = [color toFColorARGB];

            NSNumber *colorVal = [self getParamFromAttr:@"color"];
            BOOL hasStyleColor = (colorVal && colorVal.intValue != -1 && colorVal.intValue == _routeLineColor)
                    || _routeLineColor == kDefaultRouteLineDayColor
                    || _routeLineColor == kDefaultRouteLineNightColor;

            builder.setFillColor(lineColor)
                   .setPathIcon(OsmAnd::SingleSkImage([self bitmapForColor:hasStyleColor ? UIColor.whiteColor : color
                                            fileName:@"map_direction_arrow"]))
                   .setSpecialPathIcon(OsmAnd::SingleSkImage([self specialBitmapWithColor:lineColor]))
                   .setShouldShowArrows(true)
                   .setScreenScale(UIScreen.mainScreen.scale);

            if (!colors.empty())
            {
                builder.setColorizationMapping(colors)
                       .setColorizationScheme(colorizationScheme);
            }

            builder.buildAndAddToCollection(_collection);

            if (isFirstLine)
            {
                [self.mapView addKeyedSymbolsProvider:_collection];
                [self setVectorLineProvider:_collection sync:YES];
            }
        }
        else
        {
            for (auto &line : lines)
            {
                line->setPoints(points);
                if (!colors.empty())
                    line->setColorizationMapping(colors);
            }
        }
        [self buildActionArrows:points];
    }];
}

- (NSNumber *)getParamFromAttr:(NSString *)param
{
    _routeAttributes = [self.mapViewController getLineRenderingAttributes:@"route"];
    return _routeAttributes[param];
}

- (NSInteger)getDefaultColor:(BOOL)forTurnArrows
{
    BOOL isNight = [OAAppSettings sharedManager].nightMode;
    NSNumber *colorVal = [self getParamFromAttr:forTurnArrows ? @"color_3" : @"color"];
    BOOL hasStyleColor = colorVal && colorVal.intValue != -1;
    return hasStyleColor
            ? colorVal.intValue
            : isNight
                    ? forTurnArrows ? kDefaultTurnArrowsNightColor : kDefaultRouteLineNightColor
                    : forTurnArrows ? kDefaultTurnArrowsDayColor : kDefaultRouteLineDayColor;
}

- (OAPreviewRouteLineInfo *)getPreviewRouteLineInfo
{
    return _previewRouteLineInfo;
}

- (void)setPreviewRouteLineInfo:(OAPreviewRouteLineInfo *)previewInfo
{
    _previewRouteLineInfo = previewInfo;
}

- (void)updateTurnArrowsColor
{
    if ([_routeColoringType isGradient]
            && [_routeColoringType isAvailableForDrawingRoute:[_routingHelper getRoute]
                                                attributeName:_previewRouteLineInfo.routeInfoAttribute])
        _customTurnArrowsColor = kTurnArrowsColoringByAttr;
    else
        _customTurnArrowsColor = [self getDefaultColor:YES];
}

- (void)updateRouteColors:(BOOL)night
{
    if ([_routeColoringType isCustomColor])
        [self updateCustomColor:night];
    else
        _routeLineColor = [self getDefaultColor:NO];

    [self updateTurnArrowsColor];
}

- (void)updateCustomColor:(BOOL)night
{
    NSInteger customColor;
    if (_previewRouteLineInfo)
    {
        customColor = [_previewRouteLineInfo getCustomColor:night];
    }
    else
    {
        OACommonInteger *colorPreference = night
                ? [OAAppSettings sharedManager].customRouteColorNight
                : [OAAppSettings sharedManager].customRouteColorDay;
        customColor = [colorPreference get:[_routingHelper getAppMode]];
    }
    _routeLineColor = customColor;
}

- (void)updateRouteColoringType
{
    if (_previewRouteLineInfo)
    {
        _routeColoringType = _previewRouteLineInfo.coloringType;
        _routeInfoAttribute = _previewRouteLineInfo.routeInfoAttribute;
    }
    else
    {
        OAApplicationMode *mode = [_routingHelper getAppMode];
        OAAppSettings *settings = [OAAppSettings sharedManager];
        _routeColoringType = [settings.routeColoringType get:mode];
        _routeInfoAttribute = [settings.routeInfoAttribute get:mode];
    }
}

- (BOOL)shouldShowTurnArrows
{
    return _previewRouteLineInfo
            ? _previewRouteLineInfo.showTurnArrows
            : [[OAAppSettings sharedManager].routeShowTurnArrows get:[_routingHelper getAppMode]];
}

- (CGFloat)getLineWidth
{
    NSString *widthKey = _previewRouteLineInfo
            ? _previewRouteLineInfo.width
            : [[OAAppSettings sharedManager].routeLineWidth get:[_routingHelper getAppMode]];

    CGFloat width;
    if (widthKey)
    {
        if ([_cachedRouteLineWidth.allKeys containsObject:widthKey])
        {
            width = _cachedRouteLineWidth[widthKey].floatValue;
        }
        else
        {
            width = [self getWidthByKey:widthKey];
            _cachedRouteLineWidth[widthKey] = @(width);
        }
    }
    else
    {
        width = [self getParamFromAttr:@"strokeWidth"].floatValue;
    }

    return width;
}

- (CGFloat)getWidthByKey:(NSString *)widthKey
{
    CGFloat resultValue = kDefaultWidthMultiplier;
    if (widthKey && widthKey.length > 0)
    {
        if ([NSCharacterSet.decimalDigitCharacterSet isSupersetOfSet:
                [NSCharacterSet characterSetWithCharactersInString:widthKey]])
        {
            resultValue = widthKey.integerValue;
        }
        else
        {
            if (_appearanceCollection)
            {
                OAGPXTrackWidth *trackWidth = [_appearanceCollection getWidthForValue:widthKey];
                if (trackWidth)
                {
                    if ([trackWidth isCustom])
                    {
                        resultValue = trackWidth.customValue.floatValue > [self getCustomRouteWidthMax]
                                ? [self getCustomRouteWidthMin]
                                : trackWidth.customValue.floatValue;
                    }
                    else
                    {
                        double width = DBL_MIN;
                        NSArray<NSArray<NSNumber *> *> *allValues = trackWidth.allValues;
                        for (NSArray<NSNumber *> *values in allValues)
                        {
                            width = fmax(values[2].intValue, width);
                        }
                        resultValue = width;
                    }
                }
            }
        }
    }
    return resultValue * kWidthCorrectionValue;
}

- (OsmAnd::AreaI) calculateBounds:(const QVector<OsmAnd::PointI> &)pts
{
    int left = INT_MAX, top = INT_MAX, right = INT_MIN, bottom = INT_MIN;
    for (const auto& pt : pts)
    {
        right = MAX(right, pt.x);
        left = MIN(left, pt.x);
        top = MIN(top, pt.y);
        bottom = MAX(bottom, pt.y);
    }
    OsmAnd::PointI topLeft(left, top);
    OsmAnd::PointI bottomRight(right, bottom);
    return OsmAnd::AreaI(topLeft, bottomRight);
}

- (QVector<OsmAnd::PointI>) getTurnPoints:(const OsmAnd::AreaI &)area leftUp:(BOOL)leftUp
{
    QVector<OsmAnd::PointI> res;
    if (leftUp)
    {
        const auto bottomLeft = area.bottomLeft();
        const auto center = OsmAnd::PointI(area.center().x, area.bottom());
        const auto centerTop = OsmAnd::PointI(area.center().x, area.top());
        int32_t leftDist = center.x - bottomLeft.x;
        int32_t upDist = centerTop.y - center.y;
        double ratio = (double) abs(leftDist) / (double) abs(upDist);
        double upCoef = ratio > 1. ? 0.2 : 0.2 * ratio;
        double leftCoef = ratio > 1. ? 0.2 * (1 - ratio) : 0.2;
        res << OsmAnd::PointI(center.x - leftDist * leftCoef, center.y);
        res << center;
        res << OsmAnd::PointI(center.x, center.y + upDist * upCoef);
    }
    else
    {
        const auto bottom = OsmAnd::PointI(area.center().x, area.bottom());
        const auto center = OsmAnd::PointI(area.center().x, area.top());
        const auto topRight = area.topRight();
        int32_t bottomDist = center.y - bottom.y;
        int32_t rightDist = topRight.x - center.x;
        double ratio = (double) abs(rightDist) / (double) abs(bottomDist);
        double bottomCoef = ratio > 1. ? 0.2 : 0.2 * ratio;
        double rightCoef = ratio > 1. ? 0.2 * (1 - ratio) : 0.2;
        res << OsmAnd::PointI(center.x, center.y - bottomDist * bottomCoef);
        res << center;
        res << OsmAnd::PointI(center.x + rightDist * rightCoef, center.y);
    }
    return res;
}

- (void) buildActionArrows:(const QVector<OsmAnd::PointI> &)points
{
    if ([self shouldShowTurnArrows])
    {
        [self.mapViewController runWithRenderSync:^{
            if (_collection->getLines().isEmpty() || points.count() < 4) {
                [self.mapView removeKeyedSymbolsProvider:_actionLinesCollection];
                _actionLinesCollection->removeAllLines();
                return;
            }
            else
            {
                [self.mapView removeKeyedSymbolsProvider:_actionLinesCollection];
                _actionLinesCollection->removeAllLines();
                int baseOrder = self.baseOrder - 1000;
                const auto area = [self calculateBounds:points];
                QVector<OsmAnd::PointI> turn1 = [self getTurnPoints:area leftUp:YES];
                QVector<OsmAnd::PointI> turn2 = [self getTurnPoints:area leftUp:NO];
                OsmAnd::VectorLineBuilder builder1;
                builder1.setBaseOrder(baseOrder--)
                    .setIsHidden(false)
                    .setLineId(_actionLinesCollection->getLines().size())
                    .setLineWidth(_lineWidth * 0.4)
                    .setPoints(turn1)
                    .setEndCapStyle(OsmAnd::VectorLine::EndCapStyle::ARROW)
                    .setFillColor(OsmAnd::ColorARGB((uint32_t)_customTurnArrowsColor));
                builder1.buildAndAddToCollection(_actionLinesCollection);
                OsmAnd::VectorLineBuilder builder2;
                builder2.setBaseOrder(baseOrder--)
                    .setIsHidden(false)
                    .setLineId(_actionLinesCollection->getLines().size())
                    .setLineWidth(_lineWidth * 0.4)
                    .setPoints(turn2)
                    .setEndCapStyle(OsmAnd::VectorLine::EndCapStyle::ARROW)
                    .setFillColor(OsmAnd::ColorARGB((uint32_t)_customTurnArrowsColor));
                builder2.buildAndAddToCollection(_actionLinesCollection);
            }
            [self.mapView addKeyedSymbolsProvider:_actionLinesCollection];
        }];
    }
}

- (CLLocation *) calculateProjection:(double)part lp:(CLLocation *)lp l:(CLLocation *)l
{
    CLLocation *p = [[CLLocation alloc] initWithLatitude:lp.coordinate.latitude + part * (l.coordinate.latitude - lp.coordinate.latitude) longitude:lp.coordinate.longitude + part * (l.coordinate.longitude - lp.coordinate.longitude)];
    return p;
}

- (void) refreshRoute:(OsmAnd::AreaI)area
{
    [self refreshCenterIcon];
    _locationMarker->setPosition(area.center());
    _locationMarker->setIsHidden(false);
    
    BOOL isNight = [OAAppSettings sharedManager].nightMode;
    _prevRouteColoringType = _routeColoringType;
    _prevRouteInfoAttribute = _routeInfoAttribute;
    [self updateRouteColoringType];
    [self updateRouteColors:isNight];
    QVector<OsmAnd::PointI> locs;
    locs << area.bottomLeft();
    locs << OsmAnd::PointI(area.center().x, area.bottomLeft().y);
    locs << OsmAnd::PointI(area.center().x, area.topRight().y);
    locs << area.topRight();
    
    NSMutableArray<NSNumber *> *distances = [NSMutableArray array];
    NSMutableArray<NSNumber *> *angles = [NSMutableArray array];
    QList<OsmAnd::FColorARGB> colors;
    
    [self fillPreviewLineArrays:locs distances:distances angles:angles colors:colors];
    
    [self drawRouteSegment:locs addToExisting:NO colors:colors colorizationScheme:_colorizationScheme];
}

- (void) fillPreviewLineArrays:(QVector<OsmAnd::PointI> &)points distances:(NSMutableArray<NSNumber *> *)distances angles:(NSMutableArray<NSNumber *> *)angles colors:(QList<OsmAnd::FColorARGB> &)colors;
{
    [self fillDistancesAngles:points distances:distances angles:angles];
    
    if (_routeColoringType == OAColoringType.ALTITUDE)
    {
        _colorizationScheme = COLORIZATION_GRADIENT;
        [self fillAltitudeGradientArrays:distances colors:colors];
    }
    else if (_routeColoringType == OAColoringType.SLOPE)
    {
        _colorizationScheme = COLORIZATION_GRADIENT;
        [self fillSlopeGradientArrays:points distances:distances angles:angles colors:colors];
    }
    else if (_routeColoringType.isRouteInfoAttribute)
    {
        _colorizationScheme = COLORIZATION_SOLID;
        BOOL success = [self fillRouteInfoAttributeArrays:points distances:distances angles:angles colors:colors];
        if (!success)
        {
            NSLog(@"Failed to draw attribute coloring for appearance");
            _colorizationScheme = COLORIZATION_NONE;
        }
    }
    else
    {
        _colorizationScheme = COLORIZATION_NONE;
    }
}

- (void) fillDistancesAngles:(QVector<OsmAnd::PointI> &)points distances:(NSMutableArray<NSNumber *> *)distances
                      angles:(NSMutableArray<NSNumber *> *)angles
{
    [angles addObject:@0];
    [distances addObject:@0];
    for (int i = 1; i < points.size(); i++)
    {
        const auto pt = points[i];
        const auto ppt = points[i - 1];
        double angleRad = atan2(fabs(pt.y - ppt.y), fabs(pt.x - ppt.x));
        double angle = (angleRad * 180. / M_PI) + 90.;
        [angles addObject:@(angle)];
        double dist = sqrt(fabs((pt.y - ppt.y) * (pt.y - ppt.y) + (pt.x - ppt.x) * (pt.x - ppt.x)));
        [distances addObject:@(dist)];
    }
}

- (void) fillAltitudeGradientArrays:(NSArray<NSNumber *> *)distances colors:(QList<OsmAnd::FColorARGB> &)colors
{
    NSArray<NSNumber *> *colorsArr = OARouteColorizationHelper.COLORS;
    for (int i = 1; i < distances.count; i++)
    {
        double prevDist = distances[i - 1].doubleValue;
        double currDist = distances[i].doubleValue;
        double nextDist = i + 1 == distances.count ? 0 : distances[i + 1].doubleValue;
        colors << [self getPreviewColor:colorsArr index:(i - 1) coeff:(prevDist + currDist / 2) / (prevDist + currDist)];
        if (i == distances.count - 1)
            colors << [self getPreviewColor:colorsArr index:i coeff:(currDist + nextDist / 2) / (currDist + nextDist)];
    }
}

- (OsmAnd::FColorARGB) getPreviewColor:(NSArray<NSNumber *> *)colors index:(int)index coeff:(double)coeff
{
    if (index == 0)
        return OsmAnd::ColorARGB(colors[0].intValue);
    else if (index > 0 && index < colors.count)
        return [OARouteColorizationHelper getIntermediateColor:colors[index - 1].intValue maxPaletteColor:colors[index].intValue percent:coeff];
    else if (index == colors.count)
        return OsmAnd::ColorARGB(colors[index - 1].intValue);

    return OsmAnd::ColorARGB(0);
}

- (void) fillSlopeGradientArrays:(QVector<OsmAnd::PointI> &)points distances:(NSMutableArray<NSNumber *> *)distances
                          angles:(NSMutableArray<NSNumber *> *)angles colors:(QList<OsmAnd::FColorARGB> &)colors
{
    NSArray<NSNumber *> *palette = OARouteColorizationHelper.SLOPE_COLORS;
    NSArray<NSNumber *> *gradientLengthsRatio = @[@0.145833, @0.130209, @0.291031];
    NSMutableArray<NSNumber *> *cols = [NSMutableArray array];

    [self fillMultiColorLineArrays:palette lengthRatios:gradientLengthsRatio points:points distances:distances angles:angles colors:cols];
    
    for (int i = 0; i < points.size(); i++)
    {
        colors << OsmAnd::ColorARGB(cols[i].intValue);
    }
}

- (BOOL) fillRouteInfoAttributeArrays:(QVector<OsmAnd::PointI> &)points distances:(NSMutableArray<NSNumber *> *)distances
                               angles:(NSMutableArray<NSNumber *> *)angles colors:(QList<OsmAnd::FColorARGB> &)colors
{
    NSArray<NSNumber *> *palette = [self fetchColorsOfRouteInfoAttribute];
    if (palette.count == 0)
        return NO;
    NSInteger ratiosAmount = palette.count - 1;
    double lengthRatio = 1. / palette.count;
    NSMutableArray<NSNumber *> *attributesLengthsRatio = [[NSMutableArray alloc] initWithCapacity:ratiosAmount];
    for (int i = 1 ; i <= ratiosAmount ; i ++)
        [attributesLengthsRatio addObject:@(lengthRatio)];
    
    NSMutableArray<NSNumber *> *cols = [NSMutableArray array];
    [self fillMultiColorLineArrays:palette lengthRatios:attributesLengthsRatio points:points distances:distances angles:angles colors:cols];
    

    for (int i = 0; i < points.size(); i++)
    {
        colors << OsmAnd::ColorARGB(cols[i].intValue);
    }
    return YES;
}

- (void) fillMultiColorLineArrays:(NSArray<NSNumber *> *)palette
                     lengthRatios:(NSArray<NSNumber *> *)lengthRatios
                           points:(QVector<OsmAnd::PointI> &)points
                        distances:(NSMutableArray<NSNumber *> *)distances
                           angles:(NSMutableArray<NSNumber *> *)angles
                           colors:(NSMutableArray<NSNumber *> *)colors
{
    double totalDist = 0;
    for (NSNumber *d in distances)
        totalDist += d.doubleValue;

    BOOL rtl = self.mapView.isDirectionRTL;
    QVector<OsmAnd::PointI> srcPoints(points);
    NSMutableArray<NSNumber *> *colorsArray = [NSMutableArray arrayWithCapacity:points.size() + lengthRatios.count];
    colorsArray[0] = palette[0];
    
    double passedDist = 0;

    for (int i = 0; i < lengthRatios.count; i++)
    {
        double ratio = lengthRatios[i].doubleValue;
        double length = passedDist + totalDist * ratio;
        passedDist += totalDist * ratio;
        int insertIdx;
        for (insertIdx = 1; insertIdx < distances.count && length - distances[insertIdx].doubleValue > 0; insertIdx++)
        {
            length -= distances[insertIdx].doubleValue;
        }

        const auto ppt = srcPoints[insertIdx - 1];
        const auto pt = srcPoints[insertIdx];
        double r = (length / distances[insertIdx].doubleValue);
        OsmAnd::PointI curr(ceil(rtl ? ppt.x - (ppt.x - pt.x) * r : ppt.x + (pt.x - ppt.x) * r), ceil(ppt.y + (pt.y - ppt.y) * r));
        int idx = [self findNextPrevPointIdx:curr points:points next:!rtl];
        points.insert(idx, curr);
        [colorsArray addObject:palette[i + 1]];
    }

    while (colorsArray.count < points.size() + lengthRatios.count)
    {
        [colorsArray addObject:palette.lastObject];
    }

    [distances removeAllObjects];
    [angles removeAllObjects];
    [self fillDistancesAngles:points distances:distances angles:angles];

    for (NSNumber *color in colorsArray)
         [colors addObject:color];
}

- (int) findNextPrevPointIdx:(OsmAnd::PointI)point points:(QVector<OsmAnd::PointI> &)points next:(BOOL)next
{
    for (int i = 0; i < points.size(); i++)
    {
        const auto pt = points[i];
        if ((next && pt.x >= point.x) || (!next && pt.x <= point.x))
        {
            if (pt.y == point.y)
                return i;
            else if (pt.y <= point.y)
                return i;
        }
    }
    return (int) points.size() - 1;
}

- (NSArray<NSNumber *> *) fetchColorsOfRouteInfoAttribute
{
    NSMutableArray<NSNumber *> *res = [NSMutableArray array];
    OsmAndAppInstance app = [OsmAndApp instance];
    
    auto resourceId = QString::fromNSString(app.data.lastMapSource.resourceId);
    auto mapSourceResource = app.resourcesManager->getResource(resourceId);
    
    if (!mapSourceResource)
    {
        resourceId = QString::fromNSString([OAAppData defaultMapSource].resourceId);
        mapSourceResource = app.resourcesManager->getResource(resourceId);
    }
    if (!mapSourceResource)
        return res;
    
    QList<std::shared_ptr<OsmAnd::UnresolvedMapStyle::RuleNode>> subnodes;
    QString attr = QString::fromNSString(_routeInfoAttribute);
    if (mapSourceResource->type == OsmAnd::ResourcesManager::ResourceType::MapStyle)
    {
        const auto& unresolvedMapStyle = std::static_pointer_cast<const OsmAnd::ResourcesManager::MapStyleMetadata>(mapSourceResource->metadata)->mapStyle;
        if (unresolvedMapStyle == nullptr)
            return res;
        
        for (const auto& param : unresolvedMapStyle->attributes)
        {
            QString paramName = param->name;
            if (paramName == attr)
            {
                subnodes = param->rootNode->oneOfConditionalSubnodes;
                break;
            }
        }
    }
    OAMapPresentationEnvironment *env = self.mapViewController.mapPresentationEnv;
    const auto defaultEnv = app.defaultRenderer;
    for (const auto& subnode : subnodes)
    {
        auto pair = env.mapPresentationEnvironment->getRoadRenderingAttributes(attr, subnode->values);
        if (pair.first == QStringLiteral("undefined") && pair.second == 0xFFFFFFFF)
        {
            // Search in the default environment
            pair = defaultEnv->getRoadRenderingAttributes(attr, subnode->values);
        }
        if (pair.first != QStringLiteral("undefined"))
            [res addObject:@(pair.second)];
    }
    return res;
}

@end
