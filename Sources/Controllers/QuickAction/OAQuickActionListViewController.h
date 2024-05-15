//
//  OAQuickActionListViewController.h
//  OsmAnd
//
//  Created by Paul on 8/15/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OABaseButtonsViewController.h"

@protocol OAWidgetStateDelegate;

@interface OAQuickActionListViewController : OABaseButtonsViewController

@property (nonatomic, weak) id<OAWidgetStateDelegate> delegate;
@property (nonatomic, copy) void (^quickActionUpdateCallback)(void);

@end
