//
//  OAColoringType.m
//  OsmAnd Maps
//
//  Created by Paul on 25.09.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAColoringType.h"
#import "Localization.h"
#import "OARouteStatisticsHelper.h"
#import "OARouteCalculationResult.h"
#import "OAGPXDocument.h"
#import "OAGPXTrackAnalysis.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAAppSettings.h"
#import "OARouteExporter.h"
#import "OARouteProvider.h"

#include <CommonCollections.h>
#include <commonOsmAndCore.h>

static OAColoringType * DEFAULT;
static OAColoringType * CUSTOM_COLOR;
static OAColoringType * TRACK_SOLID;
static OAColoringType * SPEED;
static OAColoringType * ALTITUDE;
static OAColoringType * SLOPE;
static OAColoringType * ATTRIBUTE;

static NSArray<OAColoringType *> * ROUTE_COLORING_TYPES = @[OAColoringType.DEFAULT, OAColoringType.CUSTOM_COLOR, OAColoringType.ALTITUDE, OAColoringType.SLOPE, OAColoringType.ATTRIBUTE];
static NSArray<OAColoringType *> * TRACK_COLORING_TYPES = @[/*OAColoringType.TRACK_SOLID,*/ OAColoringType.SPEED, OAColoringType.ALTITUDE, OAColoringType.SLOPE/*, OAColoringType.ATTRIBUTE*/];

@implementation OAColoringType

- (instancetype) initWithName:(NSString *)name title:(NSString *)title iconName:(NSString *)iconName
{
    self = [super init];
    if (self) {
        _title = title;
        _name = name;
        _iconName = iconName;
    }
    return self;
}

+ (OAColoringType *) DEFAULT
{
    if (!DEFAULT)
    {
        DEFAULT = [[OAColoringType alloc] initWithName:@"default" title:OALocalizedString(@"map_settings_style") iconName:@"ic_custom_map_style"];
    }
    return DEFAULT;
}

+ (OAColoringType *) CUSTOM_COLOR
{
    if (!CUSTOM_COLOR)
    {
        CUSTOM_COLOR = [[OAColoringType alloc] initWithName:@"custom_color" title:OALocalizedString(@"shared_string_custom") iconName:@"ic_custom_settings"];
    }
    return CUSTOM_COLOR;
}

+ (OAColoringType *) TRACK_SOLID
{
    if (!TRACK_SOLID)
    {
        // TODO: ask for icon
        TRACK_SOLID = [[OAColoringType alloc] initWithName:@"solid" title:OALocalizedString(@"track_coloring_solid") iconName:@"ic_bg_point_circle_center"];
    }
    return TRACK_SOLID;
}

+ (OAColoringType *) SPEED
{
    if (!SPEED)
    {
        SPEED = [[OAColoringType alloc] initWithName:@"speed" title:OALocalizedString(@"gpx_speed") iconName:@"ic_action_max_speed"];
    }
    return SPEED;
}

+ (OAColoringType *) ALTITUDE
{
    if (!ALTITUDE)
    {
        ALTITUDE = [[OAColoringType alloc] initWithName:@"altitude" title:OALocalizedString(@"map_widget_altitude") iconName:@"ic_action_altitude"];
    }
    return ALTITUDE;
}

+ (OAColoringType *) SLOPE
{
   if (!SLOPE)
   {
       SLOPE = [[OAColoringType alloc] initWithName:@"slope" title:OALocalizedString(@"gpx_slope") iconName:@"ic_custom_altitude_and_slope"];
   }
    return SLOPE;
}

+ (OAColoringType *) ATTRIBUTE
{
    if (!ATTRIBUTE)
    {
        ATTRIBUTE = [[OAColoringType alloc] initWithName:@"attribute" title:OALocalizedString(@"attribute") iconName:@"ic_action_altitude"];
    }
    return ATTRIBUTE;
}

- (NSString *) getName:(NSString *)routeInfoAttribute
{
    if (![self isRouteInfoAttribute])
        return _name;
    else
        return routeInfoAttribute.length == 0 ? nil : routeInfoAttribute;
}

- (NSString *) getHumanString:(NSString *)routeInfoAttribute
{
    return [self isRouteInfoAttribute]
    ? [self getHumanStringRouteInfoAttribute:routeInfoAttribute]
    : _title;
}

- (NSString *) getHumanStringRouteInfoAttribute:(NSString *)routeInfoAttribute
{
    NSString *routeInfoPrefix = ROUTE_INFO_PREFIX;
    if (![self isRouteInfoAttribute] || routeInfoAttribute == nil
        || ![routeInfoAttribute hasPrefix:routeInfoPrefix])
    {
        return @"";
    }
    NSString *attr = [routeInfoAttribute stringByReplacingOccurrencesOfString:routeInfoPrefix withString:@""];
    return OALocalizedString([NSString stringWithFormat:@"routeInfo_%@_name", attr]);
}

- (BOOL) isDefault
{
    return self == self.class.DEFAULT;
}

- (BOOL) isCustomColor
{
    return self == self.class.CUSTOM_COLOR;
}

- (BOOL) isTrackSolid
{
    return self == self.class.TRACK_SOLID;
}

- (BOOL) isSolidSingleColor
{
    return [self isDefault] || [self isCustomColor] || [self isTrackSolid];
}

- (BOOL) isGradient
{
    return self == self.class.SPEED || self == self.class.ALTITUDE || self == self.class.SLOPE;
}

- (BOOL) isRouteInfoAttribute
{
    return self == self.class.ATTRIBUTE;
}

