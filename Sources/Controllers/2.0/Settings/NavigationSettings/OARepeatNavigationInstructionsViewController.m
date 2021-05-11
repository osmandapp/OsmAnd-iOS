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
#define kCellTypeDistance @"time_cell"
#define kCellTypePicker @"pickerCell"

@interface OARepeatNavigationInstructionsViewController () <UITableViewDelegate, UITableViewDataSource, OACustomPickerTableViewCellDelegate>

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

- (instancetype) initWithAppMode:(OAApplicationMode *)appMode
{
    self = [super initWithAppMode:appMode];
    if (self)
    {
        _settings = OAAppSettings.sharedManager;
        [self generateData];
    }
    return self;
}

- (void) generateData
{
    _keepInformingValues = @[@1, @2, @3, @5, @7, @10, @15, @20, @25, @30];
    NSMutableArray *array = [NSMutableArray array];
    for (NSNumber *val in _keepInformingValues)
    {
        [array addObject:[NSString stringWithFormat:@"%d %@", val.intValue, OALocalizedString(@"units_min")]];
    }
    _keepInformingEntries = [NSArray arrayWithArray:array];
    
    _selectedValue = [_keepInformingValues indexOfObject:@([_settings.keepInforming get:self.appMode])];
    _selectedValue = _selectedValue == NSNotFound ? 0 : _selectedValue;
}

-(void) applyLocalization
{
    self.titleLabel.text = OALocalizedString(@"keep_informing");
    [super applyLocalization];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self setupView];
}

- (void) setupView
{
    NSMutableArray *tableData = [NSMutableArray array];
    NSMutableArray *statusArr = [NSMutableArray array];
    NSMutableArray *distanceArr = [NSMutableArray array];
    BOOL isManualAnnunce = [_settings.keepInforming get:self.appMode] == 0;
    [statusArr addObject:@{
        @"type" : @"OASwitchCell",
        @"title" : OALocalizedString(@"only_manually"),
        @"isOn" : @(isManualAnnunce),
    }];
    [tableData addObject:statusArr];
    if (!isManualAnnunce)
    {
        [distanceArr addObject:@{
            @"type" : kCellTypeDistance,
            @"title" : OALocalizedString(@"repeat_after"),
        }];
        [distanceArr addObject:@{
            @"type" : kCellTypePicker,
        }];
        [tableData addObject:distanceArr];
    }
    
    _data = [NSArray arrayWithArray:tableData];
}

#pragma mark - TableView

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:@"OASwitchCell"])
    {
        static NSString* const identifierCell = @"OASwitchCell";
        OASwitchTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OASwitchTableViewCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.switchView.on = [item[@"isOn"] boolValue];
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView addTarget:self action:@selector(applyParameter:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    else if ([cellType isEqualToString:kCellTypeDistance])
    {
        static NSString* const identifierCell = @"OATimeTableViewCell";
        OATimeTableViewCell* cell;
        cell = (OATimeTableViewCell *)[tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OATimeCell" owner:self options:nil];
            cell = (OATimeTableViewCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        cell.lbTitle.text = item[@"title"];
        cell.lbTime.text = _keepInformingEntries[_selectedValue];
        cell.lbTime.textColor = UIColorFromRGB(color_text_footer);

        return cell;
    }
    else if ([cellType isEqualToString:kCellTypePicker])
    {
        OACustomPickerTableViewCell* cell;
        cell = (OACustomPickerTableViewCell *)[tableView dequeueReusableCellWithIdentifier:[OACustomPickerTableViewCell getCellIdentifier]];
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

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 17.0;
}

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == kDistanceSection)
    {
        if ([self pickerIsShown])
            return 2;
        return 1;
    }
    return 1;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    if ([item[@"type"] isEqualToString:kCellTypeDistance])
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

        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self.tableView endUpdates];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}

- (NSIndexPath *) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    return cell.selectionStyle == UITableViewCellSelectionStyleNone && indexPath != [NSIndexPath indexPathForRow:0 inSection:1] ? nil : indexPath;
}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return section == 0 ? OALocalizedString(@"instructions_repeat") : @"";
}

-(void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *vw = (UITableViewHeaderFooterView *) view;
    [vw.textLabel setTextColor:UIColorFromRGB(color_text_footer)];
}

# pragma mark - Switch

- (void)applyParameter:(id)sender
{
    if ([sender isKindOfClass:UISwitch.class])
    {
        UISwitch *control = (UISwitch *)sender;
        [_settings.keepInforming set:(control.isOn ? 0 : _keepInformingValues[_selectedValue].intValue) mode:self.appMode];
        [self hidePicker];
        [self.tableView beginUpdates];
        [self setupView];
        if (control.isOn)
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
        else
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }
}

# pragma mark - Picker

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

- (void)zoomChanged:(NSString *)zoom tag:(NSInteger)pickerTag {
    _selectedValue = [_keepInformingEntries indexOfObject:zoom];
    _selectedValue = _selectedValue == NSNotFound ? 0 : _selectedValue;
    [_settings.keepInforming set:_keepInformingValues[_selectedValue].intValue mode:self.appMode];
    [self setupView];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_pickerIndexPath.row - 1 inSection:_pickerIndexPath.section]] withRowAnimation:UITableViewRowAnimationFade];
}

@end
