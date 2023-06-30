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

- (instancetype) initWithBearingType:(EOABearingType)bearingType
{
    self = [super initWithType:[self widgetByBearingType:bearingType]];
    if (self) {
        [self setAngularUnitsDepended:YES];
        _cachedAngularUnits = DEGREES;
        _locationProvider = OsmAndApp.instance.locationServices;
        _bearingType = bearingType;
        [self setText:nil subtext:nil];
        [self setIcons:self.widgetType];
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
    BOOL relative = [[OAAppSettings sharedManager].showRelativeBearing get];
    [self setContentTitle:relative ? OALocalizedString(@"map_widget_bearing") : OALocalizedString(@"map_widget_magnetic_bearing")];
    int b = [self.class getBearing:relative];
    EOAAngularConstant angularUnits = [[OAAppSettings sharedManager].angularUnits get];
    if (_cachedAngularUnits != angularUnits)
    {
        _cachedAngularUnits = angularUnits;
    }
    if ([self isUpdateNeeded] || [self.class degreesChanged:_cachedDegrees degrees:b])
    {
        _cachedDegrees = b;
        if (b != -1000)
            [self setText:[NSString stringWithFormat:@"%@%@", [OAOsmAndFormatter getFormattedAzimuth:b], relative ? @"" : @" M"] subtext:nil];
        else
            [self setText:nil subtext:nil];
        
        return YES;
    }
    return NO;
}

+ (BOOL) degreesChanged:(int)oldDegrees degrees:(int)degrees
{
    return ABS(oldDegrees - degrees) >= 1;
}

+ (int) getBearing:(BOOL)relative
{
    int d = -1000;
    CLLocation *myLocation = [OsmAndApp instance].locationServices.lastKnownLocation;
    CLLocationDirection heading = [OsmAndApp instance].locationServices.lastKnownHeading;
    CLLocationDegrees declination = [OsmAndApp instance].locationServices.lastKnownDeclination;
    CLLocation *l = [self.class getNextTargetPoint];
    if (!l)
    {
        NSMutableArray *destinations = [OADestinationsHelper instance].sortedDestinations;
        if (destinations.count > 0)
        {
            OADestination *d = destinations[0];
            l = [[CLLocation alloc] initWithLatitude:d.latitude longitude:d.longitude];
        }
    }
    if (myLocation && l)
    {
        double bearing = [myLocation bearingTo:l];
        bearing += bearing < 0 && !relative ? 360 : 0;
        double bearingToDest = bearing - declination;
        if (relative)
        {
            float b = -1000;
            if (myLocation.speed < MIN_SPEED_FOR_HEADING || myLocation.course < 0)
            {
                b = heading;
            }
            else if (myLocation.course >= 0)
            {
                b = myLocation.course - declination;
            }
            if (b > -1000) {
                bearingToDest -= b;
                if (bearingToDest > 180.f)
                    bearingToDest -= 360.f;
                else if (bearingToDest < -180.f)
                    bearingToDest += 360.f;
                
                d = (int) bearingToDest;
            }
        }
        else
        {
            d = (int) bearingToDest;
        }
    }
    return d;
}

+ (CLLocation *) getNextTargetPoint
{
    NSArray<OARTargetPoint *> *points = [[OATargetPointsHelper sharedInstance] getIntermediatePointsWithTarget];
    return points.count == 0 ? nil : points[0].point;
}

//- (nullable Location *)getDestinationLocation:(Location *)fromLocation {
//    LatLon *destLatLon = nil;
//    NSArray<TargetPoint *> *points = [app.getTargetPointsHelper getIntermediatePointsWithTarget];
//    if (points.count > 0) {
//        destLatLon = points[0].point;
//    }
//
//    NSArray<MapMarker *> *markers = [app.getMapMarkersHelper getMapMarkers];
//    if (destLatLon == nil && markers.count > 0)
//    {
//        destLatLon = markers[0].point;
//    }
//
//    lua
//    Copy code
//    if (destLatLon != nil) {
//        Location *destLocation = [[Location alloc] initWithLatitude:destLatLon.getLatitude longitude:destLatLon.getLongitude];
//        [destLocation setBearing:[fromLocation bearingTo:destLocation]];
//        return destLocation;
//    }
//
//    return nil;
//}
//
//- (int) getRelativeBearing:(Location *)myLocation magneticBearingToDest:(float)magneticBearingToDest {
//    float bearing = INVALID_BEARING;
//    NSNumber *heading = [self.locationProvider getHeading];
//
//    if (heading != nil && (myLocation.getSpeed < MIN_SPEED || ![myLocation hasBearing])) {
//        bearing = [heading floatValue];
//    } else if ([myLocation hasBearing]) {
//        GeomagneticField *myLocGf = [self getGeomagneticField:myLocation];
//        bearing = myLocation.getBearing - myLocGf.getDeclination;
//    }
//
//    if (bearing > INVALID_BEARING) {
//        magneticBearingToDest -= bearing;
//        if (magneticBearingToDest > 180.0f) {
//            magneticBearingToDest -= 360.0f;
//        } else if (magneticBearingToDest < -180.0f) {
//            magneticBearingToDest += 360.0f;
//        }
//        return (int)magneticBearingToDest;
//    }
//
//    return INVALID_BEARING;
//}
//
//- (GeomagneticField *) getGeomagneticField:(Location *)location {
//    float lat = (float)location.getLatitude;
//    float lon = (float)location.getLongitude;
//    float alt = (float)location.getAltitude;
//    return [[GeomagneticField alloc] initWithFloat:lat lon:lon alt:alt time:currentTimeMillis()];
//}

//- (BOOL) isAngularUnitsDepended {
//    return YES;
//}

@end
