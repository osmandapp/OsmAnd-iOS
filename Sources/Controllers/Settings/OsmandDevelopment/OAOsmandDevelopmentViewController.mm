//
//  OAOsmandDevelopmentViewController.m
//  OsmAnd Maps
//
//  Created by nnngrach on 01.06.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAOsmandDevelopmentViewController.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "Localization.h"
#import "OAColors.h"
#import "OALocationSimulation.h"
#import "OAIconTitleValueCell.h"
#import "OASwitchTableViewCell.h"
#import "OATableRowData.h"
#import "OATableDataModel.h"
#import "OATableSectionData.h"
#import "OAOsmandDevelopmentSimulateLocationViewController.h"


@interface OAOsmandDevelopmentViewController () <OAOsmandDevelopmentSimulateLocationDelegate>

@end

@implementation OAOsmandDevelopmentViewController
{
    OATableDataModel* _data;
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
    self.tableView.tableHeaderView = [OAUtilities setupTableHeaderViewWithText:_headerDescription font:kHeaderDescriptionFont textColor:UIColorFromRGB(color_text_footer) isBigTitle:NO];
    
    self.backButton.imageView.image = [self.backButton.imageView.image imageFlippedForRightToLeftLayoutDirection];
}

- (void) viewWillAppear:(BOOL)animated
{
    [self applySafeAreaMargins];
    [self reloadData];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        self.tableView.tableHeaderView = [OAUtilities setupTableHeaderViewWithText:_headerDescription font:kHeaderDescriptionFont textColor:UIColorFromRGB(color_text_footer) isBigTitle:NO];
    } completion:nil];
}

-(UIView *) getTopView
{
    return _navBarView;
}


#pragma mark - Setup data

- (void) applyLocalization
{
    _titleView.text = OALocalizedString(@"debugging_and_development");
    _headerDescription = OALocalizedString(@"osm_editing_settings_descr");
}

- (void) generateData
{
    BOOL isRouteAnimating = [[OsmAndApp instance].locationServices.locationSimulation isRouteAnimating];
    _data = [OATableDataModel model];
    __weak OAOsmandDevelopmentViewController *weakSelf = self;
    OATableSectionData *simulationSection = [OATableSectionData sectionData];
    [simulationSection addRowFromDictionary:@{
        kCellTypeKey : [OAIconTitleValueCell getCellIdentifier],
        kCellKeyKey : kSimulateLocationKey,
        kCellTitleKey : OALocalizedString(@"simulate_your_location"),
        kCellDescrKey : isRouteAnimating ? OALocalizedString(@"simulate_in_progress") : @"",
        @"actionBlock" : (^void(){ [weakSelf openSimulateLocationSettings]; })
    }];
    simulationSection.headerText = OALocalizedString(@"osmand_depelopment_simulate_location_section");
    [_data addSection:simulationSection];
    
    OATableSectionData *heightMapSection = [OATableSectionData sectionData];
    [heightMapSection addRowFromDictionary:@{
        kCellTypeKey : OASwitchTableViewCell.getCellIdentifier,
        kCellKeyKey : @"display_heightmap",
        kCellTitleKey : OALocalizedString(@"use_heightmap_setting")
    }];
    [_data addSection:heightMapSection];
}

- (void) reloadData
{
    [self generateData];
    [self.tableView reloadData];
}

- (void) applyParameter:(UISwitch *)sender
{
    [OAAppSettings.sharedManager.showHeightmaps set:sender.isOn];
    [OsmAndApp.instance.mapSettingsChangeObservable notifyEvent];
}


#pragma mark - Actions

- (void) openSimulateLocationSettings
{
    OAOsmandDevelopmentSimulateLocationViewController *vc = [[OAOsmandDevelopmentSimulateLocationViewController alloc] init];
    vc.simulateLocationDelegate = self;
    [self.navigationController pushViewController:vc animated:YES];
}


#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.sectionCount;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_data rowCount:section];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    NSString *type = item.cellType;
    
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
            cell.textView.text = item.title;
            cell.descriptionView.text = item.descr;
        }
        return cell;
    }
    else if ([type isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
    {
        OASwitchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *) nib[0];
            cell.switchView.tintColor = UIColorFromRGB(color_bottom_sheet_secondary);
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
        }
        
        if (cell)
        {
            cell.titleLabel.text = item.title;

            cell.switchView.on = [OAAppSettings.sharedManager.showHeightmaps get];
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView removeTarget:nil action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(applyParameter:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    return nil;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [_data sectionDataForIndex:section].headerText;
}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return [_data sectionDataForIndex:section].footerText;
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
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    void (^actionBlock)() = [item objForKey:@"actionBlock"];
    if (actionBlock)
        actionBlock();
}


#pragma mark - OAOsmandDevelopmentSimulateLocationDelegate

- (void) onSimulateLocationInformationUpdated
{
    [self reloadData];
}

@end
