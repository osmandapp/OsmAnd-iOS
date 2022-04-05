//
//  OABaseVectorLinesLayer.m
//  OsmAnd
//
//  Created by Paul on 17/01/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OABaseVectorLinesLayer.h"
#import "OANativeUtilities.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OAUtilities.h"
#import "OAAutoObserverProxy.h"
#import "OAGPXDocument.h"
#import "OARouteStatisticsHelper.h"
#import "OARouteImporter.h"
#import "OARouteStatistics.h"
#import "OARootViewController.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/VectorLine.h>
#include <OsmAndCore/Map/MapMarker.h>
#include <OsmAndCore/Map/MapMarkerBuilder.h>
#include <OsmAndCore/Map/MapMarkersCollection.h>
#include <OsmAndCore/Map/VectorLineArrowsProvider.h>
#include <OsmAndCore/Map/OnSurfaceRasterMapSymbol.h>
#include <OsmAndCore/Map/MapStylesCollection.h>
#include <OsmAndCore/Map/ResolvedMapStyle.h>

#include <SkCanvas.h>

#define kZoomDelta 0.1


@implementation OABaseVectorLinesLayer
{
    OAAutoObserverProxy* _mapZoomObserver;
        
    QReadWriteLock _lock;
    std::shared_ptr<OsmAnd::VectorLinesCollection> _vectorLinesCollection;
    std::shared_ptr<OsmAnd::VectorLineArrowsProvider> _vectorLinesArrowsProvider;
}

- (NSString *) layerId
{
    return nil; //override
}

- (void) show
{
    [self.mapViewController runWithRenderSync:^{
        [self.mapView addKeyedSymbolsProvider:_vectorLinesArrowsProvider];
    }];
}

- (void) hide
{
    [self.mapViewController runWithRenderSync:^{
        [self.mapView removeKeyedSymbolsProvider:_vectorLinesArrowsProvider];
    }];
}

- (void) resetLayer
{
    [self hide];
    _vectorLinesArrowsProvider.reset();
    _vectorLinesCollection.reset();
    [self show];
}

- (BOOL) updateLayer
{
    return YES; //override
}

- (BOOL) isVisible
{
    return YES; //override
}

- (void) setVectorLineProvider:(std::shared_ptr<OsmAnd::VectorLinesCollection> &)collection
{
    QWriteLocker scopedLocker(&_lock);
    
    _vectorLinesCollection = collection;
    _vectorLinesArrowsProvider = _vectorLinesCollection->getVectorLineArrowsProvider();
    [self.mapViewController runWithRenderSync:^{
        [self.mapView addKeyedSymbolsProvider:_vectorLinesArrowsProvider];
    }];
}

- (sk_sp<SkImage>) bitmapForColor:(UIColor *)color fileName:(NSString *)fileName
{
    UIImage *image = [UIImage imageNamed:fileName];
    if ([OAUtilities isColorBright:color])
        image = [OAUtilities tintImageWithColor:image color:UIColor.blackColor];
    return [OANativeUtilities skImageFromCGImage:image.CGImage];
}

- (sk_sp<SkImage>) specialBitmapWithColor:(OsmAnd::ColorARGB)color
{
    SkBitmap bitmap;
    CGFloat bitmapSize = 20. * UIScreen.mainScreen.scale;
    CGFloat strokeWidth = 2.5 * UIScreen.mainScreen.scale;
    if (!bitmap.tryAllocPixels(SkImageInfo::MakeN32Premul(bitmapSize, bitmapSize)))
    {
        LogPrintf(OsmAnd::LogSeverityLevel::Error,
                  "Failed to allocate bitmap of size %dx%d",
                  bitmapSize,
                  bitmapSize);
        return nullptr;
    }
    
    bitmap.eraseColor(SK_ColorTRANSPARENT);

    SkCanvas canvas(bitmap);
    SkPaint paint;
    paint.setStyle(SkPaint::Style::kStroke_Style);
    paint.setColor(SkColorSetARGB(0x33, 0x00, 0x00, 0x00));
    paint.setStrokeWidth(strokeWidth);
    canvas.drawCircle(bitmapSize / 2, bitmapSize / 2, (bitmapSize - strokeWidth) / 2, paint);
    
    paint.reset();
    paint.setStyle(SkPaint::Style::kFill_Style);
    paint.setColor(SkColorSetARGB(color.a, color.r, color.g, color.b));
    canvas.drawCircle(bitmapSize / 2, bitmapSize  / 2, (bitmapSize - strokeWidth) / 2, paint);
    
    const auto arrowImage = [OANativeUtilities skImageFromPngResource:@"map_direction_arrow_small"];
    canvas.drawImage(arrowImage,
                     (bitmapSize - arrowImage->width()) / 2.0f,
                     (bitmapSize - arrowImage->height()) / 2.0f);
    
    canvas.flush();
    return bitmap.asImage();
}

- (void) calculateSegmentsColor:(QList<OsmAnd::FColorARGB> &)colors
                       attrName:(NSString *)attrName
                  segmentResult:(std::vector<std::shared_ptr<RouteSegmentResult>> &)segs
                      locations:(NSArray<CLLocation *> *)locations
{
    const auto& env = [OsmAndApp instance].defaultRenderer;
    OARouteStatisticsComputer *statsComputer = [[OARouteStatisticsComputer alloc] initWithPresentationEnvironment:env];
    int firstSegmentLocationIdx = [self getIdxOfFirstSegmentLocation:locations routeSegments:segs];
    for (NSInteger i = 0; i < segs.size(); i++)
    {
        const auto& segment = segs[i];
        OARouteSegmentWithIncline *routeSeg = [[OARouteSegmentWithIncline alloc] init];
        routeSeg.obj = segment->object;
        OARouteSegmentAttribute *attribute = [statsComputer classifySegment:attrName slopeClass:-1 segment:routeSeg];
        OsmAnd::ColorARGB color((int)attribute.color);
//        color = color == 0 ? RouteColorize.LIGHT_GREY : color;
        
        if (i == 0)
        {
            for (int j = 0; j < firstSegmentLocationIdx; j++)
            {
                colors.push_back(color);
            }
        }
        
        int pointsSize = abs(segment->getStartPointIndex() - segment->getEndPointIndex());
        for (int j = 0; j < pointsSize; j++)
        {
            colors.push_back(color);
        }
        
        if (i == segs.size() - 1)
        {
            int start = colors.size();
            for (int j = start; j < locations.count; j++)
            {
                colors.push_back(color);
            }
        }
    }
}

- (int) getIdxOfFirstSegmentLocation:(NSArray<CLLocation *> *)locations
                       routeSegments:(const std::vector<std::shared_ptr<RouteSegmentResult>> &)routeSegments
{
    int locationsIdx = 0;
    if (routeSegments.size() == 0)
        return locationsIdx;
    const auto& segmentStartPoint = routeSegments[0]->getStartPoint();
    while (locationsIdx < locations.count)
    {
        CLLocation *location = locations[locationsIdx];
        if (location.coordinate.latitude == segmentStartPoint.lat
            && location.coordinate.longitude == segmentStartPoint.lon)
        {
            break;
        }
        locationsIdx++;
    }
    return locationsIdx == locations.count ? 0 : locationsIdx;
}

@end
