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
#import "OsmAnd_Maps-Swift.h"

@interface OACloudIntroductionViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OACloudIntroductionViewController
{
    NSArray<NSDictionary *> *_data;
    
    OACloudIntroductionHeaderView *_headerView;
    CloudIntroductionButtonsView *_cloudIntroductionButtonsView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.backImageButton setImage:[UIImage rtlImageNamed:@"ic_navbar_chevron"] forState:UIControlStateNormal];
    self.backImageButton.tintColor = UIColorFromRGB(color_primary_purple);
    
    [self setUpTableHeaderView];
    [self generateData];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableHeaderView = _headerView;
    self.tableView.scrollEnabled = NO;
    self.tableView.backgroundColor = [UIColor whiteColor];
    [self configureCloudIntroductionButtonsView];
}

- (void)configureCloudIntroductionButtonsView
{
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"CloudIntroductionButtonsView" owner:self options:nil];
    _cloudIntroductionButtonsView = (CloudIntroductionButtonsView *)nib[0];
    __weak OACloudIntroductionViewController *weakSelf = self;
    _cloudIntroductionButtonsView.didRegisterButtonAction = ^{
        [weakSelf.navigationController pushViewController:[OACloudAccountCreateViewController new] animated:YES];
    };
    _cloudIntroductionButtonsView.didLogInButtonAction = ^{
        [weakSelf.navigationController pushViewController:[OACloudAccountLoginViewController new] animated:YES];
    };
    _cloudIntroductionButtonsView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_cloudIntroductionButtonsView];
    [NSLayoutConstraint activateConstraints:@[
        [_cloudIntroductionButtonsView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
        [_cloudIntroductionButtonsView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_cloudIntroductionButtonsView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_cloudIntroductionButtonsView.heightAnchor constraintEqualToConstant:110],
    ]];
}

- (void)registerNotifications
{
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(onApplicationEnteredForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)onApplicationEnteredForeground
{
    [_headerView addAnimatedViews];
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
        [weakSelf setUpTableHeaderView];
        weakSelf.tableView.tableHeaderView = _headerView;
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [_headerView addAnimatedViews];
    }];
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
    _data = @[];
}

- (void)setUpTableHeaderView
{
    _headerView = [[OACloudIntroductionHeaderView alloc] init];
    [_headerView setUpViewWithTitle:OALocalizedString(@"osmand_cloud") description:OALocalizedString(@"osmand_cloud_authorize_descr")
                              image:[UIImage imageNamed:@"ic_custom_cloud_upload_colored_day_big"]];
    CGRect frame = _headerView.frame;
    frame.size.height = [_headerView calculateViewHeight];
    _headerView.frame = frame;
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
            cell.titleView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
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
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
