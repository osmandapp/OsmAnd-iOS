//
//  OARouteLayer.m
//  OsmAnd
//
//  Created by Alexey Kulish on 11/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OARouteLayer.h"
#import "OARootViewController.h"
#import "OAMapRendererView.h"
#import "OARoutingHelper.h"
#import "OARouteCalculationResult.h"
#import "OANativeUtilities.h"
#import "OARouteStatisticsHelper.h"
#import "OATransportRoutingHelper.h"
#import "OATransportStopType.h"
#import "OARouteDirectionInfo.h"
#import "OAAutoObserverProxy.h"
#import "OAColors.h"
#import "OAPreviewRouteLineInfo.h"
#import "OAGPXAppearanceCollection.h"
#import "OAGPXUIHelper.h"
#import "OARouteColorize.h"
#import "OAGPXDocument.h"
#import "OAMapLayers.h"
#import "OAMapUtils.h"
#import "OAColorPaletteHelper.h"
#import "OsmAnd_Maps-Swift.h"

#include <OsmAndCore/Map/VectorLineBuilder.h>
#include <OsmAndCore/Map/MapMarker.h>
#include <OsmAndCore/Map/MapMarkerBuilder.h>
#include <OsmAndCore/Map/MapMarkersCollection.h>
#include <OsmAndCore/SkiaUtilities.h>
#include <OsmAndCore/SingleSkImage.h>
#include <SkCGUtils.h>

#define kTurnArrowsColoringByAttr 0xffffffff
#define kOutlineId 1001

@implementation OARouteLayer
{
    OARoutingHelper *_routingHelper;
    OATransportRoutingHelper *_transportHelper;

    std::shared_ptr<OsmAnd::VectorLinesCollection> _collection;
    
    std::shared_ptr<OsmAnd::MapMarkersCollection> _transportRouteMarkers;
    
    sk_sp<SkImage> _transportTransferIcon;
    sk_sp<SkImage> _transportShieldIcon;
    
    std::shared_ptr<OsmAnd::VectorLinesCollection> _actionLinesCollection;
    OAAutoObserverProxy* _mapZoomObserver;
    
    NSDictionary<NSString *, NSNumber *> *_routeAttributes;
    NSCache<NSString *, NSNumber *> *_сoloringTypeAvailabilityCache;

    BOOL _initDone;

    CGFloat _lineWidth;
    OAPreviewRouteLineInfo *_previewRouteLineInfo;
    NSInteger _routeLineColor;
    NSInteger _customTurnArrowsColor;
    OAColoringType *_routeColoringType;
    NSString *_routeInfoAttribute;
    NSString *_routeGradientPalette;
    OAGPXAppearanceCollection *_appearanceCollection;

    OARouteCalculationResult *_route;
    int _colorizationScheme;
    QList<OsmAnd::FColorARGB> _colors;
    OAColoringType *_prevRouteColoringType;
    NSString *_prevRouteInfoAttribute;
    NSCache<NSString *, NSNumber *> *_cachedRouteLineWidth;
    int _currentAnimatedRoute;
    CLLocation *_lastProj;

    int64_t _linesPriority;
}

- (NSString *) layerId
{
    return kRouteLayerId;
}

- (void)dealloc
{
    [_mapZoomObserver detach];
}

