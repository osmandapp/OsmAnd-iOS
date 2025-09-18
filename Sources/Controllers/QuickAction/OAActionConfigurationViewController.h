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

@protocol OAEditKeyAssignmentDelegate

- (void)setKeyAssignemntAction:(OAQuickAction *)action;

@end

@interface OAActionConfigurationViewController : OABaseButtonsViewController

- (instancetype)initWithButtonState:(QuickActionButtonState *)buttonState typeId:(NSInteger)typeId;
- (instancetype)initWithButtonState:(QuickActionButtonState *)buttonState action:(OAQuickAction *)action;

- (instancetype)initWithAction:(OAQuickAction *)action isNew:(BOOL)isNew;

- (instancetype)initWithKeyAssignmentFlow:(BOOL)keyAssignmentFlow typeId:(NSInteger)typeId;

@property (nonatomic, weak) id<OAQuickActionListDelegate> delegate;
@property (nonatomic, weak) id<OAEditKeyAssignmentDelegate> editKeyAssignmentdelegate;

@end

NS_ASSUME_NONNULL_END
