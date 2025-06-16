//
//  OANetworkRouteSelectionLayer.mm
//  OsmAnd
//
//  Created by Max Kojin on 16/06/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OANetworkRouteSelectionLayer.h"
#import "OANetworkRouteDrawable.h"
#import "OANetworkRouteSelectionTask.h"
#import "OAMapSelectionResult.h"
#import "OARouteKey.h"
#import "OAPointDescription.h"
#import "OANativeUtilities.h"
#import "OAGPXUIHelper.h"
#import "OsmAnd_Maps-Swift.h"

@implementation OANetworkRouteSelectionLayer
{
    NSMutableDictionary<OARouteKey *, OASGpxFile *> *_routesCache;
    OANetworkRouteSelectionTask *_selectionTask;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _routesCache = [NSMutableDictionary new];
    }
    return self;
}

- (void) loadNetworkGpx:(NSArray *)pair lat:(double)lat lon:(double)lon
{
    __weak OANetworkRouteSelectionLayer *weakSelf = self;
    
    if (pair.count > 1 && [pair[0] isKindOfClass:OARouteKey.class] && [pair[1] isKindOfClass:OASKQuadRect.class])
    {
        OARouteKey *routeKey = pair[0];
        OASKQuadRect *rect = pair[1];
        OsmAnd::PointI topLeft31 = [OANativeUtilities getPoint31FromLatLon:OsmAnd::LatLon(rect.top, rect.left)];
        OsmAnd::PointI bottomRight31 = [OANativeUtilities getPoint31FromLatLon:OsmAnd::LatLon(rect.bottom, rect.right)];
        NSArray *areaPoints = @[@(topLeft31.x), @(topLeft31.y), @(bottomRight31.x), @(bottomRight31.y)];
        
        [OARootViewController.instance.mapPanel showProgress];
        
        _selectionTask = [[OANetworkRouteSelectionTask alloc] initWithRouteKey:routeKey area:areaPoints];
        [_selectionTask execute:^(OASGpxFile *gpxFile) {
            
            [OARootViewController.instance.mapPanel hideProgress];
            if (!gpxFile)
                return;
            
            [weakSelf saveToCache:gpxFile routeKey:routeKey];
            [weakSelf saveAndOpenGpx:gpxFile pair:pair lat:lat lon:lon];
        }];
    }
}

- (void) saveAndOpenGpx:(OASGpxFile *)gpxFile pair:(NSArray *)pair lat:(double)lat lon:(double)lon
{
    if (pair.count > 1 && [pair[0] isKindOfClass:OARouteKey.class] && [pair[1] isKindOfClass:OASKQuadRect.class])
    {
        OARouteKey *routeKey = pair[0];
        
        OASWptPt *wptPt = [[OASWptPt alloc] initWithLat:lat lon:lon];
        NSString *name = [self getObjectName:pair].name;
        name = name.length > 0 ? name : OALocalizedString(@"layer_route");
        name = [name hasSuffix:GPX_FILE_EXT] ? name : [name stringByAppendingString:GPX_FILE_EXT];
        NSString *fileName = [OAUtilities convertToPermittedFileName:name];
        
        [OAGPXUIHelper saveAndOpenGpx:name filepath:fileName gpxFile:gpxFile selectedPoint:wptPt analysis:nil routeKey:routeKey];
    }
}

- (BOOL) isSelectingRoute
{
    return _selectionTask;
}

- (void) cancelRouteSelection
{
    [_selectionTask setCancelled:YES];
    _selectionTask = nil;
}

- (void) onCancelNetworkGPX
{
    [self cancelRouteSelection];
    [OARootViewController.instance.mapPanel hideProgress];
}



- (void) saveToCache:(OASGpxFile *)gpxFile routeKey:(OARouteKey *)routeKey
{
    //TODO: fix
//    _routesCache[routeKey] = gpxFile;
}


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
    if (object && [object isKindOfClass:NSArray.class])
    {
        NSArray *pair = object;
        if (pair.count > 1 && [pair[0] isKindOfClass:OARouteKey.class] && [pair[1] isKindOfClass:OASKQuadRect.class])
        {
            CLLocation *latLon = [self getObjectLocation:object];
            OASGpxFile *gpxFile = _routesCache[pair[0]];
            
            if (!gpxFile)
            {
                if ([self isSelectingRoute])
                    [self cancelRouteSelection];
                
                [self loadNetworkGpx:object lat:latLon.coordinate.latitude lon:latLon.coordinate.longitude];
            }
            else
            {
                [self saveAndOpenGpx:gpxFile pair:object lat:latLon.coordinate.latitude lon:latLon.coordinate.longitude];
            }
            return YES;
        }
    }
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
