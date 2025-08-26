//
//  OARouteLayer.m
//  OsmAnd
//
//  Created by Alexey Kulish on 11/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OARouteLayer.h"
#import "OARootViewController.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OARoutingHelper.h"
#import "OARouteCalculationResult.h"
#import "OANativeUtilities.h"
#import "OARouteStatisticsHelper.h"
#import "OATransportRoutingHelper.h"
#import "OATransportStopType.h"
#import "OATransportStop.h"
#import "OARouteDirectionInfo.h"
#import "OAAutoObserverProxy.h"
#import "OAColors.h"
#import "OAPreviewRouteLineInfo.h"
#import "OAGPXAppearanceCollection.h"
#import "OAGPXUIHelper.h"
#import "OARouteColorize.h"
#import "OARouteColorize+cpp.h"
#import "OAMapLayers.h"
#import "OAMapUtils.h"
#import "OAApplicationMode.h"
#import "OAColoringType.h"
#import "OAObservable.h"
#import "OAConcurrentCollections.h"
#import "OAPointDescription.h"
#import "CLLocation+Extension.h"
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

struct DrawPathData
{
    QVector<int> indexes;
    QVector<OsmAnd::PointI> points;
    QVector<double> distances;
    int lineId;
};

@interface OARouteLayer()

@property (nonatomic) CLLocation *lastProj;

@end

@implementation OARouteLayer
{
    OARoutingHelper *_routingHelper;
    OATransportRoutingHelper *_transportHelper;

    std::shared_ptr<OsmAnd::VectorLinesCollection> _collection;
    std::shared_ptr<OsmAnd::MapMarkersCollection> _transportRouteMarkers;
    
    std::shared_ptr<OsmAnd::MapMarkersCollection> _projectionPointCollection;
    std::shared_ptr<OsmAnd::MapMarker> _projectedPointMarker;
    
    sk_sp<SkImage> _transportTransferIcon;
    sk_sp<SkImage> _transportShieldIcon;
    
    std::shared_ptr<OsmAnd::VectorLinesCollection> _actionLinesCollection;
    OAAutoObserverProxy *_mapZoomObserver;
    OAAutoObserverProxy *_updateGpxTracksOnMapObserver;
    
    NSDictionary<NSString *, NSNumber *> *_routeAttributes;
    NSDictionary<NSString *, NSNumber *> *_walkAttributes;
    NSDictionary<NSString *, NSNumber *> *_walkPTAttributes;
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
    OAConcurrentDictionary<NSString *, NSString *> *_updatedColorPaletteFiles;
    
    QVector<DrawPathData> _pathsDataCache;
    int _lastCurrentRoute;
    int64_t _linesPriority;
}

- (NSString *) layerId
{
    return kRouteLayerId;
}

- (void)dealloc
{
    if (_mapZoomObserver)
    {
        [_mapZoomObserver detach];
        _mapZoomObserver = nil;
    }
    if (_updateGpxTracksOnMapObserver)
    {
        [_updateGpxTracksOnMapObserver detach];
        _updateGpxTracksOnMapObserver = nil;
    }
}

- (void) initLayer
{
    [super initLayer];

    _routeGradientPalette = PaletteGradientColor.defaultName;
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
    _walkAttributes = nil;
    _walkPTAttributes = nil;
    _сoloringTypeAvailabilityCache = [[NSCache alloc] init];
    
    _initDone = YES;
    [self.mapView addKeyedSymbolsProvider:_collection];
    [self.mapView addKeyedSymbolsProvider:_transportRouteMarkers];

    _lineWidth = [self getDefaultLineWidth];
    _routeColoringType = OAColoringType.DEFAULT;
    _colorizationScheme = COLORIZATION_NONE;
    _cachedRouteLineWidth = [[NSCache alloc] init];
    _updatedColorPaletteFiles = [[OAConcurrentDictionary alloc] init];

    _mapZoomObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                 withHandler:@selector(onMapZoomChanged:withKey:andValue:)
                                                  andObserve:self.mapViewController.zoomObservable];
    _updateGpxTracksOnMapObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                              withHandler:@selector(refreshRoute)
                                                               andObserve:[OsmAndApp instance].updateGpxTracksOnMapObservable];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onColorPalettesFilesUpdated:)
                                                 name:ColorPaletteHelper.colorPalettesUpdatedNotification
                                               object:nil];
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
    
    [self removeProjectedPointCollection];

    _routeAttributes = nil;
    _walkAttributes = nil;
    _walkPTAttributes = nil;
    _route = nil;
    _pathsDataCache = QVector<DrawPathData>();
}

