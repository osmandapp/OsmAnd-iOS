//
//  OAWaypointsScreen.h
//  OsmAnd
//
//  Created by Alexey Kulish on 14/03/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OADashboardScreen.h"

typedef NS_ENUM(NSInteger, EWaypointsScreen)
{
    EWaypointsScreenUndefined = -1,
    EWaypointsScreenMain = 0,
    EWaypointsScreenRadius,
    EWaypointsScreenPOI,
};

@protocol OAWaypointsScreen <NSObject, OADashboardScreen, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, readonly) EWaypointsScreen waypointsScreen;

@end
