//
//  OAPlanningPopupBaseViewController.m
//  OsmAnd Maps
//
//  Created by Paul on 03.07.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAPlanningPopupBaseViewController.h"

@interface OAPlanningPopupBaseViewController ()

@end

@implementation OAPlanningPopupBaseViewController

- (instancetype)init
{
    return [super initWithNibName:@"OAPlanningPopupBaseViewController" bundle:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.leftButton.layer.cornerRadius = 9.;
    self.rightButton.layer.cornerRadius = 9.;
    self.view.layer.cornerRadius = 9.;
    self.headerView.layer.cornerRadius = 9.;
    self.view.clipsToBounds = NO;
    self.view.layer.masksToBounds = YES;
}

- (void) onLeftButtonPressed
{
    // override
}

- (void) onRightButtonPressed
{
    // override
}

- (CGFloat)initialHeight
{
    //override
    return 150.;
}

- (IBAction)leftButtonPressed:(id)sender
{
    [self onLeftButtonPressed];
}

- (IBAction)rightButtonPressed:(id)sender
{
    [self onRightButtonPressed];
}

- (IBAction)closeButtonPressed:(id)sender
{
    [self dismiss];
}

- (void) dismiss
{
    if (self.delegate)
        [self.delegate onPopupDismissed];
}

- (void) setHeaderViewVisibility:(BOOL)hidden
{
    self.headerView.hidden = hidden;
    self.headerViewHeightConstant.constant = hidden ? 0. : 57.;
    [self.view setNeedsUpdateConstraints];
    [self.view updateConstraintsIfNeeded];
}

@end
