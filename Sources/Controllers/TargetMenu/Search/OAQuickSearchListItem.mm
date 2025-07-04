//
//  OAQuickSearchListItem.m
//  OsmAnd
//
//  Created by Alexey Kulish on 28/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAQuickSearchListItem.h"
#import "OASearchResult.h"
#import "OASearchResult+cpp.h"
#import "OASearchPhrase.h"
#import "OASearchSettings.h"
#import "Localization.h"
#import "OAUtilities.h"
#import "OAHistoryItem.h"
#import <CoreLocation/CoreLocation.h>
#import "OsmAndApp.h"
#import "OAPOIBaseType.h"
#import "OAPOIType.h"
#import "OAPOIFilter.h"
#import "OAPOICategory.h"
#import "OAPOI.h"
#import "OACustomSearchPoiFilter.h"
#import "OAWorldRegion.h"
#import "OAStreet.h"
#import "OADefaultFavorite.h"
#import "OAPointDescription.h"
#import "OAOsmAndFormatter.h"
#import "OAPOIUIFilter.h"
#import "OAPOIFiltersHelper.h"
#import "OAFavoriteItem.h"
#import "OAFavoritesHelper.h"
#import "OsmAndSharedWrapper.h"
#import "OsmAnd_Maps-Swift.h"
#import "OAResourcesUIHelper.h"

#include <OsmAndCore/Data/Address.h>
#include <OsmAndCore/Data/Street.h>
#include <OsmAndCore/Data/StreetGroup.h>
#include <OsmAndCore/IFavoriteLocation.h>

@implementation OAQuickSearchListItem
{
    OASearchResult *_searchResult;
    OADistanceDirection *_distanceDirection;
}

- (instancetype)initWithSearchResult:(OASearchResult *)searchResult
{
    self = [super init];
    if (self)
    {
        _searchResult = searchResult;
        if (searchResult.location)
            _distanceDirection = [[OADistanceDirection alloc] initWithLatitude:searchResult.location.coordinate.latitude longitude:searchResult.location.coordinate.longitude];
    }
    return self;
}

- (EOAQuickSearchListItemType) getType
{
    return SEARCH_RESULT;
}

- (OASearchResult *) getSearchResult
{
    return _searchResult;
}

+ (NSString *) getName:(OASearchResult *)searchResult
{
    switch (searchResult.objectType)
    {
        case EOAObjectTypeStreet:
        {
            if ([searchResult.localeName hasSuffix:@")"])
            {
                int i = [searchResult.localeName indexOf:@"("];
                if (i > 0)
                    return [[searchResult.localeName substringToIndex:i] trim];
            }
            break;
        }
        case EOAObjectTypeStreetIntersection:
        {
            if (searchResult.localeRelatedObjectName.length > 0)
                return [NSString stringWithFormat:@"%@ - %@", searchResult.localeName, searchResult.localeRelatedObjectName];
            
            break;
        }
        case EOAObjectTypeRecentObj:
        {
            OAHistoryItem *historyItem = (OAHistoryItem *) searchResult.object;
            return historyItem.name.length > 0 ? historyItem.name : historyItem.typeName;
        }
        case EOAObjectTypeLocation:
        {
            CLLocation *location = searchResult.location;
            return [OAPointDescription getLocationNamePlain:location.coordinate.latitude lon:location.coordinate.longitude];
        }
        case EOAObjectTypeIndexItem:
        {
            OARepositoryResourceItem *resourceItem = (OARepositoryResourceItem *)searchResult.relatedObject;
            return resourceItem.title;
        }
        default:
        {
            return searchResult.localeName;
        }
    }
    return searchResult.localeName;
}

- (NSString *) getName
{
    return [self.class getName:_searchResult];
}

