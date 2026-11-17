#if DEBUG
#import "OAMeasurementToolLayer+UITesting.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OAMapLayers.h"
#import "OAMapRendererView.h"
#import "OAMeasurementEditingContext.h"
#import "OsmAndSharedWrapper.h"
#import "OsmAnd_Maps-Swift.h"

#include <OsmAndCore/Map/VectorLine.h>
#include <OsmAndCore/Map/VectorLinesCollection.h>

@interface OAMeasurementToolLayer ()

- (std::shared_ptr<const OsmAnd::VectorLinesCollection>)routeLineCollectionForUITesting;
- (std::shared_ptr<const OsmAnd::VectorLinesCollection>)previewLineCollectionForUITesting;

@end

@implementation OAMeasurementToolLayer (UITesting)

+ (nullable NSDictionary<NSString *, id> *)currentRouteStateForUITesting
{
    if (!UITestState.isPlanRouteHistoryEnabled)
        return nil;
    OAMeasurementToolLayer *layer = OARootViewController.instance.mapPanel.mapViewController.mapLayers.routePlanningLayer;
    if (!layer)
        return nil;
    NSMutableArray *points = [NSMutableArray array];
    for (OASWptPt *point in layer.editingCtx.getAllPoints)
    {
        auto position = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(point.lat, point.lon));
        CGPoint screenPoint;
        id screenPosition = NSNull.null;
        if ([layer.mapView convert:&position toScreen:&screenPoint])
        {
            CGPoint windowPoint = [layer.mapView convertPoint:screenPoint toView:nil];
            screenPosition = @[@(windowPoint.x), @(windowPoint.y)];
        }
        [points addObject:@{
            @"position": @[@(position.x), @(position.y)],
            @"name": point.name ?: @"",
            @"screenPosition": screenPosition,
            @"gap": @(point.isGap)
        }];
    }
    const auto snapshotLines = [](const std::shared_ptr<const OsmAnd::VectorLinesCollection> &collection) {
        NSMutableArray *lines = [NSMutableArray array];
        if (collection)
        {
            for (const auto &line : collection->getLines())
            {
                NSMutableArray *positions = [NSMutableArray array];
                for (const auto &position : line->getPoints())
                    [positions addObject:@[@(position.x), @(position.y)]];
                const auto color = line->getFillColor();
                [lines addObject:@{
                    @"id": @(line->lineId),
                    @"positions": positions,
                    @"color": @[@(color.a), @(color.r), @(color.g), @(color.b)]
                }];
            }
        }
        [lines sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"id" ascending:YES]]];
        return lines;
    };
    OAMapRendererView *mapView = layer.mapViewController.mapView;
    OsmAnd::PointI crosshair;
    if (!CGPointEqualToPoint(layer.cursorScreenPoint, CGPointZero))
    {
        CGFloat scale = mapView.contentScaleFactor;
        CGPoint pixel = CGPointMake(layer.cursorScreenPoint.x * scale, layer.cursorScreenPoint.y * scale);
        [mapView convert:pixel toLocation:&crosshair];
    }
    else
    {
        const auto centerPixel = mapView.getCenterPixel;
        [mapView convert:CGPointMake(centerPixel.x, centerPixel.y) toLocation:&crosshair];
    }
    const auto target = layer.mapView.target31;
    return @{
        @"points": points,
        @"lines": snapshotLines([layer routeLineCollectionForUITesting]),
        @"lastLines": snapshotLines([layer previewLineCollectionForUITesting]),
        @"crosshair": @[@(crosshair.x), @(crosshair.y)],
        @"viewport": @{@"target": @[@(target.x), @(target.y)], @"zoom": @(layer.mapView.zoom)}
    };
}

@end
#endif