- (BOOL) updateLayer
{
    if (![super updateLayer])
        return NO;

    dispatch_async(dispatch_get_main_queue(), ^{
        _appearanceCollection = [OAGPXAppearanceCollection sharedInstance];
    });

    [self refreshRoute];
    return YES;
}

- (void)onColorPalettesFilesUpdated:(NSNotification *)notification
{
    if (![notification.object isKindOfClass:NSDictionary.class])
        return;

    NSDictionary<NSString *, NSString *> *colorPaletteFiles = (NSDictionary *) notification.object;
    if (!colorPaletteFiles)
        return;
    BOOL refresh = NO;
    for (NSString *colorPaletteFile in colorPaletteFiles)
    {
        if ([colorPaletteFile hasPrefix:ColorPaletteHelper.routePrefix])
        {
            [_updatedColorPaletteFiles setObjectSync:colorPaletteFiles[colorPaletteFile] forKey:colorPaletteFile];
            refresh = YES;
        }
    }
    if (refresh)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self refreshRoute];
        });
    }
}

- (NSInteger)getCustomRouteWidthMin
{
    return 1;
}

- (NSInteger)getCustomRouteWidthMax
{
    return 36;
}

- (CGFloat)getDefaultLineWidth
{
    return kDefaultWidthMultiplier * kWidthCorrectionValue;
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
                .setLineId(_collection->getLinesCount())
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

- (int) drawRouteSegment:(const QVector<OsmAnd::PointI> &)points
                     walk:(BOOL)walk
                     sync:(BOOL)sync
{
    return [self drawRouteSegment:points
                    colors:{}
        colorizationScheme:COLORIZATION_NONE
                      walk:walk
                      sync:sync
    ];
}

- (int) drawRouteSegment:(const QVector<OsmAnd::PointI> &)points
                   colors:(const QList<OsmAnd::FColorARGB> &)colors
       colorizationScheme:(int)colorizationScheme
                     walk:(BOOL)walk
                     sync:(BOOL)sync
{
    int __block lineId;
    void (^drawRouteSegment)(void) = ^{
        _lineWidth = [self getLineWidth];
        int baseOrder = self.baseOrder;
        lineId = _collection->getLinesCount() + 1;
        OsmAnd::VectorLineBuilder builder;
        builder.setBaseOrder(baseOrder--)
            .setIsHidden(points.size() < 2)
            .setLineId(lineId)
            //.setLineWidth(_lineWidth)
            .setLineWidth(walk ? 0.0 : _lineWidth)
            .setPoints(points);
        
        // Add outline for colorized lines
        if (!colors.isEmpty())
            builder.setOutlineWidth(_lineWidth + kOutlineWidth)
                .setOutlineColor(kOutlineColor);
        
        UIColor *color = _routeLineColor == kDefaultRouteLineDayColor || _routeLineColor == kDefaultRouteLineNightColor
            ? UIColorFromARGB(_routeLineColor)
            : UIColorFromRGB(_routeLineColor);
        
        OsmAnd::ColorARGB lineColor = walk ? OsmAnd::ColorARGB(0) : [color toColorARGB];
        
        if (walk)
        {
            OsmAnd::ColorARGB bitmapColor([self getWalkDefaultColor]);
            auto walkIconBitmap = [self walkBitmapWithColor:bitmapColor lineWidth:_lineWidth];
            if (walkIconBitmap)
            {
                builder.setPathIcon(OsmAnd::SingleSkImage(walkIconBitmap))
                    .setPathIconStep(walkIconBitmap->height() * 1.2)
                    .setShouldShowArrows(true);
            }
        }
        else
        {
            NSNumber *colorVal = [self getParamFromAttr:@"color"];
            BOOL hasStyleColor = (colorVal && colorVal.intValue == _routeLineColor)
                || _routeLineColor == kDefaultRouteLineDayColor
                || _routeLineColor == kDefaultRouteLineNightColor;
            
            auto iconBitmap = [self bitmapForColor:hasStyleColor ? UIColor.whiteColor : color
                                          fileName:@"map_direction_arrow"];
            if (iconBitmap)
            {
                builder.setPathIcon(OsmAnd::SingleSkImage(iconBitmap))
                    .setPathIconStep(iconBitmap->height() * kPathIconStepCoef)
                    .setShouldShowArrows(true);
            }
            auto specialIconBitmap = [self specialBitmapWithColor:lineColor];
            if (specialIconBitmap)
            {
                builder.setSpecialPathIcon(OsmAnd::SingleSkImage(specialIconBitmap))
                    .setSpecialPathIconStep(specialIconBitmap->height() * kPathIconStepCoef)
                    .setShouldShowArrows(true);
            }
        }
        
        builder.setFillColor(lineColor)
            .setScreenScale(UIScreen.mainScreen.scale);
        
        if (!colors.empty())
        {
            builder.setColorizationMapping(colors)
                .setColorizationScheme(colorizationScheme);
        }
        
        builder.buildAndAddToCollection(_collection);
    };
    if (sync)
        [self.mapViewController runWithRenderSync:^{
            drawRouteSegment();
        }];
    else
        drawRouteSegment();
    
    return lineId;
}

- (void) updateRouteSegment:(int)lineId startingDistance:(double)startingDistance
{
    const auto& lines = _collection->getLines();
    for (auto &line : lines)
    {
        if (line->lineId == lineId)
            line->setStartingDistance((float) startingDistance);
        if (line->lineId < lineId)
            line->setIsHidden(true);
    }
}

- (void)setProjectedPointMarkerLocation:(double)lat longitude:(double)lon
{
    if (_projectedPointMarker)
        _projectedPointMarker->setPosition(OsmAnd::PointI(OsmAnd::Utilities::get31TileNumberX(lon), OsmAnd::Utilities::get31TileNumberY(lat)));
}

- (void)setProjectedPointMarkerVisibility:(BOOL)visible
{
    if (_projectedPointMarker)
        _projectedPointMarker->setIsHidden(!visible);
}

- (void)recreateProjectedPointCollection
{
    if (_projectionPointCollection)
        [self.mapView removeKeyedSymbolsProvider:_projectionPointCollection];
    
    _projectionPointCollection = std::make_shared<OsmAnd::MapMarkersCollection>();
    _projectionPointCollection->setPriority(_linesPriority);
    OsmAnd::MapMarkerBuilder builder;
    builder.setBaseOrder(self.pointsOrder - 2110);
    builder.setIsAccuracyCircleSupported(NO);
    builder.setIsHidden(YES);
    builder.setPinIcon(OsmAnd::SingleSkImage([OANativeUtilities skImageFromPngResource:@"map_pedestrian_location"]));
    _projectedPointMarker = builder.buildAndAddToCollection(_projectionPointCollection);
    [self.mapView addKeyedSymbolsProvider:_projectionPointCollection];
}

- (void)removeProjectedPointCollection
{
    if (_projectionPointCollection)
    {
        [self.mapView removeKeyedSymbolsProvider:_projectionPointCollection];
        _projectionPointCollection = nullptr;
        _projectedPointMarker = nullptr;
    }
}

- (NSNumber *)getParamFromAttr:(NSString *)param
{
    return _routeAttributes[param];
}

- (NSInteger)getDefaultColor:(BOOL)forTurnArrows
{
    BOOL isNight = [OAAppSettings sharedManager].nightMode;
    NSNumber *colorVal = [self getParamFromAttr:forTurnArrows ? @"color_3" : @"color"];
    return colorVal
            ? colorVal.intValue
            : isNight
                    ? forTurnArrows ? kDefaultTurnArrowsNightColor : kDefaultRouteLineNightColor
                    : forTurnArrows ? kDefaultTurnArrowsDayColor : kDefaultRouteLineDayColor;
}

- (NSInteger)getWalkDefaultColor
{
    NSNumber *colorVal = _walkAttributes[@"color"];
    return colorVal ? colorVal.intValue : kDefaultWalkingRouteLineColor;
}

- (NSInteger)getWalkPTDefaultColor
{
    NSNumber *colorVal = _walkPTAttributes[@"color"];
    return colorVal ? colorVal.intValue : kDefaultWalkingRouteLineColor;
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
        width = [self getParamFromAttr:@"strokeWidth"] ? [self getParamFromAttr:@"strokeWidth"].floatValue : [self getDefaultLineWidth];
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
        [self buildActionArrows:YES];
    });
}

