//
//  OAQuickSearchListItem.m
//  OsmAnd
//
//  Created by Alexey Kulish on 28/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAQuickSearchListItem.h"
#import "OASearchResult.h"
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

#include <OsmAndCore/Data/Address.h>
#include <OsmAndCore/Data/Street.h>
#include <OsmAndCore/Data/StreetGroup.h>
#include <OsmAndCore/IFavoriteLocation.h>
#include <OsmAndCore/GpxDocument.h>

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

+ (NSString *) getCityTypeStr:(EOACitySubType)type
{
    switch (type)
    {
        case CITY_SUBTYPE_CITY:
            return OALocalizedString(@"city_type_city");
        case CITY_SUBTYPE_TOWN:
            return OALocalizedString(@"city_type_town");
        case CITY_SUBTYPE_VILLAGE:
            return OALocalizedString(@"city_type_village");
        case CITY_SUBTYPE_HAMLET:
            return OALocalizedString(@"city_type_hamlet");
        case CITY_SUBTYPE_SUBURB:
            return OALocalizedString(@"city_type_suburb");
        case CITY_SUBTYPE_DISTRICT:
            return OALocalizedString(@"city_type_district");
        case CITY_SUBTYPE_NEIGHBOURHOOD:
            return OALocalizedString(@"city_type_neighbourhood");
        default:
            return OALocalizedString(@"city_type_city");
    }
}

+ (NSString *) getName:(OASearchResult *)searchResult
{
    switch (searchResult.objectType)
    {
        case STREET:
        {
            if ([searchResult.localeName hasSuffix:@")"])
            {
                int i = [searchResult.localeName indexOf:@"("];
                if (i > 0)
                    return [[searchResult.localeName substringToIndex:i] trim];
            }
            break;
        }
        case STREET_INTERSECTION:
        {
            if (searchResult.localeRelatedObjectName.length > 0)
                return [NSString stringWithFormat:@"%@ - %@", searchResult.localeName, searchResult.localeRelatedObjectName];
            
            break;
        }
        case RECENT_OBJ:
        {
            OAHistoryItem *historyItem = (OAHistoryItem *) searchResult.object;
            return historyItem.name.length > 0 ? historyItem.name : historyItem.typeName;
        }
        case LOCATION:
        {
            CLLocation *location = searchResult.location;
            return [OAPointDescription getLocationNamePlain:location.coordinate.latitude lon:location.coordinate.longitude];
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
        case LOCATION:
        case PARTIAL_LOCATION:
            return @"ic_action_world_globe";
            
        case POI:
            return [((OAPOI *)searchResult.object) iconName];
            
        case CITY:
        case VILLAGE:
        case POSTCODE:
        case STREET:
        case HOUSE:
        case STREET_INTERSECTION:
            return [((OAAddress *)searchResult.object) iconName];
            
        case FAVORITE:
        {
            const auto& favorite = searchResult.favorite;
            UIColor* color = [UIColor colorWithRed:favorite->getColor().r/255.0 green:favorite->getColor().g/255.0 blue:favorite->getColor().b/255.0 alpha:1.0];
            OAFavoriteColor *favCol = [OADefaultFavorite nearestFavColor:color];
            return favCol.iconName;
        }
        case WPT:
        {
            OAWptPt *wpt = (OAWptPt *) searchResult.object;
            return [wpt getIcon];
        }

        default:
            return nil;
    }
}

+ (NSString *) getTypeName:(OASearchResult *)searchResult
{
    switch (searchResult.objectType)
    {
        case CITY:
        {
            OACity *city = (OACity *)searchResult.object;
            return [self.class getCityTypeStr:city.subType];
        }
        case POSTCODE:
        {
            return OALocalizedString(@"postcode");
        }
        case VILLAGE:
        {
            OACity *city = (OACity *)searchResult.object;
            if (searchResult.localeRelatedObjectName.length > 0)
            {
                if (searchResult.distRelatedObjectName > 0)
                {
                    return [NSString stringWithFormat:@"%@ • %@ %@ %@", [self.class getCityTypeStr:city.subType], [OAOsmAndFormatter getFormattedDistance:(float) searchResult.distRelatedObjectName], OALocalizedString(@"shared_string_from"), searchResult.localeRelatedObjectName];
                }
                else
                {
                    return [NSString stringWithFormat:@"%@, %@", [self getCityTypeStr:city.subType], searchResult.localeRelatedObjectName];
                }
            }
            else
            {
                return [self.class getCityTypeStr:city.subType];
            }
        }
        case STREET:
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
        case HOUSE:
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
        case STREET_INTERSECTION:
        {
            OAStreet *street = (OAStreet *)searchResult.object;
            if (street.city)
                return [street.city getName:[[searchResult.requiredSearchPhrase getSettings] getLang] transliterate:[[searchResult.requiredSearchPhrase getSettings] isTransliterate]];

            return @"";
        }
        case POI_TYPE:
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
        case POI:
        {
            OAPOI *poi = (OAPOI *) searchResult.object;
            return [[self.class getName:searchResult] isEqualToString:poi.type.nameLocalized] ? @"" : poi.type.nameLocalized;
        }
        case LOCATION:
        {
            CLLocation *location = (CLLocation *) searchResult.object;
            if (!searchResult.localeRelatedObjectName)
            {
                OAWorldRegion *region = [[OsmAndApp instance].worldRegion findAtLat:location.coordinate.latitude lon:location.coordinate.longitude];
                searchResult.localeRelatedObjectName = !region ? @"" : region.localizedName;
            }
            return searchResult.localeRelatedObjectName;
        }
        case FAVORITE:
        {
            const auto& fav = searchResult.favorite;
            return fav->getGroup().isNull() || fav->getGroup().isEmpty() == 0 ? OALocalizedString(@"favorites") : fav->getGroup().toNSString();
        }
        case REGION:
        {
            //BinaryMapIndexReader binaryMapIndexReader = (BinaryMapIndexReader) searchResult.object;
            //System.out.println(binaryMapIndexReader.getFile().getAbsolutePath() + " " + binaryMapIndexReader.getCountryName());
            break;
        }
        case RECENT_OBJ:
        {
            OAHistoryItem *item = (OAHistoryItem *) searchResult.object;
            return item.typeName && item.name ? item.typeName : OALocalizedString(@"history");
        }
        case WPT:
        {
            return searchResult.localeRelatedObjectName;
        }
        case UNKNOWN_NAME_FILTER:
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

@end
