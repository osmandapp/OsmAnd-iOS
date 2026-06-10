//
//  OATrackPreviewMapRenderer.m
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

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/MapPrimitivesProvider.h>
#include <OsmAndCore/Map/MapRasterLayerProvider_Software.h>
#include <OsmAndCore/Map/IMapTiledDataProvider.h>
#include <OsmAndCore/FunctorQueryController.h>

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

    __weak OATrackPreviewMapRenderer *weakSelf = self;
    dispatch_async(_queue, ^{
        __strong OATrackPreviewMapRenderer *strongSelf = weakSelf;
        if (!strongSelf || strongSelf->_cancelled)
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
            completion(strongSelf->_cancelled ? nil : image);
        });
    });
}

- (UIImage *)renderImageWithProvider:(const std::shared_ptr<OsmAnd::MapPrimitivesProvider> &)primitivesProvider
                             gpxFile:(OASGpxFile *)gpxFile
                             widthPx:(NSInteger)widthPx
                            heightPx:(NSInteger)heightPx
                             density:(float)density
                          trackColor:(int)trackColor
{
    OASKQuadRect *rect = [gpxFile getRect];
    if (rect.left == 0 && rect.right == 0 && rect.top == 0 && rect.bottom == 0)
        return nil;

    const double centerLat = (rect.top + rect.bottom) / 2.0;
    const double centerLon = (rect.left + rect.right) / 2.0;

    const int pxWidth = (int)round(widthPx * density);
    const int pxHeight = (int)round(heightPx * density);

    const auto rasterProvider = std::make_shared<OsmAnd::MapRasterLayerProvider_Software>(primitivesProvider, true, false, true);
    const uint32_t tileSize = rasterProvider->getTileSize();

    std::shared_ptr<const OsmAnd::IQueryController> queryController;
    queryController.reset(new OsmAnd::FunctorQueryController([self](const OsmAnd::FunctorQueryController* const) {
        return (bool)self->_cancelled;
    }));

    auto contains = [&](int zoom) -> bool {
        double cx = OsmAnd::Utilities::getTileNumberX(zoom, centerLon) * tileSize;
        double cy = OsmAnd::Utilities::getTileNumberY(zoom, centerLat) * tileSize;
        double l = OsmAnd::Utilities::getTileNumberX(zoom, rect.left) * tileSize;
        double r = OsmAnd::Utilities::getTileNumberX(zoom, rect.right) * tileSize;
        double t = OsmAnd::Utilities::getTileNumberY(zoom, rect.top) * tileSize;
        double b = OsmAnd::Utilities::getTileNumberY(zoom, rect.bottom) * tileSize;
        return l >= cx - pxWidth / 2.0 && r <= cx + pxWidth / 2.0
            && t >= cy - pxHeight / 2.0 && b <= cy + pxHeight / 2.0;
    };

    int zoom = 15;
    while (zoom < 17 && contains(zoom + 1))
        zoom++;
    while (zoom >= 7 && !contains(zoom))
        zoom--;
    zoom = MAX(zoom, 7);

    const double centerPxX = OsmAnd::Utilities::getTileNumberX(zoom, centerLon) * tileSize;
    const double centerPxY = OsmAnd::Utilities::getTileNumberY(zoom, centerLat) * tileSize;
    const double leftPx = centerPxX - pxWidth / 2.0;
    const double topPx = centerPxY - pxHeight / 2.0;

    const int maxTile = (1 << zoom) - 1;
    const int txMin = MAX(0, (int)floor(leftPx / tileSize));
    const int txMax = MIN(maxTile, (int)floor((leftPx + pxWidth) / tileSize));
    const int tyMin = MAX(0, (int)floor(topPx / tileSize));
    const int tyMax = MIN(maxTile, (int)floor((topPx + pxHeight) / tileSize));

    UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat preferredFormat];
    format.scale = 1;
    format.opaque = YES;
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(pxWidth, pxHeight) format:format];

    UIImage *result = [renderer imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
        [[UIColor whiteColor] setFill];
        [ctx fillRect:CGRectMake(0, 0, pxWidth, pxHeight)];

        for (int ty = tyMin; ty <= tyMax; ty++)
        {
            for (int tx = txMin; tx <= txMax; tx++)
            {
                if (self->_cancelled)
                    return;
                
                OsmAnd::IMapTiledDataProvider::Request request;
                request.tileId = OsmAnd::TileId::fromXY(tx, ty);
                request.zoom = (OsmAnd::ZoomLevel)zoom;
                request.queryController = queryController;
                
                std::shared_ptr<OsmAnd::MapRasterLayerProvider::Data> data;
                if (rasterProvider->obtainRasterizedTile(request, data) && data && !data->images.isEmpty())
                {
                    const auto skImage = data->images.constBegin().value();
                    UIImage *tileImage = [OANativeUtilities skImageToUIImage:skImage];
                    if (tileImage)
                    {
                        CGRect tileRect = CGRectMake(tx * (double)tileSize - leftPx,
                                                     ty * (double)tileSize - topPx,
                                                     tileSize, tileSize);
                        [tileImage drawInRect:tileRect];
                    }
                }
            }
        }

        UIColor *lineColor = [self colorFromARGB:trackColor];
        UIBezierPath *path = [UIBezierPath bezierPath];
        path.lineWidth = 4.0 * density;
        path.lineJoinStyle = kCGLineJoinRound;
        path.lineCapStyle = kCGLineCapRound;

        for (OASTrack *track in gpxFile.tracks)
        {
            for (OASTrkSegment *segment in track.segments)
            {
                BOOL first = YES;
                for (OASWptPt *point in segment.points)
                {
                    CGPoint p = CGPointMake(
                        OsmAnd::Utilities::getTileNumberX(zoom, point.lon) * tileSize - leftPx,
                        OsmAnd::Utilities::getTileNumberY(zoom, point.lat) * tileSize - topPx);
                    if (first)
                    {
                        [path moveToPoint:p];
                        first = NO;
                    }
                    else
                    {
                        [path addLineToPoint:p];
                    }
                }
            }
        }
        [lineColor setStroke];
        [path stroke];

        const CGFloat radius = 5.0 * density;
        for (OASWptPt *point in [gpxFile getPointsList])
        {
            CGPoint p = CGPointMake(
                OsmAnd::Utilities::getTileNumberX(zoom, point.lon) * tileSize - leftPx,
                OsmAnd::Utilities::getTileNumberY(zoom, point.lat) * tileSize - topPx);
            CGRect circle = CGRectMake(p.x - radius, p.y - radius, radius * 2, radius * 2);
            UIBezierPath *dot = [UIBezierPath bezierPathWithOvalInRect:circle];
            [lineColor setFill];
            [dot fill];
            [[UIColor whiteColor] setStroke];
            dot.lineWidth = 1.5 * density;
            [dot stroke];
        }
    }];

    return [UIImage imageWithCGImage:result.CGImage scale:density orientation:UIImageOrientationUp];
}

- (UIColor *)colorFromARGB:(int)argb
{
    CGFloat a = ((argb >> 24) & 0xFF) / 255.0;
    return [UIColor colorWithRed:((argb >> 16) & 0xFF) / 255.0
                           green:((argb >> 8) & 0xFF) / 255.0
                            blue:(argb & 0xFF) / 255.0
                           alpha:a > 0 ? a : 1.0];
}

@end
