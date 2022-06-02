//
//  OAOsmandDevelopmentSimulateLocationViewController.m
//  OsmAnd Maps
//
//  Created by nnngrach on 01.06.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAOsmandDevelopmentSimulateLocationViewController.h"
#import "OAOpenAddTrackViewController.h"
#import "OAOsmandDevelopmentSimulateSpeedSelectorViewController.h"
#import "OAIconTitleValueCell.h"
#import "OATitleRightIconCell.h"
#import "Localization.h"
#import "OAColors.h"

@interface OAOsmandDevelopmentSimulateLocationViewController () <UITableViewDelegate, UITableViewDataSource, OAOpenAddTrackDelegate, OAOsmandDevelopmentSimulateSpeedSelectorDelegate>

@end

@implementation OAOsmandDevelopmentSimulateLocationViewController
{
    NSArray<NSArray *> *_data;
    NSString *_headerDescription;
    NSString *_selectedTrackName;
    NSInteger _selectedSpeedModeIndex;
}

NSString *const kTrackSelectKey = @"kTrackSelectKey";
NSString *const kMovementSpeedKey = @"kMovementSpeedKey";
NSString *const kStartStopButtonKey = @"kStartStopButtonKey";
CGFloat const kDefaultHeight = 48.0;
CGFloat const kDefaultHeaderHeight = 40.0;

- (instancetype) init
{
    self = [super initWithNibName:@"OABaseSettingsViewController" bundle:nil];
    if (self)
    {
    }
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorInset = UIEdgeInsetsMake(0., 16.0 + OAUtilities.getLeftMargin, 0., 0.);
    self.tableView.tableHeaderView = [OAUtilities setupTableHeaderViewWithText:_headerDescription font:[UIFont systemFontOfSize:15] textColor:UIColorFromRGB(color_text_footer) lineSpacing:0.0 isTitle:NO];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self generateData];
    [self.tableView reloadData];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (_simulateLocationDelegate)
        [_simulateLocationDelegate onSimulateLocationInformationUpdated];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        self.tableView.tableHeaderView = [OAUtilities setupTableHeaderViewWithText:_headerDescription font:[UIFont systemFontOfSize:15] textColor:UIColorFromRGB(color_text_footer) lineSpacing:0.0 isTitle:NO];
        self.tableView.separatorInset = UIEdgeInsetsMake(0., 16.0 + OAUtilities.getLeftMargin, 0., 0.);
        [self.tableView reloadData];
    } completion:nil];
}


#pragma mark - Setup data

- (void) applyLocalization
{
    [super applyLocalization];
    self.titleLabel.text = OALocalizedString(@"simulate_routing");
    _headerDescription = OALocalizedString(@"simulate_your_location_gpx_descr");
}

