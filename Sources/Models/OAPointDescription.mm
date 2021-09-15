//
//  OAPointDescription.m
//  OsmAnd
//
//  Created by Alexey Kulish on 03/07/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAPointDescription.h"
#import "Localization.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "OAUtilities.h"
#import "OALocationPoint.h"
#import "OALocationConvert.h"
#import "OrderedDictionary.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OsmAnd_Maps-Swift.h"
#import "OAOsmAndFormatter.h"

#include <GeographicLib/GeoCoords.hpp>

@interface OAPointDescription()

@property (nonatomic) NSString *type;

@property (nonatomic) double lat;
@property (nonatomic) double lon;

@end

@implementation OAPointDescription

- (instancetype)initWithLatitude:(double)lat longitude:(double)lon
{
    self = [[OAPointDescription alloc] initWithType:POINT_TYPE_LOCATION name:@""];
    if (self)
    {
        _type = @"";
        _name = @"";
        _lat = lat;
        _lon = lon;
    }
    return self;
}

- (instancetype)initWithType:(NSString *)type name:(NSString *)name
{
    self = [super init];
    if (self)
    {
        _type = type;
        self.name = name;
    }
    return self;
}

- (instancetype)initWithType:(NSString *)type typeName:(NSString *)typeName name:(NSString *)name
{
    self = [super init];
    if (self)
    {
        _type = type;
        _typeName = typeName;
        self.name = name;
    }
    return self;
}

-(void)setName:(NSString *)name
{
    if (!name)
        _name = @"";
    else
        _name = name;
}

- (BOOL) isLocation
{
    return [POINT_TYPE_LOCATION isEqualToString:_type];
}

- (BOOL) isAddress
{
    return [POINT_TYPE_ADDRESS isEqualToString:_type];
}

- (BOOL) isWpt
{
    return [POINT_TYPE_WPT isEqualToString:_type];
}

- (BOOL) isRte
{
    return [POINT_TYPE_RTE isEqualToString:_type];
}

- (BOOL) isPoi
{
    return [POINT_TYPE_POI isEqualToString:_type];
}

- (BOOL) isFavorite
{
    return [POINT_TYPE_FAVORITE isEqualToString:_type];
}

- (BOOL) isAudioNote
{
    return [POINT_TYPE_AUDIO_NOTE isEqualToString:_type];
}

- (BOOL) isVideoNote
{
    return [POINT_TYPE_VIDEO_NOTE isEqualToString:_type];
}

- (BOOL) isPhotoNote
{
    return [POINT_TYPE_PHOTO_NOTE isEqualToString:_type];
}

- (BOOL) isDestination
{
    return [POINT_TYPE_TARGET isEqualToString:_type];
}

- (BOOL) isMapMarker
{
    return [POINT_TYPE_MAP_MARKER isEqualToString:_type];
}

- (BOOL) isParking
{
    return [POINT_TYPE_PARKING_MARKER isEqualToString:_type];
}

- (BOOL) isMyLocation
{
    return [POINT_TYPE_MY_LOCATION isEqualToString:_type];
}

- (BOOL) isCustomPoiFilter
{
    return [POINT_TYPE_CUSTOM_POI_FILTER isEqualToString:_type];
}

- (BOOL) isGpxPoint
{
    return [POINT_TYPE_GPX isEqualToString:_type];
}

+ (NSString *) getLocationName:(double)lat lon:(double)lon sh:(BOOL)sh
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    NSInteger f = [settings.settingGeoFormat get];
    return [OAOsmAndFormatter getFormattedCoordinatesWithLat:lat lon:lon outputFormat:f];
}

+ (NSString *) getLocationNamePlain:(double)lat lon:(double)lon
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    NSInteger f = [settings.settingGeoFormat get];
    return [OAOsmAndFormatter getFormattedCoordinatesWithLat:lat lon:lon outputFormat:f];
}

