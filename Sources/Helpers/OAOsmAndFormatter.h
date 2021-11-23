//
//  OAOsmAndFormatter.h
//  OsmAnd
//
//  Created by nnngrach on 08.09.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OAOsmAndFormatter : NSObject

#define METERS_IN_KILOMETER 1000
#define METERS_IN_ONE_MILE 1609.344f // 1609.344
#define METERS_IN_ONE_NAUTICALMILE 1852.f // 1852

#define YARDS_IN_ONE_METER 1.0936f
#define FEET_IN_ONE_METER  YARDS_IN_ONE_METER * 3;

#define MILS_IN_DEGREE 17.777778f

#define FOOTS_IN_ONE_METER  3.2808f
#define METERS_IN_ONE_METER  1.0000f

#define FORMAT_DEGREES_SHORT 6
#define FORMAT_DEGREES 0
#define FORMAT_MINUTES 1
#define FORMAT_SECONDS 2
#define FORMAT_UTM 3
#define FORMAT_OLC 4

#define DELIM @":"
#define DELIMITER_DEGREES @"°"
#define DELIMITER_MINUTES @"′"
#define DELIMITER_SECONDS @"″"
#define DELIMITER_SPACE @" "

#define NORTH @"N"
#define SOUTH @"S"
#define WEST @"W"
#define EAST @"E"

+ (double) calculateRoundedDist:(double)baseMetersDist;
+ (NSString *) getFormattedDistance:(float) meters;
+ (NSString *) getFormattedAlarmInfoDistance:(float)meters;
+ (NSString *) getFormattedAzimuth:(float)bearing;
+ (NSString *) getFormattedTimeHM:(NSTimeInterval)timeInterval;
+ (NSString*) getFormattedTimeInterval:(NSTimeInterval)interval;
+ (NSString *) getFormattedTimeInterval:(NSTimeInterval)timeInterval shortFormat:(BOOL)shortFormat;
+ (NSString *) getFormattedSpeed:(float) metersperseconds drive:(BOOL)drive;
+ (NSString *) getFormattedSpeed:(float) metersperseconds;
+ (NSString *) getFormattedAlt:(double) alt;
+ (NSString *) getFormattedCoordinatesWithLat:(double)lat lon:(double)lon outputFormat:(NSInteger)outputFormat;
+ (NSString *) getFormattedDistanceInterval:(double)interval;
+ (NSString *) getFormattedOsmTagValue:(NSString *)tagValue;

@end
