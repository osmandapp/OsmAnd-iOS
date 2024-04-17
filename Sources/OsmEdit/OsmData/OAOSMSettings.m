//
//  OAOSMSettings.m
//  OsmAnd
//
//  Created by Paul on 1/22/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAOSMSettings.h"


@implementation OAOSMSettings

+(NSString *)getOSMKey:(EOAOsmTagKey)key
{
    return [self.class getNamesArray][key];
}

+(NSArray<NSString *> *) getNamesArray
{
    static NSArray<NSString *> *names;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        names = @[@"name", @"name:en", @"lock_name", @"highway", @"building", @"boundary", @"postal_code", @"railway", @"subway", @"oneway", @"layer", @"bridge", @"tunnel", @"toll", @"junction", @"route", @"route_master", @"brand", @"operator", @"ref", @"rcn_ref", @"rwn_ref", @"place", @"addr:housenumber", @"addr2:housenumber", @"addr:housename", @"addr:street", @"addr:street2", @"addr2:street", @"addr:city", @"addr:place", @"addr:postcode", @"addr:interpolation", @"address:type", @"address:house", @"type", @"is_in", @"locality", @"amenity", @"shop", @"landuse", @"office", @"emergency", @"military", @"administrative", @"man_made", @"barrier", @"leisure", @"tourism", @"sport", @"historic", @"natural", @"internet_access", @"contact:website", @"contact:phone", @"opening_hours", @"phone", @"description", @"website", @"url", @"wikipedia", @"admin_level", @"public_transport", @"entrance", @"colour", @"relation_id"];
    });
    return names;
}

@end
