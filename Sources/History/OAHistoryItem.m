//
//  OAHistoryItem.m
//  OsmAnd
//
//  Created by Alexey Kulish on 05/08/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAHistoryItem.h"
#import "OADefaultFavorite.h"
#import "OAUtilities.h"
#import "OAPointDescription.h"
#import "OASearchCoreFactory.h"
#import "GeneratedAssetSymbols.h"

@implementation OAHistoryItem

+ (NSArray<NSString *> *)metadataKeys
{
    return @[@"objectType", @"cityType", @"displayName", @"poiCategoryKey", @"poiSubtypeKey", @"typeName", @"address", @"relatedObjectName", @"openingHours", @"alternateName", @"photoUrl", @"osmId"];
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _hType = OAHistoryTypeUnknown;
    }
    return self;
}

- (instancetype)initWithPointDescription:(OAPointDescription *)pointDescription
{
    self = [super init];
    if (self)
    {
        if ([pointDescription isLocation])
        {
            _hType = OAHistoryTypeLocation;
        }
        else if ([pointDescription isPoi])
        {
            _hType = OAHistoryTypePOI;
        }
        else if ([pointDescription isWpt])
        {
            _hType = OAHistoryTypeWpt;
        }
        else if ([pointDescription isAddress])
        {
            _hType = OAHistoryTypeAddress;
        }
        else if ([pointDescription isParking])
        {
            _hType = OAHistoryTypeParking;
        }
        else if ([pointDescription isFavorite])
        {
            _hType = OAHistoryTypeFavorite;
        }
        else if ([pointDescription isDestination])
        {
            _hType = OAHistoryTypeDirection;
        }
        else if ([pointDescription isPoiType])
        {
            _hType = OAHistoryTypePoiType;
        }
        else if ([pointDescription isCustomPoiFilter])
        {
            _hType = OAHistoryTypePoiFilter;
        }
        else
        {
            _hType = OAHistoryTypeUnknown;
        }
    }
    return self;
}

- (BOOL)fillMissingMetadataFrom:(OAHistoryItem *)item
{
    BOOL filled = NO;
    for (NSString *key in self.class.metadataKeys)
    {
        id value = [item valueForKey:key];
        if ([self.class isEmptyMetadataValue:value] || ![self.class isEmptyMetadataValue:[self valueForKey:key]])
            continue;
        [self setValue:value forKey:key];
        filled = YES;
    }
    return filled;
}

+ (BOOL)isEmptyMetadataValue:(id)value
{
    return !value || [value isEqual:@""];
}

-(UIImage *)icon
{
    if (self.hType == OAHistoryTypeParking)
    {
        return [UIImage imageNamed:ACImageNameIcParkingPinSmall];
    }
    else if (self.iconName.length > 0)
    {
        UIImage *img;
        if (self.hType == OAHistoryTypePOI || self.hType == OAHistoryTypePoiType || self.hType == OAHistoryTypePoiFilter)
            img = [UIImage mapSvgImageNamed:self.iconName];

        if (img)
        {
            return img;
        }
        else
        {
            img = [UIImage imageNamed:self.iconName];
            if (img)
            {
                if (self.hType == OAHistoryTypeAddress)
                    return [OAUtilities getTintableImage:img];
                else
                    return img;
            }
        }
    }
    return [UIImage imageNamed:ACImageNameIcMapPinSmall];
}

- (NSString *) getPointDescriptionType
{
    switch (_hType) {
        case OAHistoryTypeLocation:
            return POINT_TYPE_LOCATION;
        case OAHistoryTypePOI:
            return POINT_TYPE_POI;
        case OAHistoryTypeWpt:
            return POINT_TYPE_WPT;
        case OAHistoryTypeAddress:
            return POINT_TYPE_ADDRESS;
        case OAHistoryTypeParking:
            return POINT_TYPE_PARKING_MARKER;
        case OAHistoryTypeFavorite:
            return POINT_TYPE_FAVORITE;
        case OAHistoryTypeDirection:
            return POINT_TYPE_TARGET;
        case OAHistoryTypePoiType:
            return POINT_TYPE_POI_TYPE;
        case OAHistoryTypePoiFilter:
            return POINT_TYPE_CUSTOM_POI_FILTER;
        default:
            return POINT_TYPE_LOCATION;
    }
}

- (BOOL)hasLocation
{
    return _hType != OAHistoryTypePoiType && _hType != OAHistoryTypePoiFilter;
}

- (float)preferredZoom
{
    switch (_hType) {
        case OAHistoryTypePOI:
            return PREFERRED_POI_ZOOM;
        case OAHistoryTypeWpt:
            return PREFERRED_WPT_ZOOM;
        case OAHistoryTypeAddress:
            return PREFERRED_STREET_INTERSECTION_ZOOM;
        case OAHistoryTypeFavorite:
            return PREFERRED_FAVORITE_ZOOM;
        default:
            return PREFERRED_DEFAULT_ZOOM;
    }
}

@end
