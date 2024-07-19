//
//  OACreateProfileViewController.m
//  OsmAnd
//
//  Created by Paul on 8/29/18.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OACreateProfileViewController.h"
#import "Localization.h"
#import "OAColors.h"
#import "OAApplicationMode.h"
#import "OASimpleTableViewCell.h"
#import "OATableViewCustomHeaderView.h"
#import "OAProfileAppearanceViewController.h"
#import "OAUtilities.h"
#import "OASizes.h"

#include <generalRouter.h>

@implementation OACreateProfileViewController
{
    NSArray<OAApplicationMode *> * _profileList;
    CGFloat _heightForHeader;
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    [self.tableView registerClass:OATableViewCustomHeaderView.class forHeaderFooterViewReuseIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"create_profile");
}

- (BOOL)isNavbarSeparatorVisible
{
    return NO;
}

- (EOABaseNavbarStyle)getNavbarStyle
{
    return EOABaseNavbarStyleLargeTitle;
}

#pragma mark - Table data

- (void)generateData
{
    NSMutableArray *defaultProfileList = [NSMutableArray arrayWithArray:OAApplicationMode.allPossibleValues];
    [defaultProfileList removeObject:OAApplicationMode.DEFAULT];
    _profileList = [NSArray arrayWithArray:defaultProfileList];
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return _profileList.count;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    OASimpleTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
        cell = (OASimpleTableViewCell *)[nib objectAtIndex:0];
    }
    if (cell)
    {
        OAApplicationMode *am = _profileList[indexPath.row];
        UIImage *img = am.getIcon;
        cell.leftIconView.image = [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate].imageFlippedForRightToLeftLayoutDirection;
        cell.leftIconView.tintColor = am.getProfileColor;
        cell.titleLabel.text = _profileList[indexPath.row].toHumanString;
        cell.descriptionLabel.text = _profileList[indexPath.row].getProfileDescription;
    }
    return cell;
}

- (NSInteger)sectionsCount
{
    return 1;
}

- (UIView *)getCustomViewForHeader:(NSInteger)section
{
    OATableViewCustomHeaderView *customHeader = [self.tableView dequeueReusableHeaderFooterViewWithIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];
    customHeader.label.text = OALocalizedString(@"select_base_profile_dialog_message");
    customHeader.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    [customHeader setYOffset:0.];
    return customHeader;
}

- (CGFloat)getCustomHeightForHeader:(NSInteger)section
{
    return [OATableViewCustomHeaderView getHeight:OALocalizedString(@"select_base_profile_dialog_message")
                                            width:self.tableView.bounds.size.width
                                          xOffset:kPaddingOnSideOfContent
                                          yOffset:16.
                                             font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]];
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    OAProfileAppearanceViewController* profileAppearanceViewController = [[OAProfileAppearanceViewController alloc] initWithParentProfile:_profileList[indexPath.row]];
    [self.navigationController pushViewController:profileAppearanceViewController animated:YES];
}

@end
