//
//  OAGPXUIHelper.h
//  OsmAnd Maps
//
//  Created by Paul on 9/12/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OAGPXDocument, OAGpxTrkSeg;
@class OARouteCalculationResult;
@class OAGPX;

@interface OAGPXUIHelper : NSObject

+ (OAGPXDocument *) makeGpxFromRoute:(OARouteCalculationResult *)route;
+ (NSString *) getDescription:(OAGPX *)gpx;

+ (long) getSegmentTime:(OAGpxTrkSeg *)segment;
+ (double) getSegmentDistance:(OAGpxTrkSeg *)segment;

@end

