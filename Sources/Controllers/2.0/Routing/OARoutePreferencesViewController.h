//
//  OARoutePreferencesViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 02/09/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OADashboardViewController.h"
#import "OARoutePreferencesScreen.h"

@interface OARoutePreferencesViewController : OADashboardViewController

@property (nonatomic) id<OARoutePreferencesScreen> screenObj;
@property (nonatomic, readonly) ERoutePreferencesScreen preferencesScreen;

- (instancetype) initWithPreferencesScreen:(ERoutePreferencesScreen)preferencesScreen;
- (instancetype) initWithPreferencesScreen:(ERoutePreferencesScreen)preferencesScreen param:(id)param;
- (instancetype) initWithAvoiRoadsScreen;

@end
