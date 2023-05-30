//
//  OAGPXDocumentPrimitives.m
//  OsmAnd
//
//  Created by Alexey Kulish on 15/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGPXDocumentPrimitives.h"
#import "OAGPXTrackAnalysis.h"
#import "OAUtilities.h"
#import "OAPointDescription.h"
#import "OADefaultFavorite.h"
#import "OAPOI.h"
#import "OAGPXPrimitivesNativeWrapper.h"

#include <routeSegmentResult.h>
#include <routeDataBundle.h>
#include <routeDataResources.h>
#include <OsmAndCore/QKeyValueIterator.h>

@implementation OAGPXColor

+ (instancetype)withType:(EOAGPXColor)type name:(NSString *)name color:(int)color
{
    OAGPXColor *obj = [[OAGPXColor alloc] init];
    if (obj)
    {
        obj.type = type;
        obj.name = name;
        obj.color = color;
    }
    return obj;
}

+ (NSArray<OAGPXColor *> *)values
{
    return @[
            [OAGPXColor withType:BLACK name:@"BLACK" color:0xFF000000],
            [OAGPXColor withType:DARKGRAY name:@"DARKGRAY" color:0xFF444444],
            [OAGPXColor withType:GRAY name:@"GRAY" color:0xFF888888],
            [OAGPXColor withType:LIGHTGRAY name:@"LIGHTGRAY" color:0xFFCCCCCC],
            [OAGPXColor withType:WHITE name:@"WHITE" color:0xFFFFFFFF],
            [OAGPXColor withType:RED name:@"RED" color:0xFFFF0000],
            [OAGPXColor withType:GREEN name:@"GREEN" color:0xFF00FF00],
            [OAGPXColor withType:DARKGREEN name:@"DARKGREEN" color:0xFF006400],
            [OAGPXColor withType:BLUE name:@"BLUE" color:0xFF0000FF],
            [OAGPXColor withType:YELLOW name:@"YELLOW" color:0xFFFFFF00],
            [OAGPXColor withType:CYAN name:@"CYAN" color:0xFF00FFFF],
            [OAGPXColor withType:MAGENTA name:@"MAGENTA" color:0xFFFF00FF],
            [OAGPXColor withType:AQUA name:@"AQUA" color:0xFF00FFFF],
            [OAGPXColor withType:FUCHSIA name:@"FUCHSIA" color:0xFFFF00FF],
            [OAGPXColor withType:DARKGREY name:@"DARKGREY" color:0xFF444444],
            [OAGPXColor withType:GREY name:@"GREY" color:0xFF888888],
            [OAGPXColor withType:LIGHTGREY name:@"LIGHTGREY" color:0xFFCCCCCC],
            [OAGPXColor withType:LIME name:@"LIME" color:0xFF00FF00],
            [OAGPXColor withType:MAROON name:@"MAROON" color:0xFF800000],
            [OAGPXColor withType:NAVY name:@"NAVY" color:0xFF000080],
            [OAGPXColor withType:OLIVE name:@"OLIVE" color:0xFF808000],
            [OAGPXColor withType:PURPLE name:@"PURPLE" color:0xFF800080],
            [OAGPXColor withType:SILVER name:@"SILVER" color:0xFFC0C0C0],
            [OAGPXColor withType:TEAL name:@"TEAL" color:0xFF008080]
    ];
}

+ (OAGPXColor *)getColorFromName:(NSString *)name
{
    for (OAGPXColor *c in [self values])
    {
        if ([c.name caseInsensitiveCompare:name] == NSOrderedSame)
            return c;
    }
    return nil;
}

@end

@implementation OAGpxExtension

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _name = @"";
        _value = @"";
        _attributes = @{};
        _subextensions = @[];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    OAGpxExtension *copy = [[OAGpxExtension allocWithZone:zone] init];
    copy.name = self.name;
    copy.value = self.value;
    copy.attributes = [self.attributes copy];
    copy.subextensions = [self.subextensions copy];
    return copy;
}

@end

@implementation OAGpxExtensions

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _extensions = @[];
        _wrapper = [[OAGpxExtensionsNativeWrapper alloc] init];
    }
    return self;
}

- (NSArray<OAGpxExtension *> *)extensions
{
    if (!_extensions)
        _extensions = @[];

    return _extensions;
}

- (void)copyExtensions:(OAGpxExtensions *)e
{
    if (e && e.extensions.count > 0)
    {
        NSArray<OAGpxExtension *> *exts = [[NSArray alloc] initWithArray:e.extensions copyItems:YES];
        _extensions = [_extensions arrayByAddingObjectsFromArray:exts];
    }
}

