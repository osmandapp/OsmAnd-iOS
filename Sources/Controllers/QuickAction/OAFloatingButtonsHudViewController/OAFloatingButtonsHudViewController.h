//
//  OAFloatingButtonsHudViewController.h
//  OsmAnd
//
//  Created by Paul on 7/28/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OAMapHudViewController.h"

@class QuickActionButtonState;

@interface OAFloatingButtonsHudViewController : UIViewController

- (instancetype _Nonnull)initWithMapHudViewController:(OAMapHudViewController * _Nonnull)mapHudController;

- (void)updateViewVisibility;
- (BOOL)isActionSheetVisible;
- (BOOL)isQuickActionButtonVisible;
- (void)hideActionsSheetAnimated:(void (^ _Nullable)(void))completion;
- (void)updateColors;
- (QuickActionButtonState * _Nullable)getActiveButtonState;

@end
