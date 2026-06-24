//
//  OATrackPreviewMapRenderer.mm
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 10.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import "OATrackPreviewMapRenderer.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OAMapRendererEnvironment.h"
#import "OANativeUtilities.h"

#import "OsmAndSharedWrapper.h"
#import "OAUtilities.h"
#import "OsmAnd_Maps-Swift.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/MapPrimitivesProvider.h>
#include <OsmAndCore/Map/MapRasterLayerProvider_Software.h>
#include <OsmAndCore/Map/IMapTiledDataProvider.h>
#include <OsmAndCore/FunctorQueryController.h>

namespace {
    constexpr int kMinZoom = 7;
    constexpr int kMaxZoom = 17;
    constexpr int kInitialZoom = 15;
    constexpr CGFloat kTrackLineWidth = 4.0;
    constexpr CGFloat kWaypointRadius = 5.0;
    constexpr CGFloat kWaypointStrokeWidth = 1.5;
}

@implementation OATrackPreviewMapRenderer
{
    dispatch_queue_t _queue;
    std::atomic_bool _cancelled;
}

+ (instancetype)shared
{
    static OATrackPreviewMapRenderer *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[OATrackPreviewMapRenderer alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _queue = dispatch_queue_create("net.osmand.track_preview_map", DISPATCH_QUEUE_SERIAL);
        _cancelled = false;
    }
    return self;
}

- (void)cancelAll
{
    _cancelled = true;
}

- (BOOL)isCancelled
{
    return _cancelled;
}

#pragma mark - Public API

- (void)renderGpxFile:(OASGpxFile *)gpxFile
              widthPx:(NSInteger)widthPx
             heightPx:(NSInteger)heightPx
              density:(float)density
           trackColor:(int)trackColor
           completion:(void (^)(UIImage * _Nullable))completion
{
    _cancelled = false;

    OAMapViewController *mapVC = OARootViewController.instance.mapPanel.mapViewController;
    std::shared_ptr<OsmAnd::MapPrimitivesProvider> primitivesProvider =
        mapVC.mapRendererEnv.mapPrimitivesProvider;

    if (!primitivesProvider)
    {
        dispatch_async(dispatch_get_main_queue(), ^{ completion(nil); });
        return;
    }

    __weak __typeof(self) weakSelf = self;
    dispatch_async(_queue, ^{
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || [strongSelf isCancelled])
        {
            dispatch_async(dispatch_get_main_queue(), ^{ completion(nil); });
            return;
        }

        UIImage *image = [strongSelf renderImageWithProvider:primitivesProvider
                                                     gpxFile:gpxFile
                                                     widthPx:widthPx
                                                    heightPx:heightPx
                                                     density:density
                                                  trackColor:trackColor];
        dispatch_async(dispatch_get_main_queue(), ^{
            completion([strongSelf isCancelled] ? nil : image);
        });
    });
}

#pragma mark - Rendering

- (UIImage *)renderImageWithProvider:(const std::shared_ptr<OsmAnd::MapPrimitivesProvider> &)primitivesProvider
                             gpxFile:(OASGpxFile *)gpxFile
                             widthPx:(NSInteger)widthPx
                            heightPx:(NSInteger)heightPx
                             density:(float)density
                          trackColor:(int)trackColor
{
    OASKQuadRect *rect = [gpxFile getRect];
    if ([rect hasInitialState])
        return nil;

    const double centerLat = rect.centerY;
    const double centerLon = rect.centerX;

    const int pixelWidth = (int)round(widthPx * density);
    const int pixelHeight = (int)round(heightPx * density);

    const auto rasterProvider = std::make_shared<OsmAnd::MapRasterLayerProvider_Software>(primitivesProvider, true, false, true);
    const uint32_t tileSize = rasterProvider->getTileSize();
    const int zoom = [self zoomLevelForBounds:rect
                                     centerLat:centerLat
                                     centerLon:centerLon
                                    pixelWidth:pixelWidth
                                   pixelHeight:pixelHeight
                                      tileSize:tileSize];

    const double centerPxX = OsmAnd::Utilities::getTileNumberX(zoom, centerLon) * tileSize;
    const double centerPxY = OsmAnd::Utilities::getTileNumberY(zoom, centerLat) * tileSize;
    const double leftPx = centerPxX - pixelWidth / 2.0;
    const double topPx = centerPxY - pixelHeight / 2.0;

    UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat preferredFormat];
    format.scale = 1;
    format.opaque = YES;
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(pixelWidth, pixelHeight) format:format];

    UIImage *result = [renderer imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
        [[UIColor whiteColor] setFill];
        [ctx fillRect:CGRectMake(0, 0, pixelWidth, pixelHeight)];

        [self drawMapTilesWithProvider:rasterProvider
                                  zoom:zoom
                              tileSize:tileSize
                                leftPx:leftPx
                                 topPx:topPx
                            pixelWidth:pixelWidth
                           pixelHeight:pixelHeight];

        [self drawTrackSegmentsForGpxFile:gpxFile
                                     zoom:zoom
                                 tileSize:tileSize
                                   leftPx:leftPx
                                    topPx:topPx
                                  density:density
                               trackColor:trackColor];

        [self drawWaypointsForGpxFile:gpxFile
                                 zoom:zoom
                             tileSize:tileSize
                               leftPx:leftPx
                                topPx:topPx
                              density:density
                           trackColor:trackColor];
    }];

    return [UIImage imageWithCGImage:result.CGImage scale:density orientation:UIImageOrientationUp];
}

