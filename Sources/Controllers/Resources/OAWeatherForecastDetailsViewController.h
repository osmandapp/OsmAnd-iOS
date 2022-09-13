//
//  OAWeatherForecastDetailsViewController.h
//  OsmAnd
//
//  Created by Skalii on 05.08.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OABaseBigTitleSettingsViewController.h"

@class OAWorldRegion;

@protocol OAWeatherForecastDetails <NSObject>

@required

- (void)onRemoveForecast;
- (void)onUpdateForecast;

@end

@interface OAWeatherForecastDetailsViewController : OABaseBigTitleSettingsViewController

- (instancetype)initWithRegion:(OAWorldRegion *)region;

@property (nonatomic, weak) id<OAWeatherForecastDetails> delegate;

@end
