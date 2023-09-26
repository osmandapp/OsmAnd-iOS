//
//  OAWeatherAutoUpdateSettingsViewController.h
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 21.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
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
