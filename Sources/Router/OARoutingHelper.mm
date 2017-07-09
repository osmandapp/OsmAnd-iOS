//
//  OARoutingHelper.m
//  OsmAnd
//
//  Created by Alexey Kulish on 09/07/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OARoutingHelper.h"

@implementation OARoutingHelper

+ (NSString *) formatStreetName:(NSString *)name ref:(NSString *)ref destination:(NSString *)destination towards:(NSString *)towards
{
    //Hardy, 2016-08-05:
    //Now returns: (ref) + ((" ")+name) + ((" ")+"toward "+dest) or ""
    
    NSString *formattedStreetName = @"";
    if (ref && ref.length > 0)
        formattedStreetName = ref;
    
    if (name && name.length > 0)
    {
        if (formattedStreetName.length > 0)
            formattedStreetName = [formattedStreetName stringByAppendingString:@" "];
        
        formattedStreetName = [formattedStreetName stringByAppendingString:name];
    }
    if (destination && destination.length > 0)
    {
        if (formattedStreetName.length > 0)
            formattedStreetName = [formattedStreetName stringByAppendingString:@" "];
        
        formattedStreetName = [formattedStreetName stringByAppendingString:[NSString stringWithFormat:@"%@ %@",towards, destination]];
    }
    return [formattedStreetName stringByReplacingOccurrencesOfString:@";" withString:@", "];
}

@end
