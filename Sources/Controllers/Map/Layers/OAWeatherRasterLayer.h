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

@interface OAWeatherRasterLayer : OARasterMapLayer

@property (nonatomic, readonly) EOAWeatherLayer weatherLayer;
@property (nonatomic, readonly) NSDate *date;

- (instancetype) initWithMapViewController:(OAMapViewController *)mapViewController layerIndex:(int)layerIndex weatherLayer:(EOAWeatherLayer)weatherLayer date:(NSDate *)date;

- (void) updateDate:(NSDate *)date;

@end
