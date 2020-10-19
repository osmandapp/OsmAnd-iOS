//
//  OABaseSettingsWithBottomButtonsViewController.mm
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 15.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABaseSettingsWithBottomButtonsViewController.h"
#import "Localization.h"
#import "OAColors.h"
#include <OsmAndCore/Utilities.h>

#define kTopBottomPadding 8
#define kButtonTopBottomPadding 10
#define kButtonSidePadding 16
#define kSidePadding 16
#define kTopPadding 6

@implementation OABaseSettingsWithBottomButtonsViewController
{
    CGFloat _heightForHeader;
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

- (UIView *) generateHeaderForTableView:(UITableView *)tableView withFirstSessionText:(NSString *)text forSection:(NSInteger)section
{
    if (section == 0)
    {
        UIView *vw = [[UIView alloc] initWithFrame:CGRectMake(0, 0.0, tableView.bounds.size.width - OAUtilities.getLeftMargin * 2, _heightForHeader)];
        CGFloat textWidth = self.tableView.bounds.size.width - (kSidePadding + OAUtilities.getLeftMargin) * 2;
        UILabel *description = [[UILabel alloc] initWithFrame:CGRectMake(kSidePadding + OAUtilities.getLeftMargin, 6.0, textWidth, _heightForHeader)];
        UIFont *labelFont = [UIFont systemFontOfSize:15.0];
        description.font = labelFont;
        [description setTextColor: UIColorFromRGB(color_text_footer)];
        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
        [style setLineSpacing:6];
        description.attributedText = [[NSAttributedString alloc] initWithString:text attributes:@{NSParagraphStyleAttributeName : style}];
        description.numberOfLines = 0;
        [vw addSubview:description];
        return vw;
    }
    else
    {
        return nil;
    }
}

- (CGFloat) generateHeightForHeaderWithFirstHeaderText:(NSString *)text inSection:(NSInteger)section
{
    if (section == 0)
    {
        _heightForHeader = [self heightForLabel:text];
        return _heightForHeader + kSidePadding + kTopPadding;
    }
    else
    {
        return UITableViewAutomaticDimension;
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