- (BOOL) isAvailableForDrawingRoute:(OARouteCalculationResult *)route attributeName:(NSString *)attributeName
{
    if ([self isGradient])
    {
        NSArray<CLLocation *> *locations = route.getImmutableAllLocations;
        for (CLLocation *location in locations)
        {
            if (!isnan(location.altitude) && location.altitude > 0)
                return YES;
        }
        return NO;
    }
    
    if ([self isRouteInfoAttribute])
    {
        return !route.getOriginalRoute.empty() && [self isAttributeAvailableForDrawing:route.getOriginalRoute attributeName:attributeName];
    }
    
    return YES;
}

- (BOOL) isAvailableForDrawingTrack:(OAGPXDocument *)selectedGpxFile attributeName:(NSString *)attributeName
{
    if ([self isGradient])
        return [[selectedGpxFile getAnalysis:0] isColorizationTypeAvailable:[[self toGradientScaleType] toColorizationType]];
    
    if ([self isRouteInfoAttribute])
    {
        const auto routeSegments = [self getRouteSegmentsInTrack:selectedGpxFile];
        if (routeSegments.empty())
            return NO;
        return [self isAttributeAvailableForDrawing:routeSegments attributeName:attributeName];
    }
    
    return YES;
}


- (BOOL) isAvailableInSubscription:(NSString *)attributeName route:(BOOL)route
{
    // TODO: restrict access with subscription
//    if ((isRouteInfoAttribute() && route) || this == ColoringType.SLOPE) {
//        return InAppPurchaseHelper.isOsmAndProAvailable(app);
//    }
    return YES;
}

- (std::vector<std::shared_ptr<RouteSegmentResult>>) getRouteSegmentsInTrack:(OAGPXDocument *)gpxFile
{
    if (![OSMAND_ROUTER_V2 isEqualToString:gpxFile.creator])
        return {};
    
    std::vector<std::shared_ptr<RouteSegmentResult>> routeSegments;
    for (NSInteger i = 0; i < [gpxFile getNonEmptyTrkSegments:NO].count; i++)
    {
        OAGpxTrkSeg *segment = [gpxFile getNonEmptyTrkSegments:NO][i];
        if (segment.hasRoute)
        {
            const auto rt = [OARouteProvider parseOsmAndGPXRoute:[NSMutableArray array] gpxFile:gpxFile segmentEndpoints:[NSMutableArray array] selectedSegment:i];
            if (!rt.empty())
                routeSegments.insert(routeSegments.end(), rt.begin(), rt.end());
        }
    }
    return routeSegments;
}

- (BOOL) isAttributeAvailableForDrawing:(const std::vector<std::shared_ptr<RouteSegmentResult>> &)routeSegments
                          attributeName:(NSString *)attributeName
{
    if (routeSegments.empty() || attributeName.length == 0)
        return NO;
    
    NSArray<OARouteStatistics *> *stats = [OARouteStatisticsHelper calculateRouteStatistic:routeSegments attributeNames:@[attributeName]];
    
    return stats.count > 0;
}

- (OAGradientScaleType *) toGradientScaleType
{
    if (self == self.class.SPEED)
        return [OAGradientScaleType withGradientScaleType:EOAGradientScaleTypeSpeed];
    else if (self == self.class.ALTITUDE)
        return [OAGradientScaleType withGradientScaleType:EOAGradientScaleTypeAltitude];
    else if (self == self.class.SLOPE)
        return [OAGradientScaleType withGradientScaleType:EOAGradientScaleTypeSlope];
    else
        return nil;
}

+ (OAColoringType *) fromGradientScaleType:(EOAGradientScaleType)scaleType
{
    if (scaleType == EOAGradientScaleTypeSpeed)
        return self.SPEED;
    else if (scaleType == EOAGradientScaleTypeAltitude)
        return self.ALTITUDE;
    else if (scaleType == EOAGradientScaleTypeSlope)
        return self.SLOPE;
    return nil;
}

+ (NSString *) getRouteInfoAttribute:(NSString *)name
{
    return name.length > 0 && [name hasPrefix:ROUTE_INFO_PREFIX] ? name : nil;
}

+ (OAColoringType *) getRouteColoringTypeByName:(NSString *)name
{
    OAColoringType *defined = [self getColoringTypeByName:ROUTE_COLORING_TYPES name:name];
    return defined == nil ? self.DEFAULT : defined;
}

+ (OAColoringType *) getNonNullTrackColoringTypeByName:(NSString *)name
{
    OAColoringType *defined = [self getColoringTypeByName:TRACK_COLORING_TYPES name:name];
    return defined == nil ? self.TRACK_SOLID : defined;
}

+ (OAColoringType *) getNullableTrackColoringTypeByName:(NSString *)name
{
    return [self getColoringTypeByName:TRACK_COLORING_TYPES name:name];
}

+ (OAColoringType *) getColoringTypeByName:(NSArray<OAColoringType *> *)from name:(NSString *)name
{
    if ([self getRouteInfoAttribute:name].length > 0)
        return self.ATTRIBUTE;
    for (OAColoringType *coloringType in from)
    {
        if ([coloringType.name.lowerCase isEqualToString:name] && coloringType != self.ATTRIBUTE)
        {
            return coloringType;
        }
    }
    return nil;
}

+ (NSArray<OAColoringType *> *) getRouteColoringTypes
{
    return ROUTE_COLORING_TYPES;
}

+ (NSArray<OAColoringType *> *) getTrackColoringTypes
{
    return TRACK_COLORING_TYPES;
}

@end