- (void) initLayer
{
    [super initLayer];

    _routeGradientPalette = @"default";
    _routingHelper = [OARoutingHelper sharedInstance];
    _transportHelper = [OATransportRoutingHelper sharedInstance];
    
    _linesPriority = std::numeric_limits<int64_t>::max();
    _collection = std::make_shared<OsmAnd::VectorLinesCollection>();
    _collection->setPriority(_linesPriority);
    _actionLinesCollection = std::make_shared<OsmAnd::VectorLinesCollection>();
    _actionLinesCollection->setPriority(_linesPriority);
    _transportRouteMarkers = std::make_shared<OsmAnd::MapMarkersCollection>();
    _transportRouteMarkers->setPriority(_linesPriority);

    _transportTransferIcon = [OANativeUtilities skImageFromPngResource:@"map_public_transport_transfer"];
    _transportShieldIcon = [OANativeUtilities skImageFromPngResource:@"map_public_transport_stop_shield"];
    
    _routeAttributes = nil;
    _сoloringTypeAvailabilityCache = [[NSCache alloc] init];
    
    _initDone = YES;
    
    [self.mapView addKeyedSymbolsProvider:_collection];
    [self.mapView addKeyedSymbolsProvider:_transportRouteMarkers];

    _lineWidth = kDefaultWidthMultiplier * kWidthCorrectionValue;
    _routeColoringType = OAColoringType.DEFAULT;
    _colorizationScheme = COLORIZATION_NONE;
    _cachedRouteLineWidth = [[NSCache alloc] init];

    _mapZoomObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                 withHandler:@selector(onMapZoomChanged:withKey:andValue:)
                                                  andObserve:self.mapViewController.zoomObservable];
}

- (void) resetLayer
{
    [super resetLayer];
    
    [self.mapView removeKeyedSymbolsProvider:_collection];
    [self.mapView removeKeyedSymbolsProvider:_actionLinesCollection];
    [self.mapView removeKeyedSymbolsProvider:_transportRouteMarkers];
    
    _collection = std::make_shared<OsmAnd::VectorLinesCollection>();
    _collection->setPriority(_linesPriority);
    _actionLinesCollection = std::make_shared<OsmAnd::VectorLinesCollection>();
    _actionLinesCollection->setPriority(_linesPriority);
    _transportRouteMarkers = std::make_shared<OsmAnd::MapMarkersCollection>();
    _transportRouteMarkers->setPriority(_linesPriority);

    _routeAttributes = nil;
    _route = nil;
}

