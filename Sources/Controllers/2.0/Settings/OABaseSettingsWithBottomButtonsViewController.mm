//
//  OABaseSettingsWithBottomButtonsViewController.mm
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 15.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABaseSettingsWithBottomButtonsViewController.h"
#include <OsmAndCore/Utilities.h>

#define kTopBottomPadding 8

@implementation OABaseSettingsWithBottomButtonsViewController
{
}

- (instancetype) init
{
    self = [super initWithNibName:@"OABaseSettingsWithBottomButtonsViewController" bundle:nil];
    if (self)
    {
        
    }
    return self;
}

- (void) applyLocalization
{
    
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    [self setupNavbar];
    [self setupBottomView];
}

- (void) setupNavbar
{
    BOOL hasImage = !self.backImageButton.hidden;
    
    self.cancelButtonLeftMarginWithIcon.active = hasImage;
    self.cancelButtonLeftMarginNoIcon.active = !hasImage;
}

- (void) setupBottomView // needs refactoring
{
    BOOL hasPrimaryButton = !self.primaryBottomButton.hidden;
    BOOL hasSecondaryButton = !self.secondaryBottomButton.hidden;
    
    self.primaryBottomButton.layer.cornerRadius = 9.;
    self.secondaryBottomButton.layer.cornerRadius = 9.;
    
    if (hasPrimaryButton && hasSecondaryButton)
    {
        self.primaryButtonTopMarginYesSecondary.active = YES;
        self.primaryButtonTopMarginNoSecondary.active = NO;
        
        self.bottomViewHeigh.constant = self.primaryBottomButton.frame.size.height + self.secondaryBottomButton.frame.size.height + kTopBottomPadding * 3 + [OAUtilities getBottomMargin];
    }
    else
    {
        self.primaryButtonTopMarginYesSecondary.active = hasSecondaryButton;
        self.primaryButtonTopMarginNoSecondary.active = !hasSecondaryButton;
        
        self.bottomViewHeigh.constant = self.primaryBottomButton.frame.size.height + kTopBottomPadding * 2 + [OAUtilities getBottomMargin];
    }
}

- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

- (IBAction)backImageButtonPressed:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)backButtonPressed:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)additionalNavBarButtonPressed:(id)sender
{
}

- (IBAction)primaryButtonPressed:(id)sender
{
}

- (IBAction)secondaryButtonPressed:(id)sender
{
}

@end

