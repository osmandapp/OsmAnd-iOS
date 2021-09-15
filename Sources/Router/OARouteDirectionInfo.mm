//
//  OARouteDirectionInfo.m
//  OsmAnd
//
//  Created by Alexey Kulish on 29/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OARouteDirectionInfo.h"
#import "OsmAndApp.h"
#import "OAUtilities.h"
#import "OAOsmAndFormatter.h"


@implementation OARouteDirectionInfo
{
    // Description of the turn and route after
    NSString *_descriptionRoute;
}

- (instancetype)initWithAverageSpeed:(float)averageSpeed turnType:(std::shared_ptr<TurnType>)turnType
{
    self = [super init];
    if (self)
    {
        _routeEndPointOffset = 0;
        _descriptionRoute = @"";
        _averageSpeed = averageSpeed == 0 || isnan(averageSpeed) ? 1 : averageSpeed;
        _turnType = turnType;
    }
    return self;
}

-(void)setAverageSpeed:(float)averageSpeed
{
    _averageSpeed = averageSpeed == 0 || isnan(averageSpeed) ? 1 : averageSpeed;
}

- (NSString *) getDescriptionRoute
{
    if (![_descriptionRoute hasSuffix:[OAOsmAndFormatter getFormattedDistance:self.distance]]) {
        [_descriptionRoute stringByAppendingFormat:@" %@", [OAOsmAndFormatter getFormattedDistance:self.distance]];
    }
    return [_descriptionRoute trim];
}

- (NSString *) getDescriptionRoutePart
{
    return _descriptionRoute;
}

- (NSString *) getDescriptionRoute:(int) collectedDistance
{
    if (![_descriptionRoute hasSuffix:[OAOsmAndFormatter getFormattedDistance:collectedDistance]]) {
        [_descriptionRoute stringByAppendingFormat:@" %@", [OAOsmAndFormatter getFormattedDistance:collectedDistance]];
    }
    return [_descriptionRoute trim];
}

- (void) setDescriptionRoute:(NSString *)descriptionRoute
{
    _descriptionRoute = descriptionRoute;
}

- (long) getExpectedTime
{
    return (long) round(self.distance / self.averageSpeed);
}

@end