+ (NSDictionary <NSNumber *, NSString *> *) getLocationData:(double) lat lon:(double)lon
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    MutableOrderedDictionary<NSNumber *, NSString *> *results = [[MutableOrderedDictionary alloc] init];
        
    [results setObject:[OAOsmAndFormatter getFormattedCoordinatesWithLat:lat lon:lon outputFormat:FORMAT_DEGREES_SHORT] forKey:@(FORMAT_DEGREES_SHORT)];
    [results setObject:[OAOsmAndFormatter getFormattedCoordinatesWithLat:lat lon:lon outputFormat:FORMAT_DEGREES] forKey:@(FORMAT_DEGREES)];
    [results setObject:[OAOsmAndFormatter getFormattedCoordinatesWithLat:lat lon:lon outputFormat:FORMAT_MINUTES] forKey:@(FORMAT_MINUTES)];
    [results setObject:[OAOsmAndFormatter getFormattedCoordinatesWithLat:lat lon:lon outputFormat:FORMAT_SECONDS] forKey:@(FORMAT_SECONDS)];
    [results setObject:[OAOsmAndFormatter getFormattedCoordinatesWithLat:lat lon:lon outputFormat:FORMAT_UTM] forKey:@(FORMAT_UTM)];
    [results setObject:[OAOsmAndFormatter getFormattedCoordinatesWithLat:lat lon:lon outputFormat:FORMAT_OLC] forKey:@(FORMAT_OLC)];
    
    float zoom = [OARootViewController instance].mapPanel.mapViewController.getMapZoom;
    NSString *url = [NSString stringWithFormat:@"https://osmand.net/go?lat=%f&lon=%f&z=%f", lat, lon, zoom];
    [results setObject:url forKey:@(POINT_LOCATION_URL)];
    
    NSInteger f = [self.class coordinatesFormatToFormatterMode:[settings.settingGeoFormat get]];
    
    if (f == MAP_GEO_UTM_FORMAT)
        [results setObject:[OAOsmAndFormatter getFormattedCoordinatesWithLat:lat lon:lon outputFormat:FORMAT_UTM] forKey:@(POINT_LOCATION_LIST_HEADER)];
    else if (f == MAP_GEO_OLC_FORMAT)
        [results setObject:[OAOsmAndFormatter getFormattedCoordinatesWithLat:lat lon:lon outputFormat:FORMAT_OLC] forKey:@(POINT_LOCATION_LIST_HEADER)];
    else if (f == FORMAT_DEGREES)
        [results setObject:[OAOsmAndFormatter getFormattedCoordinatesWithLat:lat lon:lon outputFormat:FORMAT_DEGREES] forKey:@(POINT_LOCATION_LIST_HEADER)];
    else if (f == FORMAT_MINUTES)
        [results setObject:[OAOsmAndFormatter getFormattedCoordinatesWithLat:lat lon:lon outputFormat:FORMAT_MINUTES] forKey:@(POINT_LOCATION_LIST_HEADER)];
    else if (f == FORMAT_SECONDS)
        [results setObject:[OAOsmAndFormatter getFormattedCoordinatesWithLat:lat lon:lon outputFormat:FORMAT_SECONDS] forKey:@(POINT_LOCATION_LIST_HEADER)];
    return results;
}

+ (NSString *) formatToHumanString:(NSInteger)format
{
    switch (format) {
        case MAP_GEO_FORMAT_DEGREES:
            return OALocalizedString(@"navigate_point_format_D");
        case MAP_GEO_FORMAT_MINUTES:
            return OALocalizedString(@"navigate_point_format_DM");
        case MAP_GEO_FORMAT_SECONDS:
            return OALocalizedString(@"navigate_point_format_DMS");
        case MAP_GEO_UTM_FORMAT:
            return @"UTM";
        case MAP_GEO_OLC_FORMAT:
            return @"OLC";
        default:
            return @"Unknown format";
    }
}

+ (NSInteger) coordinatesFormatToFormatterMode:(NSInteger)format
{
    return format + 101;
}

