//
//  OARecalculateRouteViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 24.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OARecalculateRouteViewController.h"
#import "OASwitchTableViewCell.h"
#import "OAValueTableViewCell.h"
#import "OACustomPickerTableViewCell.h"
#import "OAApplicationMode.h"
#import "OAAppSettings.h"
#import "OsmAndApp.h"
#import "OARoutingHelper.h"
#import "OAOsmAndFormatter.h"

#import "Localization.h"
#import "OAColors.h"

#define kSidePadding 16
#define kDistanceSection 1
#define kDisableMode -1

@interface OARecalculateRouteViewController () <OACustomPickerTableViewCellDelegate>

@end

@implementation OARecalculateRouteViewController
{
    NSArray<NSArray *> *_data;
    NSIndexPath *_pickerIndexPath;
    NSArray<NSNumber *> *_possibleDistanceValues;
    NSArray<NSString *> *_valueSummaries;
    
    NSInteger _selectedValue;
    NSString *_defaultValue;
    
    OAAppSettings *_settings;
    OsmAndAppInstance _app;
}

#pragma mark - Initialization

- (void)commonInit
{
    _settings = [OAAppSettings sharedManager];
    _app = [OsmAndApp instance];
}

- (void)postInit
{
    if ([_settings.metricSystem get:self.appMode] == KILOMETERS_AND_METERS)
        _possibleDistanceValues = @[@(10.), @(20.0), @(30.0), @(50.0), @(100.0), @(200.0), @(500.0), @(1000.0), @(1500.0)];
    else
        _possibleDistanceValues = @[@(9.1), @(18.3), @(30.5), @(45.7), @(91.5), @(183.0), @(482.0), @(965.0), @(1609.0)];
    
    NSInteger selectedInd = [_possibleDistanceValues indexOfObject:@([_settings.routeRecalculationDistance get:self.appMode])];
    _defaultValue = selectedInd == NSNotFound ? [self getDefaultValue] : nil;
    _selectedValue = selectedInd != NSNotFound ? selectedInd : 0;
    
    NSMutableArray<NSString *> *arr = [NSMutableArray new];
    for (NSNumber *n in _possibleDistanceValues)
    {
        [arr addObject:[OAOsmAndFormatter getFormattedDistance:n.doubleValue withParams:[OAOsmAndFormatterParams noTrailingZerosParams]]];
    }
    _valueSummaries = arr;
}

- (NSString *) getDefaultValue
{
    double defValue = [OARoutingHelper getDefaultAllowedDeviation:self.appMode posTolerance:[OARoutingHelper getPosTolerance:0]];
    defValue = defValue == -1 ? _possibleDistanceValues.firstObject.doubleValue : defValue;
    return [OAOsmAndFormatter getFormattedDistance:defValue withParams:[OAOsmAndFormatterParams noTrailingZerosParams]];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"recalculate_route");
}

- (NSString *)getLeftNavbarButtonTitle
{
    return OALocalizedString(@"shared_string_cancel");
}

#pragma mark - Table data

- (void)generateData
{
    NSMutableArray *tableData = [NSMutableArray array];
    NSMutableArray *statusArr = [NSMutableArray array];
    NSMutableArray *distanceArr = [NSMutableArray array];
    BOOL disabled = [_settings.routeRecalculationDistance get:self.appMode] == kDisableMode;
    [statusArr addObject:@{
        @"type" : [OASwitchTableViewCell getCellIdentifier],
        @"title" : disabled ? OALocalizedString(@"rendering_value_disabled_name") : OALocalizedString(@"shared_string_enabled"),
        @"isOn" : @(!disabled),
    }];
    [tableData addObject:statusArr];
    
    if (!disabled)
    {
        [distanceArr addObject:@{
            @"type" : [OAValueTableViewCell getCellIdentifier],
            @"title" : OALocalizedString(@"shared_string_distance"),
        }];
        [distanceArr addObject:@{
            @"type" : [OACustomPickerTableViewCell getCellIdentifier],
        }];
        
        [tableData addObject:distanceArr];
    }
    _data = [NSArray arrayWithArray:tableData];
}

- (NSString *)getTitleForFooter:(NSInteger)section
{
    return section == 0 ? OALocalizedString(@"recalculate_route_distance_promo") : OALocalizedString(@"select_distance_route_will_recalc");
}

