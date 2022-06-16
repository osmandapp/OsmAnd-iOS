//
//  OARecalculateRouteViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 24.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OARecalculateRouteViewController.h"
#import "OASwitchTableViewCell.h"
#import "OATimeTableViewCell.h"
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

@interface OARecalculateRouteViewController () <UITableViewDelegate, UITableViewDataSource, OACustomPickerTableViewCellDelegate>

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

- (instancetype) initWithAppMode:(OAApplicationMode *)appMode
{
    self = [super initWithAppMode:appMode];
    if (self)
    {
        _settings = [OAAppSettings sharedManager];
        _app = OsmAndApp.instance;
        [self generateData];
    }
    return self;
}

- (void) generateData
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
        [arr addObject:[OAOsmAndFormatter getFormattedDistance:n.doubleValue forceTrailingZeroes:NO]];
    }
    _valueSummaries = arr;
}

- (NSString *) getDefaultValue
{
    double defValue = [OARoutingHelper getDefaultAllowedDeviation:self.appMode posTolerance:[OARoutingHelper getPosTolerance:0]];
    defValue = defValue == -1 ? _possibleDistanceValues.firstObject.doubleValue : defValue;
    return [OAOsmAndFormatter getFormattedDistance:defValue forceTrailingZeroes:NO];
}

-(void) applyLocalization
{
    [super applyLocalization];
    self.titleLabel.text = OALocalizedString(@"recalculate_route");
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
            @"type" : [OATimeTableViewCell getCellIdentifier],
            @"title" : OALocalizedString(@"shared_string_distance"),
        }];
        [distanceArr addObject:@{
            @"type" : [OACustomPickerTableViewCell getCellIdentifier],
        }];
        
        [tableData addObject:distanceArr];
    }
    _data = [NSArray arrayWithArray:tableData];
}

#pragma mark - TableView

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
    {
        OASwitchTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
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
        cell = (OATimeTableViewCell *)[tableView dequeueReusableCellWithIdentifier:[OATimeTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATimeTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OATimeTableViewCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        cell.lbTitle.text = item[@"title"];
        cell.lbTime.text = _defaultValue ? _defaultValue : _valueSummaries[_selectedValue];
        cell.lbTime.textColor = UIColorFromRGB(color_text_footer);

        return cell;
    }
    else if ([cellType isEqualToString:[OACustomPickerTableViewCell getCellIdentifier]])
    {
        OACustomPickerTableViewCell* cell;
        cell = (OACustomPickerTableViewCell *)[tableView dequeueReusableCellWithIdentifier:[OACustomPickerTableViewCell getCellIdentifier]];
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

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 17.0;
}

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
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
    return section == 0 ? OALocalizedString(@"route_recalculation_descr") : OALocalizedString(@"select_distance_for_recalculation");
}

-(void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *vw = (UITableViewHeaderFooterView *) view;
    [vw.textLabel setTextColor:UIColorFromRGB(color_text_footer)];
}

-(void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *vw = (UITableViewHeaderFooterView *) view;
    [vw.textLabel setTextColor:UIColorFromRGB(color_text_footer)];
}

#pragma mark - Switch

- (void) applyParameter:(id)sender
{
    if ([sender isKindOfClass:UISwitch.class])
    {
        UISwitch *control = (UISwitch *)sender;
        [_settings.routeRecalculationDistance set:control.isOn ? _possibleDistanceValues[_selectedValue].doubleValue : kDisableMode mode:self.appMode];
        [_settings.disableOffrouteRecalc set:!control.isOn mode:self.appMode];
        [self hidePicker];
        [self.tableView beginUpdates];
        [self setupView];
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
    [self setupView];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_pickerIndexPath.row - 1 inSection:_pickerIndexPath.section]] withRowAnimation:UITableViewRowAnimationAutomatic];
    
    if (self.delegate)
        [self.delegate onSettingsChanged];
}

@end
