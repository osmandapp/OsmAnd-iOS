//
//  OABaseSettingsViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 25.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABaseSettingsViewController.h"
#import "OAColors.h"
#import "OASizes.h"
#import "OAApplicationMode.h"
#import "Localization.h"

#define kSidePadding 20

@implementation OABaseSettingsViewController

#pragma mark - Initialization

- (instancetype) initWithAppMode:(OAApplicationMode *)appMode
{
    self = [super init];
    if (self)
    {
        _appMode = appMode;
        [self postInit];
    }
    return self;
}

#pragma mark - Base UI

- (NSString *)getSubtitle
{
    return [_appMode toHumanString];
}

- (void)addAccessibilityLabels
{
    self.leftNavbarButton.accessibilityLabel = OALocalizedString(@"shared_string_back");
}

#pragma mark - Additions

- (void) setupTableHeaderViewWithText:(NSString *)text
{
    CGFloat textWidth = DeviceScreenWidth - (kSidePadding + OAUtilities.getLeftMargin) * 2;
    CGFloat textHeight = [self heightForLabel:text];
    UIView *tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, DeviceScreenWidth, textHeight + kSidePadding)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(kSidePadding + OAUtilities.getLeftMargin, kSidePadding, textWidth, textHeight)];
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setLineSpacing:6];
    label.attributedText = [[NSAttributedString alloc] initWithString:text
                                                        attributes:@{NSParagraphStyleAttributeName : style,
                                                        NSForegroundColorAttributeName : UIColorFromRGB(color_text_footer),
                                                        NSFontAttributeName : [UIFont scaledSystemFontOfSize:13.0],
                                                        NSBackgroundColorAttributeName : UIColor.clearColor}];
    label.textAlignment = NSTextAlignmentLeft;
    label.numberOfLines = 0;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    tableHeaderView.backgroundColor = UIColor.clearColor;
    [tableHeaderView addSubview:label];
    self.tableView.tableHeaderView = tableHeaderView;
}

- (CGFloat) heightForLabel:(NSString *)text
{
    UIFont *labelFont = [UIFont scaledSystemFontOfSize:[self fontSizeForLabel]];
    CGFloat textWidth = DeviceScreenWidth - (kSidePadding + OAUtilities.getLeftMargin) * 2;
    return [OAUtilities heightForHeaderViewText:text width:textWidth font:labelFont lineSpacing:6.0];
}

- (CGFloat)fontSizeForLabel
{
    return 15.;
}

#pragma mark - OASettingsDataDelegate

- (void) onSettingsChanged
{
    [self.tableView reloadData];
}

@end
