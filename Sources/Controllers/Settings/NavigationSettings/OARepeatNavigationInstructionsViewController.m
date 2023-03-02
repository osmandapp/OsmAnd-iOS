//
//  OARepeatNavigationInstructionsViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 25.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OARepeatNavigationInstructionsViewController.h"
#import "OASwitchTableViewCell.h"
#import "OATimeTableViewCell.h"
#import "OACustomPickerTableViewCell.h"
#import "OAAppSettings.h"

#import "Localization.h"
#import "OAColors.h"

#define kSidePadding 16
#define kDistanceSection 1

@interface OARepeatNavigationInstructionsViewController () <OACustomPickerTableViewCellDelegate>

@end

@implementation OARepeatNavigationInstructionsViewController
{
    NSArray<NSArray *> *_data;
    NSIndexPath *_pickerIndexPath;
    NSArray<NSNumber *> *_keepInformingValues;
    NSArray<NSString *> *_keepInformingEntries;
    NSInteger _selectedValue;
    
    OAAppSettings *_settings;
}

#pragma mark - Initialization

- (void)commonInit
{
    _settings = [OAAppSettings sharedManager];

    _keepInformingValues = @[@1, @2, @3, @5, @7, @10, @15, @20, @25, @30];
    NSMutableArray *array = [NSMutableArray array];
    for (NSNumber *val in _keepInformingValues)
    {
        [array addObject:[NSString stringWithFormat:@"%d %@", val.intValue, OALocalizedString(@"int_min")]];
    }
    _keepInformingEntries = [NSArray arrayWithArray:array];
}

- (void)postInit
{
    _selectedValue = [_keepInformingValues indexOfObject:@([_settings.keepInforming get:self.appMode])];
    _selectedValue = _selectedValue == NSNotFound ? 0 : _selectedValue;
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"keep_informing");
}

#pragma mark - Table data

- (void)generateData
{
    NSMutableArray *tableData = [NSMutableArray array];
    NSMutableArray *statusArr = [NSMutableArray array];
    NSMutableArray *distanceArr = [NSMutableArray array];
    BOOL isManualAnnunce = [_settings.keepInforming get:self.appMode] == 0;
    [statusArr addObject:@{
        @"type" : [OASwitchTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"only_manually"),
        @"isOn" : @(isManualAnnunce),
    }];
    [tableData addObject:statusArr];
    if (!isManualAnnunce)
    {
        [distanceArr addObject:@{
            @"type" : [OATimeTableViewCell getCellIdentifier],
            @"title" : OALocalizedString(@"repeat_after"),
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
    return section == 0 ? OALocalizedString(@"instructions_repeat") : @"";
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
    else if ([cellType isEqualToString:[OATimeTableViewCell getCellIdentifier]])
    {
        OATimeTableViewCell* cell;
        cell = (OATimeTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:[OATimeTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATimeTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OATimeTableViewCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        cell.lbTitle.text = item[@"title"];
        cell.lbTime.text = _keepInformingEntries[_selectedValue];
        cell.lbTime.textColor = UIColorFromRGB(color_text_footer);

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
        cell.dataArray = _keepInformingEntries;
        NSInteger valueRow = _selectedValue;
        [cell.picker selectRow:valueRow inComponent:0 animated:NO];
        cell.picker.tag = indexPath.row;
        cell.delegate = self;
        return cell;
    }
    return nil;
}

- (NSInteger)sectionsCount
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
    if ([item[@"type"] isEqualToString:[OATimeTableViewCell getCellIdentifier]])
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

- (void)applyParameter:(id)sender
{
    if ([sender isKindOfClass:UISwitch.class])
    {
        UISwitch *control = (UISwitch *)sender;
        [_settings.keepInforming set:(control.isOn ? 0 : _keepInformingValues[_selectedValue].intValue) mode:self.appMode];
        [self hidePicker];
        [self.tableView beginUpdates];
        [self generateData];
        if (control.isOn)
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
        else
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
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

- (void) hideExistingPicker {
    
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

- (NSIndexPath *) calculateIndexPathForNewPicker:(NSIndexPath *)selectedIndexPath {
   return [NSIndexPath indexPathForRow:selectedIndexPath.row inSection:kDistanceSection];
}

- (void) showNewPickerAtIndex:(NSIndexPath *)indexPath {
    NSArray *indexPaths = @[[NSIndexPath indexPathForRow:indexPath.row + 1 inSection:kDistanceSection]];
    [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
}

- (void)customPickerValueChanged:(NSString *)value tag:(NSInteger)pickerTag {
    _selectedValue = [_keepInformingEntries indexOfObject:value];
    _selectedValue = _selectedValue == NSNotFound ? 0 : _selectedValue;
    [_settings.keepInforming set:_keepInformingValues[_selectedValue].intValue mode:self.appMode];
    [self generateData];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_pickerIndexPath.row - 1 inSection:_pickerIndexPath.section]] withRowAnimation:UITableViewRowAnimationFade];
    if (self.delegate)
        [self.delegate onSettingsChanged];
}

@end
