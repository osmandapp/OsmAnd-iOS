//
//  OARouteLayer.h
//  OsmAnd
//
//  Created by Alexey Kulish on 11/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OASymbolMapLayer.h"

@class OATrackChartPoints;

@interface OARouteLayer : OASymbolMapLayer

- (void) refreshRoute;

- (void) showCurrentStatisticsLocation:(OATrackChartPoints *) trackPoints;
- (void) hideCurrentStatisticsLocation;

@end
