//
//  OAObjectType.m
//  OsmAnd
//
//  Created by Alexey Kulish on 11/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAObjectType.h"

@interface OAObjectType()

@property (nonatomic) EOAObjectType type;

@end

@implementation OAObjectType

+ (instancetype)withType:(EOAObjectType)type
{
    OAObjectType *obj = [[OAObjectType alloc] init];
    if (obj)
    {
        obj.type = type;
    }
    return obj;
}

+ (BOOL) hasLocation:(EOAObjectType)objecType
{
    switch (objecType)
    {
        case CITY:
        case VILLAGE:
        case POSTCODE:
        case STREET:
        case HOUSE:
        case STREET_INTERSECTION:
            return YES;
            
        case POI_TYPE:
            return NO;
            
        case POI:
            return YES;
            
        case LOCATION:
            return YES;
            
        case PARTIAL_LOCATION:
            return NO;
            
        case FAVORITE:
        case WPT:
        case RECENT_OBJ:
            return YES;
        case FAVORITE_GROUP:
            return NO;
            
        case REGION:
            return YES;

        case SEARCH_STARTED:
        case SEARCH_FINISHED:
        case FILTER_FINISHED:
        case SEARCH_API_FINISHED:
        case SEARCH_API_REGION_FINISHED:
        case UNKNOWN_NAME_FILTER:
            return NO;
            
        default:
            return NO;
    }
}

+ (BOOL) isAddress:(EOAObjectType)objecType
{
    return objecType == CITY || objecType == VILLAGE || objecType == POSTCODE || objecType == STREET || objecType == HOUSE || objecType == STREET_INTERSECTION;
}

+ (BOOL) isTopVisible:(EOAObjectType)objecType
{
    return objecType == POI_TYPE || objecType == FAVORITE || objecType == FAVORITE_GROUP || objecType == WPT || objecType == LOCATION || objecType == PARTIAL_LOCATION;
}

+ (NSString *) toString:(EOAObjectType)objecType
{
    switch (objecType)
    {
        case CITY:
            return @"CITY";
        case VILLAGE:
            return @"VILLAGE";
        case POSTCODE:
            return @"POSTCODE";
        case STREET:
            return @"STREET";
        case HOUSE:
            return @"HOUSE";
        case STREET_INTERSECTION:
            return @"STREET_INTERSECTION";
        case POI_TYPE:
            return @"POI_TYPE";
        case POI:
            return @"POI";
        case LOCATION:
            return @"LOCATION";
        case PARTIAL_LOCATION:
            return @"PARTIAL_LOCATION";
        case FAVORITE:
            return @"FAVORITE";
        case FAVORITE_GROUP:
            return @"FAVORITE_GROUP";
        case WPT:
            return @"WPT";
        case RECENT_OBJ:
            return @"RECENT_OBJ";
        case REGION:
            return @"REGION";
        case SEARCH_STARTED:
            return @"SEARCH_STARTED";
        case SEARCH_FINISHED:
            return @"SEARCH_FINISHED";
        case FILTER_FINISHED:
            return @"FILTER_FINISHED";
        case SEARCH_API_FINISHED:
            return @"SEARCH_API_FINISHED";
        case SEARCH_API_REGION_FINISHED:
            return @"SEARCH_API_REGION_FINISHED";
        case UNKNOWN_NAME_FILTER:
            return @"UNKNOWN_NAME_FILTER";
            
        default:
            return [NSString stringWithFormat:@"%d", (int)objecType];
    }
}

+ (OAObjectType *) getExclusiveSearchType:(EOAObjectType)objectType
{
    if (objectType == FAVORITE_GROUP)
    {
        return [OAObjectType withType:FAVORITE];
    }
    return nil;
}

+ (double) getTypeWeight:(EOAObjectType)objectType
{
    switch (objectType)
    {
        case HOUSE:
        case STREET_INTERSECTION:
            return 4.0;
        case STREET:
            return 3.0;
        case CITY:
        case VILLAGE:
        case POSTCODE:
            return 2.0;
        case POI:
            return 1.0;
        default:
            return 1.0;
    }
}

+ (OAObjectType *)valueOf:(NSString *)type
{
    if ([type isEqualToString:@"CITY"])
        return [OAObjectType withType:CITY];
    if ([type isEqualToString:@"VILLAGE"])
        return [OAObjectType withType:VILLAGE];
    if ([type isEqualToString:@"POSTCODE"])
        return [OAObjectType withType:POSTCODE];
    if ([type isEqualToString:@"STREET"])
        return [OAObjectType withType:STREET];
    if ([type isEqualToString:@"HOUSE"])
        return [OAObjectType withType:HOUSE];
    if ([type isEqualToString:@"STREET_INTERSECTION"])
        return [OAObjectType withType:STREET_INTERSECTION];
    if ([type isEqualToString:@"POI_TYPE"])
        return [OAObjectType withType:POI_TYPE];
    if ([type isEqualToString:@"POI"])
        return [OAObjectType withType:POI];
    if ([type isEqualToString:@"LOCATION"])
        return [OAObjectType withType:LOCATION];
    if ([type isEqualToString:@"PARTIAL_LOCATION"])
        return [OAObjectType withType:PARTIAL_LOCATION];
    if ([type isEqualToString:@"FAVORITE"])
        return [OAObjectType withType:FAVORITE];
    if ([type isEqualToString:@"FAVORITE_GROUP"])
        return [OAObjectType withType:FAVORITE_GROUP];
    if ([type isEqualToString:@"WPT"])
        return [OAObjectType withType:WPT];
    if ([type isEqualToString:@"RECENT_OBJ"])
        return [OAObjectType withType:RECENT_OBJ];
    if ([type isEqualToString:@"REGION"])
        return [OAObjectType withType:REGION];
    if ([type isEqualToString:@"SEARCH_STARTED"])
        return [OAObjectType withType:SEARCH_STARTED];
    if ([type isEqualToString:@"SEARCH_FINISHED"])
        return [OAObjectType withType:SEARCH_FINISHED];
    if ([type isEqualToString:@"FILTER_FINISHED"])
        return [OAObjectType withType:FILTER_FINISHED];
    if ([type isEqualToString:@"SEARCH_API_FINISHED"])
        return [OAObjectType withType:SEARCH_API_FINISHED];
    if ([type isEqualToString:@"SEARCH_API_REGION_FINISHED"])
        return [OAObjectType withType:SEARCH_API_REGION_FINISHED];
    if ([type isEqualToString:@"UNKNOWN_NAME_FILTER"])
        return [OAObjectType withType:UNKNOWN_NAME_FILTER];
    
    return [OAObjectType withType:CITY];
}

@end
