//
//  OADayNightHelper.h
//  OsmAnd
//
//  Created by Alexey Kulish on 25/11/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SunriseSunset;

@interface OADayNightHelper : NSObject

+ (OADayNightHelper *) instance;

- (BOOL) isNightMode;
- (void) forceUpdate;
- (BOOL) setTempMode:(NSInteger)dayNightMode;
- (BOOL) resetTempMode;
- (SunriseSunset *) getSunriseSunset;

@end
