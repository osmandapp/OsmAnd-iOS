//
//  OAWaypointsMainScreen.h
//  OsmAnd
//
//  Created by Alexey Kulish on 14/03/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAWaypointsScreen.h"

@class OAWaypointsViewController;

@interface OAWaypointsMainScreen : NSObject<OAWaypointsScreen>

- (id) initWithTable:(UITableView *)tableView viewController:(OAWaypointsViewController *)viewController param:(id)param isShowAlong:(BOOL)isShowAlong;

@end
