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

#include <OsmAndCore/Utilities.h>

@implementation OATransportStop

- (NSString *) name
{
    if (_stop)
    {
        NSString *prefLang = [OAAppSettings sharedManager].settingPrefMapLanguage.get;
        BOOL transliterate = [OAAppSettings sharedManager].settingMapLanguageTranslit.get;
        return _stop->getName(QString::fromNSString(prefLang), transliterate).toNSString();
    }
    else
    {
        return @"";
    }
}

- (void) setStop:(std::shared_ptr<const OsmAnd::TransportStop>)stop
{
    _stop = stop;
    if (stop)
        _location = CLLocationCoordinate2DMake(stop->location.latitude, stop->location.longitude);
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
