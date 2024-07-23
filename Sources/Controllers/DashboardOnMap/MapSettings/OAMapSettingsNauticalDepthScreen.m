//
//  OAMapSettingsNauticalDepthScreen.mm
//  OsmAnd
//
//  Created by Skalii on 10.11.2022.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OAMapSettingsNauticalDepthScreen.h"
#import "OANauticalDepthParametersViewController.h"
#import "OAMapSettingsViewController.h"
#import "OAMapViewController.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAValueTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OAMapStyleSettings.h"
#import "OATableDataModel.h"
#import "OATableSectionData.h"
#import "OATableRowData.h"
#import "OASizes.h"
#import "OsmAnd_Maps-Swift.h"
#import "Localization.h"
#import "GeneratedAssetSymbols.h"

@interface OAMapSettingsNauticalDepthScreen () <OANauticalDepthParametersDelegate>

@end

@implementation OAMapSettingsNauticalDepthScreen
{
    OsmAndAppInstance _app;
    OAMapViewController *_mapViewController;

    OAMapStyleSettings *_styleSettings;
    OAMapStyleParameter *_depthContours;
    OAMapStyleParameter *_depthContourWidth;
    OAMapStyleParameter *_depthContourColorScheme;

    OATableDataModel *_data;
}

@synthesize settingsScreen, tableData, vwController, tblView, title, isOnlineMapSource;

- (id)initWithTable:(UITableView *)tableView viewController:(OAMapSettingsViewController *)viewController
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _styleSettings = [OAMapStyleSettings sharedInstance];
        tblView = tableView;
        settingsScreen = EMapSettingsScreenNauticalDepth;
        vwController = viewController;
        _mapViewController = [OARootViewController instance].mapPanel.mapViewController;
        _depthContours = [_styleSettings getParameter:NAUTICAL_DEPTH_CONTOURS];
        _depthContourWidth = [_styleSettings getParameter:NAUTICAL_DEPTH_CONTOUR_WIDTH_ATTR];
        _depthContourColorScheme = [_styleSettings getParameter:NAUTICAL_DEPTH_CONTOUR_COLOR_SCHEME_ATTR];

        [self initData];
    }
    return self;
}

- (void)initData
{
    _data = [[OATableDataModel alloc] init];
    OATableSectionData *switchSection = [OATableSectionData sectionData];
    [switchSection addRowFromDictionary:@{
        kCellTypeKey: [OASwitchTableViewCell getCellIdentifier],
        kCellTitle: OALocalizedString(@"nautical_depth"),
        kCellIconNameKey: @"ic_custom_nautical_depth_colored",
        kCellIconTintColor: [UIColor colorNamed:ACColorNameIconColorActive],
        @"iconTintDisabled" : [UIColor colorNamed:ACColorNameIconColorDisabled]
    }];
    [_data addSection:switchSection];

    if ([_depthContours.value isEqualToString:@"true"])
    {
        OATableSectionData *settingsSection = [OATableSectionData sectionData];
        settingsSection.headerText = OALocalizedString(@"depth_contour_lines");
        [settingsSection addRowFromDictionary:@{
            kCellTypeKey: [OAValueTableViewCell getCellIdentifier],
            @"parameter": _depthContourWidth
        }];
        [settingsSection addRowFromDictionary:@{
            kCellTypeKey: [OAValueTableViewCell getCellIdentifier],
            @"parameter": _depthContourColorScheme
        }];
        [_data addSection:settingsSection];
    }
}

- (void)setupView
{
    title = OALocalizedString(@"nautical_depth");
    tblView.separatorInset = UIEdgeInsetsMake(0., 20., 0., 0.);
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [_data sectionCount];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_data rowCount:section];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    if ([item.cellType isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
    {
        OASwitchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *) nib[0];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.titleLabel.text = item.title;

            BOOL isOn = [_depthContours.value isEqualToString:@"true"];
            cell.leftIconView.image = [UIImage templateImageNamed:item.iconName];
            cell.leftIconView.tintColor = isOn ? item.iconTintColor : [item objForKey:@"iconTintDisabled"];

            cell.switchView.on = isOn;
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView removeTarget:nil action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(onSwitchPressed:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    else if ([item.cellType isEqualToString:[OAValueTableViewCell getCellIdentifier]])
    {
        OAMapStyleParameter *parameter = [item objForKey:@"parameter"];
        OAValueTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAValueTableViewCell *) nib[0];
            [cell descriptionVisibility:NO];
            [cell leftIconVisibility:NO];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        if (cell)
        {
            cell.titleLabel.text = parameter.title;
            cell.valueLabel.text = [parameter getValueTitle];
        }
        return cell;
    }

    return nil;
}

#pragma mark - UITableViewDelegate

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [_data sectionDataForIndex:section].headerText;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSString *header = [_data sectionDataForIndex:section].headerText;
    if (header)
    {
        CGFloat headerHeight = [OAUtilities calculateTextBounds:header
                                                          width:tableView.frame.size.width - (kPaddingOnSideOfContent + [OAUtilities getLeftMargin]) * 2
                                                           font:[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote]].height + kPaddingOnSideOfHeaderWithText;
        return headerHeight;
    }

    return 0.;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    OATableRowData *item = [_data itemForIndexPath:indexPath];
    OAMapStyleParameter *parameter = [item objForKey:@"parameter"];
    if (parameter)
    {
        OANauticalDepthParametersViewController *depthParametersViewController = [[OANauticalDepthParametersViewController alloc] initWithParameter:parameter];
        depthParametersViewController.depthDelegate = self;
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:depthParametersViewController];
        [vwController presentViewController:navigationController animated:YES completion:nil];
    }
}

#pragma mark - Selectors

- (void)onSwitchPressed:(id)sender
{
    UISwitch *switchView = (UISwitch *) sender;
    if (switchView)
    {
        _depthContours.value = switchView.on ? @"true" : @"false";
        [_styleSettings save:_depthContours];
        [self initData];
        [UIView transitionWithView:tblView
                          duration:.35
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^(void) {
                            [tblView reloadData];
                        }
                        completion:nil];
    }
}

#pragma mark - OANauticalDepthParametersDelegate

- (void)onValueSelected:(OAMapStyleParameter *)parameter
{
    if ([_depthContours.value isEqualToString:@"true"])
    {
        [tblView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:parameter == _depthContourWidth ? 0 : 1 inSection:1]]
                       withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

@end
