//
//  OAWeatherRasterLayer.h
//  OsmAnd Maps
//
//  Created by Alexey on 24.12.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OARasterMapLayer.h"

typedef NS_ENUM(NSInteger, EOAWeatherBand)
{
    WEATHER_BAND_UNDEFINED = 0,
    WEATHER_BAND_CLOUD = 1,
    WEATHER_BAND_TEMPERATURE = 2,
    WEATHER_BAND_PRESSURE = 3,
    WEATHER_BAND_WIND_SPEED = 4,
    WEATHER_BAND_PRECIPITATION = 5
};

@interface OAWeatherRasterLayer : OARasterMapLayer

@property (nonatomic, readonly) EOAWeatherBand weatherBand;
@property (nonatomic, readonly) NSDate *date;

- (instancetype) initWithMapViewController:(OAMapViewController *)mapViewController layerIndex:(int)layerIndex weatherBand:(EOAWeatherBand)weatherBand date:(NSDate *)date;

- (void) updateDate:(NSDate *)date;

@end