- (OAGpxExtension *)getExtensionByKey:(NSString *)key
{
    for (OAGpxExtension *e in self.extensions)
    {
        if ([e.name isEqualToString:key])
            return e;
    }
    return nil;
}

- (void)addExtension:(OAGpxExtension *)e
{
    if (![self.extensions containsObject:e])
        self.extensions = [self.extensions arrayByAddingObject:e];
}

- (void)removeExtension:(OAGpxExtension *)e
{
    NSMutableArray<OAGpxExtension *> *extensions = [self.extensions mutableCopy];
    [extensions removeObject:e];

    self.extensions = extensions;
}

- (void)setExtension:(NSString *)key value:(NSString *)value
{
    OAGpxExtension *e = [self getExtensionByKey:key];
    if (!e)
    {
        e = [[OAGpxExtension alloc] init];
        e.name = key;
        e.value = value;
        if (![self.extensions containsObject:e])
            self.extensions = [self.extensions arrayByAddingObject:e];
    }
    else
    {
        e.value = value;
    }
}

- (int) getColor:(int)defColor
{
    OAGpxExtension *e = [self getExtensionByKey:@"color"];
    if (!e)
        e = [self getExtensionByKey:@"colour"];
    if (!e)
        e = [self getExtensionByKey:@"displaycolor"];
    if (!e)
        e = [self getExtensionByKey:@"displaycolour"];

    return [self parseColor:e.value defColor:defColor];
}

- (void) setColor:(int)value
{
    NSString *hexString = [NSString stringWithFormat:@"#%0X", value];
    [self setExtension:@"color" value:hexString.lowerCase];
}

- (int) parseColor:(NSString *)colorString defColor:(int)defColor
{
    if (colorString.length > 0)
    {
        if ([colorString hasPrefix:@"#"])
        {
            return [OAUtilities colorToNumberFromString:colorString];
        }
        else
        {
            OAGPXColor *gpxColor = [OAGPXColor getColorFromName:colorString];
            if (gpxColor)
                return gpxColor.color;
        }
    }
    return defColor;
}

@end

@implementation OALink
@end

@implementation OAMetadata
@end

@implementation OAWptPt

@dynamic wrapper;

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.elevation = NAN;
        self.speed = 0;
        self.horizontalDilutionOfPrecision = NAN;
        self.verticalDilutionOfPrecision = NAN;
        self.heading = NAN;
        self.distance = 0.0;
        self.wrapper = [[OAWptPtNativeWrapper alloc] init];
    }
    return self;
}

- (instancetype)initWithWpt:(OAWptPt *)wptPt
{
    self = [super init];
    if (self)
    {
        self.firstPoint = NO;
        self.lastPoint = NO;
        self.position = wptPt.position;
        self.name = wptPt.name;
//        self.link = wptPt.link;
//        self.category = wptPt.category;
        self.desc = wptPt.desc;
        self.comment = wptPt.comment;
        self.time = wptPt.time;
        self.elevation = wptPt.elevation;
        self.speed = wptPt.speed;
        self.verticalDilutionOfPrecision = wptPt.verticalDilutionOfPrecision;
        self.horizontalDilutionOfPrecision = wptPt.horizontalDilutionOfPrecision;
        self.heading = wptPt.heading;
//        self.deleted = wptPt.deleted;
//        self.speedColor = wptPt.speedColor;
//        self.altitudeColor = wptPt.altitudeColor;
//        self.slopeColor = wptPt.slopeColor;
//        self.colourARGB = wptPt.colourARGB;
        self.distance = wptPt.distance;
        self.wrapper = wptPt.wrapper;
    }
    return self;
}

- (NSString *)getIcon
{
    NSString *value = [self getExtensionByKey:ICON_NAME_EXTENSION].value;
    return value ? value : DEFAULT_ICON_NAME;
}

- (void)setIcon:(NSString *)iconName
{
    [self setExtension:ICON_NAME_EXTENSION value:iconName];
}

- (OAPOI *) getAmenity
{
    NSArray<OAGpxExtension *> *extensionsToRead = [self extensions];
    if (extensionsToRead && extensionsToRead.count > 0)
    {
        NSMutableDictionary<NSString *, NSString *> *extensions = [NSMutableDictionary dictionary];
        for (OAGpxExtension *extension in extensionsToRead)
            extensions[extension.name] = extension.value;

        return [OAPOI fromTagValue:extensions privatePrefix:PRIVATE_PREFIX osmPrefix:OSM_PREFIX];
    }
    return nil;
}

