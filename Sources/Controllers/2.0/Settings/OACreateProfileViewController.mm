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
#import "OAIconTextButtonCell.h"
#import "OATableViewCustomHeaderView.h"
#import "OAProfileAppearanceViewController.h"
#import "OAUtilities.h"
#import "OASizes.h"

#include <generalRouter.h>

#define kHeaderId @"TableViewSectionHeader"
#define kSidePadding 16
#define kTopPadding 6
#define kHeaderViewFont [UIFont systemFontOfSize:34.0 weight:UIFontWeightBold]
#define kCellTypeIconTitleSubtitle @"OAIconTextButtonCell"

@interface OACreateProfileViewController () <UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate>

@end

@implementation OACreateProfileViewController
{
    NSArray<OAApplicationMode *> * _profileList;
    CGFloat _heightForHeader;
    UIView *_navBarBackgroundView;
}

- (instancetype) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [super initWithNibName:@"OACreateProfileViewController" bundle:nil];
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
    for (OAApplicationMode *profile in defaultProfileList)
    {
        if ([profile.name isEqualToString:@"Overview"])
        {
            [defaultProfileList removeObject:profile];
            break;
        }
    }
    _profileList = [NSArray arrayWithArray:defaultProfileList];
}

- (void) applyLocalization
{
    [_backButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    _titleLabel.text = OALocalizedString(@"create_profile");
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.rowHeight = UITableViewAutomaticDimension;
    _tableView.estimatedRowHeight = 60.;
    _tableView.contentInset = UIEdgeInsetsMake(defaultNavBarHeight, 0, 0, 0);
    [self.tableView registerClass:OATableViewCustomHeaderView.class forHeaderFooterViewReuseIdentifier:kHeaderId];
    _tableView.tableHeaderView = [OAUtilities setupTableHeaderViewWithText:OALocalizedString(@"create_profile") font:kHeaderViewFont textColor:UIColor.blackColor lineSpacing:0.0 isTitle:YES];
    _navBarBackgroundView = [self createNavBarBackgroundView];
    _navBarBackgroundView.frame = _navBarView.bounds;
    [_navBarView insertSubview:_navBarBackgroundView atIndex:0];
}

- (UIView *) createNavBarBackgroundView
{
    if (!UIAccessibilityIsReduceTransparencyEnabled())
    {
        UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
        blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        blurEffectView.alpha = 0;
        return blurEffectView;
    }
    else
    {
        UIView *res = [[UIView alloc] init];
        res.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        res.backgroundColor = UIColorFromRGB(color_bottom_sheet_background);
        res.alpha = 0;
        return res;
    }
}

- (IBAction) backButtonClicked:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

- (void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        _tableView.tableHeaderView = [OAUtilities setupTableHeaderViewWithText:OALocalizedString(@"create_profile") font:kHeaderViewFont textColor:UIColor.blackColor lineSpacing:0.0 isTitle:YES];
        [_tableView reloadData];
    } completion:nil];
}

#pragma mark - Table View

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *vw = [[UIView alloc] initWithFrame:CGRectMake(0, 0.0, tableView.bounds.size.width - OAUtilities.getLeftMargin * 2, _heightForHeader)];
    CGFloat textWidth = _tableView.bounds.size.width - (kSidePadding + OAUtilities.getLeftMargin) * 2;
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
    static NSString* const identifierCell = kCellTypeIconTitleSubtitle;
    OAIconTextButtonCell* cell;
    cell = (OAIconTextButtonCell *)[tableView dequeueReusableCellWithIdentifier:identifierCell];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kCellTypeIconTitleSubtitle owner:self options:nil];
        cell = (OAIconTextButtonCell *)[nib objectAtIndex:0];
        cell.separatorInset = UIEdgeInsetsMake(0.0, 62.0, 0.0, 0.0);
        cell.buttonView.hidden = YES;
        cell.detailsIconView.hidden = YES;
    }
    OAApplicationMode *am = _profileList[indexPath.row];
    UIImage *img = am.getIcon;
    cell.iconView.image = [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    cell.iconView.tintColor = UIColorFromRGB(am.getIconColor);
    cell.textView.text = _profileList[indexPath.row].name;
    cell.descView.text = _profileList[indexPath.row].getProfileDescription;
    return cell;
}

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _profileList.count;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAProfileAppearanceViewController* profileAppearanceViewController = [[OAProfileAppearanceViewController alloc] initWithProfile:_profileList[indexPath.row]];
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    [self.navigationController pushViewController:profileAppearanceViewController animated:YES];
}

- (CGFloat) heightForLabel:(NSString *)text
{
    UIFont *labelFont = [UIFont systemFontOfSize:15.0];
    CGFloat textWidth = _tableView.bounds.size.width - (kSidePadding + OAUtilities.getLeftMargin) * 2;
    return [OAUtilities heightForHeaderViewText:text width:textWidth font:labelFont lineSpacing:6.0];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat alpha = _tableView.contentOffset.y < 0 ? 0 : (_tableView.contentOffset.y / (_tableView.contentSize.height - _tableView.frame.size.height));
    if (alpha > 0)
    {
        _titleLabel.hidden = NO;
        _navBarView.backgroundColor = UIColor.clearColor;
        _navBarBackgroundView.alpha = 1;
    }
    else
    {
        _titleLabel.hidden = YES;
        _navBarView.backgroundColor = UIColorFromRGB(color_bottom_sheet_background);
        _navBarBackgroundView.alpha = 0;
    }
}

@end