+ (NSString *) getIconName:(OASearchResult *)searchResult
{
    switch (searchResult.objectType)
    {
        case EOAObjectTypeLocation:
        case EOAObjectTypePartialLocation:
        {
            return @"ic_action_world_globe";
        }
        case EOAObjectTypeCity:
        case EOAObjectTypeVillage:
        case EOAObjectTypePostcode:
        case EOAObjectTypeStreet:
        case EOAObjectTypeHouse:
        case EOAObjectTypeStreetIntersection:
        {
            return [((OAAddress *)searchResult.object) iconName];
        }
        case EOAObjectTypePoiType:
        {
            if ([searchResult.object isKindOfClass:OAPOIBaseType.class])
            {
                NSString *iconName = [OAPOIUIFilter getPoiTypeIconName:(OAPOIBaseType *) searchResult.object];
                if ((!iconName || iconName.length == 0) && [searchResult.object isKindOfClass:OAPOIType.class])
                    iconName = ((OAPOIBaseType *) searchResult.object).iconName;
                if (!iconName || iconName.length == 0)
                    iconName = [@"mx_" stringByAppendingString:@"craft_default"];
                return iconName;
            }
            else if ([searchResult.object isKindOfClass:OACustomSearchPoiFilter.class])
            {
                OACustomSearchPoiFilter *searchPoiFilter = (OACustomSearchPoiFilter *) searchResult.object;
                OAPOIUIFilter *filter = [[OAPOIFiltersHelper sharedInstance] getFilterById:[searchPoiFilter getFilterId]];
                NSString *iconName;
                if (filter)
                    iconName = [OAPOIUIFilter getCustomFilterIconName:filter];
                return iconName && iconName.length > 0 ? iconName : @"ic_custom_search";
            }
        }
        case EOAObjectTypePoi:
        {
            OAPOI *amenity = (OAPOI *) searchResult.object;
            NSString *iconName = [amenity iconName];
            if (!iconName)
                iconName = [@"mx_" stringByAppendingString:@"craft_default"];
            return iconName;
        }
        case EOAObjectTypeGpxTrack:
        {
            return @"ic_custom_trip";
        }
        case EOAObjectTypeFavorite:
        {
            auto favorite = std::const_pointer_cast<OsmAnd::IFavoriteLocation>(searchResult.favorite);
            OAFavoriteItem *favItem = [[OAFavoriteItem alloc] initWithFavorite:favorite];
            return [favItem getIcon];
        }
        case EOAObjectTypeFavoriteGroup:
        {
            return @"ic_custom_favorites";
        }
        case EOAObjectTypeRegion:
        {
            return @"ic_world_globe_dark";
        }
        case EOAObjectTypeRecentObj:
        {
            OAHistoryItem *entry = (OAHistoryItem *) searchResult.object;
            if (entry.iconName && entry.iconName.length > 0)
                return entry.hType == OAHistoryTypeParking ? @"ic_parking_pin_small" : entry.iconName;

            OAPointDescription *name = [[OAPointDescription alloc] initWithType:[entry getPointDescriptionType]
                                                                       typeName:entry.typeName
                                                                           name:entry.name];
            if (name)
            {
                if (name.iconName && name.iconName.length > 0)
                    return name.iconName;
                else
                    return [self getItemIcon:name];
            }
            else
            {
                return @"ic_custom_marker";
            }
        }
        case EOAObjectTypeWpt:
        {
            OASWptPt *wpt = (OASWptPt *) searchResult.object;
            return [wpt getIconName];
        }
        case EOAObjectTypeIndexItem:
        {
            return @"ic_custom_map";
        }
        default:
            return nil;
    }
}

+ (NSString *)getItemIcon:(OAPointDescription *)pd
{
    if ([pd isFavorite])
        return @"ic_custom_favorites";
    else if ([pd isLocation])
        return @"ic_custom_location_marker";
    else if ([pd isPoi])
        return @"ic_custom_info";
    else if ([pd isGpxFile] || [pd isGpxPoint])
        return @"ic_custom_trip";
    else if ([pd isWpt])
        return @"ic_custom_marker";
//    else if ([pd isAudioNote])
//        iconId = R.drawable.ic_type_audio;
//    else if (pd.isVideoNote())
//        iconId = R.drawable.ic_type_video;
//    else if (pd.isPhotoNote())
//        iconId = R.drawable.ic_type_img;
    else
        return @"ic_action_street_name";
}

