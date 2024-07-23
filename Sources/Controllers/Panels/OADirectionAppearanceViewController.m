//
//  OADirectionAppearanceViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 14.04.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OADirectionAppearanceViewController.h"
#import "OARootViewController.h"
#import "OAAppSettings.h"
#import "OASwitchTableViewCell.h"
#import "OAMapWidgetRegInfo.h"
#import "OAMapWidgetRegistry.h"
#import "OAMapPanelViewController.h"
#import "OATableDataModel.h"
#import "OATableSectionData.h"
#import "OATableRowData.h"
#import "Localization.h"
#import "OAColors.h"

#define kArrowsOnMap @"arrows"
#define kLinesOnMap @"lines"

@implementation OADirectionAppearanceViewController
{
    OAAppSettings *_settings;
}

#pragma mark - Initialization

- (void)commonInit
{
    _settings = [OAAppSettings sharedManager];
}

#pragma mark - UIViewColontroller

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    [mapPanel recreateControls];
    [mapPanel refreshMap:YES];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"shared_string_appearance");
}

- (EOABaseNavbarColorScheme)getNavbarColorScheme
{
    return EOABaseNavbarColorSchemeOrange;
}

#pragma mark - Table data

- (void)generateData
{
    OATableSectionData *section = [self.tableData createNewSection];
    section.headerText = OALocalizedString(@"appearance_on_the_map");
    section.footerText = OALocalizedString(@"arrows_direction_to_markers");
    [section addRowFromDictionary:@{
        kCellKeyKey : kArrowsOnMap,
        kCellTypeKey : [OASwitchTableViewCell getCellIdentifier],
        kCellTitleKey : OALocalizedString(@"arrows_on_map"),
        @"isOn" : @([_settings.arrowsOnMap get])
    }];
    [section addRowFromDictionary:@{
        kCellKeyKey : kLinesOnMap,
        kCellTypeKey : [OASwitchTableViewCell getCellIdentifier],
        kCellTitleKey : OALocalizedString(@"direction_lines"),
        @"isOn" : @([_settings.directionLines get])
    }];
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    OATableRowData *item = [self.tableData itemForIndexPath:indexPath];
    if ([item.cellType isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
    {
        OASwitchTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *) nib[0];
            [cell descriptionVisibility:NO];
            [cell leftIconVisibility:NO];
        }
        if (cell)
        {
            cell.titleLabel.text = item.title;
            cell.switchView.on = [item boolForKey:@"isOn"];
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(onSwitchPressed:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    return nil;
}

#pragma mark - Selectors

- (void)onSwitchPressed:(UISwitch *)sender
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sender.tag & 0x3FF inSection:sender.tag >> 10];
    OATableRowData *item = [self.tableData itemForIndexPath:indexPath];
    if ([item.key isEqualToString:kArrowsOnMap])
    {
        [_settings.arrowsOnMap set:sender.isOn];
        [item setObj:@(sender.on) forKey:@"isOn"];
    }
    else if ([item.key isEqualToString:kLinesOnMap])
    {
        [_settings.directionLines set:sender.isOn];
        [item setObj:@(sender.on) forKey:@"isOn"];
    }
}

@end
