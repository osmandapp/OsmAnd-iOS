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

+ (NSString *) getLocationName:(double)lat lon:(double)lon sh:(BOOL)sh
{
    NSString *coordsStr = [[[OsmAndApp instance] locationFormatterDigits] stringFromCoordinate:CLLocationCoordinate2DMake(lat, lon)];
    if (sh)
        return coordsStr;
    else
        return [NSString stringWithFormat:@"%@: %@", OALocalizedString(@"sett_arr_loc"), coordsStr];
}

+ (NSString *) getLocationNamePlain:(double)lat lon:(double)lon
{
    return [[[OsmAndApp instance] locationFormatterDigits] stringFromCoordinate:CLLocationCoordinate2DMake(lat, lon)];
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
                                                                       
@end
