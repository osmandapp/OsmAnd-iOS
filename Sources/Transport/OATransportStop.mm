//
//  OATransportStop.m
//  OsmAnd
//
//  Created by Alexey on 14/07/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OATransportStop.h"
#import "OAUtilities.h"
#import "OAAppSettings.h"
#import "OAPOIHelper.h"
#import "OAPOI.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Data/TransportStop.h>
#include <OsmAndCore/Data/TransportRoute.h>
#include <OsmAndCore/Data/TransportStopExit.h>


@interface OATransportStop()

@property (nonatomic, assign) std::shared_ptr<const OsmAnd::TransportStop> stop;

@end


@implementation OATransportStop
{
    OAPOI *_poi;
    BOOL _wasSearchedPoi;
}

- (instancetype)initWithStop:(std::shared_ptr<const OsmAnd::TransportStop>)stop
{
    if (self)
    {
        _stop = stop;
        if (stop)
        {
            NSString *prefLang = [OAAppSettings sharedManager].settingPrefMapLanguage.get;
            BOOL transliterate = [OAAppSettings sharedManager].settingMapLanguageTranslit.get;
            self.name = _stop->getName(QString::fromNSString(prefLang), transliterate).toNSString();
            self.latitude = stop->location.latitude;
            self.longitude = stop->location.longitude;
            self.stopId = stop->id.id;
            
            NSMutableArray<CLLocation *> *extiLocations = [NSMutableArray new];
            const auto stopExits = stop->exits;
            for (const auto exit : stopExits)
            {
                const auto loc = exit->location;
                CLLocation *extiLocation = [[CLLocation alloc] initWithLatitude:loc.latitude longitude:loc.longitude];
                [extiLocations addObject:extiLocation];
            }
            self.exitLocations = extiLocations;
        }
        else
        {
            self.name = @"";
        }
    }
    return self;
}

- (OAPOI *)poi
{
    if (!_poi && !_wasSearchedPoi)
    {
        [self findAmenityDataIfNeeded];
    }
    return _poi;
}

- (void)setPoi:(OAPOI *)poi
{
    [self setupWithPOI:poi];
}

- (void)findAmenityDataIfNeeded
{
    if (!_wasSearchedPoi)
    {
        OAPOI *poi = [OAPOIHelper findPOIByName:self.name lat:self.latitude lon:self.longitude];
        [self setupWithPOI:poi];
    }
}

- (void)setupWithPOI:(OAPOI *)poi
{
    _poi = poi;
    self.obfId = _poi.obfId;
    self.name = _poi.name;
    self.enName = _poi.enName;
    self.localizedNames = _poi.localizedNames;
    self.latitude = _poi.latitude;
    self.longitude = _poi.longitude;
    self.x = _poi.x;
    self.y = _poi.y;
    _wasSearchedPoi = YES;
}

- (std::shared_ptr<const OsmAnd::TransportStop>)getStopObject
{
    return _stop;
}

- (NSString *)getStopObjectName:(NSString *)lang transliterate:(BOOL)transliterate
{
    const auto qLang = QString::fromNSString(lang);
    const auto qName = _stop->getName(qLang, transliterate);
    return qName.toNSString();
}

- (BOOL)isEqual:(OATransportStop *)object
{
    if (self == object)
        return YES;
    if (self == nil && object == nil)
        return YES;
    if (self.stop == object.stop)
        return YES;
    BOOL equal = NO;
    equal |= self.stop->id == object.stop->id;
    equal |= self.stop->location == object.stop->location;
    equal |= self.stop->localizedName == object.stop->localizedName;
    return equal;
}

@end
