//
//  OALocationConvert.h
//  OsmAnd
//
//  Created by Paul on 6/29/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#define FORMAT_DEGREES_SHORT 100
#define FORMAT_DEGREES 101
#define FORMAT_MINUTES 102
#define FORMAT_SECONDS 103
#define FORMAT_UTM 104
#define FORMAT_OLC 105

@interface OALocationConvert : NSObject

+ (double) convert:(NSString *)coordinate;
+ (NSString *) formatLocationCoordinates:(double) lat lon:(double)lon format:(NSInteger)outputFormat;
+ (NSString *) convert:(double) coordinate outputType:(NSInteger)outputType;
+ (NSString *) convertLatitude:(double) latitude outputType:(NSInteger)outType addCardinalDirection:(BOOL)addCardinalDirection;
+ (NSString *) convertLongitude:(double) longitude outputType:(NSInteger)outType addCardinalDirection:(BOOL)addCardinalDirection;

+ (NSString *) getUTMCoordinateString:(double)lat lon:(double)lon;
+ (NSString *) getLocationOlcName:(double) lat lon:(double)lon;

@end

