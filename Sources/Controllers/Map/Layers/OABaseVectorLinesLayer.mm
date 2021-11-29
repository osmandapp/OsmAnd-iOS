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
#include <OsmAndCore/Map/OnSurfaceRasterMapSymbol.h>
#include <OsmAndCore/Map/MapStylesCollection.h>
#include <OsmAndCore/Map/ResolvedMapStyle.h>

#include <SkBitmapDevice.h>

#define kZoomDelta 0.1


@implementation OABaseVectorLinesLayer
{
    OAAutoObserverProxy* _mapZoomObserver;
    std::shared_ptr<OsmAnd::MapMarkersCollection> _lineSymbolsCollection;
    
    std::shared_ptr<OsmAnd::VectorLinesCollection> _vectorLinesCollection;
    QHash<std::shared_ptr<OsmAnd::VectorLine>, QList<OsmAnd::VectorLine::OnPathSymbolData>> _fullSymbolsGroupByLine;
    
    QReadWriteLock _lock;
}

- (NSString *) layerId
{
    return nil; //override
}

- (void) show
{
    [self.mapViewController runWithRenderSync:^{
        [self.mapView addKeyedSymbolsProvider:_lineSymbolsCollection];
    }];
}

- (void) hide
{
    [self.mapViewController runWithRenderSync:^{
        [self.mapView removeKeyedSymbolsProvider:_lineSymbolsCollection];
    }];
}

- (void)resetLayer
{
    [self hide];
    _lineSymbolsCollection.reset(new OsmAnd::MapMarkersCollection());
    _fullSymbolsGroupByLine.clear();
    _vectorLinesCollection.reset();
    [self show];
}

- (BOOL)updateLayer
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
    _fullSymbolsGroupByLine.clear();
    
    if (_vectorLinesCollection)
    {
        for (const auto& line : _vectorLinesCollection->getLines())
        {
            line->lineUpdatedObservable.attach((__bridge const void*)self, [self]
                                               (const OsmAnd::VectorLine* const vectorLine)
                                               {
                QWriteLocker scopedLocker(&_lock);
                const auto& sharedLine = [self findSharedLine:vectorLine];
                if (sharedLine)
                {
                    const auto symbolsInfo = vectorLine->getArrowsOnPath();
                    _fullSymbolsGroupByLine.insert(sharedLine, symbolsInfo);
                    [self resetSymbols];
                }
            });
            const auto symbolsInfo = line->getArrowsOnPath();
            _fullSymbolsGroupByLine.insert(line, symbolsInfo);
        }
    }
    [self resetSymbols];
}

- (std::shared_ptr<OsmAnd::VectorLine>) findSharedLine:(const OsmAnd::VectorLine* const)vectorLine
{
    if (_fullSymbolsGroupByLine.isEmpty())
        return nullptr;
    const auto lines = _fullSymbolsGroupByLine.keys();
    for (auto it = lines.begin(); it != lines.end(); ++it)
    {
        if (*it && (*it).get() == vectorLine)
            return *it;
    }
    return nullptr;
}

- (void) buildMarkersSymbols
{
    QWriteLocker scopedLocker(&_lock);
    _fullSymbolsGroupByLine.clear();
    
    if (_vectorLinesCollection)
    {
        for (const auto& line : _vectorLinesCollection->getLines())
        {
            QList<OsmAnd::VectorLine::OnPathSymbolData> symbolsInfo;
            line->getArrowsOnPath();
            _fullSymbolsGroupByLine.insert(line, symbolsInfo);
        }
    }
}

