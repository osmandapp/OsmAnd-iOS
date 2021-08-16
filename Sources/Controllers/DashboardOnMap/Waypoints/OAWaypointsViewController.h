//
//  OAWaypointsViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 14/03/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OADashboardViewController.h"
#import "OAWaypointsScreen.h"

@class OALocationPointWrapper;

typedef NS_ENUM(NSInteger, EWaypointsViewControllerRequestAction)
{
    EWaypointsViewControllerChangeRadiusAction = 0,
    EWaypointsViewControllerSelectPOIAction,
    EWaypointsViewControllerEnableTypeAction,
};

@interface OAWaypointsViewControllerRequest : NSObject

@property (nonatomic, readonly) int type;
@property (nonatomic, readonly) EWaypointsViewControllerRequestAction action;
@property (nonatomic, readonly) NSNumber *param;

- (instancetype) initWithType:(int)type action:(EWaypointsViewControllerRequestAction)action param:(NSNumber *)param;

@end

@interface OAWaypointsViewController : OADashboardViewController

@property (nonatomic) id<OAWaypointsScreen> screenObj;
@property (nonatomic, readonly) EWaypointsScreen waypointsScreen;

- (instancetype) initWithWaypointsScreen:(EWaypointsScreen)waypointsScreen;
- (instancetype) initWithWaypointsScreen:(EWaypointsScreen)waypointsScreen param:(id)param;

+ (OAWaypointsViewControllerRequest *) getRequest;
+ (void) setRequest:(EWaypointsViewControllerRequestAction)action type:(int)type param:(NSNumber *)param;
+ (void) resetRequest;

@end
