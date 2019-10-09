//
//  OARouteAvoidSettingsViewController.h
//  OsmAnd
//
//  Created by Paul on 10/30/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OARouteSettingsBaseViewController.h"
#include <OsmAndCore.h>
#include <OsmAndCore/Data/Road.h>

@interface OARouteAvoidSettingsViewController : OARouteSettingsBaseViewController<UITableViewDelegate, UITableViewDataSource>

+ (NSString *) getText:(const std::shared_ptr<const OsmAnd::Road>)road;
+ (NSString *) getDescr:(const std::shared_ptr<const OsmAnd::Road>)road;

@end