- (void) resetSymbols
{
    [self.mapViewController runWithRenderSync:^{
        if (!_lineSymbolsCollection)
        {
            _lineSymbolsCollection.reset(new OsmAnd::MapMarkersCollection());
            [self.mapView addKeyedSymbolsProvider:_lineSymbolsCollection];
        }
        int lineSymbolIdx = 0;
        int initialSymbolsCount = _lineSymbolsCollection->getMarkers().size();
        for (auto it = _fullSymbolsGroupByLine.begin(); it != _fullSymbolsGroupByLine.end(); ++it)
        {
            const auto& symbolsData = it.value();
            const auto& line = it.key();
            int baseOrder = line->baseOrder - 100;
            for (const auto& symbolInfo : symbolsData)
            {
                if (lineSymbolIdx < initialSymbolsCount)
                {
                    auto marker = _lineSymbolsCollection->getMarkers()[lineSymbolIdx];
                    marker->setPosition(symbolInfo.position31);
                    marker->setOnMapSurfaceIconDirection(reinterpret_cast<OsmAnd::MapMarker::OnSurfaceIconKey>(marker->markerId), OsmAnd::Utilities::normalizedAngleDegrees(symbolInfo.direction));
                    marker->setIsHidden(line->isHidden());
                    lineSymbolIdx++;
                }
                else
                {
                    OsmAnd::MapMarkerBuilder builder;
                    const auto markerKey = reinterpret_cast<OsmAnd::MapMarker::OnSurfaceIconKey>(_lineSymbolsCollection->getMarkers().size());
                    builder.addOnMapSurfaceIcon(markerKey, line->getPointBitmap());
                    builder.setMarkerId(_lineSymbolsCollection->getMarkers().size());
                    builder.setBaseOrder(--baseOrder);
                    builder.setIsHidden(line->isHidden());
                    const auto& marker = builder.buildAndAddToCollection(_lineSymbolsCollection);
                    marker->setPosition(symbolInfo.position31);
                    marker->setOnMapSurfaceIconDirection(markerKey, symbolInfo.direction);
                    marker->setIsAccuracyCircleVisible(false);
                }
            }
        }
        QList< std::shared_ptr<OsmAnd::MapMarker> > toDelete;
        while (lineSymbolIdx < initialSymbolsCount)
        {
            toDelete.append(_lineSymbolsCollection->getMarkers()[lineSymbolIdx]);
            lineSymbolIdx++;
        }
        for (const auto& marker : toDelete)
        {
            _lineSymbolsCollection->removeMarker(marker);
        }
    }];
}

- (std::shared_ptr<SkBitmap>) bitmapForColor:(UIColor *)color fileName:(NSString *)fileName
{
    UIImage *image = [UIImage imageNamed:fileName];
    if ([OAUtilities isColorBright:color])
        image = [OAUtilities tintImageWithColor:image color:UIColor.blackColor];
    return [OANativeUtilities skBitmapFromCGImage:image.CGImage];
}

- (std::shared_ptr<SkBitmap>) specialBitmapWithColor:(OsmAnd::ColorARGB)color
{
    const auto bitmap = std::make_shared<SkBitmap>();
    CGFloat bitmapSize = 20. * UIScreen.mainScreen.scale;
    CGFloat strokeWidth = 2.5 * UIScreen.mainScreen.scale;
    if (bitmap->isNull())
    {
        if (!bitmap->tryAllocPixels(SkImageInfo::MakeN32Premul(bitmapSize, bitmapSize)))
        {
            LogPrintf(OsmAnd::LogSeverityLevel::Error,
                      "Failed to allocate bitmap of size %dx%d",
                      bitmapSize,
                      bitmapSize);
            return nullptr;
        }
        
        bitmap->eraseColor(SK_ColorTRANSPARENT);
    }

    SkBitmapDevice target(*bitmap.get());
    SkCanvas canvas(&target);
    SkPaint paint;
    paint.setStyle(SkPaint::Style::kStroke_Style);
    paint.setColor(SkColorSetARGBInline(0x33, 0x00, 0x00, 0x00));
    paint.setStrokeWidth(strokeWidth);
    canvas.drawCircle(bitmapSize / 2, bitmapSize / 2, (bitmapSize - strokeWidth) / 2, paint);
    
    paint.reset();
    paint.setStyle(SkPaint::Style::kFill_Style);
    paint.setColor(SkColorSetARGBInline(color.a, color.r, color.g, color.b));
    canvas.drawCircle(bitmapSize / 2, bitmapSize  / 2, (bitmapSize - strokeWidth) / 2, paint);
    
    const auto arrowImage = [OANativeUtilities skBitmapFromPngResource:@"map_direction_arrow_small"];
    canvas.drawBitmap(*arrowImage,
                      (bitmapSize - arrowImage->width()) / 2.0f,
                      (bitmapSize - arrowImage->height()) / 2.0f,
                      nullptr);
    
    canvas.flush();
    return bitmap;
}

- (void) calculateSegmentsColor:(QList<OsmAnd::FColorARGB> &)colors attrName:(NSString *)attrName gpx:(OAGPXDocument *)gpx
{
    OARouteImporter *routeImporter = [[OARouteImporter alloc] initWithGpxFile:gpx];
    const auto segs = [routeImporter importRoute];
    const auto& env = [OsmAndApp instance].defaultRenderer;
    
    OARouteStatisticsComputer *statsComputer = [[OARouteStatisticsComputer alloc] initWithPresentationEnvironment:env];
    NSMutableArray<CLLocation *> *locations = [NSMutableArray array];
    for (OAGpxTrkSeg *seg in [gpx getNonEmptyTrkSegments:YES])
    {
        for (OAGpxTrkPt *trkPt in seg.points)
        {
            [locations addObject:[[CLLocation alloc] initWithLatitude:trkPt.position.latitude longitude:trkPt.position.longitude]];
        }
    }
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