- (void) generateData
{
    _selectedTrackName = OALocalizedString(@"gpx_select_track"); //TODO: fetch from settings
    _selectedSpeedModeIndex = 0; //TODO: fetch from settings
    
    NSString *speedModeName;
    if (_selectedSpeedModeIndex == 0)
        speedModeName = OALocalizedString(@"simulate_location_movement_speed_original");
    else if (_selectedSpeedModeIndex == 1)
        speedModeName = OALocalizedString(@"simulate_location_movement_speed_x2");
    else if (_selectedSpeedModeIndex == 2)
        speedModeName = OALocalizedString(@"simulate_location_movement_speed_x3");
    else
        speedModeName = OALocalizedString(@"simulate_location_movement_speed_x4");
    
    NSMutableArray *tableData = [NSMutableArray array];
    NSMutableArray *settingsSection = [NSMutableArray array];
    [settingsSection addObject:@{
        @"type" : [OAIconTitleValueCell getCellIdentifier],
        @"key" : kTrackSelectKey,
        @"title" : OALocalizedString(@"shared_string_gpx_track"),
        @"value" : _selectedTrackName,
        @"icon" : @"ic_custom_trip",
        @"color" : UIColorFromRGB(color_primary_purple),
        @"hederTitle" : @" ",
        @"footerTitle" : OALocalizedString(@"simulate_location_track_select_descr"),
    }];
    [settingsSection addObject:@{
        @"type" : [OAIconTitleValueCell getCellIdentifier],
        @"key" : kMovementSpeedKey,
        @"title" : OALocalizedString(@"simulate_location_movement_speed"),
        @"value" : speedModeName,
        @"icon" : @"ic_action_max_speed",
        @"color" : UIColorFromRGB(color_primary_purple),
    }];
    [tableData addObject:settingsSection];
    
    NSMutableArray *actionsSection = [NSMutableArray array];
    [actionsSection addObject:@{
        @"type" : [OATitleRightIconCell getCellIdentifier],
        @"key" : kStartStopButtonKey,
        @"title" : OALocalizedString(@"shared_string_start"),
        @"img" : @"ic_custom_play", // ic_custom_stop
        @"color" : UIColorFromRGB(color_primary_purple),
        @"hederTitle" : @" ",
        @"footerTitle" : OALocalizedString(@"simulate_location_unselected_track_footer"),
    }];
    [tableData addObject:actionsSection];
    
    _data = [NSArray arrayWithArray:tableData];
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

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _data[section].count;
}

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSDictionary *item = [self getItem:indexPath];
    
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:[OAIconTitleValueCell getCellIdentifier]])
    {
        OAIconTitleValueCell* cell = [tableView dequeueReusableCellWithIdentifier:[OAIconTitleValueCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTitleValueCell getCellIdentifier] owner:self options:nil];
            cell = (OAIconTitleValueCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
            cell.rightIconView.image = [UIImage templateImageNamed:@"ic_custom_arrow_right"].imageFlippedForRightToLeftLayoutDirection;
            cell.rightIconView.tintColor = UIColorFromRGB(color_tint_gray);
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.descriptionView.text = item[@"value"];
            cell.leftIconView.tintColor = item[@"color"];
            cell.leftIconView.image = [UIImage templateImageNamed:item[@"icon"]];
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OATitleRightIconCell getCellIdentifier]])
    {
        OATitleRightIconCell* cell = [tableView dequeueReusableCellWithIdentifier:[OATitleRightIconCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATitleRightIconCell getCellIdentifier] owner:self options:nil];
            cell = (OATitleRightIconCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0.0, 16.0, 0.0, 0.0);
            cell.titleView.font = [UIFont systemFontOfSize:17. weight:UIFontWeightSemibold];
        }
        cell.titleView.text = item[@"title"];
        cell.titleView.textColor = item[@"color"];
        cell.iconView.tintColor = item[@"color"];
        [cell.iconView setImage:[UIImage templateImageNamed:item[@"img"]]];
        return cell;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:[OATitleRightIconCell getCellIdentifier]])
        return kDefaultHeight;
    return UITableViewAutomaticDimension;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return kDefaultHeaderHeight;
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

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    NSString *itemKey = item[@"key"];
    
    if ([itemKey isEqualToString:kTrackSelectKey])
    {
        OAOpenAddTrackViewController *vc = [[OAOpenAddTrackViewController alloc] initWithScreenType:EOASelectTrack showCurrent:YES];
        vc.delegate = self;
        [self presentViewController:vc animated:YES completion:nil];
    }
    else if ([itemKey isEqualToString:kMovementSpeedKey])
    {
        OAOsmandDevelopmentSimulateSpeedSelectorViewController *vc = [[OAOsmandDevelopmentSimulateSpeedSelectorViewController alloc] init];
        vc.delegate = self;
        [self presentViewController:vc animated:YES completion:nil];
    }
    else if ([itemKey isEqualToString:kStartStopButtonKey])
    {
        //TODO: start/stop simulation
    }

    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark - OAOpenAddTrackDelegate

- (void)closeBottomSheet
{
}

- (void) onFileSelected:(NSString *)gpxFilePath
{
    [self generateData];
    [self.tableView reloadData];
}


#pragma mark - OAOsmandDevelopmentSimulateSpeedSelectorDelegate

- (void) onSpeedSelectorInformationUpdated:(NSInteger)selectedSpeedModeIndex;
{
    [self generateData];
    [self.tableView reloadData];
}

@end
