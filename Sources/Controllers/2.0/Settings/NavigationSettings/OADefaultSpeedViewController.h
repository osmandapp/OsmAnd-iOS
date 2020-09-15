//
//  OADefaultSpeedViewController.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 30.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OASettingsModalPresentationViewController.h"

@interface OADefaultSpeedViewController : OASettingsModalPresentationViewController

- (instancetype) initWithApplicationMode:(OAApplicationMode *)am speedParameters:(NSDictionary *)speedParameters;

@end
