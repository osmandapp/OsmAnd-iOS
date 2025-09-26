//
//  OAAddQuickActionViewController.h
//  OsmAnd
//
//  Created by Paul on 8/15/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OABaseNavbarViewController.h"
#import "OAActionConfigurationViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface OAAddQuickActionViewController : OABaseNavbarViewController

@property (nonatomic, weak) id<OAQuickActionListDelegate> delegate;
@property (nonatomic, weak) id<OAEditKeyAssignmentDelegate> editKeyAssignmentdelegate;

- (instancetype)initWithButtonState:(QuickActionButtonState *)buttonState;
- (instancetype)initWithKeyAssignmentFlow:(BOOL)keyAssignmentFlow;

@end

NS_ASSUME_NONNULL_END
