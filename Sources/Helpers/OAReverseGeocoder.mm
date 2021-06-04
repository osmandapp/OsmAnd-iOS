//
//  OAGeocoder.m
//  OsmAnd
//
//  Created by Alexey Kulish on 18/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAReverseGeocoder.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"

#include <OsmAndCore/Search/ReverseGeocoder.h>
#include <OsmAndCore/RoadLocator.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/CommonTypes.h>
#include <OsmAndCore/Data/DataCommonTypes.h>
#include <OsmAndCore/Data/ObfMapSectionInfo.h>
#include <OsmAndCore/Data/ObfPoiSectionInfo.h>
#include <OsmAndCore/Data/Building.h>
#include <OsmAndCore/Data/Street.h>
#include <OsmAndCore/Data/StreetGroup.h>
#include <OsmAndCore/Data/Road.h>

#include <OsmAndCore/Search/AddressesByNameSearch.h>


@implementation OAReverseGeocoder

+ (OAReverseGeocoder *)instance
{
    static dispatch_once_t once;
    static OAReverseGeocoder * sharedInstance;
    dispatch_once(&once, ^{
    
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (NSString *) lookupAddressAtLat:(double)lat lon:(double)lon
{
    OsmAndAppInstance app = [OsmAndApp instance];
    const auto& obfsCollection = app.resourcesManager->obfsCollection;

    const auto& geocoder = std::shared_ptr<OsmAnd::ReverseGeocoder>(new OsmAnd::ReverseGeocoder(obfsCollection, std::shared_ptr<OsmAnd::RoadLocator>(new OsmAnd::RoadLocator(obfsCollection))));
    
    const auto& geoCriteria = std::shared_ptr<OsmAnd::ReverseGeocoder::Criteria>(new OsmAnd::ReverseGeocoder::Criteria);
    geoCriteria->position31 = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(lat, lon));
    const auto object = geocoder->performSearch(*geoCriteria);
    
    NSMutableString *geocodingResult = [NSMutableString string];
    if (object)
    {
        OAAppSettings *settings = [OAAppSettings sharedManager];
        QString lang = QString::fromNSString(settings.settingPrefMapLanguage.get ? settings.settingPrefMapLanguage.get : @"");
        bool transliterate = settings.settingMapLanguageTranslit.get;
        if (object->building)
        {
            QString bldName;
            if (!object->buildingInterpolation.isEmpty())
                bldName = object->buildingInterpolation;
            else
                bldName = object->building->getName(lang, transliterate);
            
            [geocodingResult appendFormat:@"%@ %@, %@", object->street->getName(lang, transliterate).toNSString(), bldName.toNSString(), object->streetGroup->getName(lang, transliterate).toNSString()];
        }
        else if (object->street)
        {
            [geocodingResult appendFormat:@"%@, %@", object->street->getName(lang, transliterate).toNSString(), object->streetGroup->getName(lang, transliterate).toNSString()];
        }
        else if (object->streetGroup)
        {
            [geocodingResult appendString:object->streetGroup->getName(lang, transliterate).toNSString()];
        }
        else if (object->road && object->road->hasGeocodingAccess())
        {
            QString sname = object->road->getName(lang, transliterate);
            if (!sname.isNull())
                [geocodingResult appendString:sname.toNSString()];
        }
    }
    
    //[self testAddressSearch:@"про" lat:lat lon:lon];
    
    return [NSString stringWithString:geocodingResult];
}

- (void) testAddressSearch:(NSString *)query lat:(double)lat lon:(double)lon
{
    NSLog(@"\n--- Start search: %@ ---", query);
    
    OsmAndAppInstance app = [OsmAndApp instance];
    const auto& obfsCollection = app.resourcesManager->obfsCollection;
    
    OsmAnd::AreaI bbox31 = (OsmAnd::AreaI)OsmAnd::Utilities::boundingBox31FromAreaInMeters(10000, OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(lat, lon)));

    const std::shared_ptr<OsmAnd::AddressesByNameSearch::Criteria>& searchCriteria = std::shared_ptr<OsmAnd::AddressesByNameSearch::Criteria>(new OsmAnd::AddressesByNameSearch::Criteria);
    
    searchCriteria->name = QString::fromNSString(query ? query : @"");
    searchCriteria->includeStreets = true;
    //searchCriteria->streetGroupTypesMask = OsmAnd::ObfAddressStreetGroupTypesMask().set(OsmAnd::ObfAddressStreetGroupType::CityOrTown);
    searchCriteria->bbox31 = bbox31;
    searchCriteria->obfInfoAreaFilter = bbox31;
    
    const auto search = std::shared_ptr<const OsmAnd::AddressesByNameSearch>(new OsmAnd::AddressesByNameSearch(obfsCollection));
    const auto result = search->performSearch(*searchCriteria);
    
    OAAppSettings *settings = [OAAppSettings sharedManager];
    QString lang = QString::fromNSString(settings.settingPrefMapLanguage.get ? settings.settingPrefMapLanguage.get : @"");
    bool transliterate = settings.settingMapLanguageTranslit.get;

    for (auto& res : result)
    {
        NSString *name;
        if (res.address->addressType == OsmAnd::AddressType::Street)
        {
            const auto street = std::dynamic_pointer_cast<const OsmAnd::Street>(res.address);
            name = [NSString stringWithFormat:@"%@, %@", street->getName(lang, transliterate).toNSString(), street->streetGroup->getName(lang, transliterate).toNSString()];
        }
        else
        {
            name = res.address->getName(lang, transliterate).toNSString();
        }
        OsmAnd::LatLon pos = OsmAnd::Utilities::convert31ToLatLon(res.address->position31);
        NSLog(@">> %@ (%f km)", name, OsmAnd::Utilities::distance(lon, lat, pos.longitude, pos.latitude) / 1000);
    }
    
    NSLog(@"+++ Finish search +++\n");
}

@end