- (BOOL) updateLayer
{
    [super updateLayer];

    dispatch_async(dispatch_get_main_queue(), ^{
        _appearanceCollection = [OAGPXAppearanceCollection sharedInstance];
    });

    [self refreshRoute];
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

- (void)drawRouteMarkers:(const std::shared_ptr<TransportRouteResultSegment> &)routeSegment
{
    OsmAnd::MapMarkerBuilder transportMarkerBuilder;
    transportMarkerBuilder.setIsAccuracyCircleSupported(false);
    transportMarkerBuilder.setBaseOrder(self.pointsOrder - 15);
    transportMarkerBuilder.setIsHidden(false);
    transportMarkerBuilder.setPinIconHorisontalAlignment(OsmAnd::MapMarker::CenterHorizontal);
    transportMarkerBuilder.setPinIconVerticalAlignment(OsmAnd::MapMarker::CenterVertical);
    OsmAnd::LatLon startLatLon(routeSegment->getStart().lat, routeSegment->getStart().lon);
    transportMarkerBuilder.setPinIcon(OsmAnd::SingleSkImage(_transportTransferIcon));
    
    auto marker = transportMarkerBuilder.buildAndAddToCollection(_transportRouteMarkers);
    marker->setPosition(OsmAnd::Utilities::convertLatLonTo31(startLatLon));
    
    OATransportStopType *type = [OATransportStopType findType:[NSString stringWithUTF8String:routeSegment->route->type.c_str()]];
    NSString *resId = type != nil ? type.resId : [OATransportStopType getResId:TST_BUS];
    UIImage *origIcon = [UIImage mapSvgImageNamed:resId];
    sk_sp<SkImage> stopImg = nullptr;
    if (origIcon)
    {
        UIImage *tintedIcon = [OAUtilities tintImageWithColor:origIcon color:[UIColor blackColor]];
        stopImg = SkMakeImageFromCGImage(tintedIcon.CGImage);
    }
    sk_sp<SkImage> icon = nullptr;
    if (stopImg)
    {
        const QList<sk_sp<const SkImage>> composition({_transportShieldIcon, OsmAnd::SkiaUtilities::scaleImage(stopImg, 0.5, 0.5)});
        icon = OsmAnd::SkiaUtilities::mergeImages(composition);
    }
    
    transportMarkerBuilder.setPinIcon(OsmAnd::SingleSkImage(icon ? icon : _transportShieldIcon));
    for (int i = routeSegment->start + 1; i < routeSegment->end; i++)
    {
        const auto& stop = routeSegment->getStop(i);
        OsmAnd::LatLon latLon(stop.lat, stop.lon);
        const auto& marker = transportMarkerBuilder.buildAndAddToCollection(_transportRouteMarkers);
        marker->setPosition(OsmAnd::Utilities::convertLatLonTo31(latLon));
    }
    transportMarkerBuilder.setPinIcon(OsmAnd::SingleSkImage(_transportTransferIcon));
    OsmAnd::LatLon endLatLon(routeSegment->getEnd().lat, routeSegment->getEnd().lon);
    marker = transportMarkerBuilder.buildAndAddToCollection(_transportRouteMarkers);
    marker->setPosition(OsmAnd::Utilities::convertLatLonTo31(endLatLon));
}

- (void) drawTransportSegment:(SHARED_PTR<TransportRouteResultSegment>)routeSegment sync:(BOOL)sync
{
    void (^drawTransportSegmentBlock)(void) = ^{
        [self drawRouteMarkers:routeSegment];
            
        OATransportStopType *type = [OATransportStopType findType:[NSString stringWithUTF8String:routeSegment->route->type.c_str()]];
        NSString *str = [NSString stringWithUTF8String:routeSegment->route->color.c_str()];
        str = str.length == 0 ? type.renderAttr : str;
        OsmAnd::ColorARGB colorARGB;
        UIColor *color = [self.mapViewController getTransportRouteColor:OAAppSettings.sharedManager.nightMode renderAttrName:str];
        CGFloat red, green, blue, alpha;
        if (str.length > 0 && color)
        {
            [color getRed:&red green:&green blue:&blue alpha:&alpha];
        }
        else
        {
            color = UIColorFromARGB(color_nav_route_default_argb);
            [color getRed:&red green:&green blue:&blue alpha:&alpha];
        }
        colorARGB = OsmAnd::ColorARGB(255 * alpha, 255 * red, 255 * green, 255 * blue);
        
        int baseOrder = self.baseOrder;
        vector<std::shared_ptr<Way>> list;
        routeSegment->getGeometry(list);
        for (const auto& way : list)
        {
            QVector<OsmAnd::PointI> points;
            for (const auto& node : way->nodes)
            {
                points.push_back(OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(node.lat, node.lon)));
            }
            if (points.size() > 1)
            {
                OsmAnd::VectorLineBuilder builder;
                builder.setBaseOrder(baseOrder--)
                .setIsHidden(way->nodes.size() == 0)
                .setLineId(1)
                .setLineWidth(50.)
                .setPoints(points)
                .setFillColor(colorARGB);
                builder.buildAndAddToCollection(_collection);
            }
        }
    };
    if (sync)
        [self.mapViewController runWithRenderSync:^{
            drawTransportSegmentBlock();
        }];
    else
        drawTransportSegmentBlock();
}

- (void) drawRouteSegment:(const QVector<OsmAnd::PointI> &)points addToExisting:(BOOL)addToExisting sync:(BOOL)sync
{
    [self drawRouteSegment:points
             addToExisting:addToExisting
                    colors:{}
        colorizationScheme:COLORIZATION_NONE
                      sync:sync
    ];
}

