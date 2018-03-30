//
//  OALocationPointWrapper.m
//  OsmAnd
//
//  Created by Alexey Kulish on 22/12/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OALocationPointWrapper.h"
#import "OALocationPoint.h"
#import "OARouteCalculationResult.h"
#import "OAWaypointHelper.h"
#import "OAAmenityLocationPoint.h"
#import "OAPOI.h"
#import "OARTargetPoint.h"
#import "OATargetPointsHelper.h"
#import "OAAppSettings.h"
#import "OADefaultFavorite.h"
#import "OAAlarmInfo.h"
#import "OAUtilities.h"

@implementation OALocationPointWrapper

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _announce = YES;
    }
    return self;
}

- (instancetype) initWithRouteCalculationResult:(OARouteCalculationResult *)rt type:(int)type point:(id<OALocationPoint>)point deviationDistance:(float)deviationDistance routeIndex:(int)routeIndex
{
    self = [super init];
    if (self)
    {
        _announce = YES;
        
        _route = rt;
        _type = type;
        _point = point;
        _deviationDistance = deviationDistance;
        _routeIndex = routeIndex;
    }
    return self;
}

- (UIImage *) getImage:(BOOL)nightMode
{
    if (_type == LPW_POI)
    {
        OAPOI *amenity = ((OAAmenityLocationPoint *) _point).poi;
        OAPOIType *st = amenity.type;
        if (st)
            return st.icon;

        return nil;
    }
    else if (_type == LPW_TARGETS)
    {
        if (((OARTargetPoint *) _point).start)
        {
            if (![[OATargetPointsHelper sharedInstance] getPointToStart])
                return [UIImage imageNamed:[OAApplicationMode DEFAULT].locationIconDay];
            else
                return [UIImage imageNamed:@"ic_list_startpoint"];
        }
        else if (((OARTargetPoint *) _point).intermediate)
        {
            return [UIImage imageNamed:@"list_intermediate"]; // todo no image: R.drawable.list_intermediate
        }
        else
        {
            return [UIImage imageNamed:@"ic_list_destination"];
        }
        
    }
    else if (_type == LPW_FAVORITES || _type == LPW_WAYPOINTS)
    {
        OAFavoriteColor *favCol = [OADefaultFavorite nearestFavColor:[_point getColor]];
        return favCol.icon;
    }
    else if (_type == LPW_ALARMS)
    {
        EOADrivingRegion drivingRegion = [OAAppSettings sharedManager].drivingRegion;
        OAAlarmInfo *alarm = (OAAlarmInfo *) _point;
        EOAAlarmInfoType type = alarm.type;
        //assign alarm list icons manually for now
        if (type == AIT_SPEED_CAMERA)
        {
            return [OAUtilities getMxIcon:@"highway_speed_camera"];
        }
        else if (type == AIT_BORDER_CONTROL)
        {
            return [OAUtilities getMxIcon:@"barrier_border_control"];
        }
        else if (type == AIT_RAILWAY)
        {
            if ([OADrivingRegion isAmericanSigns:drivingRegion])
                return [UIImage imageNamed:@"list_warnings_railways_us"];
            else
                return [UIImage imageNamed:@"list_warnings_railways"];
        }
        else if (type == AIT_TRAFFIC_CALMING)
        {
            if ([OADrivingRegion isAmericanSigns:drivingRegion])
                return [UIImage imageNamed:@"list_warnings_traffic_calming_us"];
            else
                return [UIImage imageNamed:@"list_warnings_traffic_calming"];
        }
        else if (type == AIT_TOLL_BOOTH)
        {
            return [OAUtilities getMxIcon:@"toll_booth"];
        }
        else if (type == AIT_STOP)
        {
            return [UIImage imageNamed:@"list_stop"];
        }
        else if (type == AIT_PEDESTRIAN)
        {
            if ([OADrivingRegion isAmericanSigns:drivingRegion])
                return [UIImage imageNamed:@"list_warnings_pedestrian_us"];
            else
                return [UIImage imageNamed:@"list_warnings_pedestrian"];
        }
        else
        {
            return nil;
        }
    }
    else
    {
        return nil;
    }
}

- (NSUInteger) hash
{
    return !_point ? 0 : [_point hash];
}

- (BOOL) isEqual:(id)obj
{
    if (self == obj)
        return YES;
    
    if (!obj)
        return NO;
    
    if (![self isKindOfClass:[obj class]])
        return NO;
    
    OALocationPointWrapper *other = (OALocationPointWrapper *) obj;
    if (!_point)
    {
        if (other.point)
            return NO;
    }
    else if (![_point isEqual:other.point])
    {
        return NO;
    }
    return YES;
}

@end
