//
//  OAClickableWayMenuProvider.mm
//  OsmAnd
//
//  Created by Max Kojin on 11/06/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OAClickableWayMenuProvider.h"
#import "OAPointDescription.h"
#import "OsmAnd_Maps-Swift.h"

@implementation OAClickableWayMenuProvider

#pragma mark - OAContextMenuProvider

- (BOOL) showMenuAction:(id)object
{
    OASelectedMapObject *selectedMapObject = (OASelectedMapObject *)object;
    if ([[selectedMapObject getObject] isKindOfClass:OAClickableWay.class])
    {
        OAClickableWay *clickableWay = (OAClickableWay *)[selectedMapObject getObject];
        OAClickableWayAsyncTask *task = [[OAClickableWayAsyncTask alloc] initWithClickableWay:clickableWay];
        [task execute];
        return YES;
    }
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

- (BOOL)isSecondaryProvider
{
    return NO;
}

- (CLLocation *) getObjectLocation:(id)obj
{
    if ([obj isKindOfClass:OAClickableWay.class])
    {
        OAClickableWay *clickableWay = (OAClickableWay *)obj;
        OASWptPt *wpt = [[clickableWay getSelectedGpxPoint] getSelectedPoint];
        return [[CLLocation alloc] initWithLatitude:[wpt getLatitude] longitude:[wpt getLongitude]];
    }
    return  nil;
}

- (OAPointDescription *) getObjectName:(id)obj
{
    if ([obj isKindOfClass:OAClickableWay.class])
    {
        OAClickableWay *clickableWay = (OAClickableWay *)obj;
        NSString *name = [clickableWay getWayName];
        return [[OAPointDescription alloc] initWithType:POINT_TYPE_GPX name:name];
    }
    return nil;
}

- (void) collectObjectsFromPoint:(OAMapSelectionResult *)result unknownLocation:(BOOL)unknownLocation excludeUntouchableObjects:(BOOL)excludeUntouchableObjects
{
    
}

- (OATargetPoint *) getTargetPoint:(id)obj
{
    return nil;
}

- (OATargetPoint *) getTargetPointCpp:(const void *)obj
{
    return nil;
}

@end
