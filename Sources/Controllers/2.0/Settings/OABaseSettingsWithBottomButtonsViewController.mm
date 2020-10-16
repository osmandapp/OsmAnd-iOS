//
//  OABaseSettingsWithBottomButtonsViewController.mm
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 15.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABaseSettingsWithBottomButtonsViewController.h"
#include <OsmAndCore/Utilities.h>
#import "Localization.h"

#define kTopBottomPadding 8
#define kButtonTopBottomPadding 10
#define kButtonSidePadding 16

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
    [self.backButton setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    [self setupNavbar];
    [self layoutMultyLabelBottomButtoms];
    [self setupBottomView];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self layoutMultyLabelBottomButtoms];
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
        self.bottomViewHeigh.constant = self.primaryButtonHeight.constant + self.secondaryButtonHeight.constant + kTopBottomPadding * 3 + [OAUtilities getBottomMargin];
    }
    else
    {
        self.primaryButtonTopMarginYesSecondary.active = hasSecondaryButton;
        self.primaryButtonTopMarginNoSecondary.active = !hasSecondaryButton;
        self.bottomViewHeigh.constant = self.primaryButtonHeight.constant + kTopBottomPadding * 2 + [OAUtilities getBottomMargin];
    }
}

- (void) setToButton:(UIButton *)button firstLabelText:(NSString *)firstLabelText firstLabelFont:(UIFont *)firstLabelFont firstLabelColor:(UIColor *)firstLabelColor secondLabelText:(NSString *)secondLabelText secondLabelFont:(UIFont *)secondLabelFont secondLabelColor:(UIColor *)secondLabelColor
{
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n%@", firstLabelText, secondLabelText]];
    
    NSMutableParagraphStyle *paragraphStyles = [NSMutableParagraphStyle new];
    paragraphStyles.alignment = NSTextAlignmentCenter;
    paragraphStyles.lineSpacing = 3;
    
    NSDictionary *firstLabelAttributes = @{NSForegroundColorAttributeName: firstLabelColor, NSFontAttributeName: firstLabelFont, NSParagraphStyleAttributeName:paragraphStyles};
    NSDictionary *secondLabelAttributes = @{NSForegroundColorAttributeName: secondLabelColor, NSFontAttributeName: secondLabelFont, NSParagraphStyleAttributeName:paragraphStyles};
    
    [attributedText setAttributes:firstLabelAttributes range:NSMakeRange(0,  [firstLabelText length])];
    [attributedText setAttributes:secondLabelAttributes range:NSMakeRange([firstLabelText length], [secondLabelText length] + 1)];
    
    button.titleLabel.numberOfLines = 0;
    button.contentEdgeInsets = UIEdgeInsetsMake(kButtonTopBottomPadding, kButtonSidePadding, kButtonTopBottomPadding, kButtonSidePadding);
    [button setAttributedTitle:attributedText forState:UIControlStateNormal];
}

- (void) layoutMultyLabelBottomButtoms
{
    CGFloat estimatedLabelWidth = self.view.frame.size.width - 2*[OAUtilities getLeftMargin] - 2*kButtonSidePadding;
    if (self.primaryBottomButton.titleLabel.attributedText)
        self.primaryButtonHeight.constant = [OAUtilities calculateTextBounds:self.primaryBottomButton.titleLabel.attributedText width:estimatedLabelWidth].height + 2*kButtonTopBottomPadding;
    if (self.secondaryBottomButton.titleLabel.attributedText)
        self.secondaryButtonHeight.constant = [OAUtilities calculateTextBounds:self.secondaryBottomButton.titleLabel.attributedText width:estimatedLabelWidth].height + 2*kButtonTopBottomPadding;
    if (self.primaryBottomButton.titleLabel.attributedText || self.secondaryBottomButton.titleLabel.attributedText)
        [self setupBottomView];
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

