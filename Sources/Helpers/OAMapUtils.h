//
//  OAMapUtils.h
//  OsmAnd
//
//  Created by Alexey Kulish on 21/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#define MIN_LATITUDE -85.0511
#define MAX_LATITUDE 85.0511
#define LATITUDE_TURN 180.0
#define MIN_LONGITUDE -180.0
#define MAX_LONGITUDE 180.0
#define LONGITUDE_TURN 360.0

@class OAPOI;
@class QuadRect;

@interface OAMapUtils : NSObject

+ (NSArray<OAPOI *> *) sortPOI:(NSArray<OAPOI *> *)array lat:(double)lat lon:(double)lon;

+ (CLLocation *) getProjection:(CLLocation *)location fromLocation:(CLLocation *)fromLocation toLocation:(CLLocation *)toLocation;
+ (double) getOrthogonalDistance:(CLLocation *)location fromLocation:(CLLocation *)fromLocation toLocation:(CLLocation *)toLocation;

+ (CLLocationDirection) adjustBearing:(CLLocationDirection)bearing;
+ (BOOL) rightSide:(double)lat lon:(double)lon aLat:(double)aLat aLon:(double)aLon bLat:(double)bLat bLon:(double)bLon;

+ (CLLocation *) calculateMidPoint:(CLLocation *) s1 s2:(CLLocation *) s2;
+ (NSValue *) calculateIntersection:(CGFloat)inx iny:(CGFloat)iny outx:(CGFloat)outx outy:(CGFloat)outy leftX:(CGFloat)leftX rightX:(CGFloat)rightX bottomY:(CGFloat)bottomY topY:(CGFloat)topY;
+ (NSArray<NSValue *> *) calculateLineInRect:(CGRect)rect start:(CGPoint)start end:(CGPoint)end;

+ (double) getAngleBetween:(CGPoint)start end:(CGPoint)end;

+ (double) checkLatitude:(double) latitude;
+ (double) checkLongitude:(double) longitude;

+(double) getDistance:(CLLocationCoordinate2D)first second:(CLLocationCoordinate2D)second;
+(double) getDistance:(double)lat1 lon1:(double)lon1 lat2:(double)lat2 lon2:(double)lon2;

@end
