//
//  OASimulationNavigationSettingViewController.m
//  OsmAnd Maps
//
//  Created by nnngrach on 05.05.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OASimulationNavigationSettingViewController.h"
#import "OsmAndApp.h"
#import "OsmAndAppImpl.h"
#import "OAAppSettings.h"
#import "OAApplicationMode.h"
#import "Localization.h"
#import "OAColors.h"
#import "OAOsmAndFormatter.h"
#import "OASettingSwitchCell.h"
#import "OASliderWithValuesCell.h"
#import "OADividerCell.h"

#define kSimMaxSpeed 900 / 3.6f
#define kUICellHeight 48.0
#define kUICellKey @"kUICellKey"
#define kSimulateNavigationSwitchkey @"kSimulateNavigationSwitchkey"

@interface OASimulationNavigationSettingViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OASimulationNavigationSettingViewController
{
    OAAppSettings *_settings;
    NSArray<NSArray *> *_data;
    OAApplicationMode *_appMode;
    
    BOOL _isEnabled;
    NSString *_selectedMode;
    float _selectedSpeed;
    float _minSpeedValue;
    float _maxSpeedValue;
    NSString *_minSpeedText;
    NSString *_maxSpeedText;
}

- (instancetype)initWithAppMode:(OAApplicationMode *)mode
{
    self = [super init];
    if (self)
    {
        _appMode = mode;
        [self commonInit];
    }
    return self;
}

- (void) commonInit
{
    _settings = [OAAppSettings sharedManager];
    _isEnabled = _settings.simulateNavigation;
    _selectedMode = _settings.simulateNavigationMode;
    _selectedSpeed = _settings.simulateNavigationSpeed;
    [self setupSpeedSlider];
    [self generateData];
}

- (void) applyLocalization
{
    [super applyLocalization];
    self.titleLabel.text = OALocalizedString(@"simulate_navigation");
    [self.doneButton setTitle:OALocalizedString(@"shared_string_done") forState:UIControlStateNormal];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        
    [self generateData];
    [self updateHeaderButtons];
}

- (void) viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self generateData];
    [self.tableView reloadData];
}
    
#pragma mark - Setup data

- (NSDictionary *) getDataItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.section][indexPath.row];
}

- (void) generateData
{
    NSMutableArray *result = [NSMutableArray array];
    NSNumber *zeroInset = [NSNumber numberWithFloat:0];
    NSNumber *defaultInset = [NSNumber numberWithFloat:20 + [OAUtilities getLeftMargin]];
    
    NSString *selectedModeDescription = @"";
    for (OASimulationMode *mode in [OASimulationMode values])
    {
        if ([_selectedMode isEqualToString:[mode key]])
            selectedModeDescription = [mode description];
    }
    
    NSArray *switchSection = @[
        @{
            @"type" : [OADividerCell getCellIdentifier],
            @"inset" : zeroInset,
        },
        @{
            @"type" : [OASettingSwitchCell getCellIdentifier],
            @"key" : kSimulateNavigationSwitchkey,
            @"title" : OALocalizedString(@"shared_string_enabled"),
            @"value" : @(_isEnabled),
            @"headerTitle" : @"",
            @"footerTitle" : @""
        },
        @{
            @"type" : [OADividerCell getCellIdentifier],
            @"inset" : zeroInset,
        }
    ];
    [result addObject:switchSection];
    
    if (_isEnabled)
    {
        BOOL isConstantMode = [_selectedMode isEqualToString:[OASimulationMode toKey:EOASimulationModeConstant]];
        NSMutableArray *paramsSection = [NSMutableArray array];
        [paramsSection addObject:@{
            @"type" : [OADividerCell getCellIdentifier],
            @"inset" : zeroInset,
            @"headerTitle" : OALocalizedString(@"speed_mode"),
            @"footerTitle" : selectedModeDescription
        }];
        [paramsSection addObject:@{
            @"type" : kUICellKey,
            @"key" : [OASimulationMode toKey:EOASimulationModePreview],
            @"title" : [OASimulationMode toTitle:EOASimulationModePreview],
            @"descr" : @"",
            @"selected" : @([_selectedMode isEqualToString:[OASimulationMode toKey:EOASimulationModePreview]])
        }];
        [paramsSection addObject:@{
            @"type" : [OADividerCell getCellIdentifier],
            @"inset" : defaultInset,
        }];
        [paramsSection addObject:@{
            @"type" : kUICellKey,
            @"key" : [OASimulationMode toKey:EOASimulationModeConstant],
            @"title" : [OASimulationMode toTitle:EOASimulationModeConstant],
            @"descr" : isConstantMode ? [OAOsmAndFormatter getFormattedSpeed:_selectedSpeed] : @"",
            @"selected" : @([_selectedMode isEqualToString:[OASimulationMode toKey:EOASimulationModeConstant]])
        }];
        if (isConstantMode)
        {
            [paramsSection addObject:@{
                @"type" : [OASliderWithValuesCell getCellIdentifier],
                @"selectedValue" : [NSNumber numberWithFloat:_selectedSpeed],
                @"minValue" : [NSNumber numberWithFloat:_minSpeedValue],
                @"maxValue" : [NSNumber numberWithFloat:_maxSpeedValue],
                @"minLabel" : _minSpeedText,
                @"maxLabel" : _maxSpeedText
            }];
        }
        [paramsSection addObject:@{
            @"type" : [OADividerCell getCellIdentifier],
            @"inset" : defaultInset,
        }];
        [paramsSection addObject:@{
            @"type" : kUICellKey,
            @"key" : [OASimulationMode toKey:EOASimulationModeRealistic],
            @"title" : [OASimulationMode toTitle:EOASimulationModeRealistic],
            @"descr" : @"",
            @"selected" : @([_selectedMode isEqualToString:[OASimulationMode toKey:EOASimulationModeRealistic]])
        }];
        [paramsSection addObject:@{
            @"type" : [OADividerCell getCellIdentifier],
            @"inset" : zeroInset,
        }];
        [result addObject:[NSArray arrayWithArray:paramsSection]];
    }
    
    _data = [NSArray arrayWithArray:result];
}

