//
//  OAQuickActionListViewController.h
//  OsmAnd
//
//  Created by Paul on 8/15/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OABaseButtonsViewController.h"

@class QuickActionButtonState;

@protocol OAWidgetStateDelegate;

@interface OAQuickActionListViewController : OABaseButtonsViewController

- (instancetype)initWithButtonState:(QuickActionButtonState *)buttonState;

@property (nonatomic, weak) id<OAWidgetStateDelegate> delegate;

@end
