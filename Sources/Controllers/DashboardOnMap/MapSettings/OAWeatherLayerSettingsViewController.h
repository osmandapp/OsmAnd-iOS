//
//  OAWeatherLayerSettingsViewController.h
//  OsmAnd Maps
//
//  Created by Yuliia Stetsenko on 02.04.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OABaseScrollableHudViewController.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, EOAWeatherLayerType)
{
    EOAWeatherLayerTypeTemperature = 0,
    EOAWeatherLayerTypePresssure,
    EOAWeatherLayerTypeWind,
    EOAWeatherLayerTypeCloud,
    EOAWeatherLayerTypePrecipitation,
    EOAWeatherLayerTypeContours
};

@interface OAWeatherLayerSettingsViewController : OABaseScrollableHudViewController

- (instancetype)initWithLayerType:(EOAWeatherLayerType)layerType;

@end

NS_ASSUME_NONNULL_END