- (void) setupSpeedSlider
{
    float min = kSimMinSpeed;
    float max = kSimMaxSpeed;
    std::shared_ptr<GeneralRouter> router = [OsmAndApp.instance getRouter:_appMode];
    if (router != nullptr)
    {
        max = ((float)router->getMaxSpeed()) * 2;
    }
    float speedValue = _settings.simulateNavigationSpeed;
    _selectedSpeed = MIN(speedValue, max);
    
    _minSpeedValue = min;
    _maxSpeedValue = max;
    _minSpeedText = [OAOsmAndFormatter getFormattedSpeed:min];
    _maxSpeedText = [OAOsmAndFormatter getFormattedSpeed:max];
}

- (void) updateHeaderButtons
{
    self.cancelButton.hidden = YES;
    self.backButton.hidden = NO;
    self.doneButton.hidden = !_isEnabled;
}

#pragma mark - Actions

- (void) updateSwitchValue:(id)sender
{
    if ([sender isKindOfClass:[UISwitch class]])
    {
        UISwitch *sw = (UISwitch *) sender;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sw.tag & 0x3FF inSection:sw.tag >> 10];
        NSDictionary *item = [self getDataItem:indexPath];
        NSString *key = item[@"key"];
        if (key)
        {
            BOOL isChecked = sw.on;
            if ([key isEqualToString:kSimulateNavigationSwitchkey])
            {
                [self setSimulationEnabled:isChecked];
            }
        }
    }
}

- (void) setSimulationEnabled:(BOOL)enabled
{
    _isEnabled = enabled;
    [self generateData];
    [self updateHeaderButtons];
    
    [self.tableView beginUpdates];
    if (_isEnabled)
        [self.tableView insertSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 1)] withRowAnimation:UITableViewRowAnimationFade];
    else
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 1)] withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView endUpdates];
}

- (void) setSimulationMode:(NSString *)key
{
    NSString *oldValue = _selectedMode;
    _selectedMode = key;
    BOOL isSliderCellAdded = ![oldValue isEqualToString:[OASimulationMode toKey:EOASimulationModeConstant]] && [_selectedMode isEqualToString:[OASimulationMode toKey:EOASimulationModeConstant]];
    BOOL isSliderCellDeleted = [oldValue isEqualToString:[OASimulationMode toKey:EOASimulationModeConstant]] && ![_selectedMode isEqualToString:[OASimulationMode toKey:EOASimulationModeConstant]];
    [self generateData];
    
    if (isSliderCellAdded)
    {
        [self.tableView beginUpdates];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 1)] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
    }
    else if (isSliderCellDeleted)
    {
        [self.tableView beginUpdates];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 1)] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
    }
    else
    {
        [self.tableView reloadData];
        [self.tableView beginUpdates];
        [self.tableView endUpdates];
    }
}

