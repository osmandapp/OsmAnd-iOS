//
//  OAChoosePlanViewController.m
//  OsmAnd
//
//  Created by Alexey on 17/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAChoosePlanViewController.h"
#import "Localization.h"
#import "OAUtilities.h"

@interface OAChoosePlanViewController ()

@end

@implementation OAChoosePlanViewController

- (void) applyLocalization
{
    self.lbTitle.text = OALocalizedString(@"purchase_dialog_title");
    self.lbDescription.text = OALocalizedString(@"purchase_dialog_travel_description");
    [self.btnLater setTitle:OALocalizedString(@"shared_string_later") forState:UIControlStateNormal];
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    
}

- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

- (void) viewWillLayoutSubviews
{
    CGRect frame = self.scrollView.frame;
    
    CGFloat w = frame.size.width;
    CGFloat descrHeight = [OAUtilities calculateTextBounds:self.lbDescription.text width:w - 32 - 32 font:self.lbDescription.font].height;
    CGRect nf = self.navBarView.frame;
    CGRect df = self.lbDescription.frame;
    self.lbDescription.frame = CGRectMake(32, nf.origin.y + nf.size.height, w - 32 - 32, descrHeight + 16 + 16);
    df = self.lbDescription.frame;
    
    CGFloat cardsHeight = 0;
    CGRect cf = self.cardsContainer.frame;
    self.cardsContainer.frame = CGRectMake(cf.origin.x, df.origin.y + df.size.height + 16, w - cf.origin.x * 2, cardsHeight);
    cf = self.cardsContainer.frame;
    
    CGRect lbf = self.btnLater.frame;
    self.btnLater.frame = CGRectMake(lbf.origin.x, cf.origin.y + cf.size.height + 16, w - lbf.origin.x * 2, lbf.size.height);
    
}

- (IBAction) backButtonClicked:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
