//
//  OAActionConfigurationViewController.h
//  OsmAnd
//
//  Created by Paul on 8/15/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OABaseButtonsViewController.h"

NS_ASSUME_NONNULL_BEGIN

@protocol OAQuickActionListDelegate

- (void)updateData;

@end

@class OAQuickAction, QuickActionButtonState;

@interface OAActionConfigurationViewController : OABaseButtonsViewController

- (instancetype)initWithButtonState:(QuickActionButtonState *)buttonState typeId:(NSInteger)typeId;
- (instancetype)initWithButtonState:(QuickActionButtonState *)buttonState action:(OAQuickAction *)action;

- (instancetype)initWithAction:(OAQuickAction *)action isNew:(BOOL)isNew;

@property (nonatomic, weak) id<OAQuickActionListDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
