//
//  OAQuickActionHudViewController.h
//  OsmAnd
//
//  Created by Paul on 7/28/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OAMapHudViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface OAQuickActionHudViewController : UIViewController

- (instancetype) initWithMapHudViewController:(OAMapHudViewController *)mapHudController;

@end

NS_ASSUME_NONNULL_END
