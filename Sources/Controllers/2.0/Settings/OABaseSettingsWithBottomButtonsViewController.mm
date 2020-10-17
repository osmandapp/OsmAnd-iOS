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

- (void) setupBottomView
{
    BOOL hasPrimaryButton = !self.primaryBottomButton.hidden;
    BOOL hasSecondaryButton = !self.secondaryBottomButton.hidden;
    
    self.primaryBottomButton.layer.cornerRadius = 9.;
    self.secondaryBottomButton.layer.cornerRadius = 9.;
    
    self.primaryButtonTopMarginYesSecondary.active = hasPrimaryButton && hasSecondaryButton;
    self.primaryButtonTopMarginNoSecondary.active = !hasSecondaryButton;
    
    self.bottomViewHeigh.constant = (hasPrimaryButton ? self.primaryButtonHeight.constant : 0.) + (hasSecondaryButton ? self.secondaryButtonHeight.constant : 0.) + kTopBottomPadding * (hasPrimaryButton && hasSecondaryButton ? 3 : 2) + [OAUtilities getBottomMargin];
}

- (void) setToButton:(UIButton *)button firstLabelText:(NSString *)firstLabelText firstLabelFont:(UIFont *)firstLabelFont firstLabelColor:(UIColor *)firstLabelColor secondLabelText:(NSString *)secondLabelText secondLabelFont:(UIFont *)secondLabelFont secondLabelColor:(UIColor *)secondLabelColor
{
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n%@", firstLabelText, secondLabelText]];
    
    NSMutableParagraphStyle *paragraphStyles = [NSMutableParagraphStyle new];
    paragraphStyles.alignment = NSTextAlignmentCenter;
    paragraphStyles.lineSpacing = 3;
    
    NSDictionary *firstLabelAttributes = @{NSForegroundColorAttributeName: firstLabelColor, NSFontAttributeName: firstLabelFont, NSParagraphStyleAttributeName:paragraphStyles};
    NSDictionary *secondLabelAttributes = @{NSForegroundColorAttributeName: secondLabelColor, NSFontAttributeName: secondLabelFont, NSParagraphStyleAttributeName:paragraphStyles};
    
    [attributedText setAttributes:firstLabelAttributes range:NSMakeRange(0, [firstLabelText length])];
    [attributedText setAttributes:secondLabelAttributes range:NSMakeRange([firstLabelText length], [secondLabelText length] + 1)];
    
    button.titleLabel.numberOfLines = 0;
    button.contentEdgeInsets = UIEdgeInsetsMake(kButtonTopBottomPadding, kButtonSidePadding, kButtonTopBottomPadding, kButtonSidePadding);
    [button setAttributedTitle:attributedText forState:UIControlStateNormal];
    
    CGFloat height = [OAUtilities calculateTextBounds:attributedText width:(button.frame.size.width - 2*kButtonSidePadding)].height + 2*kButtonTopBottomPadding;
    if ([button isEqual:self.primaryBottomButton])
        self.primaryButtonHeight.constant = height;
    else
        self.secondaryButtonHeight.constant = height;
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