- (void) buildActionArrows:(BOOL)recalculate
{
    if ([self shouldShowTurnArrows])
    {
        const auto zoom = self.mapView.zoomLevel;
        @synchronized (self) 
        {
            if (zoom <= OsmAnd::ZoomLevel14 || _collection->isEmpty()) {
                if (!_actionLinesCollection->isEmpty())
                {
                    [self.mapView removeKeyedSymbolsProvider:_actionLinesCollection];
                    _actionLinesCollection->removeAllLines();
                }
                return;
            }
            else if (recalculate)
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
                            points.push_back(OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(point.coordinate.latitude, point.coordinate.longitude)));

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
    OARouteCalculationResult *route = _routingHelper.getRoute;
    NSArray<CLLocation *> *routeNodes = route.getRouteLocations;
    CLLocation *lastProjection = _routingHelper.getLastProjection;
    int cd = route.currentRoute;
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
        if (loc == route.firstIntroducedPoint || loc == route.lastIntroducedPoint)
            continue;
        
        if (nf != nil)
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
        if (!action && previousAction == nil)
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
                                            loc:loc
                           firstIntroducedPoint:route.firstIntroducedPoint
                            lastIntroducedPoint:route.lastIntroducedPoint];
            }
            [actionPoints addObject:loc];
            previousAction = loc;
            prevFinishPoint = -1;
            actionDist = 0;
        }
    }

    if (previousAction != nil)
        [res addObject:actionPoints];

    return res;
}

