//
//  OAGeocoder.m
//  OsmAnd
//
//  Created by Alexey Kulish on 18/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAGeocoder.h"
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


@implementation OAGeocoder

+ (OAGeocoder *)instance
{
    static dispatch_once_t once;
    static OAGeocoder * sharedInstance;
    dispatch_once(&once, ^{
    
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (NSString *) geocodeLat:(double)lat lon:(double)lon
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
        QString lang = QString::fromNSString([settings settingPrefMapLanguage]);
        bool transliterate = [settings settingMapLanguageTranslit];
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
        
    return [NSString stringWithString:geocodingResult];
}

@end
