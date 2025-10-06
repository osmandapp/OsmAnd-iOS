//
//  OAMapBehaviorViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 29.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAMapBehaviorViewController.h"
#import "OAValueTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OAAutoCenterMapViewController.h"
#import "OAAutoZoomMapViewController.h"
#import "OAAppSettings.h"
#import "OAApplicationMode.h"
#import "OATableDataModel.h"
#import "OATableSectionData.h"
#import "OATableRowData.h"
#import "OsmAnd_Maps-Swift.h"
#import "Localization.h"
#import "OAColors.h"

@implementation OAMapBehaviorViewController
{
    OAAppSettings *_settings;
    OATableDataModel *_data;
}

#pragma mark - Initialization

- (void)commonInit
{
    _settings = [OAAppSettings sharedManager];
    _data = [OATableDataModel model];
}

- (void)registerCells
{
    [self addCell:OAValueTableViewCell.reuseIdentifier];
    [self addCell:OASwitchTableViewCell.reuseIdentifier];
}

#pragma mark - UIViewController

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self generateData];
    [self.tableView reloadData];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"map_during_navigation");
}

#pragma mark - Table data

- (void)generateData
{
    [_data clearAllData];
    NSString *autoCenterValue = nil;
    NSUInteger autoCenter = [_settings.autoFollowRoute get:self.appMode];
    if (autoCenter == 0)
        autoCenterValue = OALocalizedString(@"shared_string_never");
    else
        autoCenterValue = [NSString stringWithFormat:@"%lu %@", (unsigned long)autoCenter, OALocalizedString(@"int_seconds")];
    
    NSString *autoZoomValue = nil;
    if (![_settings.autoZoomMap get:self.appMode])
    {
        autoZoomValue = OALocalizedString(@"auto_zoom_none");
    }
    else
    {
        EOAAutoZoomMap autoZoomMap = [_settings.autoZoomMapScale get:self.appMode];
        autoZoomValue = [OAAutoZoomMap getName:autoZoomMap];
    }

    OATableSectionData *autoCenterSection = [_data createNewSection];
    autoCenterSection.footerText = OALocalizedString(@"choose_auto_center_map_view_descr");
    OATableRowData *autoCenterRow = [autoCenterSection createNewRow];
    autoCenterRow.key = @"autoCenter";
    autoCenterRow.cellType = OAValueTableViewCell.reuseIdentifier;
    autoCenterRow.title = OALocalizedString(@"choose_auto_follow_route");
    autoCenterRow.descr = autoCenterValue;
    
    OATableSectionData *autoZoomSection = [_data createNewSection];
    autoZoomSection.footerText = OALocalizedString(@"auto_zoom_map_descr");
    OATableRowData *autoZoomRow = [autoZoomSection createNewRow];
    autoZoomRow.key = @"autoZoom";
    autoZoomRow.cellType = OAValueTableViewCell.reuseIdentifier;
    autoZoomRow.title = OALocalizedString(@"auto_zoom_map");
    autoZoomRow.descr = autoZoomValue;
    OATableRowData *autoZoom3dAngleRow = [autoZoomSection createNewRow];
    autoZoom3dAngleRow.key = @"autoZoom3dAngle";
    autoZoom3dAngleRow.cellType = OAValueTableViewCell.reuseIdentifier;
    autoZoom3dAngleRow.title = OALocalizedString(@"auto_zoom_3d_angle");
    autoZoom3dAngleRow.descr = [NSString stringWithFormat:@"%ld %@", (long)[_settings.autoZoom3DAngle get:self.appMode], OALocalizedString(@"shared_string_degrees")];
    
    OATableSectionData *previewNextTurnSection = [_data createNewSection];
    previewNextTurnSection.footerText = OALocalizedString(@"preview_next_turn_descr");
    OATableRowData *previewNextTurnRow = [previewNextTurnSection createNewRow];
    previewNextTurnRow.key = @"previewNextTurn";
    previewNextTurnRow.cellType = OASwitchTableViewCell.reuseIdentifier;
    previewNextTurnRow.title = OALocalizedString(@"preview_next_turn");
    [previewNextTurnRow setObj:_settings.previewNextTurn forKey:@"value"];
    
    OATableSectionData *snapToRoadSection = [_data createNewSection];
    snapToRoadSection.footerText = OALocalizedString(@"snap_to_road_descr");
    OATableRowData *snapToRoadRow = [snapToRoadSection createNewRow];
    snapToRoadRow.key = @"snapToRoad";
    snapToRoadRow.cellType = OASwitchTableViewCell.reuseIdentifier;
    snapToRoadRow.title = OALocalizedString(@"snap_to_road");
    [snapToRoadRow setObj:_settings.snapToRoad forKey:@"value"];
}

