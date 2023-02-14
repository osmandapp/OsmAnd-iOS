//
//  OAWeatherBandSettingsViewController.h
//  OsmAnd
//
//  Created by Skalii on 31.03.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OABaseNavbarViewController.h"

@class OAWeatherBand;

@protocol OAWeatherBandSettingsDelegate <NSObject>

@required

- (void)onBandUnitChanged;

@end

@interface OAWeatherBandSettingsViewController : OABaseNavbarViewController

- (instancetype)initWithWeatherBand:(OAWeatherBand *)band;

@property (nonatomic, weak) id<OAWeatherBandSettingsDelegate> bandDelegate;

@end
