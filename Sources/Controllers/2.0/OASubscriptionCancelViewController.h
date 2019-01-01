//
//  OASubscriptionCancelViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 27/12/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OASuperViewController.h"

@interface OASubscriptionCancelViewController : OASuperViewController

+ (BOOL) shouldShowDialog;
+ (void) showInstance:(UINavigationController *)navigationController;

@end
