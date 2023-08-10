//
//  OAWeatherFrequencySettingsViewController.h
//  OsmAnd
//
//  Created by Skalii on 11.08.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OABaseNavbarViewController.h"

@class OAWorldRegion;

@protocol OAWeatherAutoUpdateSettingsViewControllerDelegate <NSObject>

@required

- (void)onAutoUpdateSelected;

@end

@interface OAWeatherAutoUpdateSettingsViewController : OABaseNavbarViewController

- (instancetype)initWithRegion:(OAWorldRegion *)region;

@property (nonatomic, weak) id<OAWeatherAutoUpdateSettingsViewControllerDelegate> autoUpdateDelegate;

@end
