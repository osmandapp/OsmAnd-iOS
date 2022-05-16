//
//  OALocationParser.h
//  OsmAnd
//
//  Created by Paul on 02.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface OAParsedOpenLocationCode : NSObject

@property (nonatomic, readonly) NSString *text;
@property (nonatomic, readonly) NSString *code;
@property (nonatomic, readonly) BOOL full;
@property (nonatomic, readonly) NSString *placeName;
@property (nonatomic, readonly) CLLocation *latLon;

- (instancetype) initWithText:(NSString *) text;

- (BOOL) isValidCode;
- (CLLocation *) recover:(CLLocation *) searchLocation;

@end

@interface OALocationParser : NSObject

+ (BOOL) isValidOLC:(NSString *) code;
+ (BOOL) isShortCode:(NSString *) code;
+ (OAParsedOpenLocationCode *) parseOpenLocationCode:(NSString *) locPhrase;
+ (CLLocation *) parseLocation:(NSString *)s;
+ (void) splitObjects:(NSString *)s d:(NSMutableArray<NSNumber *> *)d all:(NSMutableArray *)all strings:(NSMutableArray<NSString *> *)strings;
+ (double) parse1Coordinate:(NSMutableArray *)all begin:(int)begin end:(int)end;

@end
