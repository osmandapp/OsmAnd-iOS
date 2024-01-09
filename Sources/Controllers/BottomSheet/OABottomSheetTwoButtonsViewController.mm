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
#import "OsmAnd_Maps-Swift.h"
#import "OASizes.h"
#import "GeneratedAssetSymbols.h"

#define kOABottomSheetWidth 320.0
#define kButtonsDividerTag 150

@implementation OABottomSheetTwoButtonsViewController
{
    OsmAndAppInstance _app;
    
    BOOL _appearFirstTime;
    BOOL _showing;
    BOOL _hiding;
    BOOL _rotating;
}

- (void)additionalSetup
{
    [super additionalSetup];
    _doneButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_doneButton addTarget:self action:@selector(doneButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [_doneButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.buttonsView addSubview:_doneButton];
    [OAUtilities setMaskTo:self.tableBackgroundView byRoundingCorners:UIRectCornerTopLeft|UIRectCornerTopRight];
    [self setupButtons];
    [self applyLocalization];
}

- (void) setupButtons
{
    [self layoutButtons];
    _doneButton.backgroundColor = [UIColor colorNamed:ACColorNameButtonBgColorPrimary];
    _doneButton.layer.cornerRadius = 9;
    _doneButton.titleLabel.font = [UIFont scaledSystemFontOfSize:15.0 weight:UIFontWeightSemibold];
    
    self.cancelButton.backgroundColor = [UIColor colorNamed:ACColorNameButtonBgColorSecondary];
    self.cancelButton.layer.cornerRadius = 9;
    self.cancelButton.titleLabel.font = [UIFont scaledSystemFontOfSize:15.0 weight:UIFontWeightSemibold];
    [self.cancelButton setTitleColor:[UIColor colorNamed:ACColorNameButtonTextColorSecondary] forState:UIControlStateNormal];
}

- (void) layoutButtons
{
    if (_doneButton.hidden)
    {
        CGFloat buttonWidth = self.buttonsView.frame.size.width - 32;
        self.cancelButton.frame = CGRectMake(16.0 , 4.0, buttonWidth, 42.0);
    }
    else
    {
        CGFloat buttonWidth = (self.buttonsView.frame.size.width - 48.0) / 2;
        _doneButton.frame = CGRectMake(self.buttonsView.frame.size.width - 16.0 - buttonWidth, 4.0, buttonWidth, 42.0);
        self.cancelButton.frame = CGRectMake(16.0 , 4.0, buttonWidth, 42.0);
        self.cancelButton.autoresizingMask = UIViewAutoresizingNone;
    }
}

- (void) hideDoneButton
{
    _doneButton.hidden = YES;
    [self layoutButtons];
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
        [self layoutButtons];
        [OAUtilities setMaskTo:self.tableBackgroundView byRoundingCorners:UIRectCornerTopLeft|UIRectCornerTopRight];
    } completion:nil];
}

-(void) doneButtonPressed:(id)sender
{
    if ([self.screenObj respondsToSelector:@selector(doneButtonPressed)])
        return [self.screenObj doneButtonPressed];
    
    [self dismiss];
}

@end
