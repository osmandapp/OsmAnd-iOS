//
//  OATransportStop.h
//  OsmAnd
//
//  Created by Alexey on 14/07/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAMapObject.h"

#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

@class OAPOI, OATransportStopAggregated;

@interface OATransportStop : OAMapObject

@property (nonatomic) uint64_t stopId;
@property (nonatomic, nullable) OAPOI *poi;
@property (nonatomic) int distance;
@property (nonatomic) NSArray<CLLocation *> *exitLocations;
@property (nonatomic, nullable) OATransportStopAggregated *transportStopAggregated;

- (void)findAmenityDataIfNeeded;
- (NSString *)getStopObjectName:(NSString *)lang transliterate:(BOOL)transliterate;

@end

NS_ASSUME_NONNULL_END
