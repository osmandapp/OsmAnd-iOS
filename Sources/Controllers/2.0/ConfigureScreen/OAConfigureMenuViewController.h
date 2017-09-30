//
//  OAConfigureMenuViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 29/09/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OADashboardViewController.h"
#import "OAConfigureMenuScreen.h"

@interface OAConfigureMenuViewController : OADashboardViewController

@property (nonatomic) id<OAConfigureMenuScreen> screenObj;
@property (nonatomic, readonly) EConfigureMenuScreen configureMenuScreen;

- (instancetype) initWithConfigureMenuScreen:(EConfigureMenuScreen)configureMenuScreen;
- (instancetype) initWithConfigureMenuScreen:(EConfigureMenuScreen)configureMenuScreen param:(id)param;

@end
