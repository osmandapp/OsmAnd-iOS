//
//  OAQuickActionListViewController.h
//  OsmAnd
//
//  Created by Paul on 8/15/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OABaseButtonsViewController.h"

@class OAQuickActionButtonState;

@protocol OAWidgetStateDelegate;

@interface OAQuickActionListViewController : OABaseButtonsViewController

- (instancetype)initWithButtonState:(OAQuickActionButtonState *)buttonState;

@property (nonatomic, weak) id<OAWidgetStateDelegate> delegate;
@property (nonatomic, copy, nullable) void (^quickActionUpdateCallback)(void);

@end
