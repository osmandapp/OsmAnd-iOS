//
//  OALocationConvert.h
//  OsmAnd
//
//  Created by Paul on 6/29/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#define FORMAT_DEGREES_SHORT 6
#define FORMAT_DEGREES 0
#define FORMAT_MINUTES 1
#define FORMAT_SECONDS 2
#define FORMAT_UTM 3
#define FORMAT_OLC 4

@interface OALocationConvert : NSObject

+ (double) convert:(NSString *)coordinate;
+ (NSString *) convert:(double) coordinate outputType:(NSInteger)outputType;
+ (NSString *) convertLatitude:(double) latitude outputType:(NSInteger)outType addCardinalDirection:(BOOL)addCardinalDirection;
+ (NSString *) convertLongitude:(double) longitude outputType:(NSInteger)outType addCardinalDirection:(BOOL)addCardinalDirection;

+ (NSString *) getUTMCoordinateString:(double)lat lon:(double)lon;
+ (NSString *) getLocationOlcName:(double) lat lon:(double)lon;

@end

