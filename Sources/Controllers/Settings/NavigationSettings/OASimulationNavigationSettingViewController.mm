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
#import "OsmAnd_Maps-Swift.h"
#import "OAOsmAndFormatter.h"
#import "OASwitchTableViewCell.h"
#import "OASliderWithValuesCell.h"
#import "OADividerCell.h"
#import "GeneratedAssetSymbols.h"

#define kSimMaxSpeed 900 / 3.6f
#define kUICellHeight 48.0
#define kUICellKey @"kUICellKey"
#define kSimulateNavigationSwitchkey @"kSimulateNavigationSwitchkey"

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

#pragma mark - Initialization

- (instancetype)initWithAppMode:(OAApplicationMode *)mode
{
    self = [super init];
    if (self)
    {
        _appMode = mode;
        [self postInit];
    }
    return self;
}

- (void)postInit
{
    _settings = [OAAppSettings sharedManager];
    _isEnabled = _settings.simulateNavigation;
    _selectedMode = _settings.simulateNavigationMode;
    _selectedSpeed = _settings.simulateNavigationSpeed;
    [self setupSpeedSlider];
    [self generateData];
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self generateData];
    [self updateNavbar];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    [self generateData];
    [self.tableView reloadData];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"simulate_navigation");
}

- (NSArray<UIBarButtonItem *> *)getRightNavbarButtons
{
    return !_isEnabled ? nil : @[[self createRightNavbarButton:OALocalizedString(@"shared_string_done") iconName:nil action:@selector(onRightNavbarButtonPressed) menu:nil]];
}

#pragma mark - Table data

- (void)generateData
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
            @"type" : [OASwitchTableViewCell getCellIdentifier],
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

- (NSDictionary *)getDataItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.section][indexPath.row];
}

- (void)setupSpeedSlider
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

- (NSInteger)sectionsCount
{
    return _data.count;
}

- (NSString *)getTitleForHeader:(NSInteger)section;
{
    return _data[section][0][@"headerTitle"];
}

- (NSString *)getTitleForFooter:(NSInteger)section
{
    return _data[section][0][@"footerTitle"];
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return _data[section].count;
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

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getDataItem:indexPath];
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

            cell.switchView.on = [item[@"value"] boolValue];
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView removeTarget:nil action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(updateSwitchValue:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    else if ([cellType isEqualToString:kUICellKey])
    {
        UITableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:kUICellKey];
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kUICellKey];
            cell.backgroundColor = [UIColor colorNamed:ACColorNameGroupBg];
        }
        if ([item[@"selected"] boolValue])
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        else
            cell.accessoryType = UITableViewCellAccessoryNone;
        
        NSString *regularText = item[@"title"];
        NSString *coloredText = item[@"descr"];
        if (coloredText.length > 0)
        {
            NSString *fullText = [NSString stringWithFormat:@"%@: %@", regularText, coloredText];
            NSRange fullRange = NSMakeRange(0, fullText.length);
            NSRange coloredRange = [fullText rangeOfString:coloredText];
            NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:fullText];
            UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
            [attributedString addAttribute:NSFontAttributeName value:font range:fullRange];
            [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor colorNamed:ACColorNameTextColorPrimary] range:fullRange];
            [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor colorNamed:ACColorNameTextColorSecondary] range:coloredRange];
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
        cell = (OASliderWithValuesCell *)[self.tableView dequeueReusableCellWithIdentifier:[OASliderWithValuesCell getCellIdentifier]];
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
        cell = [self.tableView dequeueReusableCellWithIdentifier:[OADividerCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OADividerCell getCellIdentifier] owner:self options:nil];
            cell = (OADividerCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.backgroundColor = [UIColor colorNamed:ACColorNameGroupBg];
            cell.dividerColor = [UIColor colorNamed:ACColorNameCustomSeparator];
            cell.dividerHight = 1.0 / [UIScreen mainScreen].scale;
        }
        cell.dividerInsets = UIEdgeInsetsMake(0, [item[@"inset"] doubleValue], 0, 0);
        return cell;
    }
    return nil;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *item = [self getDataItem:indexPath];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:kUICellKey])
    {
        [self setSimulationMode:item[@"key"]];
    }
}

#pragma mark - Actions

- (void)updateSwitchValue:(id)sender
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

- (void)setSimulationEnabled:(BOOL)enabled
{
    _isEnabled = enabled;
    [self generateData];
    [self updateNavbar];
    
    [self.tableView beginUpdates];
    if (_isEnabled)
        [self.tableView insertSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 1)] withRowAnimation:UITableViewRowAnimationFade];
    else
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 1)] withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView endUpdates];
}

- (void)setSimulationMode:(NSString *)key
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
    }
}

- (void)updateSliderValue:(UISlider *)sender
{
    if (sender)
    {
        _selectedSpeed = sender.value;
        [self generateData];
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:3 inSection:1]] withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (void)onRightNavbarButtonPressed
{
    //Saving changed variables
    _settings.simulateNavigationSpeed = _selectedSpeed;
    _settings.simulateNavigationMode = _selectedMode;
    _settings.simulateNavigation = _isEnabled;
    
    if (self.delegate)
        [self.delegate onSettingsChanged];
    [self dismissViewController];
}

@end
