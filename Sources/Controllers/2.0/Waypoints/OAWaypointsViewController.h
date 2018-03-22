//
//  OAWaypointsViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 14/03/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OADashboardViewController.h"
#import "OAWaypointsScreen.h"

@interface OAWaypointsViewController : OADashboardViewController

@property (nonatomic) id<OAWaypointsScreen> screenObj;
@property (nonatomic, readonly) EWaypointsScreen waypointsScreen;

- (instancetype) initWithWaypointsScreen:(EWaypointsScreen)waypointsScreen;
- (instancetype) initWithWaypointsScreen:(EWaypointsScreen)waypointsScreen param:(id)param;

@end