- (void) setAmenity:(OAPOI *)amenity
{
    if (amenity)
    {
        NSDictionary<NSString *, NSString *> *extensions = [amenity toTagValue:PRIVATE_PREFIX osmPrefix:OSM_PREFIX];
        if (extensions && extensions.count > 0)
        {
            [extensions enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull value, BOOL * _Nonnull stop) {
                [self setExtension:key value:value];
            }];
        }
    }
}

- (NSString *) getAmenityOriginName
{
    NSString *value = [self getExtensionByKey:AMENITY_ORIGIN_EXTENSION].value;
    return value;
}

- (void) setAmenityOriginName:(NSString *)originName
{
    [self setExtension:AMENITY_ORIGIN_EXTENSION value:originName];
}

- (NSString *)getBackgroundIcon
{
    NSString *value = [self getExtensionByKey:BACKGROUND_TYPE_EXTENSION].value;
    return value ? value : @"circle";
}

- (void)setBackgroundIcon:(NSString *)backgroundIconName
{
    [self setExtension:BACKGROUND_TYPE_EXTENSION value:backgroundIconName];
}

- (NSString *)getAddress
{
    NSString *value = [self getExtensionByKey:ADDRESS_EXTENSION].value;
    return value ? value : @"";
}

- (NSString *) getProfileType
{
    OAGpxExtension *e = [self getExtensionByKey:PROFILE_TYPE_EXTENSION];
    if (e)
        return e.value;
    return nil;
}

- (void) setProfileType:(NSString *)profileType
{
    [self setExtension:PROFILE_TYPE_EXTENSION value:profileType];
}

- (void) removeProfileType
{
    OAGpxExtension *e = [self getExtensionByKey:PROFILE_TYPE_EXTENSION];
    if (e)
    {
        NSMutableArray *extensions = [self.extensions mutableCopy];
        [extensions removeObject:e];

        self.extensions = extensions;
    }
}

- (BOOL) hasProfile
{
    NSString *profileType = self.getProfileType;
    return profileType != nil && ![GAP_PROFILE_TYPE isEqualToString:profileType];
}

- (NSInteger) getTrkPtIndex
{
    OAGpxExtension *e = [self getExtensionByKey:TRKPT_INDEX_EXTENSION];
    return e ? e.value.integerValue : -1;
}

- (void) setTrkPtIndex:(NSInteger)index
{
    NSString *stringValue = [NSString stringWithFormat:@"%ld", index];
    [self setExtension:TRKPT_INDEX_EXTENSION value:stringValue];
}

- (BOOL) isGap
{
    NSString *profileType = [self getProfileType];
    return [GAP_PROFILE_TYPE isEqualToString:profileType];
}

- (void)setGap
{
    [self setProfileType:GAP_PROFILE_TYPE];
}

- (double) getLatitude
{
    return self.position.latitude;
}

- (double) getLongitude
{
    return self.position.longitude;
}

- (UIColor *)getColor
{
    int color = [self getColor:0];
    return color != 0 ? UIColorFromARGB(color) : [OADefaultFavorite getDefaultColor];
}

- (OAPointDescription *) getPointDescription
{
    return [[OAPointDescription alloc] initWithType:POINT_TYPE_WPT name:self.name];
}

- (BOOL) isVisible
{
    return YES;
}

- (BOOL) isEqual:(id)o
{
    if (self == o)
        return YES;
    if (!o || ![self isKindOfClass:[o class]])
        return NO;

    OAWptPt *wptPt = (OAWptPt *) o;
    if (!self.name && wptPt.name)
        return NO;
    if (self.name && ![self.name isEqualToString:wptPt.name])
        return NO;

    if (![OAUtilities isCoordEqual:self.position.latitude
                            srcLon:self.position.longitude
                           destLat:wptPt.position.latitude
                           destLon:wptPt.position.longitude])
        return NO;

    if (!self.desc && wptPt.desc)
        return NO;
    if (self.desc && ![self.desc isEqualToString:wptPt.desc])
        return NO;

    if (self.time != wptPt.time)
        return NO;
    
    if (self.heading != wptPt.heading)
        return NO;

    if (!self.type && wptPt.type)
        return NO;
    if (self.type && ![self.type isEqualToString:wptPt.type])
        return NO;

    return YES;
}

