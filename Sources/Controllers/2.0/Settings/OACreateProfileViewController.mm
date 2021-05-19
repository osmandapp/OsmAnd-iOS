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
#import "OAMenuSimpleCell.h"
#import "OATableViewCustomHeaderView.h"
#import "OAProfileAppearanceViewController.h"
#import "OAUtilities.h"
#import "OASizes.h"

#include <generalRouter.h>

#define kSidePadding 16
#define kTopPadding 6

@interface OACreateProfileViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OACreateProfileViewController
{
    NSArray<OAApplicationMode *> * _profileList;
    CGFloat _heightForHeader;
}

- (instancetype) init
{
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void) commonInit
{
    [self generateData];
}

- (void) generateData
{
    NSMutableArray *defaultProfileList = [NSMutableArray arrayWithArray:OAApplicationMode.allPossibleValues];
    [defaultProfileList removeObject:OAApplicationMode.DEFAULT];
    _profileList = [NSArray arrayWithArray:defaultProfileList];
}

- (void) applyLocalization
{
    [super applyLocalization];
    self.titleLabel.text = OALocalizedString(@"create_profile");
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerClass:OATableViewCustomHeaderView.class forHeaderFooterViewReuseIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];
}

- (NSString *) getTableHeaderTitle
{
    return OALocalizedString(@"create_profile");
}

- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

#pragma mark - Table View

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *vw = [[UIView alloc] initWithFrame:CGRectMake(0, 0.0, tableView.bounds.size.width - OAUtilities.getLeftMargin * 2, _heightForHeader)];
    CGFloat textWidth = self.tableView.bounds.size.width - (kSidePadding + OAUtilities.getLeftMargin) * 2;
    UILabel *description = [[UILabel alloc] initWithFrame:CGRectMake(kSidePadding + OAUtilities.getLeftMargin, 6.0, textWidth, _heightForHeader)];
    UIFont *labelFont = [UIFont systemFontOfSize:15.0];
    description.font = labelFont;
    [description setTextColor: UIColorFromRGB(color_text_footer)];
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setLineSpacing:6];
    description.attributedText = [[NSAttributedString alloc] initWithString:OALocalizedString(@"create_profile_descr") attributes:@{NSParagraphStyleAttributeName : style}];
    description.numberOfLines = 0;
    [vw addSubview:description];
    return vw;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    _heightForHeader = [self heightForLabel:OALocalizedString(@"create_profile_descr")];
    return _heightForHeader + kSidePadding + kTopPadding;
}

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    OAMenuSimpleCell* cell;
    cell = (OAMenuSimpleCell *)[tableView dequeueReusableCellWithIdentifier:[OAMenuSimpleCell getCellIdentifier]];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAMenuSimpleCell getCellIdentifier] owner:self options:nil];
        cell = (OAMenuSimpleCell *)[nib objectAtIndex:0];
        cell.separatorInset = UIEdgeInsetsMake(0.0, 70.0, 0.0, 0.0);
    }
    OAApplicationMode *am = _profileList[indexPath.row];
    UIImage *img = am.getIcon;
    cell.imgView.image = [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    cell.imgView.tintColor = UIColorFromRGB(am.getIconColor);
    cell.textView.text = _profileList[indexPath.row].toHumanString;
    cell.descriptionView.text = _profileList[indexPath.row].getProfileDescription;
    return cell;
}

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _profileList.count;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAProfileAppearanceViewController* profileAppearanceViewController = [[OAProfileAppearanceViewController alloc] initWithParentProfile:_profileList[indexPath.row]];
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    [self.navigationController pushViewController:profileAppearanceViewController animated:YES];
}

@end
