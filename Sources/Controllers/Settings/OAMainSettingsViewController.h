//
//  OAMainSettingsViewController.h
//  OsmAnd
//
//  Created by Paul on 07.30.2020
//  Copyright (c) 2020 OsmAnd. All rights reserved.
//

#import "OABaseNavbarViewController.h"

@class OAApplicationMode;

@interface OAMainSettingsViewController : OABaseNavbarViewController

- (instancetype) initWithTargetAppMode:(OAApplicationMode *)mode targetScreenKey:(NSString *)targetScreenKey;

@end
