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

@end

@implementation OAGpxExtensions

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _extensions = @[];
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
        _extensions = [_extensions arrayByAddingObjectsFromArray:e.extensions];
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

- (NSArray<OAGpxExtension *> *)fetchExtension:(QList<OsmAnd::Ref<OsmAnd::GpxExtensions::GpxExtension>>)extensions
{
    if (!extensions.isEmpty())
    {
        NSMutableArray<OAGpxExtension *> *extensionsArray = [NSMutableArray array];
        for (const auto &ext: extensions)
        {
            OAGpxExtension *e = [[OAGpxExtension alloc] init];
            e.name = ext->name.toNSString().lowerCase;
            e.value = ext->value.toNSString();
            if (!ext->attributes.isEmpty())
            {
                NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                for (const auto &entry: OsmAnd::rangeOf(OsmAnd::constOf(ext->attributes)))
                {
                    dict[entry.key().toNSString()] = entry.value().toNSString();
                }
                e.attributes = dict;
            }
            e.subextensions = [self fetchExtension:ext->subextensions];
            [extensionsArray addObject:e];
        }
        return extensionsArray;
    }
    return @[];
}

- (void)fetchExtensions:(std::shared_ptr<OsmAnd::GpxExtensions>)extensions
{
    self.value = extensions->value.toNSString();
    if (!extensions->attributes.isEmpty()) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        for (const auto &entry: OsmAnd::rangeOf(OsmAnd::constOf(extensions->attributes))) {
            [dict setObject:entry.value().toNSString() forKey:entry.key().toNSString()];
        }
        self.attributes = dict;
    }

    self.extensions = [self fetchExtension:extensions->extensions];
}

- (void)fillExtension:(const std::shared_ptr<OsmAnd::GpxExtensions::GpxExtension>&)extension ext:(OAGpxExtension *)e
{
    extension->name = QString::fromNSString(e.name);
    extension->value = QString::fromNSString(e.value);
    for (NSString *key in e.attributes.allKeys)
    {
        extension->attributes[QString::fromNSString(key)] = QString::fromNSString(e.attributes[key]);
    }
    for (OAGpxExtension *es in e.subextensions)
    {
        std::shared_ptr<OsmAnd::GpxExtensions::GpxExtension> subextension(new OsmAnd::GpxExtensions::GpxExtension());
        [self fillExtension:subextension ext:es];
        extension->subextensions.push_back(subextension);
        subextension.reset();
    }
}