- (void) drawRouteSegment:(const QVector<OsmAnd::PointI> &)points addToExisting:(BOOL)addToExisting colors:(const QList<OsmAnd::FColorARGB> &)colors colorizationScheme:(int)colorizationScheme sync:(BOOL)sync
{
    void (^drawRouteSegment)(void) = ^{
        _lineWidth = [self getLineWidth];
        const auto& lines = _collection->getLines();
        if (lines.empty() || addToExisting)
        {
            BOOL isFirstLine = lines.empty() && !addToExisting;
            if (isFirstLine)
            {
                [self.mapView removeKeyedSymbolsProvider:_collection];
                _collection = std::make_shared<OsmAnd::VectorLinesCollection>();
                _collection->setPriority(_linesPriority);
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
                [self setVectorLineProvider:_collection sync:sync];
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
        [self buildActionArrows];
    };
    if (sync)
        [self.mapViewController runWithRenderSync:^{
            drawRouteSegment();
        }];
    else
        drawRouteSegment();
}

- (NSNumber *)getParamFromAttr:(NSString *)param
{
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
        _routeGradientPalette = _previewRouteLineInfo.gradientPalette;
    }
    else
    {
        OAApplicationMode *mode = [_routingHelper getAppMode];
        OAAppSettings *settings = [OAAppSettings sharedManager];
        _routeColoringType = [settings.routeColoringType get:mode];
        _routeInfoAttribute = [settings.routeInfoAttribute get:mode];
        _routeGradientPalette = [settings.routeGradientPalette get:mode];
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
        NSNumber *widthNumber = [_cachedRouteLineWidth objectForKey:widthKey];
        if (widthNumber)
        {
            width = widthNumber.floatValue;
        }
        else
        {
            width = [self getWidthByKey:widthKey];
            [_cachedRouteLineWidth setObject:@(width) forKey:widthKey];
        }
    }
    else
    {
        width = [self getParamFromAttr:@"strokeWidth"].floatValue;
    }

    return width * VECTOR_LINE_SCALE_COEF;
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

- (OsmAnd::AreaI) calculateBounds:(NSArray<CLLocation *> *)pts
{
    double left = DBL_MAX, top = DBL_MIN, right = DBL_MIN, bottom = DBL_MAX;
    for (NSInteger i = 0; i < pts.count; i++)
    {
        CLLocation *pt = pts[i];
        right = MAX(right, pt.coordinate.longitude);
        left = MIN(left, pt.coordinate.longitude);
        top = MAX(top, pt.coordinate.latitude);
        bottom = MIN(bottom, pt.coordinate.latitude);
    }
    OsmAnd::PointI topLeft = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(top, left));
    OsmAnd::PointI bottomRight = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(bottom, right));
    return OsmAnd::AreaI(topLeft, bottomRight);
}

- (void) onMapZoomChanged:(id)observable withKey:(id)key andValue:(id)value
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self buildActionArrows];
    });
}

- (void) buildActionArrows
{
    if ([self shouldShowTurnArrows])
    {
        @synchronized (self) 
        {
            const auto zoom = self.mapView.zoomLevel;
            if (zoom <= OsmAnd::ZoomLevel14 || _collection->isEmpty()) {
                if (!_actionLinesCollection->isEmpty())
                {
                    [self.mapView removeKeyedSymbolsProvider:_actionLinesCollection];
                    _actionLinesCollection->removeAllLines();
                }
                return;
            }
            else
            {
                int baseOrder = self.baseOrder - 1000;
                NSArray<NSArray<CLLocation *> *> *actionPoints = [self calculateActionPoints];
                if (actionPoints.count > 0)
                {
                    auto actionLines = _actionLinesCollection->getLines();
                    int lineIdx = 0;
                    int initialLinesCount = actionLines.count();
                    for (NSArray<CLLocation *> *line in actionPoints)
                    {
                        QVector<OsmAnd::PointI> points;
                        for (CLLocation *point in line)
                        {
                            points.push_back(OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(point.coordinate.latitude, point.coordinate.longitude)));
                        }
                        if (lineIdx < initialLinesCount)
                        {
                            auto line = actionLines[lineIdx];
                            line->setPoints(points);
                            line->setIsHidden(false);
                            lineIdx++;
                        }
                        else
                        {
                            OsmAnd::VectorLineBuilder builder;
                            builder.setBaseOrder(baseOrder--)
                                    .setIsHidden(false)
                                    .setLineId(_actionLinesCollection->getLinesCount())
                                    .setLineWidth(_lineWidth * 0.4)
                                    .setPoints(points)
                                    .setEndCapStyle(OsmAnd::VectorLine::EndCapStyle::ARROW)
                                    .setFillColor(OsmAnd::ColorARGB(_customTurnArrowsColor));
                            builder.buildAndAddToCollection(_actionLinesCollection);
                        }
                    }
                    while (lineIdx < initialLinesCount)
                    {
                        actionLines[lineIdx]->setIsHidden(true);
                        lineIdx++;
                    }
                }
            }
            [self.mapView addKeyedSymbolsProvider:_actionLinesCollection];
        }
    }
}

