//
//  OACloudIntroductionViewController.m
//  OsmAnd Maps
//
//  Created by Yuliia Stetsenko on 17.03.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OACloudIntroductionViewController.h"
#import "Localization.h"
#import "OAColors.h"
#import "OASizes.h"
#import "OACloudIntroductionHeaderView.h"
#import "OATitleRightIconCell.h"
#import "OAIAPHelper.h"
#import "OACloudAccountCreateViewController.h"
#import "OACloudAccountLoginViewController.h"
#import "OAChoosePlanHelper.h"

@interface OACloudIntroductionViewController () <UITableViewDelegate, UITableViewDataSource, OACloudIntroductionDelegate>

@end

@implementation OACloudIntroductionViewController
{
    NSArray<NSDictionary *> *_data;
    
    OACloudIntroductionHeaderView *_headerView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
        
    self.backImageButton.tintColor = UIColorFromRGB(color_primary_purple);
    
    [self setUpTableHeaderView];
    [self generateData];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableHeaderView = _headerView;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self setUpTableHeaderView];
        self.tableView.tableHeaderView = _headerView;
    } completion:nil];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

- (void)applyLocalization
{
    self.titleLabel.text = OALocalizedString(@"osmand_cloud");
}

- (void)generateData
{
    _data = @[ [self getLocalBackupSectionData] ];
}

- (void)setUpTableHeaderView
{
    _headerView = [[OACloudIntroductionHeaderView alloc] init];
    NSString *topButtonTitle = OALocalizedString(@"cloud_create_account");
    [_headerView setUpViewWithTitle:OALocalizedString(@"osmand_cloud") description:OALocalizedString(@"cloud_description") image:[UIImage imageNamed:@"ic_custom_cloud_upload_colored_day_big"] topButtonTitle:topButtonTitle bottomButtonTitle:OALocalizedString(@"cloud_existing_account")];
    CGRect frame = _headerView.frame;
    frame.size.height = [_headerView calculateViewHeight];
    _headerView.frame = frame;
    _headerView.delegate = self;
}

- (UIColor *)navBarBackgroundColor
{
    return UIColor.whiteColor;
}

- (void)onScrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView.contentOffset.y <= -defaultNavBarHeight)
    {
        scrollView.contentOffset = CGPointMake(scrollView.contentOffset.x, -defaultNavBarHeight);
    }
}

// MARK: UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return _data[section][@"sectionHeader"];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return _data[section][@"sectionFooter"];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return ((NSArray *)_data[section][@"rows"]).count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][@"rows"][indexPath.row];
    NSString *cellId = item[@"cellId"];
    if ([cellId isEqualToString:OATitleRightIconCell.getCellIdentifier])
    {
        OATitleRightIconCell* cell = [tableView dequeueReusableCellWithIdentifier:OATitleRightIconCell.getCellIdentifier];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATitleRightIconCell getCellIdentifier] owner:self options:nil];
            cell = (OATitleRightIconCell *)[nib objectAtIndex:0];
            cell.iconView.tintColor = UIColorFromRGB(color_primary_purple);
            cell.titleView.font = [UIFont systemFontOfSize:17.];
        }
        cell.titleView.text = item[@"title"];
        [cell.iconView setImage:[UIImage templateImageNamed:item[@"image"]]];
        return cell;
    }
    return nil;
}

// MARK: UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][@"rows"][indexPath.row];
    NSString *itemId = item[@"name"];
    if ([itemId isEqualToString:@"backupIntoFile"])
    {
        [self onBackupIntoFilePressed];
    }
    else if ([itemId isEqualToString:@"restoreFromFile"])
    {
        [self onRestoreFromFilePressed];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

// MARK: OACloudIntroductionDelegate

- (void)getOrRegisterButtonPressed
{
    OAIAPHelper *iapHelper = OAIAPHelper.sharedInstance;
    if ([iapHelper subscribedToLiveUpdates])
    {
        OACloudAccountCreateViewController *vc = [[OACloudAccountCreateViewController alloc] init];
        [self.navigationController pushViewController:vc animated:YES];
    }
    else
    {
        [OAChoosePlanHelper showChoosePlanScreenWithProduct:iapHelper.monthlyLiveUpdates navController:self.navigationController];
    }
}

- (void)logInButtonPressed
{
    OACloudAccountLoginViewController *vc = [[OACloudAccountLoginViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
