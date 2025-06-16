//
//  OANetworkRouteSelectionLayer.mm
//  OsmAnd
//
//  Created by Max Kojin on 16/06/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OANetworkRouteSelectionLayer.h"
#import "OANetworkRouteDrawable.h"
#import "OAMapSelectionResult.h"
#import "OARouteKey.h"
#import "OAPointDescription.h"
#import "OANativeUtilities.h"
#import "OsmAnd_Maps-Swift.h"

@implementation OANetworkRouteSelectionLayer


#pragma mark - OAContextMenuProvider

- (CLLocation *) getObjectLocation:(id)obj
{
    if (obj && [obj isKindOfClass:NSArray.class])
    {
        NSArray *pair = obj;
        if (pair.count > 1 && [pair[0] isKindOfClass:OARouteKey.class] && [pair[1] isKindOfClass:OASKQuadRect.class])
        {
            OASKQuadRect *rect = pair[1];
            return [[CLLocation alloc] initWithLatitude:[rect centerY] longitude:[rect centerX]];
        }
    }
    return  nil;
}

- (OAPointDescription *) getObjectName:(id)obj
{
    if (obj && [obj isKindOfClass:NSArray.class])
    {
        NSArray *pair = obj;
        if (pair.count > 1 && [pair[0] isKindOfClass:OARouteKey.class] && [pair[1] isKindOfClass:OASKQuadRect.class])
        {
            OARouteKey *routeKey = pair[0];
            NSString *name = routeKey.routeKey.getRouteName().toNSString();
            return [[OAPointDescription alloc] initWithType:POINT_TYPE_ROUTE name:name];
        }
    }
    return  nil;
}

- (BOOL) showMenuAction:(id)object
{
    return NO;
}

//TODO: implement or delete?

//public boolean showMenuAction(@Nullable Object object) {
//    if (object instanceof Pair) {
//        Pair<?, ?> pair = (Pair<?, ?>) object;
//        if (pair.first instanceof RouteKey && pair.second instanceof QuadRect) {
//            Pair<RouteKey, QuadRect> routePair = (Pair<RouteKey, QuadRect>) pair;
//
//            LatLon latLon = getObjectLocation(object);
//            GpxFile gpxFile = routesCache.get(pair.first);
//            if (gpxFile == null) {
//                if (isSelectingRoute()) {
//                    cancelRouteSelection();
//                }
//                loadNetworkGpx(routePair, latLon);
//            } else {
//                saveAndOpenGpx(gpxFile, routePair, latLon);
//            }
//            return true;
//        }
//    }
//    return false;
//}

- (BOOL) runExclusiveAction:(id)obj unknownLocation:(BOOL)unknownLocation
{
    return NO;
}

- (void) collectObjectsFromPoint:(OAMapSelectionResult *)result unknownLocation:(BOOL)unknownLocation excludeUntouchableObjects:(BOOL)excludeUntouchableObjects
{
}

- (BOOL)isSecondaryProvider
{
    return NO;
}

- (OATargetPoint *) getTargetPoint:(id)obj
{
    if (obj && [obj isKindOfClass:NSArray.class])
    {
        NSArray *pair = obj;
        if (pair.count > 1 && [pair[0] isKindOfClass:OARouteKey.class] && [pair[1] isKindOfClass:OASKQuadRect.class])
        {
            OARouteKey *routeKey = pair[0];
            OASKQuadRect *rect = pair[1];
            
            OATargetPoint *point = [[OATargetPoint alloc] init];
            point.location = CLLocationCoordinate2DMake([rect centerY], [rect centerX]);
            point.type = OATargetNetworkGPX;
            point.targetObj = routeKey;
            OANetworkRouteDrawable *drawable = [[OANetworkRouteDrawable alloc] initWithRouteKey:routeKey];
            point.icon = drawable.getIcon;
            point.title = routeKey.routeKey.getRouteName().toNSString();
            
            OsmAnd::PointI topLeft31 = [OANativeUtilities getPoint31FromLatLon:OsmAnd::LatLon(rect.top, rect.left)];
            OsmAnd::PointI bottomRight31 = [OANativeUtilities getPoint31FromLatLon:OsmAnd::LatLon(rect.bottom, rect.right)];
            NSArray *areaPoints = @[@(topLeft31.x), @(topLeft31.y), @(bottomRight31.x), @(bottomRight31.y)];
            point.values = @{ @"area": areaPoints };

            point.sortIndex = (NSInteger)point.type;
            return point;
        }
    }
    return nil;
}

- (OATargetPoint *) getTargetPointCpp:(const void *)obj
{
    return nil;
}

@end
