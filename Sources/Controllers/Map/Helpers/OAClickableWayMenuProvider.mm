//
//  OAClickableWayMenuProvider.mm
//  OsmAnd
//
//  Created by Max Kojin on 11/06/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OAClickableWayMenuProvider.h"
#import "OAClickableWayAsyncTask.h"
#import "OASelectedGpxPoint.h"
#import "OASelectedMapObject.h"
#import "OAPointDescription.h"
#import "OsmAnd_Maps-Swift.h"

@implementation OAClickableWayMenuProvider

#pragma mark - OAContextMenuProvider

- (BOOL) showMenuAction:(id)object
{
    OASelectedMapObject *selectedMapObject = (OASelectedMapObject *)object;
    if ([[selectedMapObject object] isKindOfClass:OAClickableWay.class])
    {
        OAClickableWay *clickableWay = (OAClickableWay *)[selectedMapObject object];
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

//TODO: delete?
- (OATargetPoint *) getTargetPoint:(id)obj
{
    /*
    if ([obj isKindOfClass:[OAClickableWay class]])
    {
        OAClickableWay *clickableWay = (OAClickableWay *)obj;
        OASGpxFile *gpxFile = [clickableWay getGpxFile];
//        OASGpxTrackAnalysis *analysis [gpxFile getAnalysisFileTimestamp:0];
//        NSString *safeFileName = [clickableWay getGpxFile];
        
        
        
        //[gpxFile recalculateProcessPoint]; // ??
        
        OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
        targetPoint.type = OATargetGPX;
        
//        targetPoint.type = OATargetNetworkGPX; // ???
        
        targetPoint.targetObj = gpxFile;

        targetPoint.icon = [UIImage imageNamed:@"ic_custom_trip"];
        targetPoint.title = [clickableWay getWayName];

        targetPoint.sortIndex = (NSInteger)targetPoint.type;
        targetPoint.values = @{ @"opened_from_map": @YES };

        return targetPoint;
//
//        OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
//        targetPoint.location = CLLocationCoordinate2DMake(destination.latitude, destination.longitude);
//        targetPoint.title = destination.desc;
//        
//        targetPoint.icon = [UIImage imageNamed:destination.markerResourceName];
//        targetPoint.type = OATargetDestination;
//        
//        targetPoint.targetObj = destination;
//        
//        targetPoint.sortIndex = (NSInteger)targetPoint.type;
//        return targetPoint;
    }
     */
    return nil;
}

- (OATargetPoint *) getTargetPointCpp:(const void *)obj
{
    return nil;
}

@end