- (void) updateSliderValue:(UISlider *)sender
{
    if (sender)
    {
        _selectedSpeed = sender.value;
        [self generateData];
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:3 inSection:1]] withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (void)onDoneButtonPressed
{
    //Saving changed variables
    _settings.simulateNavigationSpeed = _selectedSpeed;
    _settings.simulateNavigationMode = _selectedMode;
    _settings.simulateNavigation = _isEnabled;
    
    if (self.delegate)
        [self.delegate onSettingsChanged];
    [super onDoneButtonPressed];
}

#pragma mark - TableViewDelegate

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}
- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data[section].count;
}

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSDictionary *item = [self getDataItem:indexPath];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:[OASettingSwitchCell getCellIdentifier]])
    {
        OASettingSwitchCell* cell = nil;
        cell = [tableView dequeueReusableCellWithIdentifier:[OASettingSwitchCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASettingSwitchCell getCellIdentifier] owner:self options:nil];
            cell = (OASettingSwitchCell *)[nib objectAtIndex:0];
            cell.textView.numberOfLines = 0;
            cell.descriptionView.hidden = YES;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            [cell.textView setText: item[@"title"]];
            cell.switchView.on = [item[@"value"] boolValue];
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView removeTarget:nil action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(updateSwitchValue:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    else if ([cellType isEqualToString:kUICellKey])
    {
        UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:kUICellKey];
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kUICellKey];
        }
        if ([item[@"selected"] boolValue])
            cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"menu_cell_selected.png"]];
        else
            cell.accessoryView = nil;
        
        NSString *regularText = item[@"title"];
        NSString *coloredText = item[@"descr"];
        if (coloredText.length > 0)
        {
            NSString *fullText = [NSString stringWithFormat:@"%@: %@", regularText, coloredText];
            NSRange fullRange = NSMakeRange(0, fullText.length);
            NSRange coloredRange = [fullText rangeOfString:coloredText];
            NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:fullText];
            UIFont *font = [UIFont systemFontOfSize:17];
            [attributedString addAttribute:NSFontAttributeName value:font range:fullRange];
            [attributedString addAttribute:NSForegroundColorAttributeName value:UIColor.blackColor range:fullRange];
            [attributedString addAttribute:NSForegroundColorAttributeName value:UIColorFromRGB(color_text_footer) range:coloredRange];
            cell.textLabel.attributedText = attributedString;
        }
        else
        {
            cell.textLabel.text = regularText;
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OASliderWithValuesCell getCellIdentifier]])
    {
        OASliderWithValuesCell* cell = nil;
        cell = (OASliderWithValuesCell *)[tableView dequeueReusableCellWithIdentifier:[OASliderWithValuesCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASliderWithValuesCell getCellIdentifier] owner:self options:nil];
            cell = (OASliderWithValuesCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.sliderView.continuous = YES;
        }
        if (cell)
        {
            cell.leftValueLabel.text = item[@"minLabel"];
            cell.rightValueLabel.text = item[@"maxLabel"];
            cell.sliderView.minimumValue = [item[@"minValue"] floatValue];
            cell.sliderView.maximumValue = [item[@"maxValue"] floatValue];
            cell.sliderView.value = [item[@"selectedValue"] floatValue];
            [cell.sliderView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.sliderView addTarget:self action:@selector(updateSliderValue:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OADividerCell getCellIdentifier]])
    {
        OADividerCell* cell = nil;
        cell = [tableView dequeueReusableCellWithIdentifier:[OADividerCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OADividerCell getCellIdentifier] owner:self options:nil];
            cell = (OADividerCell *)[nib objectAtIndex:0];
            cell.backgroundColor = UIColor.whiteColor;
            cell.dividerColor = UIColorFromRGB(color_divider_blur);
            cell.dividerHight = 1.0 / [UIScreen mainScreen].scale;
        }
        cell.dividerInsets = UIEdgeInsetsMake(0, [item[@"inset"] doubleValue], 0, 0);
        return cell;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getDataItem:indexPath];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:kUICellKey])
    {
        return kUICellHeight;
    }
    else if ([cellType isEqualToString:[OADividerCell getCellIdentifier]])
    {
        return 1.0 / [UIScreen mainScreen].scale;
    }
    return UITableViewAutomaticDimension;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 32.0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return _data[section][0][@"headerTitle"];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return _data[section][0][@"footerTitle"];
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *item = [self getDataItem:indexPath];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:kUICellKey])
    {
        [self setSimulationMode:item[@"key"]];
    }
}

@end

