//
//  OAOsmAndFormatter.h
//  OsmAnd
//
//  Created by nnngrach on 08.09.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAAppSettings.h"

@class OsmAndFormatterParams;

static const NSInteger METERS_IN_KILOMETER = 1000;
static const CGFloat METERS_IN_ONE_MILE = 1609.344f;
static const CGFloat METERS_IN_ONE_NAUTICALMILE = 1852.f;
static const CGFloat YARDS_IN_ONE_METER = 1.0936f;
static const CGFloat FEET_IN_ONE_METER = YARDS_IN_ONE_METER * 3;

@interface OAOsmAndFormatter : NSObject

#define MILS_IN_DEGREE 17.777778f

#define FORMAT_DEGREES_SHORT 6
#define FORMAT_DEGREES 0
#define FORMAT_MINUTES 1
#define FORMAT_SECONDS 2
#define FORMAT_UTM 3
#define FORMAT_OLC 4
#define FORMAT_MGRS 5

#define DELIM @":"
#define DELIMITER_DEGREES @"°"
#define DELIMITER_MINUTES @"′"
#define DELIMITER_SECONDS @"″"
#define DELIMITER_SPACE @" "

#define NORTH @"N"
#define SOUTH @"S"
#define WEST @"W"
#define EAST @"E"

+ (double)calculateRoundedDist:(double)baseMetersDist;
+ (NSString *)getFormattedDistance:(float)meters withParams:(OsmAndFormatterParams *)params valueUnitArray:(NSMutableArray <NSString *>*)valueUnitArray;
+ (NSString *)getFormattedDistance:(float)meters;
+ (NSString *)getFormattedDistance:(float)meters withParams:(OsmAndFormatterParams *)params;
+ (NSString *)getFormattedAlarmInfoDistance:(float)meters;
+ (NSString *)getFormattedAzimuth:(float)bearing;
+ (NSString *)getFormattedTimeHM:(NSTimeInterval)timeInterval;
+ (NSString *)getFormattedTimeInterval:(NSTimeInterval)interval;
+ (NSString *)getFormattedTimeInterval:(NSTimeInterval)timeInterval shortFormat:(BOOL)shortFormat;
+ (NSString *)getFormattedPassedTime:(NSTimeInterval)time def:(NSString *)def;
+ (NSString *)getFormattedDateTime:(NSTimeInterval)time;
+ (NSString *)getFormattedDate:(NSTimeInterval)time;
+ (NSString *)getFormattedSpeed:(float)metersperseconds;
+ (NSString *)getFormattedSpeed:(float)metersperseconds speedSystem:(EOASpeedConstant)speedSystem;
+ (NSString *)getFormattedSpeed:(float)metersperseconds valueUnitArray:(NSMutableArray <NSString *>*)valueUnitArray;
+ (NSString *)getFormattedAlt:(double)alt;
+ (NSString *)getFormattedAlt:(double)alt mc:(EOAMetricsConstant)mc;
+ (NSString *)getFormattedAlt:(double)alt mc:(EOAMetricsConstant)mc valueUnitArray:(NSMutableArray <NSString *>*)valueUnitArray;
+ (NSString *)getFormattedCoordinatesWithLat:(double)lat lon:(double)lon outputFormat:(NSInteger)outputFormat;
+ (NSString *)getFormattedDistanceInterval:(double)interval withParams:(OsmAndFormatterParams *)params;
+ (NSString *)getFormattedOsmTagValue:(NSString *)tagValue;
+ (NSString *)getFormattedDurationShort:(NSTimeInterval)seconds fullForm:(BOOL)fullForm;
+ (NSString *)getFormattedDuration:(NSTimeInterval)seconds;
+ (NSTimeInterval)getStartOfDayForTime:(NSTimeInterval)timestamp;
+ (NSTimeInterval)getStartOfToday;
+ (NSString *)formatValue:(float)value
                     unit:(NSString *)unit
      forceTrailingZeroes:(BOOL)forceTrailingZeroes
      decimalPlacesNumber:(NSInteger)decimalPlacesNumber
           valueUnitArray:(NSMutableArray <NSString *>*)valueUnitArray;

@end
