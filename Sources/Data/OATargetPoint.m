//
//  OATargetPoint.m
//  OsmAnd
//
//  Created by Alexey Kulish on 28/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OATargetPoint.h"
#import "OAPointDescription.h"
#import "OAUtilities.h"

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
            case OATargetTransportStop:
                return [[OAPointDescription alloc] initWithType:POINT_TYPE_TRANSPORT_STOP name:_title];
            case OATargetTransportRoute:
                return [[OAPointDescription alloc] initWithType:POINT_TYPE_TRANSPORT_ROUTE name:_title];

            default:
                return [[OAPointDescription alloc] initWithType:POINT_TYPE_LOCATION name:@""];
        }
    }
    return _pd;
}

- (BOOL) isEqual:(id)o
{
    if (self == o)
        return YES;
    if (!o || ![self isKindOfClass:[o class]])
        return NO;
    
    OATargetPoint *targetPoint = (OATargetPoint *) o;

    if (self.type != targetPoint.type)
        return NO;
    if (![OAUtilities isCoordEqual:self.location.latitude srcLon:self.location.longitude destLat:targetPoint.location.latitude destLon:targetPoint.location.longitude upToDigits:4])
        return NO;
    if (self.symbolId != targetPoint.symbolId)
        return NO;
    if (self.obfId != targetPoint.obfId)
        return NO;
    if (!self.targetObj && targetPoint.targetObj)
        return NO;
    if (self.targetObj && ![self.targetObj isEqual:targetPoint.targetObj])
        return NO;
    if (!self.symbolGroupId && targetPoint.symbolGroupId)
        return NO;
    if (self.symbolGroupId && ![self.symbolGroupId isEqualToString:targetPoint.symbolGroupId])
        return NO;

    return YES;
}

- (NSUInteger) hash
{
    NSUInteger result = self.type ? self.type : 0; 
    result = 31 * result + [@(self.location.latitude) hash];
    result = 31 * result + [@(self.location.longitude) hash];
    result = 31 * result + self.symbolId;
    return result;
}

@end
