//
//  OAAverageSpeedComputer.h
//  OsmAnd Maps
//
//  Created by Paul on 16.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OAAverageSpeedComputer : NSObject

+ (instancetype) sharedInstance;

+ (NSArray<NSNumber *> *) MEASURED_INTERVALS;
+ (long) DEFAULT_INTERVAL_MILLIS;
+ (NSArray<NSNumber *> *) MEASURED_INTERVALS;

- (void)updateLocation:(nullable CLLocation *)location;
- (float)getAverageSpeed:(long)measuredInterval skipLowSpeed:(BOOL)skipLowSpeed;

@end

NS_ASSUME_NONNULL_END