- (NSString *)getTitleForFooter:(NSInteger)section
{
    return [_data sectionDataForIndex:section].footerText;
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return [_data rowCount:section];
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    NSString *cellType = item.cellType;
    if ([cellType isEqualToString:OAValueTableViewCell.reuseIdentifier])
    {
        OAValueTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:OAValueTableViewCell.reuseIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        [cell leftIconVisibility:NO];
        [cell descriptionVisibility:NO];
        cell.titleLabel.text = item.title;
        cell.valueLabel.text = item.descr;
        return cell;
    }
    else if ([cellType isEqualToString:OASwitchTableViewCell.reuseIdentifier])
    {
        OASwitchTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:OASwitchTableViewCell.reuseIdentifier];
        [cell descriptionVisibility:NO];
        [cell leftIconVisibility:NO];
        cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
        cell.titleLabel.text = item.title;
        id val = [item objForKey:@"value"];
        [cell.switchView removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
        if ([val isKindOfClass:[OACommonBoolean class]])
        {
            OACommonBoolean *value = val;
            cell.switchView.on = [value get:self.appMode];
        }
        else
        {
            cell.switchView.on = [val boolValue];
        }
        cell.switchView.tag = indexPath.section << 10 | indexPath.row;
        [cell.switchView addTarget:self action:@selector(applyParameter:) forControlEvents:UIControlEventValueChanged];
        return cell;
    }
    return nil;
}

- (NSInteger)sectionsCount
{
    return [_data sectionCount];
}

- (CGFloat)getCustomHeightForHeader:(NSInteger)section
{
    return section == 0 ? 18.0 : 9.0;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    NSString *itemKey = item.key;
    OABaseSettingsViewController* settingsViewController = nil;
    if ([itemKey isEqualToString:@"autoCenter"])
        settingsViewController = [[OAAutoCenterMapViewController alloc] initWithAppMode:self.appMode];
    else if ([itemKey isEqualToString:@"autoZoom"])
        settingsViewController = [[OAAutoZoomMapViewController alloc] initWithAppMode:self.appMode];
    else if ([itemKey isEqualToString:@"autoZoom3dAngle"])
        settingsViewController = [[AutoZoom3DAngleViewController alloc] initWithAppMode:self.appMode];

    settingsViewController.delegate = self;
    [self showViewController:settingsViewController];
}

#pragma mark - Selectors

- (void) applyParameter:(id)sender
{
    UISwitch *sw = (UISwitch *) sender;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sw.tag & 0x3FF inSection:sw.tag >> 10];
    OATableRowData *item = [_data itemForIndexPath:indexPath];

    BOOL isChecked = ((UISwitch *) sender).on;
    id v = [item objForKey:@"value"];
    if ([v isKindOfClass:[OACommonBoolean class]])
    {
        OACommonBoolean *value = v;
        [value set:isChecked mode:self.appMode];
    }
    if (self.delegate)
        [self.delegate onSettingsChanged];
}

#pragma mark - OASettingsDataDelegate

- (void)onSettingsChanged
{
    [self generateData];
    [self.tableView reloadData];
}

@end
