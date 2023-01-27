//
//  OAVoicePromptsViewController.mm
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 24.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAVoicePromptsViewController.h"
#import "OAValueTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OACardTableViewCell.h"
#import "OANavigationLanguageViewController.h"
#import "OASpeedLimitToleranceViewController.h"
#import "OARepeatNavigationInstructionsViewController.h"
#import "OAArrivalAnnouncementViewController.h"
#import "OAUninstallSpeedCamerasViewController.h"
#import "OATableDataModel.h"
#import "OATableSectionData.h"
#import "OATableRowData.h"
#import "OATableCollapsableRowData.h"
#import "OAAppSettings.h"
#import "OAApplicationMode.h"
#import "OARoutingHelper.h"
#import "OAVoiceRouter.h"
#import "OASizes.h"
#import "Localization.h"
#import "OAColors.h"

#include <OsmAndCore/Utilities.h>

@interface OAVoicePromptsViewController () <UITableViewDelegate, UITableViewDataSource, OAUninstallSpeedCamerasDelegate>

@end

@implementation OAVoicePromptsViewController
{
    OATableDataModel *_data;
    OAAppSettings *_settings;
    BOOL _voiceOn;
    NSArray<NSIndexPath *> *_speedCamerasIndexPaths;
}

- (instancetype) initWithAppMode:(OAApplicationMode *)appMode
{
    self = [super initWithAppMode:appMode];
    if (self)
    {
        _settings = [OAAppSettings sharedManager];
    }
    return self;
}

-(void) applyLocalization
{
    [super applyLocalization];
    self.titleLabel.text = OALocalizedString(@"voice_announces");
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;

    [self generateData];
}