- (NSInteger)rowsCount:(NSInteger)section
{
    if (section == kDistanceSection)
    {
        if ([self pickerIsShown])
            return 2;
        return 1;
    }
    return 1;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
    {
        OASwitchTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];

            cell.switchView.on = [item[@"isOn"] boolValue];
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(applyParameter:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OAValueTableViewCell getCellIdentifier]])
    {
        OAValueTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAValueTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            cell.valueLabel.text = _defaultValue ? _defaultValue : _valueSummaries[_selectedValue];
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OACustomPickerTableViewCell getCellIdentifier]])
    {
        OACustomPickerTableViewCell* cell;
        cell = (OACustomPickerTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:[OACustomPickerTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OACustomPickerTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OACustomPickerTableViewCell *)[nib objectAtIndex:0];
        }
        cell.dataArray = _valueSummaries;
        [cell.picker selectRow:_selectedValue inComponent:0 animated:NO];
        cell.picker.tag = indexPath.row;
        cell.delegate = self;
        return cell;
    }
    return nil;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (CGFloat)getCustomHeightForHeader:(NSInteger)section
{
    return 17.;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    if ([item[@"type"] isEqualToString:[OAValueTableViewCell getCellIdentifier]])
    {
        [self.tableView beginUpdates];

        if ([self pickerIsShown] && (_pickerIndexPath.row - 1 == indexPath.row))
            [self hideExistingPicker];
        else
        {
            NSIndexPath *newPickerIndexPath = [self calculateIndexPathForNewPicker:indexPath];
            if ([self pickerIsShown])
                [self hideExistingPicker];

            [self showNewPickerAtIndex:newPickerIndexPath];
            _pickerIndexPath = [NSIndexPath indexPathForRow:newPickerIndexPath.row + 1 inSection:indexPath.section];
        }

        [self.tableView endUpdates];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}

#pragma mark - Selectors

- (void) applyParameter:(id)sender
{
    if ([sender isKindOfClass:UISwitch.class])
    {
        UISwitch *control = (UISwitch *)sender;
        [_settings.routeRecalculationDistance set:control.isOn ? _possibleDistanceValues[_selectedValue].doubleValue : kDisableMode mode:self.appMode];
        [_settings.disableOffrouteRecalc set:!control.isOn mode:self.appMode];
        [self hidePicker];
        [self.tableView beginUpdates];
        [self generateData];
        if (!control.isOn)
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
        else
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
        
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
        
        if (self.delegate)
            [self.delegate onSettingsChanged];
    }
}

#pragma mark - Picker

- (BOOL) pickerIsShown
{
    return _pickerIndexPath != nil;
}

- (void) hideExistingPicker
{
    
    [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_pickerIndexPath.row inSection:_pickerIndexPath.section]] withRowAnimation:UITableViewRowAnimationFade];
    _pickerIndexPath = nil;
}

- (void) hidePicker
{
    [self.tableView beginUpdates];
    if ([self pickerIsShown])
        [self hideExistingPicker];
    [self.tableView endUpdates];
}

- (NSIndexPath *) calculateIndexPathForNewPicker:(NSIndexPath *)selectedIndexPath
{
   return [NSIndexPath indexPathForRow:selectedIndexPath.row inSection:kDistanceSection];
}

- (void) showNewPickerAtIndex:(NSIndexPath *)indexPath
{
    NSArray *indexPaths = @[[NSIndexPath indexPathForRow:indexPath.row + 1 inSection:kDistanceSection]];
    [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
}

- (void) customPickerValueChanged:(NSString *)value tag:(NSInteger)pickerTag
{
    _selectedValue = [_valueSummaries indexOfObject:value];
    _selectedValue = _selectedValue == NSNotFound ? 0 : _selectedValue;
    _defaultValue = nil;
    [_settings.routeRecalculationDistance set:_possibleDistanceValues[_selectedValue].doubleValue mode:self.appMode];
    [_settings.disableOffrouteRecalc set:[_settings.routeRecalculationDistance get:self.appMode] != kDisableMode];
    [self generateData];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_pickerIndexPath.row - 1 inSection:_pickerIndexPath.section]] withRowAnimation:UITableViewRowAnimationAutomatic];
    
    if (self.delegate)
        [self.delegate onSettingsChanged];
}

@end