#pragma mark - Zoom

- (int)zoomLevelForBounds:(OASKQuadRect *)rect
                centerLat:(double)centerLat
                centerLon:(double)centerLon
               pixelWidth:(int)pixelWidth
              pixelHeight:(int)pixelHeight
                 tileSize:(uint32_t)tileSize
{
    auto boundsFitInViewport = [&](int zoom) -> bool {
        double centerPxX = OsmAnd::Utilities::getTileNumberX(zoom, centerLon) * tileSize;
        double centerPxY = OsmAnd::Utilities::getTileNumberY(zoom, centerLat) * tileSize;
        double leftPx = OsmAnd::Utilities::getTileNumberX(zoom, rect.left) * tileSize;
        double rightPx = OsmAnd::Utilities::getTileNumberX(zoom, rect.right) * tileSize;
        double topPx = OsmAnd::Utilities::getTileNumberY(zoom, rect.top) * tileSize;
        double bottomPx = OsmAnd::Utilities::getTileNumberY(zoom, rect.bottom) * tileSize;
        return leftPx >= centerPxX - pixelWidth / 2.0
            && rightPx <= centerPxX + pixelWidth / 2.0
            && topPx >= centerPxY - pixelHeight / 2.0
            && bottomPx <= centerPxY + pixelHeight / 2.0;
    };

    int zoom = kInitialZoom;
    while (zoom < kMaxZoom && boundsFitInViewport(zoom + 1))
        zoom++;
    while (zoom >= kMinZoom && !boundsFitInViewport(zoom))
        zoom--;
    return MAX(zoom, kMinZoom);
}

#pragma mark - Drawing

- (void)drawMapTilesWithProvider:(const std::shared_ptr<OsmAnd::MapRasterLayerProvider_Software> &)rasterProvider
                            zoom:(int)zoom
                        tileSize:(uint32_t)tileSize
                          leftPx:(double)leftPx
                           topPx:(double)topPx
                      pixelWidth:(int)pixelWidth
                     pixelHeight:(int)pixelHeight
{
    const int maxTile = (1 << zoom) - 1;
    const int txMin = MAX(0, (int)floor(leftPx / tileSize));
    const int txMax = MIN(maxTile, (int)floor((leftPx + pixelWidth) / tileSize));
    const int tyMin = MAX(0, (int)floor(topPx / tileSize));
    const int tyMax = MIN(maxTile, (int)floor((topPx + pixelHeight) / tileSize));

    std::shared_ptr<const OsmAnd::IQueryController> queryController;
    queryController.reset(new OsmAnd::FunctorQueryController([self](const OsmAnd::FunctorQueryController* const) {
        return [self isCancelled];
    }));

    for (int ty = tyMin; ty <= tyMax; ty++)
    {
        for (int tx = txMin; tx <= txMax; tx++)
        {
            if ([self isCancelled])
                return;

            OsmAnd::IMapTiledDataProvider::Request request;
            request.tileId = OsmAnd::TileId::fromXY(tx, ty);
            request.zoom = (OsmAnd::ZoomLevel)zoom;
            request.queryController = queryController;

            std::shared_ptr<OsmAnd::MapRasterLayerProvider::Data> data;
            if (!rasterProvider->obtainRasterizedTile(request, data) || !data || data->images.isEmpty())
                continue;

            const auto skImage = data->images.constBegin().value();
            UIImage *tileImage = [OANativeUtilities skImageToUIImage:skImage];
            if (!tileImage)
                continue;

            CGRect tileRect = CGRectMake(tx * (double)tileSize - leftPx,
                                         ty * (double)tileSize - topPx,
                                         tileSize, tileSize);
            [tileImage drawInRect:tileRect];
        }
    }
}

