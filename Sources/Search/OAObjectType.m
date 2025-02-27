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
        case EOAObjectTypeCITY:
        case EOAObjectTypeVILLAGE:
        case EOAObjectTypePOSTCODE:
        case EOAObjectTypeSTREET:
        case EOAObjectTypeHOUSE:
        case EOAObjectTypeSTREET_INTERSECTION:
            return YES;
            
        case EOAObjectTypePOI_TYPE:
            return NO;
            
        case EOAObjectTypePOI:
            return YES;
            
        case EOAObjectTypeLOCATION:
            return YES;
            
        case EOAObjectTypePARTIAL_LOCATION:
            return NO;
            
        case EOAObjectTypeFAVORITE:
        case EOAObjectTypeWPT:
        case EOAObjectTypeRECENT_OBJ:
            return YES;
        case EOAObjectTypeFAVORITE_GROUP:
            return NO;
            
        case EOAObjectTypeREGION:
            return YES;

        case EOAObjectTypeSEARCH_STARTED:
        case EOAObjectTypeSEARCH_FINISHED:
        case EOAObjectTypeFILTER_FINISHED:
        case EOAObjectTypeSEARCH_API_FINISHED:
        case EOAObjectTypeSEARCH_API_REGION_FINISHED:
        case EOAObjectTypeUNKNOWN_NAME_FILTER:
            return NO;
            
        default:
            return NO;
    }
}

+ (BOOL) isAddress:(EOAObjectType)objecType
{
    return objecType == EOAObjectTypeCITY || objecType == EOAObjectTypeVILLAGE || objecType == EOAObjectTypePOSTCODE || objecType == EOAObjectTypeSTREET || objecType == EOAObjectTypeHOUSE || objecType == EOAObjectTypeSTREET_INTERSECTION;
}

+ (BOOL) isTopVisible:(EOAObjectType)objecType
{
    return objecType == EOAObjectTypePOI_TYPE || objecType == EOAObjectTypeFAVORITE || objecType == EOAObjectTypeFAVORITE_GROUP || objecType == EOAObjectTypeWPT || objecType == EOAObjectTypeGPX_TRACK || objecType == EOAObjectTypeLOCATION || objecType == EOAObjectTypePARTIAL_LOCATION;
}

+ (NSString *) toString:(EOAObjectType)objecType
{
    switch (objecType)
    {
        case EOAObjectTypeCITY:
            return @"CITY";
        case EOAObjectTypeVILLAGE:
            return @"VILLAGE";
        case EOAObjectTypePOSTCODE:
            return @"POSTCODE";
        case EOAObjectTypeSTREET:
            return @"STREET";
        case EOAObjectTypeHOUSE:
            return @"HOUSE";
        case EOAObjectTypeSTREET_INTERSECTION:
            return @"STREET_INTERSECTION";
        case EOAObjectTypePOI_TYPE:
            return @"POI_TYPE";
        case EOAObjectTypePOI:
            return @"POI";
        case EOAObjectTypeLOCATION:
            return @"LOCATION";
        case EOAObjectTypePARTIAL_LOCATION:
            return @"PARTIAL_LOCATION";
        case EOAObjectTypeFAVORITE:
            return @"FAVORITE";
        case EOAObjectTypeFAVORITE_GROUP:
            return @"FAVORITE_GROUP";
        case EOAObjectTypeWPT:
            return @"WPT";
        case EOAObjectTypeRECENT_OBJ:
            return @"RECENT_OBJ";
        case EOAObjectTypeREGION:
            return @"REGION";
        case EOAObjectTypeSEARCH_STARTED:
            return @"SEARCH_STARTED";
        case EOAObjectTypeSEARCH_FINISHED:
            return @"SEARCH_FINISHED";
        case EOAObjectTypeFILTER_FINISHED:
            return @"FILTER_FINISHED";
        case EOAObjectTypeSEARCH_API_FINISHED:
            return @"SEARCH_API_FINISHED";
        case EOAObjectTypeSEARCH_API_REGION_FINISHED:
            return @"SEARCH_API_REGION_FINISHED";
        case EOAObjectTypeUNKNOWN_NAME_FILTER:
            return @"UNKNOWN_NAME_FILTER";
        case EOAObjectTypeGPX_TRACK:
            return @"GPX_TRACK";
            
        default:
            return [NSString stringWithFormat:@"%d", (int)objecType];
    }
}

