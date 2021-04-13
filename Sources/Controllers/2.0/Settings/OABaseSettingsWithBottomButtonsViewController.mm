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
#define kBottomPadding 32


@implementation OABaseSettingsWithBottomButtonsViewController
{
    CGFloat _heightForHeader;
}

- (instancetype) init
{
    self = [super initWithNibName:@"OABaseSettingsWithBottomButtonsViewController" bundle:nil];
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
    BOOL hasBottomView = !self.bottomBarView.hidden;
    
    self.primaryBottomButton.layer.cornerRadius = 9.;
    self.secondaryBottomButton.layer.cornerRadius = 9.;
    
    self.primaryButtonTopMarginYesSecondary.active = hasPrimaryButton && hasSecondaryButton;
    self.primaryButtonTopMarginNoSecondary.active = !hasSecondaryButton;
    
    self.bottomViewHeigh.constant = (hasPrimaryButton ? self.primaryButtonHeight.constant : 0.) + (hasSecondaryButton ? self.secondaryButtonHeight.constant : 0.) + kTopBottomPadding * (hasPrimaryButton && hasSecondaryButton ? 3 : 2) + [OAUtilities getBottomMargin];
    
    self.tableViewBottomMarginYesView.active = hasBottomView;
    self.tableViewBottomMarginNoView.active = !hasBottomView;
}

- (void) setParams:(NSDictionary *)params forTwoLabelButton:(UIButton *)button
{
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n%@", params[@"firstLabelText"], params[@"secondLabelText"]]];
    
    NSMutableParagraphStyle *paragraphStyles = [NSMutableParagraphStyle new];
    paragraphStyles.alignment = NSTextAlignmentCenter;
    paragraphStyles.lineSpacing = 3;
    
    UIFont *firstLabelFont = params[@"firstLabelFont"] ? params[@"firstLabelFont"] :[UIFont systemFontOfSize:15 weight:UIFontWeightSemibold]; [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    UIFont *secondLabelFont = params[@"secondLabelFont"] ? params[@"secondLabelFont"] : [UIFont systemFontOfSize:13];
    NSDictionary *firstLabelAttributes = @{NSForegroundColorAttributeName: params[@"firstLabelColor"], NSFontAttributeName: firstLabelFont, NSParagraphStyleAttributeName:paragraphStyles};
    NSDictionary *secondLabelAttributes = @{NSForegroundColorAttributeName: params[@"secondLabelColor"], NSFontAttributeName: secondLabelFont, NSParagraphStyleAttributeName:paragraphStyles};
    
    [attributedText setAttributes:firstLabelAttributes range:NSMakeRange(0, [params[@"firstLabelText"] length])];
    [attributedText setAttributes:secondLabelAttributes range:NSMakeRange([params[@"firstLabelText"] length], [params[@"secondLabelText"] length] + 1)];
    
    button.titleLabel.numberOfLines = 0;
    button.contentEdgeInsets = UIEdgeInsetsMake(kButtonTopBottomPadding, kButtonSidePadding, kButtonTopBottomPadding, kButtonSidePadding);
    [button setAttributedTitle:attributedText forState:UIControlStateNormal];
    
    CGFloat height = [OAUtilities calculateTextBounds:attributedText width:(button.frame.size.width - 2*kButtonSidePadding)].height + 2*kButtonTopBottomPadding;
    if ([button isEqual:self.primaryBottomButton])
        self.primaryButtonHeight.constant = height;
    else
        self.secondaryButtonHeight.constant = height;
}

- (UIView *) getHeaderForTableView:(UITableView *)tableView withFirstSectionText:(NSString *)text boldFragment:(NSString *)boldFragment forSection:(NSInteger)section
{
    if (section == 0)
    {
        NSString *descriptionText;
        if (boldFragment && boldFragment.length > 0)
            descriptionText = [NSString stringWithFormat:text, boldFragment];
        else
            descriptionText = text;
            
        CGFloat textWidth = tableView.bounds.size.width - 32 - OAUtilities.getLeftMargin * 2;
        CGFloat heightForHeader = [OAUtilities heightForHeaderViewText:descriptionText width:textWidth font:[UIFont systemFontOfSize:15] lineSpacing:6.] + 16;
        UIView *vw = [[UIView alloc] initWithFrame:CGRectMake(0., 0., tableView.bounds.size.width, heightForHeader)];
        UILabel *description = [[UILabel alloc] initWithFrame:CGRectMake(16. + OAUtilities.getLeftMargin, 8., textWidth, heightForHeader)];
        UIFont *labelFont = [UIFont systemFontOfSize:15.0];
        description.font = labelFont;
        [description setTextColor: UIColorFromRGB(color_text_footer)];
        
        if (boldFragment && boldFragment.length > 0)
            description.attributedText = [OAUtilities getStringWithBoldPart:descriptionText mainString:descriptionText boldString:boldFragment lineSpacing:4. fontSize:15. highlightColor:UIColor.blackColor];
        else
        {
            NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
            [style setLineSpacing:6];
            description.attributedText = [[NSAttributedString alloc] initWithString:descriptionText attributes:@{NSParagraphStyleAttributeName : style}];
        }
            
        description.numberOfLines = 0;
        description.lineBreakMode = NSLineBreakByWordWrapping;
        description.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [vw addSubview:description];
        return vw;
    }
    else
    {
        return nil;
    }
}

- (CGFloat) getHeightForHeaderWithFirstHeaderText:(NSString *)text boldFragment:(NSString *)boldFragment inSection:(NSInteger)section
{
    if (section == 0)
    {
        NSString *descriptionText;
        if (boldFragment && boldFragment.length > 0)
            descriptionText = [NSString stringWithFormat:text, boldFragment];
        else
            descriptionText = text;
        
        _heightForHeader = [self heightForLabel:descriptionText];
        return _heightForHeader + kBottomPadding + kTopPadding;
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