- (NSString *) getSimpleName:(BOOL)addTypeName
{
    if ([self isLocation])
    {
        if (self.name.length > 0 && ![self.name isEqualToString:OALocalizedString(@"no_address_found")])
            return self.name;
        else
            return [self.class getLocationName:_lat lon:_lon sh:YES];
    }
    if (self.typeName.length > 0) {
        if (self.name.length == 0) {
            return self.typeName;
        } else if (addTypeName) {
            return [NSString stringWithFormat:@"%@: %@", [_typeName trim], self.name];
        }
    }
    return self.name;
}

- (NSUInteger) hash
{
    NSUInteger prime = 31;
    NSUInteger result = 1;
    result = prime * result + ((!self.name) ? 0 : [self.name hash]);
    result = prime * result + ((!_type) ? 0 : [_type hash]);
    result = prime * result + ((!self.typeName) ? 0 : [self.typeName hash]);
    result = prime * result + ((_lat == 0) ? 0 : [[NSNumber numberWithDouble:_lat] hash]);
    result = prime * result + ((_lon == 0) ? 0 : [[NSNumber numberWithDouble:_lon] hash]);
    return result;
}

- (BOOL) isEqual:(id)object
{
    if (self == object)
        return YES;
    if (!object || ![object isKindOfClass:self.class])
        return NO;
    OAPointDescription *other = (OAPointDescription *) object;
    if ([other.name isEqualToString:self.name] && [other.type isEqualToString:self.type]
        && other.lat == self.lat && other.lon == self.lon && [other.typeName isEqualToString:self.typeName]) {
        return YES;
    }
    return NO;
}

+ (NSString *) getSimpleName:(id<OALocationPoint>)o
{
    OAPointDescription *pd = [o getPointDescription];
    return [pd getSimpleName:true];
    //		return o.getPointDescription(ctx).getFullPlainName(ctx, o.getLatitude(), o.getLongitude());
}

- (BOOL) isSearchingAddress
{
    return self.name.length > 0 && [self isLocation] && [self.name isEqualToString:[self.class getSearchAddressStr]];
}

+ (NSString *) getSearchAddressStr
{
    return [NSString stringWithFormat:@"%@...", OALocalizedString(@"looking_up_address")];
}

+ (NSString *) getAddressNotFoundStr
{
    return OALocalizedString(@"no_address_found");
}

+ (NSString *) serializeToString:(OAPointDescription *)p
{
    if (!p)
        return @"";
    
    NSString *tp = p.type;
    if (p.typeName.length > 0)
        tp = [NSString stringWithFormat:@"%@.%@", tp, p.typeName];
    
    NSString *res = [NSString stringWithFormat:@"%@#%@", tp, p.name];
    if (p.iconName.length > 0)
        res = [NSString stringWithFormat:@"%@#%@", res, p.iconName];
    
    return res;
}

+ (OAPointDescription *) deserializeFromString:(NSString *)s l:(CLLocation *)l
{
    OAPointDescription *pd = nil;
    if (s && s.length > 0)
    {
        int ind = [s indexOf:@"#"];
        if (ind >= 0)
        {
            int ii = [s indexOf:@"#" start:ind + 1];
            NSString *name;
            NSString *icon = nil;
            if (ii > 0)
            {
                name = [[s substringWithRange:NSMakeRange(ind + 1, ii - (ind + 1))] trim];
                icon = [[s substringFromIndex:ii + 1] trim];
            }
            else
            {
                name = [[s substringFromIndex:ind + 1] trim];
            }
            NSString *tp = [s substringToIndex:ind];
            if ([tp containsString:@"."])
            {
                pd = [[OAPointDescription alloc] initWithType:[tp substringToIndex:[tp indexOf:@"."]] typeName:[tp substringFromIndex:[tp indexOf:@"."] + 1] name:name];
            }
            else
            {
                pd = [[OAPointDescription alloc] initWithType:tp name:name];
            }
            if (icon.length > 0)
                pd.iconName = icon;
        }
    }

    if (!pd)
        pd = [[OAPointDescription alloc] initWithType:POINT_TYPE_LOCATION name:@""];
    
    if ([pd isLocation] && l)
    {
        pd.lat = l.coordinate.latitude;
        pd.lon = l.coordinate.longitude;
    }
    return pd;
}

@end