- (void)drawTrackSegmentsForGpxFile:(OASGpxFile *)gpxFile
                               zoom:(int)zoom
                           tileSize:(uint32_t)tileSize
                             leftPx:(double)leftPx
                              topPx:(double)topPx
                            density:(float)density
                         trackColor:(int)trackColor
{
    NSArray<OASTrkSegment *> *segments = [TrackPreviewColorHelper previewSegmentsFor:gpxFile];
    const CGFloat lineWidth = kTrackLineWidth * density;

    for (OASTrkSegment *segment in segments)
    {
        if ([self isCancelled])
            return;

        int segmentColor = [TrackPreviewColorHelper resolvedColorWithGpxFile:gpxFile
                                                                     segment:segment
                                                                defaultColor:trackColor];
        UIBezierPath *path = [self trackPathForSegment:segment
                                                  zoom:zoom
                                              tileSize:tileSize
                                                leftPx:leftPx
                                                 topPx:topPx
                                             lineWidth:lineWidth];
        if (!path)
            continue;

        [UIColorFromARGB(segmentColor) setStroke];
        [path stroke];
    }
}

- (UIBezierPath *)trackPathForSegment:(OASTrkSegment *)segment
                                 zoom:(int)zoom
                             tileSize:(uint32_t)tileSize
                               leftPx:(double)leftPx
                                topPx:(double)topPx
                            lineWidth:(CGFloat)lineWidth
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    path.lineWidth = lineWidth;
    path.lineJoinStyle = kCGLineJoinRound;
    path.lineCapStyle = kCGLineCapRound;

    BOOL hasPoints = NO;
    for (OASWptPt *point in segment.points)
    {
        CGPoint mappedPoint = [self mapPoint:point zoom:zoom tileSize:tileSize leftPx:leftPx topPx:topPx];
        if (!hasPoints)
        {
            [path moveToPoint:mappedPoint];
            hasPoints = YES;
        }
        else
        {
            [path addLineToPoint:mappedPoint];
        }
    }

    return hasPoints ? path : nil;
}

- (void)drawWaypointsForGpxFile:(OASGpxFile *)gpxFile
                           zoom:(int)zoom
                       tileSize:(uint32_t)tileSize
                         leftPx:(double)leftPx
                          topPx:(double)topPx
                        density:(float)density
                     trackColor:(int)trackColor
{
    int pointsColor = [TrackPreviewColorHelper resolvedColorWithGpxFile:gpxFile segment:nil defaultColor:trackColor];
    UIColor *waypointColor = UIColorFromARGB(pointsColor);
    const CGFloat radius = kWaypointRadius * density;

    for (OASWptPt *point in [gpxFile getPointsList])
    {
        if ([self isCancelled])
            return;

        CGPoint mappedPoint = [self mapPoint:point zoom:zoom tileSize:tileSize leftPx:leftPx topPx:topPx];
        CGRect circle = CGRectMake(mappedPoint.x - radius, mappedPoint.y - radius, radius * 2, radius * 2);
        UIBezierPath *dot = [UIBezierPath bezierPathWithOvalInRect:circle];
        [waypointColor setFill];
        [dot fill];
        [[UIColor whiteColor] setStroke];
        dot.lineWidth = kWaypointStrokeWidth * density;
        [dot stroke];
    }
}

- (CGPoint)mapPoint:(OASWptPt *)point
               zoom:(int)zoom
           tileSize:(uint32_t)tileSize
             leftPx:(double)leftPx
              topPx:(double)topPx
{
    return CGPointMake(
        OsmAnd::Utilities::getTileNumberX(zoom, point.lon) * tileSize - leftPx,
        OsmAnd::Utilities::getTileNumberY(zoom, point.lat) * tileSize - topPx
    );
}

@end
