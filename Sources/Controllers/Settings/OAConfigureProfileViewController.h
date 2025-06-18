//
//  OAConfigureProfileViewController.h
//  OsmAnd
//
//  Created by Paul on 01.08.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABaseNavbarViewController.h"

extern NSString * const kNavigationSettings;

@class OAApplicationMode;

@interface OAConfigureProfileViewController : OABaseNavbarViewController

- (instancetype) initWithAppMode:(OAApplicationMode *)mode targetScreenKey:(NSString *)targetScreenKey;

@end
