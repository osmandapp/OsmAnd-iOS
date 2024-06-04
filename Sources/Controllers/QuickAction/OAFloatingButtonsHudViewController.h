//
//  OAFloatingButtonsHudViewController.h
//  OsmAnd
//
//  Created by Paul on 7/28/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OAMapHudViewController.h"

@interface OAFloatingButtonsHudViewController : UIViewController

- (instancetype) initWithMapHudViewController:(OAMapHudViewController *)mapHudController;

- (void) updateViewVisibility;
- (BOOL) isActionSheetVisible;
- (BOOL) isQuickActionFloatingButtonVisible;
- (void) hideActionsSheetAnimated;
- (void) updateColors;

@end
