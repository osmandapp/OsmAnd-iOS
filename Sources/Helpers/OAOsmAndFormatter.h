//
//  OAOsmAndFormatter.h
//  OsmAnd
//
//  Created by Paul on 7/4/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#define FORMAT_DEGREES_SHORT 100
#define FORMAT_DEGREES 101
#define FORMAT_MINUTES 102
#define FORMAT_SECONDS 103
#define FORMAT_UTM 104
#define FORMAT_OLC 105

@interface OAOsmAndFormatter : NSObject

+ (NSString *) formatLocationCoordinates:(double) lat lon:(double)lon format:(NSInteger)outputFormat;
+ (NSString *) getUTMCoordinateString:(double)lat lon:(double)lon;
+ (NSString *) getLocationOlcName:(double) lat lon:(double)lon;


@end