- (NSArray<NSArray<CLLocation *> *> *) calculateActionPoints
{
    NSArray<OARouteDirectionInfo *> *directions = _routingHelper.getRouteDirections;
    NSInteger dirIdx = 0;
    NSArray<CLLocation *> *routeNodes = _routingHelper.getRoute.getRouteLocations;
    CLLocation *lastProjection = _routingHelper.getLastProjection;
    int cd = _routingHelper.getRoute.currentRoute;
    OsmAnd::ZoomLevel zoom = self.mapView.zoomLevel;
    
    OARouteDirectionInfo *nf = nil;
    double DISTANCE_ACTION = 35;
    if(zoom >= OsmAnd::ZoomLevel17)
        DISTANCE_ACTION = 15;
    else if (zoom == OsmAnd::ZoomLevel15)
        DISTANCE_ACTION = 70;
    else if (zoom < OsmAnd::ZoomLevel15)
        DISTANCE_ACTION = 110;
    
    double actionDist = 0;
    CLLocation *previousAction = nil;
    NSMutableArray<NSArray<CLLocation *> *> *res = [NSMutableArray array];
    NSMutableArray<CLLocation *> *actionPoints = [NSMutableArray array];
    int prevFinishPoint = -1;
    for (int routePoint = 0; routePoint < routeNodes.count; routePoint++)
    {
        CLLocation *loc = routeNodes[routePoint];
        if(nf != nil)
        {
            int pnt = nf.routeEndPointOffset == 0 ? nf.routePointOffset : nf.routeEndPointOffset;
            if (pnt < routePoint + cd)
                nf = nil;
        }
        while (nf == nil && dirIdx < directions.count)
        {
            nf = directions[dirIdx++];
            int pnt = nf.routeEndPointOffset == 0 ? nf.routePointOffset : nf.routeEndPointOffset;
            if (pnt < routePoint + cd)
                nf = nil;
        }
        BOOL action = nf != nil && (nf.routePointOffset == routePoint + cd ||
                                        (nf.routePointOffset <= routePoint + cd && routePoint + cd  <= nf.routeEndPointOffset));
        if(!action && previousAction == nil)
        {
            // no need to check
            continue;
        }
        if (!action)
        {
            // previousAction != null
            double dist = [loc distanceFromLocation:previousAction];
            actionDist += dist;
            if (actionDist >= DISTANCE_ACTION)
            {
                [actionPoints addObject:[self calculateProjection:1 - (actionDist - DISTANCE_ACTION) / dist lp:previousAction l:loc]];
                [res addObject:actionPoints];
                actionPoints = [NSMutableArray array];
                prevFinishPoint = routePoint;
                previousAction = nil;
                actionDist = 0;
            }
            else
            {
                [actionPoints addObject:loc];
                previousAction = loc;
            }
        }
        else
        {
            // action point
            if (previousAction == nil)
            {
                [self addPreviousToActionPoints:actionPoints
                                 lastProjection:lastProjection
                                     routeNodes:routeNodes
                                DISTANCE_ACTION:DISTANCE_ACTION
                                prevFinishPoint:prevFinishPoint
                                     routePoint:routePoint
                                            loc:loc];
            }
            [actionPoints addObject:loc];
            previousAction = loc;
            prevFinishPoint = -1;
            actionDist = 0;
        }
    }
    if(previousAction != nil)
    {
        [res addObject:actionPoints];
    }
    return res;
}

