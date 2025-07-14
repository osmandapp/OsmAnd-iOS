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

#include <OsmAndCore/Data/TransportStop.h>
#include <OsmAndCore/Utilities.h>

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
            _name = _stop->getName(QString::fromNSString(prefLang), transliterate).toNSString();
            _location = CLLocationCoordinate2DMake(stop->location.latitude, stop->location.longitude);
        }
        else
        {
            _name = @"";
        }
    }
    return self;
}

- (OAPOI *)poi
{
    if (!_poi && !_wasSearchedPoi)
    {
        _poi = [OAPOIHelper findPOIByName:self.name lat:_location.latitude lon:_location.longitude];
        _wasSearchedPoi = YES;
    }
    return _poi;
}

- (void)setPoi:(OAPOI *)poi
{
    _poi = poi;
    _wasSearchedPoi = YES;
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