- (NSUInteger) hash
{
    NSUInteger result = self.time;
    result = 31 * result + [@(self.position.latitude) hash];
    result = 31 * result + [@(self.position.longitude) hash];
    result = 31 * result + (self.name ? [self.name hash] : 0);
    result = 31 * result + (self.desc ? [self.desc hash] : 0);
    result = 31 * result + (self.type ? [self.type hash] : 0);
    result = 31 * result + [@(self.heading) hash];
    return result;
}

@end

@implementation OARouteSegment

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.wrapper = [[OARouteSegmentNativeWrapper alloc] init];
    }
    return self;
}

- (instancetype)initWithNativeWrapper:(OARouteSegmentNativeWrapper *)wrapper
{
    self = [super init];
    if (self)
    {
        self.wrapper = wrapper;
    }
    return self;
}

@end

@implementation OARouteType

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.wrapper = [[OARouteTypeNativeWrapper alloc] init];
    }
    return self;
}

- (instancetype)initWithNativeWrapper:(OARouteTypeNativeWrapper *)wrapper
{
    self = [super init];
    if (self)
    {
        self.wrapper = wrapper;
    }
    return self;
}

@end

@implementation OATrkSegment

@dynamic wrapper;

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _routeTypes = [NSMutableArray new];
        _routeSegments = [NSMutableArray new];
        self.wrapper = [[OATrkSegmentNativeWrapper alloc] init];
    }
    return self;
}

-(NSArray*) splitByDistance:(double)meters joinSegments:(BOOL)joinSegments
{
    return [self split:[[OADistanceMetric alloc] init] secondaryMetric:[[OATimeSplit alloc] init] metricLimit:meters joinSegments:joinSegments];
}

-(NSArray*) splitByTime:(int)seconds joinSegments:(BOOL)joinSegments
{
    return [self split:[[OATimeSplit alloc] init] secondaryMetric:[[OADistanceMetric alloc] init] metricLimit:seconds joinSegments:joinSegments];
}

-(NSArray*) split:(OASplitMetric*)metric secondaryMetric:(OASplitMetric *)secondaryMetric metricLimit:(double)metricLimit joinSegments:(BOOL)joinSegments
{
    NSMutableArray *splitSegments = [NSMutableArray array];
    [OAGPXTrackAnalysis splitSegment:metric secondaryMetric:secondaryMetric metricLimit:metricLimit splitSegments:splitSegments segment:self joinSegments:joinSegments];
    return [OAGPXTrackAnalysis convert:splitSegments];
}

- (BOOL) hasRoute
{
    return _routeSegments.count > 0 && _routeTypes.count > 0;
}

- (void) fillRouteDetails
{
    if (self.wrapper.trkseg)
    {
        for (auto& rteSeg : self.wrapper.trkseg->routeSegments)
        {
            [_routeSegments addObject:[[OARouteSegment alloc] initWithNativeWrapper:[[OARouteSegmentNativeWrapper alloc] initWithRteSegment:rteSeg]]];
        }
        for (auto& rteType : self.wrapper.trkseg->routeTypes)
        {
            [_routeTypes addObject:[[OARouteType alloc] initWithNativeWrapper:[[OARouteTypeNativeWrapper alloc] initWithRteType:rteType]]];
        }
    }
}

- (void) fillExtensions
{
    if (_routeSegments.count > 0)
    {
        OAGpxExtension *ext = [[OAGpxExtension alloc] init];
        ext.name = @"route";
        NSMutableArray<OAGpxExtension *> *subexts = [NSMutableArray new];
        for (OARouteSegment *seg in _routeSegments)
        {
            OAGpxExtension *subExt = [[OAGpxExtension alloc] init];
            subExt.name = @"segment";
            subExt.attributes = [seg.wrapper toDictionary];
            [subexts addObject:subExt];
        }
        ext.subextensions = subexts;
        [self addExtension:ext];
    }
    if (_routeTypes.count > 0)
    {
        OAGpxExtension *ext = [[OAGpxExtension alloc] init];
        ext.name = @"types";
        NSMutableArray<OAGpxExtension *> *subexts = [NSMutableArray new];
        for (OARouteType *type in _routeTypes)
        {
            OAGpxExtension *subExt = [[OAGpxExtension alloc] init];
            subExt.name = @"type";
            subExt.attributes = [type.wrapper toDictionary];
            [subexts addObject:subExt];
        }
        ext.subextensions = subexts;
        [self addExtension:ext];
    }
}

@end

@implementation OATrack

@dynamic wrapper;

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.wrapper = [[OATrackNativeWrapper alloc] init];
    }
    return self;
}

@end

@implementation OARoute

@dynamic wrapper;

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.wrapper = [[OARouteNativeWrapper alloc] init];
    }
    return self;
}

@end