- (void)fillExtensions:(const std::shared_ptr<OsmAnd::GpxExtensions>&)extensions
{
    extensions->extensions.clear();
    for (OAGpxExtension *e in self.extensions)
    {
        std::shared_ptr<OsmAnd::GpxExtensions::GpxExtension> extension(new OsmAnd::GpxExtensions::GpxExtension());
        [self fillExtension:extension ext:e];
        extensions->extensions.push_back(extension);
        extension.reset();
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
    [self setExtension:@"color" value:hexString];
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
    return color != 0 ? UIColorFromRGBA(color) : [OADefaultFavorite getDefaultColor];
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

- (instancetype)initWithDictionary:(NSDictionary<NSString *,NSString *> *)dict
{
    self = [super init];
    if (self) {
        _identifier = dict[@"id"];
        _length = dict[@"length"];
        _segmentTime = dict[@"segmentTime"];
        _speed = dict[@"speed"];
        _turnType = dict[@"turnType"];
        _turnAngle = dict[@"turnAngle"];
        _types = dict[@"types"];
        _pointTypes = dict[@"pointTypes"];
        _names = dict[@"names"];
    }
    return self;
}

- (instancetype) initWithRteSegment:(OsmAnd::Ref<OsmAnd::GpxDocument::RouteSegment> &)seg
{
    self = [super init];
    if (self) {
        _identifier = seg->id.toNSString();
        _length = seg->length.toNSString();
        _segmentTime = seg->segmentTime.toNSString();
        _speed = seg->speed.toNSString();
        _turnType = seg->turnType.toNSString();
        _turnAngle = seg->turnAngle.toNSString();
        _types = seg->types.toNSString();
        _pointTypes = seg->pointTypes.toNSString();
        _names = seg->names.toNSString();
    }
    return self;
}

+ (OARouteSegment *) fromStringBundle:(const std::shared_ptr<RouteDataBundle> &)bundle
{
    OARouteSegment *s = [[OARouteSegment alloc] init];
    s.identifier = [NSString stringWithUTF8String:bundle->getString("id", "").c_str()];
    s.length = [NSString stringWithUTF8String:bundle->getString("length", "").c_str()];
    s.segmentTime = [NSString stringWithUTF8String:bundle->getString("segmentTime", "").c_str()];
    s.speed = [NSString stringWithUTF8String:bundle->getString("speed", "").c_str()];
    s.turnType = [NSString stringWithUTF8String:bundle->getString("turnType", "").c_str()];
    s.turnAngle = [NSString stringWithUTF8String:bundle->getString("turnAngle", "").c_str()];
    s.types = [NSString stringWithUTF8String:bundle->getString("types", "").c_str()];
    s.pointTypes = [NSString stringWithUTF8String:bundle->getString("pointTypes", "").c_str()];
    s.names = [NSString stringWithUTF8String:bundle->getString("names", "").c_str()];
    return s;
}

- (std::shared_ptr<RouteDataBundle>) toStringBundle
{
    auto bundle = std::make_shared<RouteDataBundle>();
    [self addToBundleIfNotNull:"id" value:_identifier bundle:bundle];
    [self addToBundleIfNotNull:"length" value:_length bundle:bundle];
    [self addToBundleIfNotNull:"segmentTime" value:_segmentTime bundle:bundle];
    [self addToBundleIfNotNull:"speed" value:_speed bundle:bundle];
    [self addToBundleIfNotNull:"turnType" value:_turnType bundle:bundle];
    [self addToBundleIfNotNull:"turnAngle" value:_turnAngle bundle:bundle];
    [self addToBundleIfNotNull:"types" value:_types bundle:bundle];
    [self addToBundleIfNotNull:"pointTypes" value:_pointTypes bundle:bundle];
    [self addToBundleIfNotNull:"names" value:_names bundle:bundle];
    return bundle;
}

- (void) addToBundleIfNotNull:(const string&)key value:(NSString *)value bundle:(std::shared_ptr<RouteDataBundle> &)bundle
{
    if (value)
        bundle->put(key, value.UTF8String);
}

- (NSDictionary<NSString *,NSString *> *)toDictionary
{
    NSMutableDictionary<NSString *, NSString *> *res = [NSMutableDictionary new];
    [self addIfValueNotEmpty:res key:@"id" value:_identifier];
    [self addIfValueNotEmpty:res key:@"length" value:_length];
    [self addIfValueNotEmpty:res key:@"segmentTime" value:_segmentTime];
    [self addIfValueNotEmpty:res key:@"speed" value:_speed];
    [self addIfValueNotEmpty:res key:@"turnType" value:_turnType];
    [self addIfValueNotEmpty:res key:@"turnAngle" value:_turnAngle];
    [self addIfValueNotEmpty:res key:@"types" value:_types];
    [self addIfValueNotEmpty:res key:@"pointTypes" value:_pointTypes];
    [self addIfValueNotEmpty:res key:@"names" value:_names];
    return res;
}

- (void) addIfValueNotEmpty:(NSMutableDictionary<NSString *, NSString *> *)dict key:(NSString *)key value:(NSString *)value
{
    if (value.length > 0)
        dict[key] = value;
}

@end

@implementation OARouteType

- (instancetype)initWithDictionary:(NSDictionary<NSString *,NSString *> *)dict
{
    self = [super init];
    if (self) {
        _tag = dict[@"t"];
        _value = dict[@"v"];
    }
    return self;
}

- (instancetype) initWithRteType:(OsmAnd::Ref<OsmAnd::GpxDocument::RouteType> &)type
{
    self = [super init];
    if (self) {
        _tag = type->tag.toNSString();
        _value = type->value.toNSString();
    }
    return self;
}

+ (OARouteType *) fromStringBundle:(const std::shared_ptr<RouteDataBundle> &)bundle
{
    OARouteType *t = [[OARouteType alloc] init];
    t.tag = [NSString stringWithUTF8String:bundle->getString("t", "").c_str()];
    t.value = [NSString stringWithUTF8String:bundle->getString("v", "").c_str()];
    return t;
}

- (std::shared_ptr<RouteDataBundle>) toStringBundle
{
    auto bundle = std::make_shared<RouteDataBundle>();
    if (_tag)
        bundle->put("t", _tag.UTF8String);
    if (_value)
        bundle->put("v", _value.UTF8String);
    return bundle;
}

- (NSDictionary<NSString *,NSString *> *)toDictionary
{
    return @{
            @"t" : _tag,
            @"v" : _value
    };
}

@end

@implementation OATrkSegment

- (instancetype)init
{
    self = [super init];
    if (self) {
        _routeTypes = [NSMutableArray new];
        _routeSegments = [NSMutableArray new];
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
    if (self.trkseg)
    {
        for (auto& rteSeg : self.trkseg->routeSegments)
        {
            [_routeSegments addObject:[[OARouteSegment alloc] initWithRteSegment:rteSeg]];
        }
        for (auto& rteType : self.trkseg->routeTypes)
        {
            [_routeTypes addObject:[[OARouteType alloc] initWithRteType:rteType]];
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
            subExt.attributes = seg.toDictionary;
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
            subExt.attributes = type.toDictionary;
            [subexts addObject:subExt];
        }
        ext.subextensions = subexts;
        [self addExtension:ext];
    }
}

@end

@implementation OATrack
@end

@implementation OARoute
@end
