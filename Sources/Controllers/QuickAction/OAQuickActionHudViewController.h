//
//  OAQuickActionHudViewController.h
//  OsmAnd
//
//  Created by Paul on 7/28/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OAMapHudViewController.h"

@interface OAQuickActionHudViewController : UIViewController

- (instancetype) initWithMapHudViewController:(OAMapHudViewController *)mapHudController;

- (void) updateViewVisibility;
- (void) updateViewVisibilityAnimated:(BOOL)isAnimated;
- (void) hideActionsSheetAnimated;
- (void) updateColors:(BOOL)isNight;

@end
