//
//  OARoutePreferencesParameterGroupScreen.h
//  OsmAnd
//
//  Created by Alexey Kulish on 17/12/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OARoutePreferencesScreen.h"

@class OALocalRoutingParameterGroup;
@class OARoutePreferencesViewController;

@interface OARoutePreferencesParameterGroupScreen : NSObject<OARoutePreferencesScreen>

@property (nonatomic, readonly) OALocalRoutingParameterGroup *group;

- (id) initWithTable:(UITableView *)tableView viewController:(OARoutePreferencesViewController *)viewController group:(OALocalRoutingParameterGroup *)group;

@end
