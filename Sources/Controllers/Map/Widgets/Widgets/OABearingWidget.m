//
//  OABearingWidget.m
//  OsmAnd Maps
//
//  Created by Paul on 12.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OABearingWidget.h"
#import "OsmAndApp.h"
#import "OALocationServices.h"
#import "OADestinationsHelper.h"
#import "OsmAnd_Maps-Swift.h"

static float MIN_SPEED_FOR_HEADING = 1.f;

@implementation OABearingWidget
{
    OALocationServices *_locationProvider;
    
    EOABearingType _bearingType;
    
    EOAAngularConstant _cachedAngularUnits;
    int _cachedDegrees;
}

static const float MIN_SPEED = 1.0f;
static const int INVALID_BEARING = -1000;

- (instancetype)initWithBearingType:(EOABearingType)bearingType
                           customId:(NSString *)customId
                            appMode:(OAApplicationMode *)appMode
                       widgetParams:(NSDictionary *)widgetParams
{
    self = [super initWithType:[self widgetByBearingType:bearingType]];
    if (self) {
        [self configurePrefsWithId:customId appMode:appMode widgetParams:widgetParams];
        [self setAngularUnitsDepended:YES];
        _cachedAngularUnits = DEGREES;
        _locationProvider = OsmAndApp.instance.locationServices;
        _bearingType = bearingType;
        [self setText:nil subtext:nil];
        [self setIconForWidgetType:self.widgetType];
        [self setContentTitle:[self widgetByBearingType:bearingType].title];
    }
    return self;
}

- (OAWidgetType *) widgetByBearingType:(EOABearingType)bearingType
{
    switch (bearingType) {
        case EOABearingTypeTrue:
            return OAWidgetType.trueBearing;
        case EOABearingTypeMagnetic:
            return OAWidgetType.magneticBearing;
        case EOABearingTypeRelative:
            return OAWidgetType.relativeBearing;
    }
}

- (BOOL) updateInfo
{
    int b = [self getBearing];
    EOAAngularConstant angularUnits = [[OAAppSettings sharedManager].angularUnits get];
    if (_cachedAngularUnits != angularUnits)
    {
        _cachedAngularUnits = angularUnits;
    }
    if ([self isUpdateNeeded] || [self.class degreesChanged:_cachedDegrees degrees:b])
    {
        _cachedDegrees = b;
        if (b != INVALID_BEARING)
        {
            BOOL relative = [[OAAppSettings sharedManager].showRelativeBearing get];
            [self setText:[NSString stringWithFormat:@"%@%@", [OAOsmAndFormatter getFormattedAzimuth:b], relative ? @"" : @" M"] subtext:nil];
        }
        else
        {
            [self setText:nil subtext:nil];
        }
        
        return YES;
    }
    return NO;
}

+ (BOOL) degreesChanged:(int)oldDegrees degrees:(int)degrees
{
    return ABS(oldDegrees - degrees) >= 1;
}

- (int) getBearing
{
    CLLocation *myLocation = [OsmAndApp instance].locationServices.lastKnownLocation;
    CLLocation *destination = [self getDestinationLocation];
    
    if (!myLocation || !destination)
        return INVALID_BEARING;
    
    double trueBearing = [myLocation bearingTo:destination];
    if (_bearingType == EOABearingTypeTrue)
        return (int)trueBearing;
    
    OAGeomagneticField *destGf = [self getGeomagneticField:destination];
    double magneticBearing = trueBearing - [destGf declination];
    
    if (_bearingType == EOABearingTypeMagnetic)
    {
        return (int)magneticBearing;
    }
    else if (_bearingType == EOABearingTypeRelative)
    {
        return [self getRelativeBearing:myLocation magneticBearingToDest:magneticBearing];
    }
    else
    {
        return INVALID_BEARING;
    }
}

- (CLLocation *) getDestinationLocation
{
    NSArray<OARTargetPoint *> *points = [[OATargetPointsHelper sharedInstance] getIntermediatePointsWithTarget];
    if (points && points.count > 0)
        return points[0].point;
    
    NSArray<OADestination *> *markers = [OADestinationsHelper instance].sortedDestinations;
    if (markers && markers.count > 0)
        return [[CLLocation alloc] initWithLatitude:markers[0].latitude longitude:markers[0].longitude];

    return nil;
}

- (int) getRelativeBearing:(CLLocation *)myLocation magneticBearingToDest:(float)magneticBearingToDest {
    double bearing = INVALID_BEARING;
    CLLocationDirection heading = [OsmAndApp instance].locationServices.lastKnownHeading;
    CLLocation *destination = [self getDestinationLocation];
    
    if (heading != -1.0 && (myLocation.speed < MIN_SPEED || myLocation.course < 0)) {
        bearing = heading;
    } else if (myLocation && destination) {
        OAGeomagneticField *myLocGf = [self getGeomagneticField:myLocation];
        bearing = myLocation.course - [myLocGf declination];
    }

    if (bearing > INVALID_BEARING) {
        magneticBearingToDest -= bearing;
        if (magneticBearingToDest > 180.0f) {
            magneticBearingToDest -= 360.0f;
        } else if (magneticBearingToDest < -180.0f) {
            magneticBearingToDest += 360.0f;
        }
        return (int)magneticBearingToDest;
    }

    return INVALID_BEARING;
}

- (OAGeomagneticField *) getGeomagneticField:(CLLocation *)location
{
    CLLocationDegrees lat = location.coordinate.latitude;
    CLLocationDegrees lon = location.coordinate.longitude;
    CLLocationDistance alt = location.altitude;
    return [[OAGeomagneticField alloc] initWithLongitude:lon latitude:lat altitude:alt date:[NSDate now]];
}

- (BOOL) isAngularUnitsDepended {
    return YES;
}

@end
