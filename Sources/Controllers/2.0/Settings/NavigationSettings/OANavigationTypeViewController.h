//
//  OANavigationTypeViewController.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 22.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABaseSettingsViewController.h"

@class OAApplicationMode;

@interface OANavigationTypeViewController : OABaseSettingsViewController

- (instancetype) initWithAppMode:(OAApplicationMode *)appMode;

@end
