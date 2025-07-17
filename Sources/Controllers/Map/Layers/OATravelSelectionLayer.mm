//
//  OATravelSelectionLayer.mm
//  OsmAnd
//
//  Created by Max Kojin on 17/07/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OATravelSelectionLayer.h"
#import "OAPointDescription.h"
#import "OsmAnd_Maps-Swift.h"

@implementation OATravelSelectionLayer

#pragma mark - OAContextMenuProvider

- (CLLocation *)getObjectLocation:(id)obj
{
    if ([obj isKindOfClass:SelectedMapObject.class])
    {
        SelectedMapObject *selectedObj = obj;
        obj = selectedObj.object;
    }
    if (obj && [obj isKindOfClass:NSArray.class])
    {
        NSArray *pair = obj;
        if (pair.count > 1 && [pair[0] isKindOfClass:OATravelGpx.class] && [pair[1] isKindOfClass:SelectedGpxPoint.class])
        {
            SelectedGpxPoint *selectedGpxPoint = pair[1];
            OASWptPt *selectedPoint = selectedGpxPoint.selectedPoint;
            return [[CLLocation alloc] initWithLatitude:selectedPoint.lat longitude:selectedPoint.lon];
        }
    }
    return  nil;
}

- (OAPointDescription *)getObjectName:(id)obj
{
    if (obj && [obj isKindOfClass:NSArray.class])
    {
        NSArray *pair = obj;
        if (pair.count > 1 && [pair[0] isKindOfClass:OATravelGpx.class] && [pair[1] isKindOfClass:SelectedGpxPoint.class])
        {
            OATravelGpx *travelGpx = pair[0];
            if (!NSStringIsEmpty(travelGpx.title))
                return [[OAPointDescription alloc] initWithType:POINT_TYPE_GPX name:travelGpx.title];
            else if (!NSStringIsEmpty(travelGpx.descr))
                return [[OAPointDescription alloc] initWithType:POINT_TYPE_GPX name:travelGpx.descr];
            else
                return [[OAPointDescription alloc] initWithType:POINT_TYPE_GPX name:travelGpx.routeId];
        }
    }
    return  nil;
}

- (BOOL)showMenuAction:(id)object
{
    if ([object isKindOfClass:SelectedMapObject.class])
    {
        SelectedMapObject *obj = object;
        object = obj.object;
    }
    if (object && [object isKindOfClass:NSArray.class])
    {
        NSArray *pair = object;
        if (pair.count > 1 && [pair[0] isKindOfClass:OATravelGpx.class] && [pair[1] isKindOfClass:SelectedGpxPoint.class])
        {
            OATravelGpx *travelGpx = pair[0];
            SelectedGpxPoint *selectedGpxPoint = pair[1];
            
            OASWptPt * wptPt = selectedGpxPoint.selectedPoint;
            CLLocation *latLon = [[CLLocation alloc] initWithLatitude:wptPt.lat longitude:wptPt.lon];
            
            [OATravelObfHelper.shared openTrackMenuWithArticle:travelGpx gpxFileName:[travelGpx getGpxFileName] latLon:latLon adjustMapPosition:NO];
            return YES;
        }
    }
    return NO;
}

- (BOOL)runExclusiveAction:(id)obj unknownLocation:(BOOL)unknownLocation
{
    return NO;
}

- (int64_t)getSelectionPointOrder:(id)selectedObject
{
    return 0;
}

- (BOOL)isSecondaryProvider
{
    return NO;
}

- (OATargetPoint *)getTargetPoint:(id)obj
{
    if ([obj isKindOfClass:SelectedMapObject.class])
    {
        SelectedMapObject *selectedObj = obj;
        obj = selectedObj.object;
    }
    if (obj && [obj isKindOfClass:NSArray.class])
    {
        NSArray *pair = obj;
        if (pair.count > 1 && [pair[0] isKindOfClass:OATravelGpx.class] && [pair[1] isKindOfClass:SelectedGpxPoint.class])
        {
            OATravelGpx *travelGpx = pair[0];
            SelectedGpxPoint *selectedGpxPoint = pair[1];
            OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
            targetPoint.type = OATargetGPX;
            targetPoint.targetObj = travelGpx;
            targetPoint.location = CLLocationCoordinate2DMake(travelGpx.lat, travelGpx.lon);
            targetPoint.icon = [UIImage imageNamed:@"ic_custom_trip"];
            targetPoint.title = [travelGpx getGpxFileName];
            targetPoint.sortIndex = (NSInteger)targetPoint.type;
            return targetPoint;
        }
    }
    return nil;
}

- (OATargetPoint *)getTargetPointCpp:(const void *)obj
{
    return nil;
}

@end
