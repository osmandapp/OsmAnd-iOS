//
//  OARouteColorize.mm
//  OsmAnd Maps
//
//  Created by Paul on 24.09.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OARouteColorize.h"
#import "OARouteColorize+cpp.h"
#import "OsmAnd_Maps-Swift.h"
#import "OsmAndSharedWrapper.h"

@implementation OARouteColorizationPoint

- (instancetype)initWithIdentifier:(NSInteger)identifier lat:(CGFloat)lat lon:(CGFloat)lon val:(CGFloat)val
{
    self = [super init];
    if (self)
    {
        self.identifier = identifier;
        self.lat = lat;
        self.lon = lon;
        self.val = val;
        self.color = 0;
    }
    return self;
}

@end

@implementation OARouteColorize
{
    OASRouteColorize *_routeColorize;
}

- (instancetype)initWithGpxFile:(OASGpxFile *)gpxFile
                       analysis:(OASGpxTrackAnalysis *)analysis
                           type:(NSInteger)colorizationType
                        palette:(nullable OASColorPalette *)palette
                maxProfileSpeed:(float)maxProfileSpeed
                    fixedValues:(BOOL)fixedValues
{
    if (!gpxFile.hasTrkPt)
    {
        NSLog(@"GPX file is not consist of track points");
        return nil;
    }
    self = [super init];
    if (self)
    {
        _routeColorize = [[OASRouteColorize alloc] initWithGpxFile:gpxFile
                                                          analysis:analysis
                                                              type:[self.class sharedColorizationType:colorizationType]
                                                           palette:palette
                                                   maxProfileSpeed:maxProfileSpeed
                                                       fixedValues:fixedValues];
    }
    return self;
}

- (NSArray<OARouteColorizationPoint *> *)getResult
{
    NSMutableArray<OARouteColorizationPoint *> *result = [NSMutableArray array];
    for (OASRouteColorizeRouteColorizationPoint *colorizationPoint in _routeColorize.result)
    {
        OARouteColorizationPoint *point = [[OARouteColorizationPoint alloc] initWithIdentifier:colorizationPoint.id
                                                                                           lat:colorizationPoint.lat
                                                                                           lon:colorizationPoint.lon
                                                                                           val:colorizationPoint.value];
        point.color = colorizationPoint.primaryColor;
        [result addObject:point];
    }
    return result;
}

- (QList<OsmAnd::FColorARGB>)getResultQList
{
    QList<OsmAnd::FColorARGB> result;
    for (OASRouteColorizeRouteColorizationPoint *colorizationPoint in _routeColorize.result)
    {
        result.append(OsmAnd::ColorARGB((uint32_t) colorizationPoint.primaryColor));
    }
    
    return result;
}

+ (OASRouteColorizeColorizationType *)sharedColorizationType:(NSInteger)colorizationType
{
    switch ((ColorizationType) colorizationType)
    {
        case ColorizationTypeElevation:
            return OASRouteColorizeColorizationType.elevation;
        case ColorizationTypeSpeed:
            return OASRouteColorizeColorizationType.speed;
        case ColorizationTypeSlope:
            return OASRouteColorizeColorizationType.slope;
        case ColorizationTypeNone:
        default:
            return OASRouteColorizeColorizationType.none;
    }
}

+ (NSArray<NSNumber *> *)colorsFromSharedPalette:(nullable OASColorPalette *)palette
{
    if (!palette)
        return @[];
    
    NSMutableArray<NSNumber *> *colors = [NSMutableArray array];
    for (OASColorPaletteColorValue *colorValue in palette.colors)
    {
        [colors addObject:@(colorValue.clr)];
    }
    
    return colors;
}

@end
