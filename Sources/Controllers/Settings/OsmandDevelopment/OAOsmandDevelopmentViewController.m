//
//  OAOsmandDevelopmentViewController.m
//  OsmAnd Maps
//
//  Created by nnngrach on 01.06.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAOsmandDevelopmentViewController.h"
#import "OAAppSettings.h"
#import "Localization.h"
#import "OAColors.h"
#import "OAIconTitleValueCell.h"
#import "OAOsmandDevelopmentSimulateLocationViewController.h"

@interface OAOsmandDevelopmentViewController () <OAOsmandDevelopmentSimulateLocationDelegate>

@end

@implementation OAOsmandDevelopmentViewController
{
    NSArray<NSArray *> *_data;
    NSString *_headerDescription;
}

NSString *const kSimulateLocationKey = @"kSimulateLocationKey";

- (void) viewDidLoad
{
    [super viewDidLoad];
    [self applySafeAreaMargins];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.estimatedRowHeight = kEstimatedRowHeight;
    self.tableView.tableHeaderView = [OAUtilities setupTableHeaderViewWithText:_headerDescription font:[UIFont systemFontOfSize:15] textColor:UIColorFromRGB(color_text_footer) lineSpacing:0.0 isTitle:NO];
    
    self.backButton.imageView.image = [self.backButton.imageView.image imageFlippedForRightToLeftLayoutDirection];
}

- (void) viewWillAppear:(BOOL)animated
{
    [self generateData];
    [self applySafeAreaMargins];
    [self.tableView reloadData];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        self.tableView.tableHeaderView = [OAUtilities setupTableHeaderViewWithText:_headerDescription font:[UIFont systemFontOfSize:15] textColor:UIColorFromRGB(color_text_footer) lineSpacing:0.0 isTitle:NO];
    } completion:nil];
}

-(UIView *) getTopView
{
    return _navBarView;
}


#pragma mark - Setup data

- (void) applyLocalization
{
    _titleView.text = OALocalizedString(@"product_title_development");
    _headerDescription = OALocalizedString(@"osm_editing_settings_descr");
}

- (void) generateData
{
    NSMutableArray<NSArray *> *sectionArr = [NSMutableArray new];
    NSMutableArray *dataArr = [NSMutableArray new];
    
    [dataArr addObject:@{
        @"type" : [OAIconTitleValueCell getCellIdentifier],
        @"key" : kSimulateLocationKey,
        @"title" : OALocalizedString(@"simulate_routing"),
        @"value" : OALocalizedString(@"simulate_in_progress"),
        @"hederTitle" : OALocalizedString(@"osmand_depelopment_simulate_location_section"),
        @"footerTitle" : @"",
    }];
    [sectionArr addObject:[NSArray arrayWithArray:dataArr]];
    
    _data = sectionArr;
}

- (NSDictionary *) getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.section][indexPath.row];
}


#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data[section].count;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    NSString *type = item[@"type"];
    
    if ([type isEqualToString:[OAIconTitleValueCell getCellIdentifier]])
    {
        OAIconTitleValueCell* cell = [tableView dequeueReusableCellWithIdentifier:[OAIconTitleValueCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTitleValueCell getCellIdentifier] owner:self options:nil];
            cell = (OAIconTitleValueCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
            cell.rightIconView.image = [UIImage templateImageNamed:@"ic_custom_arrow_right"].imageFlippedForRightToLeftLayoutDirection;
            cell.rightIconView.tintColor = UIColorFromRGB(color_tint_gray);
            [cell showLeftIcon: NO];
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.descriptionView.text = item[@"value"];
        }
        return cell;
    }
    return nil;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSDictionary *item = [self getItem:[NSIndexPath indexPathForRow:0 inSection:section]];
    return item[@"hederTitle"];
}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    NSDictionary *item = [self getItem:[NSIndexPath indexPathForRow:0 inSection:section]];
    return item[@"footerTitle"];
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    [header.textLabel setTextColor:UIColorFromRGB(color_text_footer)];
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *footer = (UITableViewHeaderFooterView *)view;
    [footer.textLabel setTextColor:UIColorFromRGB(color_text_footer)];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"key"] isEqualToString:kSimulateLocationKey])
    {
        OAOsmandDevelopmentSimulateLocationViewController *vc = [[OAOsmandDevelopmentSimulateLocationViewController alloc] init];
        vc.simulateLocationDelegate = self;
        [self.navigationController pushViewController:vc animated:YES];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark - OAOsmandDevelopmentSimulateLocationDelegate

- (void) onSimulateLocationInformationUpdated
{
    [self generateData];
    [self.tableView reloadData];
}

@end
