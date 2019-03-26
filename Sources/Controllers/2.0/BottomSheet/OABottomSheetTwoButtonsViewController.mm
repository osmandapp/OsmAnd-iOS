//
//  OABottomSheetTwoButtonsViewController.m
//  OsmAnd
//
//  Created by Pasul on 03/04/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OABottomSheetTwoButtonsViewController.h"

#import "OAMapViewController.h"
#import "OARootViewController.h"

#import "Localization.h"
#import "OAUtilities.h"
#import "OAColors.h"
#import "OASizes.h"

#define kOABottomSheetWidth 320.0
#define kButtonsDividerTag 150

@implementation OABottomSheetTwoButtonsViewController
{
    OsmAndAppInstance _app;
    
    BOOL _appearFirstTime;
    UIView *_tableBackgroundView;
    BOOL _showing;
    BOOL _hiding;
    BOOL _rotating;
}

- (void) commonInit
{
    [super commonInit];
    _doneButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_doneButton addTarget:self action:@selector(doneButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [_doneButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.buttonsView addSubview:_doneButton];
    [self setupButtons];
    [self applyLocalization];
}

- (void) setupButtons
{
    CGFloat buttonWidth = self.buttonsView.frame.size.width / 2 - 21;
    _doneButton.frame = CGRectMake(self.buttonsView.frame.size.width - 16.0 - buttonWidth, 4.0, buttonWidth, 42.0);
    _doneButton.backgroundColor = [UIColor colorWithRed:0 green:0.48 blue:1 alpha:1];
    _doneButton.layer.cornerRadius = 9;
    _doneButton.titleLabel.font = [UIFont systemFontOfSize:15.0];
    
    self.cancelButton.frame = CGRectMake(16.0 , 4.0, buttonWidth, 42.0);
    self.cancelButton.autoresizingMask = UIViewAutoresizingNone;
    self.cancelButton.backgroundColor = [UIColor colorWithRed:0.82 green:0.82 blue:0.84 alpha:1];
    self.cancelButton.layer.cornerRadius = 9;
}

- (void)adjustViewHeight
{
    CGFloat bottomMargin = [OAUtilities getBottomMargin];
    CGRect cancelFrame = self.buttonsView.frame;
    cancelFrame.size.height = twoButtonsBottmomSheetHeight + bottomMargin;
    cancelFrame.origin.y = DeviceScreenHeight - cancelFrame.size.height;
    self.buttonsView.frame = cancelFrame;
    
    CGRect tableViewFrame = self.tableView.frame;
    tableViewFrame.size.height = DeviceScreenHeight - cancelFrame.size.height;
    self.tableView.frame = tableViewFrame;
}


-(void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self setupButtons];
    } completion:nil];
}

-(void) doneButtonPressed:(id)sender
{
    if ([self.screenObj respondsToSelector:@selector(doneButtonPressed)])
        return [self.screenObj doneButtonPressed];
    
    [self dismiss];
}

@end
