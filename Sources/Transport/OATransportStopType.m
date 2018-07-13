//
//  OATransportStopType.m
//  OsmAnd
//
//  Created by Alexey on 11/07/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OATransportStopType.h"

@implementation OATransportStopType

- (instancetype) initWithType:(EOATransportStopType)type;
{
    self = [super init];
    if (self)
    {
        _type = type;
    }
    return self;
}

+ (NSString *) getResId:(EOATransportStopType)type
{
    switch (type)
    {
        case TST_BUS:
            return @"mx_route_bus_ref";
        case TST_FERRY:
            return @"mx_route_ferry_ref";
        case TST_FUNICULAR:
            return @"mx_route_funicular_ref";
        case TST_LIGHT_RAIL:
            return @"mx_route_light_rail_ref";
        case TST_MONORAIL:
            return @"mx_route_monorail_ref";
        case TST_RAILWAY:
            return @"mx_route_railway_ref";
        case TST_SHARE_TAXI:
            return @"mx_route_share_taxi_ref";
        case TST_TRAIN:
            return @"mx_route_train_ref";
        case TST_TRAM:
            return @"mx_route_tram_ref";
        case TST_TROLLEYBUS:
            return @"mx_route_trolleybus_ref";
        case TST_SUBWAY:
            return @"mx_subway_station";

        default:
            return @"";
    }
}

+ (NSString *) getTopResId:(EOATransportStopType)type
{
    switch (type)
    {
        case TST_BUS:
            return @"mx_route_bus_ref";
        case TST_FERRY:
            return @"mx_route_ferry_ref";
        case TST_FUNICULAR:
            return @"mx_route_funicular_ref";
        case TST_LIGHT_RAIL:
            return @"mx_route_light_rail_ref";
        case TST_MONORAIL:
            return @"mx_route_monorail_ref";
        case TST_RAILWAY:
            return @"mx_route_railway_ref";
        case TST_SHARE_TAXI:
            return @"mx_route_share_taxi_ref";
        case TST_TRAIN:
            return @"mx_route_train_ref";
        case TST_TRAM:
            return @"mx_railway_tram_stop";
        case TST_TROLLEYBUS:
            return @"mx_route_trolleybus_ref";
        case TST_SUBWAY:
            return @"mx_subway_station";
            
        default:
            return @"";
    }
}

+ (NSString *) getRenderAttr:(EOATransportStopType)type
{
    switch (type)
    {
        case TST_BUS:
            return @"routeBusColor";
        case TST_FERRY:
            return @"routeFerryColor";
        case TST_FUNICULAR:
            return @"routeFunicularColor";
        case TST_LIGHT_RAIL:
            return @"routeLightrailColor";
        case TST_MONORAIL:
            return @"routeLightrailColor";
        case TST_RAILWAY:
            return @"routeTrainColor";
        case TST_SHARE_TAXI:
            return @"routeShareTaxiColor";
        case TST_TRAIN:
            return @"routeTrainColor";
        case TST_TRAM:
            return @"routeTramColor";
        case TST_TROLLEYBUS:
            return @"routeTrolleybusColor";
        case TST_SUBWAY:
            return @"routeTrainColor";
            
        default:
            return @"";
    }
}

+ (NSString *) getResName:(EOATransportStopType)type
{
    switch (type)
    {
        case TST_BUS:
            return @"route_bus_ref";
        case TST_FERRY:
            return @"route_ferry_ref";
        case TST_FUNICULAR:
            return @"route_funicular_ref";
        case TST_LIGHT_RAIL:
            return @"route_light_rail_ref";
        case TST_MONORAIL:
            return @"route_monorail_ref";
        case TST_RAILWAY:
            return @"route_railway_ref";
        case TST_SHARE_TAXI:
            return @"route_share_taxi_ref";
        case TST_TRAIN:
            return @"route_train_ref";
        case TST_TRAM:
            return @"route_tram_ref";
        case TST_TROLLEYBUS:
            return @"route_trolleybus_ref";
        case TST_SUBWAY:
            return @"subway_station";
            
        default:
            return @"";
    }
}

+ (NSString *) getName:(EOATransportStopType)type
{
    switch (type)
    {
        case TST_BUS:
            return @"TST_BUS";
        case TST_FERRY:
            return @"TST_FERRY";
        case TST_FUNICULAR:
            return @"TST_FUNICULAR";
        case TST_LIGHT_RAIL:
            return @"TST_LIGHT_RAIL";
        case TST_MONORAIL:
            return @"TST_MONORAIL";
        case TST_RAILWAY:
            return @"TST_RAILWAY";
        case TST_SHARE_TAXI:
            return @"TST_SHARE_TAXI";
        case TST_TRAIN:
            return @"TST_TRAIN";
        case TST_TRAM:
            return @"TST_TRAM";
        case TST_TROLLEYBUS:
            return @"TST_TROLLEYBUS";
        case TST_SUBWAY:
            return @"TST_SUBWAY";
            
        default:
            return @"";
    }
}

+ (NSArray<NSNumber *> *) values
{
    return @[@(TST_BUS), @(TST_FERRY), @(TST_FUNICULAR), @(TST_LIGHT_RAIL), @(TST_MONORAIL), @(TST_RAILWAY), @(TST_SHARE_TAXI), @(TST_TRAIN), @(TST_TRAM), @(TST_TROLLEYBUS), @(TST_SUBWAY)];
}

+ (BOOL) isTopType:(EOATransportStopType)type
{
    return type == TST_TRAM || type == TST_SUBWAY;
}

+ (OATransportStopType *) findType:(NSString *)typeName
{
    NSString *tName = [typeName uppercaseString];
    for (NSNumber *tn in [self.class values])
    {
        if ([[self.class getName:tn.intValue] isEqualToString:tName])
            return [[OATransportStopType alloc] initWithType:tn.intValue];
    }
    return nil;
}

@end

