//
//  OABottomSheetTwoButtonsViewController.h
//  OsmAnd
//
//  Created by Paul on 03/04/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OABottomSheetViewController.h"

@interface OABottomSheetTwoButtonsViewController : OABottomSheetViewController

@property (nonatomic, readonly) UIButton *doneButton;

- (void) setupButtons;
- (void) hideDoneButton;

@end