- (void) addPreviousToActionPoints:(NSMutableArray<CLLocation *> *)actionPoints
                    lastProjection:(CLLocation *)lastProjection
                        routeNodes:(NSArray<CLLocation *> *)routeNodes
                   DISTANCE_ACTION:(double)DISTANCE_ACTION
                   prevFinishPoint:(int)prevFinishPoint
                        routePoint:(int)routePoint
                               loc:(CLLocation *)loc
              firstIntroducedPoint:(CLLocation *)firstIntroducedPoint
               lastIntroducedPoint:(CLLocation *)lastIntroducedPoint
{
    // put some points in front
    NSInteger ind = actionPoints.count;
    CLLocation *lprevious = loc;
    double dist = 0;
    for (NSInteger k = routePoint - 1; k >= -1; k--)
    {
        if (firstIntroducedPoint && k <= 0)
            continue;
        CLLocation *l = k == -1 ? lastProjection : routeNodes[k];
        if (l == nil || l == lastIntroducedPoint)
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
    [self refreshRoute:YES];
}

- (void) refreshRoute:(BOOL)forceRedraw
{
    [self drawRouteWithSync:YES forceRedraw:forceRedraw];
}

- (void) drawRouteWithSync:(BOOL)sync forceRedraw:(BOOL)forceRedraw
{
    BOOL shouldRedraw = forceRedraw;
    if (!_routeAttributes || !_walkAttributes || !_walkPTAttributes || shouldRedraw)
    {
        _routeAttributes = [self.mapViewController getLineRenderingAttributes:@"route"];
        _walkAttributes = [self.mapViewController getLineRenderingAttributes:@"straightWalkingRouteLine"];
        _walkPTAttributes = [self.mapViewController getLineRenderingAttributes:@"walkingRouteLine"];
        shouldRedraw = YES;
    }
    if (!_routeAttributes || !_walkAttributes || !_walkPTAttributes)
        return;
    
    BOOL isNight = [OAAppSettings sharedManager].nightMode;
    OARouteCalculationResult *route = [_routingHelper getRoute];
    
    // Draw public transport route
    if ([_routingHelper isPublicTransportMode])
    {
        if (!shouldRedraw)
            return;
        
        _route = nil;
        _pathsDataCache = QVector<DrawPathData>();
        _colors.clear();
        [self.mapView removeKeyedSymbolsProvider:_collection];
        _collection = std::make_shared<OsmAnd::VectorLinesCollection>();
        _collection->setPriority(_linesPriority);
        [self.mapView removeKeyedSymbolsProvider:_transportRouteMarkers];
        _transportRouteMarkers = std::make_shared<OsmAnd::MapMarkersCollection>();
        _transportRouteMarkers->setPriority(_linesPriority);
        
        NSInteger currentRoute = _transportHelper.currentRoute;
        const auto routes = [_transportHelper getRoutes];
        const auto route = currentRoute != -1 && routes.size() > currentRoute ? routes[currentRoute] : nullptr;
        if (route != nullptr)
        {
            CLLocation *start = _transportHelper.startLocation;
            CLLocation *end = _transportHelper.endLocation;
            
            CLLocation *p = start;
            SHARED_PTR<TransportRouteResultSegment> prev = nullptr;
            
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
            [self setVectorLineProvider:_collection sync:sync];
            [self.mapView addKeyedSymbolsProvider:_transportRouteMarkers];
        }
        return;
    }
    
    // Draw regular route
    if ([_routingHelper getFinalLocation] && route && [route isCalculated])
    {
        OAColoringType *prevRouteColoringType = _prevRouteColoringType;
        NSString *prevRouteInfoAttribute = _prevRouteInfoAttribute;
        [self updateRouteColoringType];
        [self updateRouteColors:isNight];
        _prevRouteColoringType = _routeColoringType;
        _prevRouteInfoAttribute = _routeInfoAttribute;
        
        OAColoringType *routeColoringType = _routeColoringType;
        if (![self isColoringAvailable:route routeColoringType:routeColoringType attributeName:_routeInfoAttribute])
            routeColoringType = OAColoringType.DEFAULT;
        
        BOOL routeUpdated = shouldRedraw || _route != route;
        
        BOOL gradientRoute = [routeColoringType isGradient];
        NSString *colorPaletteFile = @"";
        if (gradientRoute)
        {
            colorPaletteFile = [ColorPaletteHelper getRoutePaletteFileName:(ColorizationType) [routeColoringType toColorizationType]
                                                       gradientPaletteName:_routeGradientPalette];
            routeUpdated = routeUpdated || prevRouteColoringType != routeColoringType
            || _colorizationScheme != COLORIZATION_GRADIENT || [_updatedColorPaletteFiles objectForKeySync:colorPaletteFile];
        }
        
        BOOL attributedRoute = [routeColoringType isRouteInfoAttribute];
        if (attributedRoute)
            routeUpdated = routeUpdated || ![prevRouteInfoAttribute isEqualToString:_routeInfoAttribute]
            || _colorizationScheme != COLORIZATION_SOLID;
        
        BOOL solidColorRoute = [routeColoringType isSolidSingleColor];
        if (solidColorRoute)
            routeUpdated = routeUpdated || _colorizationScheme != COLORIZATION_NONE || _colors.count() > 0;
        
        NSArray<CLLocation *> *locations = [route getImmutableAllLocations];
        if (gradientRoute && routeUpdated)
        {
            NSString *updatedColorPaletteValue = [_updatedColorPaletteFiles objectForKeySync:colorPaletteFile];
            if ([updatedColorPaletteValue isEqualToString:ColorPaletteHelper.deletedFileKey])
                _routeGradientPalette = PaletteGradientColor.defaultName;
            [_updatedColorPaletteFiles removeObjectForKeySync:colorPaletteFile];
            
            OASGpxFile *gpx = [OAGPXUIHelper makeGpxFromRoute:route];
            ColorPalette *colorPalette = [[ColorPaletteHelper shared] getGradientColorPaletteSync:(ColorizationType) [routeColoringType toColorizationType]
                                                                              gradientPaletteName:_routeGradientPalette];
            if (!colorPalette)
                return;
            
            OARouteColorize *colorizationHelper =
            [[OARouteColorize alloc] initWithGpxFile:gpx
                                            analysis:[gpx getAnalysisFileTimestamp:0]
                                                type:[routeColoringType toColorizationType]
                                             palette:colorPalette
                                     maxProfileSpeed:0
            ];
            _colorizationScheme = COLORIZATION_GRADIENT;
            _colors.clear();
            if (colorizationHelper)
                _colors.append([colorizationHelper getResultQList]);
        }
        else if (attributedRoute && routeUpdated)
        {
            _colorizationScheme = COLORIZATION_SOLID;
            _colors.clear();
            auto segs = route.getOriginalRoute;
            [self calculateSegmentsColor:_colors
                                attrName:_routeInfoAttribute
                           segmentResult:segs
                               locations:locations];
        }
        else if (solidColorRoute && routeUpdated)
        {
            _colorizationScheme = COLORIZATION_NONE;
            _colors.clear();
        }
        _route = route;
        
        CLLocation *lastProj = nil;
        CLLocationCoordinate2D coord = self.mapViewController.mapLayers.myPositionLayer.getActiveMarkerLocation;
        CLLocation *currentLocation = [[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude];
        int currentRoute = [route getCurrentRouteForLocation:currentLocation];
        
        EOARouteService routeService = (EOARouteService)_routingHelper.getAppMode.getRouterService;
        BOOL directToActive = routeService == DIRECT_TO;
        if (currentRoute > 0)
        {
            CLLocation *previousRouteLocation = locations[currentRoute - 1];
            CLLocation *currentRouteLocation = locations[currentRoute];
            lastProj = [self getProject:currentLocation from:previousRouteLocation to:currentRouteLocation];
            
            BOOL result = [OASKMapUtils.shared areLatLonEqualL1:[[OASKLatLon alloc]
                                                                 initWithLatitude:previousRouteLocation.coordinate.latitude longitude:previousRouteLocation.coordinate.longitude]
                                                             l2:[[OASKLatLon alloc]
                                                                 initWithLatitude:currentRouteLocation.coordinate.latitude longitude:currentRouteLocation.coordinate.longitude]];
            
            float calcbearing = !result
            ? [previousRouteLocation bearingTo:currentRouteLocation]
            : [previousRouteLocation bearingTo:currentLocation];
            lastProj = [lastProj locationWithCourse:[OASKMapUtils.shared normalizeDegrees360Degrees:calcbearing]];
            if ([currentLocation haversineDistanceInMetersTo:lastProj] > [_routingHelper getMaxAllowedProjectDist:currentLocation])
                lastProj = nil;
        } else {
            lastProj = nil;
        }
        if (directToActive)
        {
            lastProj = nil;
            currentRoute = 0;
        }
        _lastProj = lastProj;
        BOOL currentRouteChanged = _lastCurrentRoute != currentRoute;
        _lastCurrentRoute = currentRoute;
        
        if (directToActive)
        {
            if (!_projectionPointCollection)
                [self recreateProjectedPointCollection];
            
            CLLocationCoordinate2D coord = [self calculateProjectionOnRoutePoint];
            if (CLLocationCoordinate2DIsValid(coord))
            {
                [self setProjectedPointMarkerLocation:coord.latitude longitude:coord.longitude];
                [self setProjectedPointMarkerVisibility:YES];
            }
            else
            {
                [self setProjectedPointMarkerVisibility:NO];
            }
        }
        else
        {
            [self removeProjectedPointCollection];
        }
        
        if (routeUpdated)
        {
            [self.mapView removeKeyedSymbolsProvider:_collection];
            _collection = std::make_shared<OsmAnd::VectorLinesCollection>();
            _collection->setPriority(_linesPriority);
        }
        else
        {
            double passedDist = 0;
            int passedLineId = 0;
            int lastX31 = 0;
            int lastY31 = 0;
            double lastPathDist = 0;
            for (const auto& pathData : _pathsDataCache)
            {
                BOOL hasIndex = NO;
                for (int index : pathData.indexes)
                    if (index <= currentRoute)
                    {
                        hasIndex = YES;
                        break;
                    }
                
                if (hasIndex)
                {
                    const auto& indexes = pathData.indexes;
                    for (int i = 0; i < indexes.size() - 1; i++)
                    {
                        int index = indexes[i];
                        if (index < currentRoute)
                        {
                            lastX31 = pathData.points[i].x;
                            lastY31 = pathData.points[i].y;
                            if (passedLineId != pathData.lineId)
                                passedDist = pathData.distances[i];
                            else
                                passedDist += i > 0 ? pathData.distances[i] : lastPathDist;
                            
                            passedLineId = pathData.lineId;
                            lastPathDist = pathData.distances[pathData.distances.size() - 1];
                        }
                    }
                }
            }
            
            if (lastProj && lastX31 != 0 && lastY31 != 0) {
                double dist = [OASKMapUtils.shared measuredDist31X1:
                               [OASKMapUtils.shared get31TileNumberXLongitude:lastProj.coordinate.longitude]
                                                                 y1:[OASKMapUtils.shared get31TileNumberYLatitude:lastProj.coordinate.latitude]
                                                                 x2:lastX31
                                                                 y2:lastY31];
                
                passedDist += dist;
                
            }
            
            if (passedLineId > 0)
                [self updateRouteSegment:passedLineId startingDistance:passedDist];
            
            [self buildActionArrows:currentRouteChanged];
            
            return;
        }
        
        DrawPathData pointsData;
        DrawPathData firstWalkingPointsData;
        DrawPathData lastWalkingPointsData;
        for (int i = currentRoute; i < locations.count; i++)
        {
            CLLocation *location = locations[i];
            
            if (location == route.firstIntroducedPoint && i + 1 < locations.count)
            {
                firstWalkingPointsData.indexes.push_back(i);
                firstWalkingPointsData.points.push_back(OsmAnd::PointI(
                                                                       OsmAnd::Utilities::get31TileNumberX(location.coordinate.longitude),
                                                                       OsmAnd::Utilities::get31TileNumberY(location.coordinate.latitude)));
                firstWalkingPointsData.indexes.push_back(i + 1);
                firstWalkingPointsData.points.push_back(OsmAnd::PointI(
                                                                       OsmAnd::Utilities::get31TileNumberX(locations[i + 1].coordinate.longitude),
                                                                       OsmAnd::Utilities::get31TileNumberY(locations[i + 1].coordinate.latitude)));
                firstWalkingPointsData.distances.push_back(0.0);
                firstWalkingPointsData.distances.push_back([location haversineDistanceInMetersTo:locations[i + 1]]);
            }
            else if (location == route.lastIntroducedPoint && i > 0)
            {
                lastWalkingPointsData.indexes.push_back(i - 1);
                lastWalkingPointsData.points.push_back(OsmAnd::PointI(
                                                                      OsmAnd::Utilities::get31TileNumberX(locations[i - 1].coordinate.longitude),
                                                                      OsmAnd::Utilities::get31TileNumberY(locations[i - 1].coordinate.latitude)));
                lastWalkingPointsData.indexes.push_back(i);
                lastWalkingPointsData.points.push_back(OsmAnd::PointI(
                                                                      OsmAnd::Utilities::get31TileNumberX(location.coordinate.longitude),
                                                                      OsmAnd::Utilities::get31TileNumberY(location.coordinate.latitude)));
                lastWalkingPointsData.distances.push_back(0.0);
                lastWalkingPointsData.distances.push_back([location haversineDistanceInMetersTo:locations[i - 1]]);
            }
            else
            {
                if (pointsData.points.isEmpty())
                    pointsData.distances.push_back(0.0);
                else
                    pointsData.distances.push_back([locations[i] haversineDistanceInMetersTo:locations[i - 1]]);
                
                pointsData.indexes.push_back(i);
                pointsData.points.push_back(OsmAnd::PointI(
                                                           OsmAnd::Utilities::get31TileNumberX(location.coordinate.longitude),
                                                           OsmAnd::Utilities::get31TileNumberY(location.coordinate.latitude)));
            }
        }
        
        QVector<DrawPathData> pathsData;
        if (_colorizationScheme == COLORIZATION_NONE)
        {
            if (!pointsData.points.isEmpty())
            {
                if (!firstWalkingPointsData.points.isEmpty())
                {
                    int lineId = [self drawRouteSegment:firstWalkingPointsData.points walk:YES sync:sync];
                    firstWalkingPointsData.lineId = lineId;
                    pathsData.push_back(firstWalkingPointsData);
                }
                
                {
                    int lineId = [self drawRouteSegment:pointsData.points walk:NO sync:sync];
                    pointsData.lineId = lineId;
                    pathsData.push_back(pointsData);
                }
                
                if (!lastWalkingPointsData.points.isEmpty())
                {
                    int lineId = [self drawRouteSegment:lastWalkingPointsData.points walk:YES sync:sync];
                    lastWalkingPointsData.lineId = lineId;
                    pathsData.push_back(lastWalkingPointsData);
                }
            }
            else
            {
                [self.mapViewController runWithRenderSync:^{ [self resetLayer]; }];
            }
        }
        else if (!pointsData.points.isEmpty())
        {
            if (!firstWalkingPointsData.points.isEmpty())
            {
                int lineId = [self drawRouteSegment:firstWalkingPointsData.points walk:YES sync:sync];
                firstWalkingPointsData.lineId = lineId;
                pathsData.push_back(firstWalkingPointsData);
            }
            
            int segStartIndex = _colors.count() - pointsData.points.count();
            QList<OsmAnd::FColorARGB> segmentColors;
            if (pointsData.points.size() > 1 && !_colors.isEmpty() && segStartIndex < _colors.size() && segStartIndex + pointsData.points.size() - 1 < _colors.size())
                segmentColors = _colors.mid(segStartIndex, pointsData.points.size());
            
            if (!segmentColors.isEmpty())
            {
                int lineId = [self drawRouteSegment:pointsData.points
                                             colors:segmentColors
                                 colorizationScheme:_colorizationScheme
                                               walk:NO
                                               sync:sync];
                pointsData.lineId = lineId;
                pathsData.push_back(pointsData);
                
                segmentColors.clear();
            }
            
            if (!lastWalkingPointsData.points.isEmpty())
            {
                int lineId = [self drawRouteSegment:lastWalkingPointsData.points walk:YES sync:sync];
                lastWalkingPointsData.lineId = lineId;
                pathsData.push_back(lastWalkingPointsData);
            }
        }
        
        if (routeUpdated)
        {
            [self.mapView addKeyedSymbolsProvider:_collection];
            [self setVectorLineProvider:_collection sync:sync];
            [self buildActionArrows:YES];
        }
        
        _pathsDataCache = pathsData;
    }
}

- (CLLocation *)getProject:(CLLocation *)loc
                      from:(CLLocation *)from
                        to:(CLLocation *)to
{
    OASKLatLon *project = [OASKMapUtils.shared getProjectionLat:loc.coordinate.latitude
                                                            lon:loc.coordinate.longitude
                                                        fromLat:from.coordinate.latitude
                                                        fromLon:from.coordinate.longitude
                                                          toLat:to.coordinate.latitude
                                                          toLon:to.coordinate.longitude];
    
    CLLocation *locationProjection = [[CLLocation alloc] initWithLatitude:project.latitude
                                                                longitude:project.longitude];
    
    return locationProjection;
}

- (CLLocationCoordinate2D)calculateProjectionOnRoutePoint
{
    CLLocation *lastLocation = [_routingHelper getLastFixedLocation];
    OARouteCalculationResult *route = [_routingHelper getRoute];
    NSArray<CLLocation *> *locations = [route getImmutableAllLocations];
    if (locations.count == 0)
        return kCLLocationCoordinate2DInvalid;
    
    int currentRoute = route.currentRoute;
    int locIndex = (int)locations.count - 1;
    if ([route getIntermediatePointsToPass] > 0)
        locIndex = [route getIndexOfIntermediate:[route getIntermediatePointsToPass] - 1];
    
    if (lastLocation != nil && currentRoute > 0 && currentRoute < locations.count && locIndex >= 0 && locIndex < locations.count)
    {
        CLLocation *target = locations[locIndex];
        double targetDistance = [lastLocation distanceFromLocation:target];
        CLLocationCoordinate2D latLon = [GpxUtils calculateProjectionOnSegmentFrom:locations target:target startIndex:currentRoute - 1 targetDistance:targetDistance];
        if (!CLLocationCoordinate2DIsValid(latLon))
            latLon = [GpxUtils calculateProjectionOnSegmentFrom:locations target:target startIndex:currentRoute targetDistance:targetDistance];
        if (CLLocationCoordinate2DIsValid(latLon))
            return latLon;
    }
    
    return kCLLocationCoordinate2DInvalid;
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
        [self drawRouteSegment:points walk:YES sync:sync];
    }
}

- (void) onMapFrameAnimatorsUpdated
{
    if (_routingHelper && ![_routingHelper isPublicTransportMode])
        [self drawRouteWithSync:NO forceRedraw:NO];
}

- (CLLocation *) getObjectLocation:(id)obj
{
    if ([obj isKindOfClass:OATransportStop.class])
    {
        OATransportStop *transportStop = (OATransportStop *)obj;
        return [[CLLocation alloc] initWithLatitude:transportStop.latitude longitude:transportStop.longitude];
    }
    return nil;
}

- (OAPointDescription *) getObjectName:(id)obj
{
    if ([obj isKindOfClass:OATransportStop.class])
    {
        OATransportStop *transportStop = (OATransportStop *)obj;
        return [[OAPointDescription alloc] initWithType:POINT_TYPE_TRANSPORT_STOP typeName:OALocalizedString(@"transport_Stop") name:[transportStop name]];
    }
    return nil;
}

- (BOOL) showMenuAction:(id)object
{
    return NO;
}

- (BOOL) runExclusiveAction:(id)obj unknownLocation:(BOOL)unknownLocation
{
    return NO;
}

- (int64_t) getSelectionPointOrder:(id)selectedObject
{
    return 0;
}

@end