- (void) addPreviousToActionPoints:(NSMutableArray<CLLocation *> *)actionPoints
                    lastProjection:(CLLocation *)lastProjection
                        routeNodes:(NSArray<CLLocation *> *)routeNodes
                   DISTANCE_ACTION:(double)DISTANCE_ACTION
                   prevFinishPoint:(int)prevFinishPoint
                        routePoint:(int)routePoint
                               loc:(CLLocation *)loc
{
    // put some points in front
    NSInteger ind = actionPoints.count;
    CLLocation *lprevious = loc;
    double dist = 0;
    for (NSInteger k = routePoint - 1; k >= -1; k--)
    {
        CLLocation *l = k == -1 ? lastProjection : routeNodes[k];
        if (l == nil)
            continue;

        double locDist = [lprevious distanceFromLocation:l];
        dist += locDist;
        if (dist >= DISTANCE_ACTION)
        {
            if (locDist > 1)
            {
                [actionPoints insertObject:[self calculateProjection:(1 - (dist - DISTANCE_ACTION) / locDist) lp:lprevious l:l] atIndex:ind];
            }
            break;
        }
        else
        {
            [actionPoints insertObject:l atIndex:ind];
            lprevious = l;
        }
        if (prevFinishPoint == k)
        {
            if (ind >= 2)
            {
                [actionPoints removeObjectAtIndex:ind - 2];
                [actionPoints removeObjectAtIndex:ind - 2];
            }
            break;
        }
    }
}

- (CLLocation *) calculateProjection:(double)part lp:(CLLocation *)lp l:(CLLocation *)l
{
    CLLocation *p = [[CLLocation alloc] initWithLatitude:lp.coordinate.latitude + part * (l.coordinate.latitude - lp.coordinate.latitude) longitude:lp.coordinate.longitude + part * (l.coordinate.longitude - lp.coordinate.longitude)];
    return p;
}

- (void) refreshRoute
{
    [self refreshRouteWithSync:YES refreshColors:NO];
}

