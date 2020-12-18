//
//  OARouteAvoidSettingsViewController.h
//  OsmAnd
//
//  Created by Paul on 10/30/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OARouteSettingsBaseViewController.h"
#import "OACompoundViewController.h"
#import "OABaseSettingsViewController.h"

@class OAAvoidRoadInfo;

@interface OARouteAvoidSettingsViewController : OARouteSettingsBaseViewController<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic) id<OASettingsDataDelegate> delegate;

+ (NSString *) getDescr:(OAAvoidRoadInfo *)roadInfo;

@end
