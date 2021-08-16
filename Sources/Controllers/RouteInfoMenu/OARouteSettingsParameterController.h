//
//  OARouteSettingsParameterController.h
//  OsmAnd
//
//  Created by Paul on 10/30/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OARouteSettingsBaseViewController.h"

@class OALocalRoutingParameterGroup;

@interface OARouteSettingsParameterController : OARouteSettingsBaseViewController <UITableViewDelegate, UITableViewDataSource>

- (instancetype) initWithParameterGroup:(OALocalRoutingParameterGroup *) group;

@end
