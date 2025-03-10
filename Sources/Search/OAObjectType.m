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
        case EOAObjectTypeCity:
        case EOAObjectTypeVillage:
        case EOAObjectTypePostcode:
        case EOAObjectTypeStreet:
        case EOAObjectTypeHouse:
        case EOAObjectTypeStreetIntersection:
            return YES;
            
        case EOAObjectTypePoiType:
            return NO;
            
        case EOAObjectTypePoi:
            return YES;
            
        case EOAObjectTypeLocation:
            return YES;
            
        case EOAObjectTypePartialLocation:
            return NO;
            
        case EOAObjectTypeFavorite:
        case EOAObjectTypeWpt:
        case EOAObjectTypeRecentObj:
            return YES;
        case EOAObjectTypeFavoriteGroup:
            return NO;
            
        case EOAObjectTypeRegion:
            return YES;

        case EOAObjectTypeSearchStarted:
        case EOAObjectTypeSearchFinished:
        case EOAObjectTypeFilterFinished:
        case EOAObjectTypeSearchApiFinished:
        case EOAObjectTypeSearchApiRegionFinished:
        case EOAObjectTypeUnknownNameFilter:
            return NO;
            
        default:
            return NO;
    }
}

+ (BOOL) isAddress:(EOAObjectType)objecType
{
    return objecType == EOAObjectTypeCity || objecType == EOAObjectTypeVillage || objecType == EOAObjectTypePostcode || objecType == EOAObjectTypeStreet || objecType == EOAObjectTypeHouse || objecType == EOAObjectTypeStreetIntersection;
}

+ (BOOL) isTopVisible:(EOAObjectType)objecType
{
    return objecType == EOAObjectTypePoiType || objecType == EOAObjectTypeFavorite || objecType == EOAObjectTypeFavoriteGroup || objecType == EOAObjectTypeWpt || objecType == EOAObjectTypeGpxTrack || objecType == EOAObjectTypeLocation || objecType == EOAObjectTypePartialLocation;
}

+ (NSString *) toString:(EOAObjectType)objecType
{
    switch (objecType)
    {
        case EOAObjectTypeCity:
            return @"CITY";
        case EOAObjectTypeVillage:
            return @"VILLAGE";
        case EOAObjectTypePostcode:
            return @"POSTCODE";
        case EOAObjectTypeStreet:
            return @"STREET";
        case EOAObjectTypeHouse:
            return @"HOUSE";
        case EOAObjectTypeStreetIntersection:
            return @"STREET_INTERSECTION";
        case EOAObjectTypePoiType:
            return @"POI_TYPE";
        case EOAObjectTypePoi:
            return @"POI";
        case EOAObjectTypeLocation:
            return @"LOCATION";
        case EOAObjectTypePartialLocation:
            return @"PARTIAL_LOCATION";
        case EOAObjectTypeFavorite:
            return @"FAVORITE";
        case EOAObjectTypeFavoriteGroup:
            return @"FAVORITE_GROUP";
        case EOAObjectTypeWpt:
            return @"WPT";
        case EOAObjectTypeRecentObj:
            return @"RECENT_OBJ";
        case EOAObjectTypeRegion:
            return @"REGION";
        case EOAObjectTypeSearchStarted:
            return @"SEARCH_STARTED";
        case EOAObjectTypeSearchFinished:
            return @"SEARCH_FINISHED";
        case EOAObjectTypeFilterFinished:
            return @"FILTER_FINISHED";
        case EOAObjectTypeSearchApiFinished:
            return @"SEARCH_API_FINISHED";
        case EOAObjectTypeSearchApiRegionFinished:
            return @"SEARCH_API_REGION_FINISHED";
        case EOAObjectTypeUnknownNameFilter:
            return @"UNKNOWN_NAME_FILTER";
        case EOAObjectTypeGpxTrack:
            return @"GPX_TRACK";
            
        default:
            return [NSString stringWithFormat:@"%d", (int)objecType];
    }
}

+ (OAObjectType *) getExclusiveSearchType:(EOAObjectType)objectType
{
    if (objectType == EOAObjectTypeFavoriteGroup)
    {
        return [OAObjectType withType:EOAObjectTypeFavorite];
    }
    return nil;
}

+ (double) getTypeWeight:(EOAObjectType)objectType
{
    switch (objectType)
    {
        case EOAObjectTypeHouse:
        case EOAObjectTypeStreetIntersection:
            return 4.0;
        case EOAObjectTypeStreet:
            return 3.0;
        case EOAObjectTypeCity:
        case EOAObjectTypeVillage:
        case EOAObjectTypePostcode:
            return 2.0;
        case EOAObjectTypePoi:
            return 1.0;
        default:
            return 1.0;
    }
}

+ (OAObjectType *)valueOf:(NSString *)type
{
    if ([type isEqualToString:@"CITY"])
        return [OAObjectType withType:EOAObjectTypeCity];
    if ([type isEqualToString:@"VILLAGE"])
        return [OAObjectType withType:EOAObjectTypeVillage];
    if ([type isEqualToString:@"POSTCODE"])
        return [OAObjectType withType:EOAObjectTypePostcode];
    if ([type isEqualToString:@"STREET"])
        return [OAObjectType withType:EOAObjectTypeStreet];
    if ([type isEqualToString:@"HOUSE"])
        return [OAObjectType withType:EOAObjectTypeHouse];
    if ([type isEqualToString:@"STREET_INTERSECTION"])
        return [OAObjectType withType:EOAObjectTypeStreetIntersection];
    if ([type isEqualToString:@"POI_TYPE"])
        return [OAObjectType withType:EOAObjectTypePoiType];
    if ([type isEqualToString:@"POI"])
        return [OAObjectType withType:EOAObjectTypePoi];
    if ([type isEqualToString:@"LOCATION"])
        return [OAObjectType withType:EOAObjectTypeLocation];
    if ([type isEqualToString:@"PARTIAL_LOCATION"])
        return [OAObjectType withType:EOAObjectTypePartialLocation];
    if ([type isEqualToString:@"FAVORITE"])
        return [OAObjectType withType:EOAObjectTypeFavorite];
    if ([type isEqualToString:@"FAVORITE_GROUP"])
        return [OAObjectType withType:EOAObjectTypeFavoriteGroup];
    if ([type isEqualToString:@"WPT"])
        return [OAObjectType withType:EOAObjectTypeWpt];
    if ([type isEqualToString:@"RECENT_OBJ"])
        return [OAObjectType withType:EOAObjectTypeRecentObj];
    if ([type isEqualToString:@"REGION"])
        return [OAObjectType withType:EOAObjectTypeRegion];
    if ([type isEqualToString:@"SEARCH_STARTED"])
        return [OAObjectType withType:EOAObjectTypeSearchStarted];
    if ([type isEqualToString:@"SEARCH_FINISHED"])
        return [OAObjectType withType:EOAObjectTypeSearchFinished];
    if ([type isEqualToString:@"FILTER_FINISHED"])
        return [OAObjectType withType:EOAObjectTypeFilterFinished];
    if ([type isEqualToString:@"SEARCH_API_FINISHED"])
        return [OAObjectType withType:EOAObjectTypeSearchApiFinished];
    if ([type isEqualToString:@"SEARCH_API_REGION_FINISHED"])
        return [OAObjectType withType:EOAObjectTypeSearchApiRegionFinished];
    if ([type isEqualToString:@"UNKNOWN_NAME_FILTER"])
        return [OAObjectType withType:EOAObjectTypeUnknownNameFilter];
    
    return [OAObjectType withType:EOAObjectTypeCity];
}

@end
