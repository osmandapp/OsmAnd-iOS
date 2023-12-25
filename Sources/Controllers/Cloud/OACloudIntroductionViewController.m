//
//  OACloudIntroductionViewController.m
//  OsmAnd Maps
//
//  Created by Yuliia Stetsenko on 17.03.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OACloudIntroductionViewController.h"
#import "Localization.h"
#import "OASizes.h"
#import "OACloudIntroductionHeaderView.h"
#import "OARightIconTableViewCell.h"
#import "OAIAPHelper.h"
#import "OACloudAccountCreateViewController.h"
#import "OACloudAccountLoginViewController.h"
#import "OAChoosePlanHelper.h"
#import "OsmAnd_Maps-Swift.h"

@implementation OACloudIntroductionViewController
{
    NSArray<NSDictionary *> *_data;
    OACloudIntroductionHeaderView *_headerView;
}

#pragma mark - Initialization

- (void)registerNotifications
{
    [self addNotification:UIApplicationWillEnterForegroundNotification selector:@selector(onApplicationEnteredForeground)];
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupTableHeaderView];
    self.tableView.tableHeaderView = _headerView;
    self.tableView.backgroundColor = UIColor.groupBgColor;
    self.bottomButton.backgroundColor = UIColor.buttonBgColorTertiary;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [_headerView addAnimatedViews];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    __weak OACloudIntroductionViewController *weakSelf = self;
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [weakSelf setupTableHeaderView];
        weakSelf.tableView.tableHeaderView = _headerView;
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [_headerView addAnimatedViews];
    }];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

#pragma mark - Base setup UI

- (NSString *)getTitle
{
    return OALocalizedString(@"osmand_cloud");
}

- (EOABaseNavbarColorScheme)getNavbarColorScheme
{
    return EOABaseNavbarColorSchemeWhite;
}

- (NSString *)getTopButtonTitle
{
    return OALocalizedString(@"cloud_create_account");
}

- (NSString *)getBottomButtonTitle
{
    return OALocalizedString(@"register_opr_have_account");
}

- (EOABaseButtonColorScheme)getTopButtonColorScheme
{
    return EOABaseButtonColorSchemePurple;
}

- (EOABaseButtonColorScheme)getBottomButtonColorScheme
{
    return EOABaseButtonColorSchemeGraySimple;
}

- (EOABaseBottomColorScheme)getBottomColorScheme;
{
    return EOABaseBottomColorSchemeWhite;
}

- (BOOL)isNavbarSeparatorVisible
{
    return NO;
}

- (BOOL)isBottomSeparatorVisible
{
    return NO;
}

- (BOOL)useCustomTableViewHeader
{
    return YES;
}

#pragma mark - Table data

- (void)generateData
{
    _data = @[];
}

- (void)setupTableHeaderView
{
    _headerView = [[OACloudIntroductionHeaderView alloc] init];
    [_headerView setUpViewWithTitle:OALocalizedString(@"osmand_cloud") description:OALocalizedString(@"osmand_cloud_authorize_descr")
                              image:[UIImage imageNamed:@"ic_custom_cloud_upload_colored_day_big"]];
    CGRect frame = _headerView.frame;
    frame.size.height = [_headerView calculateViewHeight];
    _headerView.frame = frame;
}

- (void)onApplicationEnteredForeground
{
    [_headerView addAnimatedViews];
}

- (NSInteger)sectionsCount:(UITableView *)tableView
{
    return _data.count;
}

- (NSString *)getTitleForHeader:(NSInteger)section
{
    return _data[section][@"sectionHeader"];
}

- (NSString *)getTitleForFooter:(NSInteger)section
{
    return _data[section][@"sectionFooter"];
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return ((NSArray *)_data[section][@"rows"]).count;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][@"rows"][indexPath.row];
    NSString *cellId = item[@"cellId"];
    if ([cellId isEqualToString:OARightIconTableViewCell.getCellIdentifier])
    {
        OARightIconTableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:OARightIconTableViewCell.getCellIdentifier];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OARightIconTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OARightIconTableViewCell *)[nib objectAtIndex:0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
            cell.rightIconView.tintColor = UIColor.iconColorActive;
            cell.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            [cell.rightIconView setImage:[UIImage templateImageNamed:item[@"image"]]];
        }
        return cell;
    }
    return nil;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Selectors

- (void)onTopButtonPressed
{
    [self.navigationController pushViewController:[OACloudAccountCreateViewController new] animated:YES];
}

- (void)onBottomButtonPressed
{
    [self.navigationController pushViewController:[OACloudAccountLoginViewController new] animated:YES];
}

@end