- (void)generateData
{
    _data = [OATableDataModel model];
    _voiceOn = ![_settings.voiceMute get:self.appMode];

    OATableSectionData *voicePromptsSection = [OATableSectionData sectionData];
    [_data addSection:voicePromptsSection];

    [voicePromptsSection addRowFromDictionary:@{
        kCellTypeKey : [OASwitchTableViewCell getCellIdentifier],
        kCellTitleKey : OALocalizedString(@"voice_announces"),
        kCellKeyKey : @"voiceGuidance",
        @"value" : _settings.voiceMute,
    }];

    if (!_voiceOn)
        return;

    NSDictionary *screenVoiceProviders = [OAUtilities getSortedVoiceProviders];
    NSString *selectedLanguage = @"";
    NSString *selectedValue = [_settings.voiceProvider get:self.appMode];
    for (NSString *key in screenVoiceProviders.allKeys)
    {
        if ([screenVoiceProviders[key] isEqualToString:selectedValue])
            selectedLanguage = key;
    }
    [voicePromptsSection addRowFromDictionary:@{
        kCellTypeKey : [OAValueTableViewCell getCellIdentifier],
        kCellTitleKey : OALocalizedString(@"shared_string_language"),
        kCellKeyKey : @"language",
        kCellIconNameKey : @"ic_custom_map_languge",
        @"value" : selectedLanguage
    }];

    OATableSectionData *announceFirstSection = [OATableSectionData sectionData];
    announceFirstSection.headerText = OALocalizedString(@"accessibility_announce");
    [_data addSection:announceFirstSection];

    [announceFirstSection addRowFromDictionary:@{
        kCellTypeKey : [OASwitchTableViewCell getCellIdentifier],
        kCellTitleKey : OALocalizedString(@"speak_street_names"),
        kCellKeyKey : @"streetNames",
        @"value" : _settings.speakStreetNames
    }];
    [announceFirstSection addRowFromDictionary:@{
        kCellTypeKey : [OASwitchTableViewCell getCellIdentifier],
        kCellTitleKey : OALocalizedString(@"exit_number"),
        kCellKeyKey : @"exitNumber",
        @"value" : _settings.speakExitNumberNames,
    }];

    OATableSectionData *announceSecondSection = [OATableSectionData sectionData];
    [_data addSection:announceSecondSection];

    [announceSecondSection addRowFromDictionary:@{
        kCellTypeKey : [OASwitchTableViewCell getCellIdentifier],
        kCellTitleKey : OALocalizedString(@"show_traffic_warnings"),
        kCellKeyKey : @"trafficWarnings",
        @"value" : _settings.speakTrafficWarnings,
    }];
    [announceSecondSection addRowFromDictionary:@{
        kCellTypeKey : [OASwitchTableViewCell getCellIdentifier],
        kCellTitleKey : OALocalizedString(@"traffic_warning_pedestrian"),
        kCellKeyKey : @"pedestrianCrosswalks",
        @"value" : _settings.speakPedestrian
    }];

    if (![_settings.speedCamerasUninstalled get])
    {
        [announceSecondSection addRowFromDictionary:@{
            kCellTypeKey : [OASwitchTableViewCell getCellIdentifier],
            kCellTitleKey : OALocalizedString(@"speak_cameras"),
            kCellKeyKey : @"speedCameras",
            @"value" : _settings.speakCameras
        }];
        NSIndexPath *speedCamerasIndexPath = [NSIndexPath indexPathForRow:[announceSecondSection rowCount] - 1 inSection:[_data sectionCount] - 1];
        [announceSecondSection addRowFromDictionary:@{
            kCellTypeKey : [OACardTableViewCell getCellIdentifier],
            kCellTitleKey : OALocalizedString(@"speed_cameras_alert"),
            kCellKeyKey : @"speed_cameras_read_more",
            kCellIconNameKey : @"ic_custom_alert_color",
            @"buttonTitle" : OALocalizedString(@"shared_string_read_more"),
        }];
        NSIndexPath *speedCamerasAlertIndexPath = [NSIndexPath indexPathForRow:[announceSecondSection rowCount] - 1 inSection:[_data sectionCount] - 1];

        _speedCamerasIndexPaths = @[speedCamerasIndexPath, speedCamerasAlertIndexPath];
    }

    [announceSecondSection addRowFromDictionary:@{
        kCellTypeKey : [OASwitchTableViewCell getCellIdentifier],
        kCellTitleKey : OALocalizedString(@"show_tunnels"),
        kCellKeyKey : @"tunnels",
        @"value" : _settings.speakTunnels
    }];

    OATableSectionData *userPointsSection = [OATableSectionData sectionData];
    userPointsSection.headerText = OALocalizedString(@"user_points");
    [_data addSection:userPointsSection];

    [userPointsSection addRowFromDictionary:@{
        kCellTypeKey : [OASwitchTableViewCell getCellIdentifier],
        kCellTitleKey : OALocalizedString(@"shared_string_gpx_waypoints"),
        kCellKeyKey : @"GPXWaypoints",
        @"value" : _settings.announceWpt
    }];
    [userPointsSection addRowFromDictionary:@{
        kCellTypeKey : [OASwitchTableViewCell getCellIdentifier],
        kCellTitleKey : OALocalizedString(@"speak_favorites"),
        kCellKeyKey : @"nearbyFavorites",
        @"value" : _settings.announceNearbyFavorites
    }];
    [userPointsSection addRowFromDictionary:@{
        kCellTypeKey : [OASwitchTableViewCell getCellIdentifier],
        kCellTitleKey : OALocalizedString(@"speak_poi"),
        kCellKeyKey : @"nearbyPOI",
        @"value" : _settings.announceNearbyPoi
    }];

    OATableSectionData *speedLimitSection = [OATableSectionData sectionData];
    speedLimitSection.headerText = OALocalizedString(@"traffic_warning_speed_limit");
    [_data addSection:speedLimitSection];

    NSArray<NSNumber *> *speedLimitsKm = @[ @0.f, @5.f, @7.f, @10.f, @15.f, @20.f ];
    NSArray<NSNumber *> *speedLimitsMiles = @[ @0.f, @3.f, @5.f, @7.f, @10.f, @15.f ];

    OATableCollapsableRowData *speedLimitCollapsableRow = [[OATableCollapsableRowData alloc] initWithData:@{
        kCellTypeKey : [OASwitchTableViewCell getCellIdentifier],
        kCellTitleKey : OALocalizedString(@"announce_when_exceeded"),
        kCellKeyKey : @"speedLimit",
        @"value" : _settings.speakSpeedLimit
    }];
    speedLimitCollapsableRow.collapsed = ![_settings.speakSpeedLimit get:self.appMode];
    [speedLimitSection addRow:speedLimitCollapsableRow];
    NSString *value = @"";
    if ([_settings.metricSystem get:self.appMode] == KILOMETERS_AND_METERS)
    {
        value = [NSString stringWithFormat:@"%d %@", (int)[_settings.speedLimitExceedKmh get:self.appMode], OALocalizedString(@"km_h")];
    }
    else
    {
        NSUInteger index = [speedLimitsKm indexOfObject:@([_settings.speedLimitExceedKmh get:self.appMode])];
        if (index != NSNotFound)
            value = [NSString stringWithFormat:@"%d %@", speedLimitsMiles[index].intValue, OALocalizedString(@"units_mph")];
    }
    [speedLimitCollapsableRow addDependentRow:[[OATableRowData alloc] initWithData:@{
        kCellTypeKey : [OAValueTableViewCell getCellIdentifier],
        kCellTitleKey : OALocalizedString(@"speed_limit_exceed"),
        kCellKeyKey : @"speedLimitTolerance",
        @"value" : value
    }]];

    OATableSectionData *otherSection = [OATableSectionData sectionData];
    otherSection.headerText = OALocalizedString(@"other_location");
    [_data addSection:otherSection];

    [otherSection addRowFromDictionary:@{
        kCellTypeKey : [OASwitchTableViewCell getCellIdentifier],
        kCellTitleKey : OALocalizedString(@"speak_gps_signal_status"),
        kCellKeyKey : @"speakGpsSignalStatus",
        @"value" : _settings.speakGpsSignalStatus
    }];
    [otherSection addRowFromDictionary:@{
        kCellTypeKey : [OASwitchTableViewCell getCellIdentifier],
        kCellTitleKey : OALocalizedString(@"speak_route_recalculation"),
        kCellKeyKey : @"speakRouteRecalculation",
        @"value" : _settings.speakRouteRecalculation
    }];

    OATableSectionData *optionsSection = [OATableSectionData sectionData];
    optionsSection.headerText = OALocalizedString(@"shared_string_options");
    [_data addSection:optionsSection];

    NSString *val;
    if ([_settings.keepInforming get:self.appMode] == 0)
        val = OALocalizedString(@"only_manually");
    else
        val = [NSString stringWithFormat:@"%d %@", [_settings.keepInforming get:self.appMode], OALocalizedString(@"int_min")];

    [optionsSection addRowFromDictionary:@{
        kCellTypeKey : [OAValueTableViewCell getCellIdentifier],
        kCellTitleKey : OALocalizedString(@"keep_informing"),
        kCellKeyKey : @"repeatInstructions",
        @"value" : val
    }];

    NSArray<NSNumber *> *arrivalValues = @[ @1.5f, @1.f, @0.5f, @0.25f ];
    NSArray<NSString *> *arrivalNames =  @[ OALocalizedString(@"arrival_distance_factor_early"),
                                            OALocalizedString(@"arrival_distance_factor_normally"),
                                            OALocalizedString(@"arrival_distance_factor_late"),
                                            OALocalizedString(@"arrival_distance_factor_at_last") ];
    NSString *arrivalAnnouncementValue = @"";
    NSInteger index = [arrivalValues indexOfObject:@([_settings.arrivalDistanceFactor get:self.appMode])];
    if (index != NSNotFound)
        arrivalAnnouncementValue = arrivalNames[index];

    [optionsSection addRowFromDictionary:@{
        kCellTypeKey : [OAValueTableViewCell getCellIdentifier],
        kCellTitleKey : OALocalizedString(@"announcement_time_title"),
        kCellKeyKey : @"arrivalAnnouncement",
        @"value" : arrivalAnnouncementValue
    }];
}