- (void) refreshRouteWithSync:(BOOL)sync refreshColors:(BOOL)refreshColors
{
    if (!_routeAttributes)
        _routeAttributes = [self.mapViewController getLineRenderingAttributes:@"route"];
    if (!_routeAttributes)
        return;

    BOOL isNight = [OAAppSettings sharedManager].nightMode;
    OARouteCalculationResult *route = [_routingHelper getRoute];
    if ([_routingHelper isPublicTransportMode])
    {
        _prevRouteColoringType = _routeColoringType;
        _prevRouteInfoAttribute = _routeInfoAttribute;
        [self updateRouteColoringType];
        [self updateRouteColors:isNight];

        NSInteger currentRoute = _transportHelper.currentRoute;
        const auto routes = [_transportHelper getRoutes];
        const auto route = currentRoute != -1 && routes.size() > currentRoute ? routes[currentRoute] : nullptr;
        _route = nil;
        _colors.clear();
        if (route != nullptr)
        {
            CLLocation *start = _transportHelper.startLocation;
            CLLocation *end = _transportHelper.endLocation;
            
            CLLocation *p = start;
            SHARED_PTR<TransportRouteResultSegment> prev = nullptr;
            
            [self.mapView removeKeyedSymbolsProvider:_collection];
            _collection = std::make_shared<OsmAnd::VectorLinesCollection>();
            _collection->setPriority(_linesPriority);

            [self.mapView removeKeyedSymbolsProvider:_transportRouteMarkers];
            _transportRouteMarkers = std::make_shared<OsmAnd::MapMarkersCollection>();
            _transportRouteMarkers->setPriority(_linesPriority);
            for (const auto &seg : route->segments)
            {
                [self drawTransportSegment:seg sync:sync];
                CLLocation *floc = [[CLLocation alloc] initWithLatitude:seg->getStart().lat longitude:seg->getStart().lon];
                [self addWalkRoute:prev s2:seg start:p end:floc sync:sync];
                p = [[CLLocation alloc] initWithLatitude:seg->getEnd().lat longitude:seg->getEnd().lon];
                prev = seg;
            }
            [self addWalkRoute:prev s2:nullptr start:p end:end sync:sync];
            
            [self.mapView addKeyedSymbolsProvider:_collection];
            [self.mapView addKeyedSymbolsProvider:_transportRouteMarkers];
        }
    }
    else if ([_routingHelper getFinalLocation] && route && [route isCalculated])
    {
        _prevRouteColoringType = _routeColoringType;
        _prevRouteInfoAttribute = _routeInfoAttribute;
        [self updateRouteColoringType];
        [self updateRouteColors:isNight];

        int currentRoute = route.currentRoute;
        if (currentRoute < 0)
            currentRoute = 0;

        OAColoringType *routeColoringType = _routeColoringType;
        if (![self isColoringAvailable:route routeColoringType:routeColoringType attributeName:_routeInfoAttribute])
            routeColoringType = OAColoringType.DEFAULT;

        NSArray<CLLocation *> *locations = [route getImmutableAllLocations];
        BOOL routeUpdated = NO;
        if ([routeColoringType isGradient]
                && (_route != route
                    || _prevRouteColoringType != routeColoringType
                    || _colorizationScheme != COLORIZATION_GRADIENT
                    || refreshColors))
        {
            OAGPXDocument *gpx = [OAGPXUIHelper makeGpxFromRoute:route];
            ColorPalette *colorPalette = [[OAColorPaletteHelper sharedInstance] getGradientColorPaletteSync:[routeColoringType toColorizationType] gradientPaletteName:_routeGradientPalette refresh:refreshColors];
            OARouteColorize *colorizationHelper =
                    [[OARouteColorize alloc] initWithGpxFile:gpx
                                                              analysis:[gpx getAnalysis:0]
                                                                  type:[[routeColoringType toGradientScaleType] toColorizationType]
                                                               palette:colorPalette
                                                       maxProfileSpeed:0
                    ];
            _colorizationScheme = COLORIZATION_GRADIENT;
            _colors.clear();
            if (colorizationHelper)
            {
                for (OARouteColorizationPoint *colorizationPoint in [colorizationHelper getResult])
                {
                    _colors.append(OsmAnd::ColorARGB(colorizationPoint.color));
                }
            }
            _route = route;
            routeUpdated = YES;
        }
        else if ([routeColoringType isRouteInfoAttribute]
                && (_route != route || ![_prevRouteInfoAttribute isEqualToString:_routeInfoAttribute] || _colorizationScheme != COLORIZATION_SOLID))
        {
            _colorizationScheme = COLORIZATION_SOLID;
            _colors.clear();
            auto segs = route.getOriginalRoute;
            [self calculateSegmentsColor:_colors
                                attrName:_routeInfoAttribute
                           segmentResult:segs
                               locations:locations];
            _route = route;
            routeUpdated = YES;
        }
        else if ([routeColoringType isSolidSingleColor]
                && (_route != route || _colorizationScheme != COLORIZATION_NONE || _colors.count() > 0))
        {
            _colorizationScheme = COLORIZATION_NONE;
            _colors.clear();
            _route = route;
            routeUpdated = YES;
        }

        QVector<OsmAnd::PointI> points;
        //CLLocation* lastProj = [_routingHelper getLastProjection];

        if (routeUpdated)
            _currentAnimatedRoute = 0;

        BOOL initState = _currentAnimatedRoute == 0 && !_routingHelper.isFollowingMode;

        CLLocation *lastProj = nil;
        CLLocation *lastFixedLocation = [_routingHelper getLastFixedLocation];
        CLLocationCoordinate2D coord = self.mapViewController.mapLayers.myPositionLayer.getActiveMarkerLocation;
        if (!initState && CLLocationCoordinate2DIsValid(coord))
        {
            CLLocation *currentLocation = [[CLLocation alloc] initWithCoordinate:coord altitude:lastFixedLocation.altitude horizontalAccuracy:lastFixedLocation.horizontalAccuracy verticalAccuracy:lastFixedLocation.verticalAccuracy course:lastFixedLocation.course speed:lastFixedLocation.speed timestamp:lastFixedLocation.timestamp];

            double posTolerance = [OARoutingHelper getPosTolerance:currentLocation.horizontalAccuracy];
            currentRoute = MIN(currentRoute, [_routingHelper calculateCurrentRoute:currentLocation posTolerance:posTolerance routeNodes:locations currentRoute:_currentAnimatedRoute updateAndNotify:NO]);
            lastProj = currentRoute > 0
                ? [OAMapUtils getProjection:currentLocation fromLocation:locations[currentRoute - 1] toLocation:locations[currentRoute]]
                : nil;
        }

        BOOL lastProjsEqual = _lastProj == lastProj || (_lastProj != nil && lastProj != nil &&
            [OAUtilities isCoordEqual:_lastProj.coordinate.latitude srcLon:_lastProj.coordinate.longitude destLat:lastProj.coordinate.latitude destLon:lastProj.coordinate.longitude]);

        if (!routeUpdated && _currentAnimatedRoute == currentRoute && lastProjsEqual)
            return;

        _currentAnimatedRoute = currentRoute;
        _lastProj = lastProj;
        if (lastProj)
        {
            points.push_back(OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(lastProj.coordinate.latitude, lastProj.coordinate.longitude)));
            if (_colorizationScheme != COLORIZATION_NONE && !_colors.isEmpty())
                _colors.push_front(_colors.front());
        }
        
        for (int i = currentRoute; i < locations.count; i++)
        {
            CLLocation *location = locations[i];
            points.push_back(OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(location.coordinate.latitude, location.coordinate.longitude)));
        }
        if (_colorizationScheme == COLORIZATION_NONE)
        {
            if (!points.isEmpty())
                [self drawRouteSegment:points addToExisting:NO sync:sync];
            else
                [self.mapViewController runWithRenderSync:^{ [self resetLayer]; }];
        }
        else
        {
            int segStartIndex = _colors.count() - points.count();
            QList<OsmAnd::FColorARGB> segmentColors;
            if (points.size() > 1 && !_colors.isEmpty() && segStartIndex < _colors.size() && segStartIndex + points.size() - 1 < _colors.size())
                segmentColors = _colors.mid(segStartIndex, points.size());

            if (!segmentColors.isEmpty())
            {
                [self drawRouteSegment:points
                         addToExisting:NO
                                colors:segmentColors
                    colorizationScheme:_colorizationScheme
                                  sync:sync];
                segmentColors.clear();
            }
        }
        points.clear();
    }
    else
    {
        if (sync)
            [self.mapViewController runWithRenderSync:^{
                [self resetLayer];
            }];
        else
            [self resetLayer];
    }
}

