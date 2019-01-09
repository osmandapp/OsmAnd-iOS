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

+ (OAObjectType *)getExclusiveSearchType:(EOAObjectType)objecType
{
    if (objecType == FAVORITE_GROUP)
    {
        return [OAObjectType withType:FAVORITE];
    }
    return nil;
}

@end
