//
//  OAFloatingButtonsHudViewController.h
//  OsmAnd
//
//  Created by Paul on 7/28/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

@class QuickActionButtonState, OAMapHudViewController;

NS_ASSUME_NONNULL_BEGIN

@interface OAFloatingButtonsHudViewController : UIViewController

- (instancetype)initWithMapHudViewController:(OAMapHudViewController *)mapHudController;

- (void)updateViewVisibility;
- (BOOL)isActionSheetVisible;
- (BOOL)isQuickActionButtonVisible;
- (void)hideActionsSheetAnimated:(void (^ _Nullable)(void))completion;
- (void)updateColors;
- (QuickActionButtonState * _Nullable)getActiveButtonState;

@end

NS_ASSUME_NONNULL_END

