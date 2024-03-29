//
//  OAWeatherFrequencySettingsViewController.h
//  OsmAnd
//
//  Created by Skalii on 11.08.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OABaseNavbarViewController.h"

@class OAWorldRegion;

@protocol OAWeatherFrequencySettingsDelegate <NSObject>

@required

- (void)onFrequencySelected;

@end

@interface OAWeatherFrequencySettingsViewController : OABaseNavbarViewController

- (instancetype)initWithRegion:(OAWorldRegion *)region;

@property (nonatomic, weak) id<OAWeatherFrequencySettingsDelegate> frequencyDelegate;

@end