#pragma mark - TableView

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
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
            BOOL isVoicePrompts = [item.key isEqualToString:@"voiceGuidance"];

            CGFloat leftInset = [item.key isEqualToString:@"speedCameras"] ? CGFLOAT_MAX
                : [OAUtilities getLeftMargin] + (isVoicePrompts ? kPaddingToLeftOfContentWithIcon : kPaddingOnSideOfContent);
            cell.separatorInset = UIEdgeInsetsMake(0., leftInset, 0., 0.);
            cell.titleLabel.text = item.title;

            [cell leftIconVisibility:isVoicePrompts];
            if (isVoicePrompts)
            {
                cell.leftIconView.image = [UIImage templateImageNamed:_voiceOn ? @"ic_custom_sound" : @"ic_custom_sound_off"];
                cell.leftIconView.tintColor = _voiceOn ? UIColorFromRGB(self.appMode.getIconColor) : UIColorFromRGB(color_icon_inactive);
            }
            else
            {
                cell.leftIconView.image = nil;
            }
                                  
            id v = [item objForKey:@"value"];
            [cell.switchView removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            if ([v isKindOfClass:[OACommonBoolean class]])
            {
                OACommonBoolean *value = v;
                cell.switchView.on = [[v key] isEqualToString:@"voiceMute"] ? ![value get:self.appMode] : [value get:self.appMode];
            }
            else
            {
                cell.switchView.on = [v boolValue];
            }
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView addTarget:self action:@selector(onSwitchButtonPressed:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    else if ([item.cellType isEqualToString:[OAValueTableViewCell getCellIdentifier]])
    {
        OAValueTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAValueTableViewCell *) nib[0];
            [cell descriptionVisibility:NO];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        if (cell)
        {
            BOOL hasIcon = item.iconName.length > 0;
            cell.separatorInset = UIEdgeInsetsMake(0., [OAUtilities getLeftMargin] + (hasIcon ? kPaddingToLeftOfContentWithIcon : kPaddingOnSideOfContent), 0., 0.);

            cell.titleLabel.text = item.title;
            cell.valueLabel.text = [item objForKey:@"value"];

            [cell leftIconVisibility:hasIcon];
            if (hasIcon)
            {
                cell.leftIconView.image = [UIImage templateImageNamed:item.iconName];
                cell.leftIconView.tintColor = UIColorFromRGB([self.appMode getIconColor]);
            }
            else
            {
                cell.leftIconView.image = nil;
            }
        }
        return cell;
    }
    else if ([item.cellType isEqualToString:[OACardTableViewCell getCellIdentifier]])
    {
        OACardTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OACardTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OACardTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OACardTableViewCell *) nib[0];
            [cell topBackgroundMarginVisibility:NO];
        }
        if (cell)
        {
            cell.separatorInset = UIEdgeInsetsMake(0., [OAUtilities getLeftMargin] + kPaddingOnSideOfContent, 0., 0.);

            cell.titleLabel.text = item.title;
            cell.leftIconView.image = [UIImage imageNamed:item.iconName];

            [cell.button setTitle:[item stringForKey:@"buttonTitle"] forState:UIControlStateNormal];
            cell.button.tag = indexPath.section << 10 | indexPath.row;
            [cell.button removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
            [cell.button addTarget:self action:@selector(onButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        }
        return cell;
    }
    return nil;
}

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[_data sectionDataForIndex:section] rowCount];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return [_data sectionCount];
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [_data sectionDataForIndex:section].headerText;
}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return [_data sectionDataForIndex:section].footerText;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    OABaseSettingsViewController *settingsViewController = nil;
    if ([item.key isEqualToString:@"language"])
        settingsViewController = [[OANavigationLanguageViewController alloc] initWithAppMode:self.appMode];
    else if ([item.key isEqualToString:@"speedLimitTolerance"])
        settingsViewController = [[OASpeedLimitToleranceViewController alloc] initWithAppMode:self.appMode];
    else if ([item.key isEqualToString:@"repeatInstructions"])
        settingsViewController = [[OARepeatNavigationInstructionsViewController alloc] initWithAppMode:self.appMode];
    else if ([item.key isEqualToString:@"arrivalAnnouncement"])
        settingsViewController = [[OAArrivalAnnouncementViewController alloc] initWithAppMode:self.appMode];
    [self showViewController:settingsViewController];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Selectors

