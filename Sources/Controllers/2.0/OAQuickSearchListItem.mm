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

#include <OsmAndCore/Data/Address.h>
#include <OsmAndCore/Data/Street.h>
#include <OsmAndCore/Data/StreetGroup.h>
#include <OsmAndCore/IFavoriteLocation.h>
#include <OsmAndCore/GeoInfoDocument.h>

@implementation OAQuickSearchListItem
{
    OASearchResult *_searchResult;
}

- (instancetype)initWithSearchResult:(OASearchResult *)searchResult
{
    self = [super init];
    if (self)
    {
        _searchResult = searchResult;
        
    }
    return self;
}

- (OASearchResult *) getSearchResult
{
    return _searchResult;
}

+ (NSString *) getCityTypeStr:(OsmAnd::ObfAddressStreetGroupSubtype)type
{
    switch (type)
    {
        case OsmAnd::ObfAddressStreetGroupSubtype::City:
            return OALocalizedString(@"city_type_city");
        case OsmAnd::ObfAddressStreetGroupSubtype::Town:
            return OALocalizedString(@"city_type_town");
        case OsmAnd::ObfAddressStreetGroupSubtype::Village:
            return OALocalizedString(@"city_type_village");
        case OsmAnd::ObfAddressStreetGroupSubtype::Hamlet:
            return OALocalizedString(@"city_type_hamlet");
        case OsmAnd::ObfAddressStreetGroupSubtype::Suburb:
            return OALocalizedString(@"city_type_suburb");
        case OsmAnd::ObfAddressStreetGroupSubtype::District:
            return OALocalizedString(@"city_type_district");
        case OsmAnd::ObfAddressStreetGroupSubtype::Neighbourhood:
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
            return [[[OsmAndApp instance] locationFormatterDigits] stringFromCoordinate:location.coordinate];
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

+ (NSString *) getTypeName:(OASearchResult *)searchResult
{
    switch (searchResult.objectType)
    {
        case CITY:
        {
            const auto& city = std::dynamic_pointer_cast<const OsmAnd::StreetGroup>(searchResult.address);
            return [self.class getCityTypeStr:city->subtype];
        }
        case POSTCODE:
        {
            return OALocalizedString(@"postcode");
        }
        case VILLAGE:
        {
            const auto& city = std::dynamic_pointer_cast<const OsmAnd::StreetGroup>(searchResult.address);
            if (searchResult.localeRelatedObjectName.length > 0)
            {
                if (searchResult.distRelatedObjectName > 0)
                {
                    return [NSString stringWithFormat:@"%@ • %@ %@ %@", [self.class getCityTypeStr:city->subtype], [[OsmAndApp instance] getFormattedDistance:(float) searchResult.distRelatedObjectName], OALocalizedString(@"shared_string_from"), searchResult.localeRelatedObjectName];
                }
                else
                {
                    return [NSString stringWithFormat:@"%@, %@", [self getCityTypeStr:city->subtype], searchResult.localeRelatedObjectName];
                }
            }
            else
            {
                return [self.class getCityTypeStr:city->subtype];
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
                const auto& relatedStreet = std::dynamic_pointer_cast<const OsmAnd::Street>(searchResult.relatedAddress);
                if (relatedStreet->streetGroup)
                    return [NSString stringWithFormat:@"%@, %@", searchResult.localeRelatedObjectName, relatedStreet->streetGroup->getName(QString::fromNSString([[searchResult.requiredSearchPhrase getSettings] getLang]), true).toNSString()];
                else
                    return searchResult.localeRelatedObjectName;
            }
            return @"";
        }
        case STREET_INTERSECTION:
        {
            const auto& street = std::dynamic_pointer_cast<const OsmAnd::Street>(searchResult.address);
            if (street->streetGroup)
                return street->streetGroup->getName(QString::fromNSString([[searchResult.requiredSearchPhrase getSettings] getLang]), true).toNSString();

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
            return poi.type.nameLocalized;
        }
        case LOCATION:
        {
            CLLocation *location = (CLLocation *) searchResult.object;
            if (!searchResult.localeRelatedObjectName)
            {
                OAWorldRegion *region = [[OsmAndApp instance].worldRegion findAtLat:location.coordinate.latitude lon:location.coordinate.longitude];
                searchResult.localeRelatedObjectName = !region ? @"" : region.nativeName;
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
            return item.typeName ? item.typeName : @"";
        }
        case WPT:
        {
            return searchResult.localeRelatedObjectName;
        }
        case UNKNOWN_NAME_FILTER:
            break;
    }
    return [OAObjectType toString:searchResult.objectType];
}


@end
