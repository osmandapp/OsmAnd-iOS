//
//  OAWeatherRasterLayer.h
//  OsmAnd Maps
//
//  Created by Alexey on 24.12.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OARasterMapLayer.h"

typedef NS_ENUM(NSInteger, EOAWeatherLayer)
{
    WEATHER_LAYER_LOW = 0,
    WEATHER_LAYER_HIGH = 1
};

static int64_t FORECAST_ANIMATION_DURATION_HOURS = 6;
static int64_t HOUR_IN_MILLISECONDS = 60 * 60 * 1000;
static int64_t DAY_IN_MILLISECONDS = 24 * HOUR_IN_MILLISECONDS;

@interface OAWeatherRasterLayer : OARasterMapLayer

@property (nonatomic, readonly) EOAWeatherLayer weatherLayer;
@property (nonatomic, readonly) NSDate *date;

- (instancetype) initWithMapViewController:(OAMapViewController *)mapViewController layerIndex:(int)layerIndex weatherLayer:(EOAWeatherLayer)weatherLayer date:(NSDate *)date;

- (void) updateDate:(NSDate *)date;
- (void) updateWeatherLayer;
- (void) updateWeatherLayerAlpha;

- (void) setDateTime:(int64_t)dateTime goForward:(BOOL)goForward resetPeriod:(BOOL)resetPeriod;

@end
