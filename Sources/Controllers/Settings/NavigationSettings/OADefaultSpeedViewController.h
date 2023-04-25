//
//  OADefaultSpeedViewController.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 30.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABaseSettingsViewController.h"

@interface OADefaultSpeedViewController : OABaseSettingsViewController

- (instancetype) initWithApplicationMode:(OAApplicationMode *)am speedParameters:(NSDictionary *)speedParameters;

@end
