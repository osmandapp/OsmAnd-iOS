//
//  OAConfigureProfileViewController.h
//  OsmAnd
//
//  Created by Paul on 01.08.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABaseBigTitleSettingsViewController.h"

@class OAApplicationMode;

@protocol OAConfigureProfileDelegate <NSObject>

- (void) onModeAvailabilityChanged:(OAApplicationMode *)mode isOn:(BOOL)isOn;

@end

@interface OAConfigureProfileViewController : OABaseBigTitleSettingsViewController

@property (nonatomic) id<OAConfigureProfileDelegate> delegate;

- (instancetype) initWithAppMode:(OAApplicationMode *)mode;

@end