- (void)onButtonPressed:(id)sender
{
    UIButton *button = (UIButton *) sender;
    if (button)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:button.tag & 0x3FF inSection:button.tag >> 10];
        OATableRowData *item = [_data itemForIndexPath:indexPath];
        if ([item.key isEqualToString:@"speed_cameras_read_more"])
        {
            OAUninstallSpeedCamerasViewController *speedCamerasViewController = [[OAUninstallSpeedCamerasViewController alloc] init];
            speedCamerasViewController.delegate = self;
            [self presentViewController:speedCamerasViewController animated:YES completion:nil];
        }
    }
}

- (void)onSwitchButtonPressed:(id)sender
{
    UISwitch *sw = (UISwitch *) sender;
    if (sw)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sw.tag & 0x3FF inSection:sw.tag >> 10];
        OATableRowData *item = [_data itemForIndexPath:indexPath];
        BOOL isChecked = ((UISwitch *) sender).on;
        id v = [item objForKey:@"value"];
        if ([v isKindOfClass:[OACommonBoolean class]])
        {
            OACommonBoolean *value = v;
            if ([[v key] isEqualToString:@"voiceMute"])
            {
                [value set:!isChecked mode:self.appMode];
                [OARoutingHelper.sharedInstance.getVoiceRouter setMute:!isChecked];
                _voiceOn = isChecked;
                [self onVoicePromptsPressed];
            }
            else
            {
                [value set:isChecked mode:self.appMode];
            }
        }
        if (self.delegate)
            [self.delegate onSettingsChanged];

        if ([item.key isEqualToString:@"speedLimit"])
            [self onSpeedLimitPressed:indexPath];
    }
}

