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
    [self setMaskTo:self.tableBackgroundView byRoundingCorners:UIRectCornerTopLeft|UIRectCornerTopRight];
    [self setupButtons];
    [self applyLocalization];
}

-(void) setMaskTo:(UIView*)view byRoundingCorners:(UIRectCorner)corners
{
    UIBezierPath* rounded = [UIBezierPath bezierPathWithRoundedRect:view.bounds byRoundingCorners:corners cornerRadii:CGSizeMake(10.0, 10.0)];
    
    CAShapeLayer* shape = [[CAShapeLayer alloc] init];
    [shape setPath:rounded.CGPath];
    
    view.layer.mask = shape;
}

- (void) setupButtons
{
    if (_doneButton.hidden)
        return [self hideDoneButton];
    
    CGFloat buttonWidth = (self.buttonsView.frame.size.width - 48.0) / 2;
    _doneButton.frame = CGRectMake(self.buttonsView.frame.size.width - 16.0 - buttonWidth, 4.0, buttonWidth, 42.0);
    _doneButton.backgroundColor = UIColorFromRGB(primary_purple_color);
    _doneButton.layer.cornerRadius = 9;
    _doneButton.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightSemibold];
    
    self.cancelButton.frame = CGRectMake(16.0 , 4.0, buttonWidth, 42.0);
    self.cancelButton.autoresizingMask = UIViewAutoresizingNone;
    self.cancelButton.backgroundColor = UIColorFromRGB(bottom_sheet_secondary_color);
    self.cancelButton.layer.cornerRadius = 9;
    self.cancelButton.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightSemibold];
    [self.cancelButton setTitleColor:UIColorFromRGB(primary_purple_color) forState:UIControlStateNormal];
}

- (void) hideDoneButton
{
    _doneButton.hidden = YES;
    CGFloat buttonWidth = self.buttonsView.frame.size.width - 32;
    self.cancelButton.frame = CGRectMake(16.0 , 4.0, buttonWidth, 42.0);
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
        [self setMaskTo:self.tableBackgroundView byRoundingCorners:UIRectCornerTopLeft|UIRectCornerTopRight];
    } completion:nil];
}

-(void) doneButtonPressed:(id)sender
{
    if ([self.screenObj respondsToSelector:@selector(doneButtonPressed)])
        return [self.screenObj doneButtonPressed];
    
    [self dismiss];
}

@end
