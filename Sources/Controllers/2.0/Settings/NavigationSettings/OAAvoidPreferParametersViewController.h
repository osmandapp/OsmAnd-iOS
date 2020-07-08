//
//  OAAvoidRoadsViewController.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 24.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABaseSettingsViewController.h"

@class OAApplicationMode;

@interface OAAvoidPreferParametersViewController : OABaseSettingsViewController

+ (BOOL) hasPreferParameters:(OAApplicationMode *)appMode;

- (instancetype) initWithAppMode:(OAApplicationMode *)appMode isAvoid:(BOOL)isAvoid;

@end