- (void) onVoicePromptsPressed
{
    [self.tableView performBatchUpdates:^{
        if (_voiceOn)
        {
            [self generateData];
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]]
                                  withRowAnimation:(UITableViewRowAnimation)UITableViewRowAnimationFade];
            [self.tableView insertSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, [_data sectionCount] - 1)]
                          withRowAnimation:UITableViewRowAnimationFade];
        }
        else
        {
            [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]]
                                  withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, [_data sectionCount] - 1)]
                          withRowAnimation:UITableViewRowAnimationFade];
            [self generateData];
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
                                    withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    } completion:nil];
}

- (void)onSpeedLimitPressed:(NSIndexPath *)indexPath
{
    OATableCollapsableRowData *collapsableRow = (OATableCollapsableRowData *) [_data itemForIndexPath:indexPath];
    collapsableRow.collapsed = !collapsableRow.collapsed;
    NSMutableArray<NSIndexPath *> *rowIndexes = [NSMutableArray array];
    for (NSInteger i = 1; i <= collapsableRow.dependentRowsCount; i++)
        [rowIndexes addObject:[NSIndexPath indexPathForRow:(indexPath.row + i) inSection:indexPath.section]];
    
    [self.tableView performBatchUpdates:^{
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        if (collapsableRow.collapsed)
            [self.tableView deleteRowsAtIndexPaths:rowIndexes withRowAnimation:UITableViewRowAnimationBottom];
        else
            [self.tableView insertRowsAtIndexPaths:rowIndexes withRowAnimation:UITableViewRowAnimationBottom];
    } completion:nil];
}

#pragma mark - OAUninstallSpeedCamerasDelegate

- (void)onUninstallSpeedCameras
{
    if (_speedCamerasIndexPaths && _speedCamerasIndexPaths.count > 0)
    {
        [self.tableView performBatchUpdates:^{
            [self.tableView deleteRowsAtIndexPaths:_speedCamerasIndexPaths withRowAnimation:UITableViewRowAnimationBottom];
            [_data removeItemAtIndexPaths:_speedCamerasIndexPaths];
        } completion:nil];
    }
}

@end
