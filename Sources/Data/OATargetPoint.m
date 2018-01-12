//
//  OATargetPoint.m
//  OsmAnd
//
//  Created by Alexey Kulish on 28/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OATargetPoint.h"
#import "OAPointDescription.h"

@implementation OATargetPoint
{
    OAPointDescription *_pd;
}

- (OAPointDescription *) pointDescription
{
    if (!_pd)
    {
        switch (_type)
        {
            case OATargetNone:
            case OATargetLocation:
            case OATargetHistoryItem:
                return [[OAPointDescription alloc] initWithType:POINT_TYPE_LOCATION name:_title];
            case OATargetPOI:
            case OATargetWiki:
                return [[OAPointDescription alloc] initWithType:POINT_TYPE_POI name:_title];
            case OATargetDestination:
                return [[OAPointDescription alloc] initWithType:POINT_TYPE_MARKER name:_title];
            case OATargetFavorite:
                return [[OAPointDescription alloc] initWithType:POINT_TYPE_FAVORITE name:_title];
            case OATargetParking:
                return [[OAPointDescription alloc] initWithType:POINT_TYPE_PARKING_MARKER name:_title];
            case OATargetWpt:
                return [[OAPointDescription alloc] initWithType:POINT_TYPE_WPT name:_title];
            case OATargetGPX:
                return [[OAPointDescription alloc] initWithType:POINT_TYPE_GPX_ITEM name:_title];
            case OATargetGPXRoute:
                return [[OAPointDescription alloc] initWithType:POINT_TYPE_GPX_ITEM name:_title];
            case OATargetGPXEdit:
                return [[OAPointDescription alloc] initWithType:POINT_TYPE_GPX_ITEM name:_title];
            case OATargetAddress:
                return [[OAPointDescription alloc] initWithType:POINT_TYPE_ADDRESS name:_title];
            case OATargetTurn:
                return [[OAPointDescription alloc] initWithType:POINT_TYPE_TARGET name:_title];
            case OATargetRouteStart:
                return [[OAPointDescription alloc] initWithType:POINT_TYPE_TARGET name:_title];
            case OATargetRouteFinish:
                return [[OAPointDescription alloc] initWithType:POINT_TYPE_TARGET name:_title];
            case OATargetImpassableRoad:
                return [[OAPointDescription alloc] initWithType:POINT_TYPE_BLOCKED_ROAD name:_title];

            default:
                return [[OAPointDescription alloc] initWithType:POINT_TYPE_LOCATION name:@""];
        }
    }
    return _pd;
}

@end