+ (OAObjectType *) getExclusiveSearchType:(EOAObjectType)objectType
{
    if (objectType == EOAObjectTypeFAVORITE_GROUP)
    {
        return [OAObjectType withType:EOAObjectTypeFAVORITE];
    }
    return nil;
}

+ (double) getTypeWeight:(EOAObjectType)objectType
{
    switch (objectType)
    {
        case EOAObjectTypeHOUSE:
        case EOAObjectTypeSTREET_INTERSECTION:
            return 4.0;
        case EOAObjectTypeSTREET:
            return 3.0;
        case EOAObjectTypeCITY:
        case EOAObjectTypeVILLAGE:
        case EOAObjectTypePOSTCODE:
            return 2.0;
        case EOAObjectTypePOI:
            return 1.0;
        default:
            return 1.0;
    }
}

+ (OAObjectType *)valueOf:(NSString *)type
{
    if ([type isEqualToString:@"CITY"])
        return [OAObjectType withType:EOAObjectTypeCITY];
    if ([type isEqualToString:@"VILLAGE"])
        return [OAObjectType withType:EOAObjectTypeVILLAGE];
    if ([type isEqualToString:@"POSTCODE"])
        return [OAObjectType withType:EOAObjectTypePOSTCODE];
    if ([type isEqualToString:@"STREET"])
        return [OAObjectType withType:EOAObjectTypeSTREET];
    if ([type isEqualToString:@"HOUSE"])
        return [OAObjectType withType:EOAObjectTypeHOUSE];
    if ([type isEqualToString:@"STREET_INTERSECTION"])
        return [OAObjectType withType:EOAObjectTypeSTREET_INTERSECTION];
    if ([type isEqualToString:@"POI_TYPE"])
        return [OAObjectType withType:EOAObjectTypePOI_TYPE];
    if ([type isEqualToString:@"POI"])
        return [OAObjectType withType:EOAObjectTypePOI];
    if ([type isEqualToString:@"LOCATION"])
        return [OAObjectType withType:EOAObjectTypeLOCATION];
    if ([type isEqualToString:@"PARTIAL_LOCATION"])
        return [OAObjectType withType:EOAObjectTypePARTIAL_LOCATION];
    if ([type isEqualToString:@"FAVORITE"])
        return [OAObjectType withType:EOAObjectTypeFAVORITE];
    if ([type isEqualToString:@"FAVORITE_GROUP"])
        return [OAObjectType withType:EOAObjectTypeFAVORITE_GROUP];
    if ([type isEqualToString:@"WPT"])
        return [OAObjectType withType:EOAObjectTypeWPT];
    if ([type isEqualToString:@"RECENT_OBJ"])
        return [OAObjectType withType:EOAObjectTypeRECENT_OBJ];
    if ([type isEqualToString:@"REGION"])
        return [OAObjectType withType:EOAObjectTypeREGION];
    if ([type isEqualToString:@"SEARCH_STARTED"])
        return [OAObjectType withType:EOAObjectTypeSEARCH_STARTED];
    if ([type isEqualToString:@"SEARCH_FINISHED"])
        return [OAObjectType withType:EOAObjectTypeSEARCH_FINISHED];
    if ([type isEqualToString:@"FILTER_FINISHED"])
        return [OAObjectType withType:EOAObjectTypeFILTER_FINISHED];
    if ([type isEqualToString:@"SEARCH_API_FINISHED"])
        return [OAObjectType withType:EOAObjectTypeSEARCH_API_FINISHED];
    if ([type isEqualToString:@"SEARCH_API_REGION_FINISHED"])
        return [OAObjectType withType:EOAObjectTypeSEARCH_API_REGION_FINISHED];
    if ([type isEqualToString:@"UNKNOWN_NAME_FILTER"])
        return [OAObjectType withType:EOAObjectTypeUNKNOWN_NAME_FILTER];
    
    return [OAObjectType withType:EOAObjectTypeCITY];
}

@end
