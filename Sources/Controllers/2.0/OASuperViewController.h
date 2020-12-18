//
//  OASuperViewController.h
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 06.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OASuperViewController : UIViewController

- (IBAction) backButtonClicked:(id)sender;

- (void) applyLocalization;
- (BOOL) isModal;
- (void) dismissViewController;
- (void) showViewController:(UIViewController *)viewController;

@end