- (BOOL) isColoringAvailable:(OARouteCalculationResult *)route routeColoringType:(OAColoringType *)routeColoringType attributeName:(NSString *)attributeName
{
        if (_route != route)
            [_сoloringTypeAvailabilityCache removeAllObjects];

        NSString *key = [routeColoringType getName:attributeName];
        if (!key)
            key = @"_nil_";

        NSNumber *available = [_сoloringTypeAvailabilityCache objectForKey:key];
        if (!available)
        {
            BOOL drawing = [routeColoringType isAvailableForDrawingRoute:route attributeName:attributeName];
            BOOL subscription = [routeColoringType isAvailableInSubscription];
            available = @(drawing && subscription);
            [_сoloringTypeAvailabilityCache setObject:available forKey:key];
        }
        return available.boolValue;
    }

- (void) addWalkRoute:(SHARED_PTR<TransportRouteResultSegment>) s1 s2:(SHARED_PTR<TransportRouteResultSegment>)s2 start:(CLLocation *)start end:(CLLocation *)end sync:(BOOL)sync
{
    OARouteCalculationResult *res = [_transportHelper.walkingRouteSegments objectForKey:@[[[OATransportRouteResultSegment alloc] initWithSegment:s1], [[OATransportRouteResultSegment alloc] initWithSegment:s2]]];
    NSArray<CLLocation *> *locations = [res getRouteLocations];
    if (res && locations.count > 0)
    {
        QVector<OsmAnd::PointI> points;
        for (NSInteger i = 0; i < locations.count; i++)
        {
            CLLocation *p = locations[i];
            points.push_back(OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(p.coordinate.latitude, p.coordinate.longitude)));
        }
        [self drawRouteSegment:points addToExisting:YES sync:sync];
    }
}

- (void) onMapFrameAnimatorsUpdated
{
    if (_routingHelper && ![_routingHelper isPublicTransportMode])
        [self refreshRouteWithSync:NO refreshColors:NO];
}

@end