+ (NSString *) getTypeName:(OASearchResult *)searchResult
{
    switch (searchResult.objectType)
    {
        case EOAObjectTypeCity:
        {
            OACity *city = (OACity *)searchResult.object;
            return [OACity getLocalizedTypeStr:city.subType];
        }
        case EOAObjectTypePostcode:
        {
            return OALocalizedString(@"postcode");
        }
        case EOAObjectTypeVillage:
        {
            OACity *city = (OACity *)searchResult.object;
            if (searchResult.localeRelatedObjectName.length > 0)
            {
                if (searchResult.distRelatedObjectName > 0)
                {
                    return [NSString stringWithFormat:@"%@ • %@ %@ %@", [OACity getLocalizedTypeStr:city.subType], [OAOsmAndFormatter getFormattedDistance:(float) searchResult.distRelatedObjectName], OALocalizedString(@"shared_string_from"), searchResult.localeRelatedObjectName];
                }
                else
                {
                    return [NSString stringWithFormat:@"%@, %@", [OACity getLocalizedTypeStr:city.subType], searchResult.localeRelatedObjectName];
                }
            }
            else
            {
                return [OACity getLocalizedTypeStr:city.subType];
            }
        }
        case EOAObjectTypeStreet:
        {
            NSMutableString *streetBuilder = [NSMutableString string];
            if ([searchResult.localeName hasSuffix:@")"])
            {
                int i = [searchResult.localeName indexOf:@"("];
                if (i > 0)
                    [streetBuilder appendString:[searchResult.localeName substringWithRange:NSMakeRange(i + 1, searchResult.localeName.length - (i + 1) - 1)]];
            }
            if (searchResult.localeRelatedObjectName.length > 0)
            {
                if (streetBuilder.length > 0) {
                    [streetBuilder appendString:@", "];
                }
                [streetBuilder appendString:searchResult.localeRelatedObjectName];
            }
            return [NSString stringWithString:streetBuilder];
        }
        case EOAObjectTypeHouse:
        {
            if (searchResult.relatedObject)
            {
                OAStreet *relatedStreet = (OAStreet *)searchResult.relatedObject;
                if (relatedStreet.city)
                    return [NSString stringWithFormat:@"%@, %@", searchResult.localeRelatedObjectName, [relatedStreet.city getName:[[searchResult.requiredSearchPhrase getSettings] getLang] transliterate:[[searchResult.requiredSearchPhrase getSettings] isTransliterate]]];
                else
                    return searchResult.localeRelatedObjectName;
            }
            return @"";
        }
        case EOAObjectTypeStreetIntersection:
        {
            OAStreet *street = (OAStreet *)searchResult.object;
            if (street.city)
                return [street.city getName:[[searchResult.requiredSearchPhrase getSettings] getLang] transliterate:[[searchResult.requiredSearchPhrase getSettings] isTransliterate]];

            return @"";
        }
        case EOAObjectTypePoiType:
        {
            NSString *res = @"";
            if ([searchResult.object isKindOfClass:[OAPOIBaseType class]])
            {
                OAPOIBaseType *abstractPoiType = (OAPOIBaseType *) searchResult.object;
                if ([abstractPoiType isKindOfClass:[OAPOICategory class]])
                {
                    res = @"";
                }
                else if ([abstractPoiType isKindOfClass:[OAPOIFilter class]])
                {
                    OAPOIFilter *poiFilter = (OAPOIFilter *) abstractPoiType;
                    res = poiFilter.category ? poiFilter.category.nameLocalized : @"";
                }
                else if ([abstractPoiType isKindOfClass:[OAPOIType class]])
                {
                    OAPOIType *poiType = (OAPOIType *) abstractPoiType;
                    res = poiType.parentType ? poiType.parentType.nameLocalized : nil;
                    if (!res)
                        res = poiType.category ? poiType.category.nameLocalized : nil;

                    if (!res)
                        res = @"";
                }
                else
                {
                    res = @"";
                }
            }
            else if ([searchResult.object isKindOfClass:[OACustomSearchPoiFilter class]])
            {
                res = [((OACustomSearchPoiFilter *) searchResult.object) getName];
            }
            return res;
        }
        case EOAObjectTypePoi:
        {
            OAPOI *poi = (OAPOI *) searchResult.object;
            NSString * subType = [poi getSubTypeStr];
            NSString * alternateName = searchResult.alternateName;
            NSString * city = poi.cityName;
            if ([alternateName length] > 0)
            {
                subType = [subType stringByAppendingFormat:@" • %@", alternateName];
            } else if ([city length] > 0)
            {
                subType = [subType stringByAppendingFormat:@" • %@", city];
            }
            return [[self.class getName:searchResult] isEqualToString:subType] ? @"" : subType;
        }
        case EOAObjectTypeLocation:
        {
            CLLocation *location = (CLLocation *) searchResult.object;
            if (!searchResult.localeRelatedObjectName)
            {
                OAWorldRegion *region = [[OsmAndApp instance].worldRegion findAtLat:location.coordinate.latitude lon:location.coordinate.longitude];
                searchResult.localeRelatedObjectName = !region ? @"" : region.localizedName;
            }
            return searchResult.localeRelatedObjectName;
        }
        case EOAObjectTypeFavorite:
        {
            const auto& fav = searchResult.favorite;
            return [OAFavoriteGroup getDisplayName: fav->getGroup().toNSString()];
        }
        case EOAObjectTypeRegion:
        {
            //BinaryMapIndexReader binaryMapIndexReader = (BinaryMapIndexReader) searchResult.object;
            //System.out.println(binaryMapIndexReader.getFile().getAbsolutePath() + " " + binaryMapIndexReader.getCountryName());
            break;
        }
        case EOAObjectTypeRecentObj:
        {
            OAHistoryItem *item = (OAHistoryItem *) searchResult.object;
            return item.typeName && item.name ? item.typeName : OALocalizedString(@"shared_string_history");
        }
        case EOAObjectTypeWpt:
        {
            return searchResult.localeRelatedObjectName;
        }
        case EOAObjectTypeGpxTrack:
        {
            OASGpxDataItem *dataItem = (OASGpxDataItem *)searchResult.relatedObject;
            if (dataItem)
            {
                return [OAGPXUIHelper getGPXStatisticStringForGpxDataItem:dataItem showLastModifiedTime:YES];
            }
            return @"";
        }
        case EOAObjectTypeIndexItem:
        {
            NSString *name = @"";
            OARepositoryResourceItem *resourceItem = (OARepositoryResourceItem *)searchResult.relatedObject;
            if (resourceItem && resourceItem.sizePkg > 0)
            {
                OAResourceSwiftItem *mapItem = [[OAResourceSwiftItem alloc] initWithItem:resourceItem];
                
                name = [NSString stringWithFormat:@"%@  •  %@", [mapItem formatedSizePkg], [mapItem type]];
                
                NSString *dateString = [resourceItem getDate];
                if (dateString != nil)
                {
                    name = [name stringByAppendingFormat:@"  •  %@", dateString];
                }
            }
            return name;
        }
        case EOAObjectTypeUnknownNameFilter:
        {
            break;
        }
        default:
            break;
            
    }
    return [OAObjectType toString:searchResult.objectType];
}

- (OADistanceDirection *) getEvaluatedDistanceDirection:(BOOL)decelerating
{
    if (_distanceDirection)
        [_distanceDirection evaluateDistanceDirection:decelerating];
    
    return _distanceDirection;
}

- (void) setMapCenterCoordinate:(CLLocationCoordinate2D)mapCenterCoordinate
{
    if (_distanceDirection)
        [_distanceDirection setMapCenterCoordinate:mapCenterCoordinate];
}

- (void) resetMapCenterSearch
{
    if (_distanceDirection)
        [_distanceDirection resetMapCenterSearch];
}

- (BOOL)isEqual:(id)other
{
    if (other == self) {
        return YES;
    } if (![self isKindOfClass:[other class]]) {
        return NO;
    } else {
        OAQuickSearchListItem *item = (OAQuickSearchListItem *)other;
        return [_searchResult.localeName isEqualToString:item.getSearchResult.localeName];
    }
}

- (NSUInteger)hash {
    return _searchResult.localeName.hash;
}

@end
