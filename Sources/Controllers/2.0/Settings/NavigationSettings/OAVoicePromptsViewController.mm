//
//  OAVoicePromptsViewController.mm
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 24.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAVoicePromptsViewController.h"
#import "OASwitchTableViewCell.h"
#import "OAIconTitleValueCell.h"
#import "OASettingSwitchCell.h"
#import "OASettingsTableViewCell.h"
#import "OANavigationLanguageViewController.h"
#import "OASpeedLimitToleranceViewController.h"
#import "OARepeatNavigationInstructionsViewController.h"
#import "OAArrivalAnnouncementViewController.h"
#import "OAAppSettings.h"
#import "OAApplicationMode.h"
#import "OARoutingHelper.h"
#import "OAVoiceRouter.h"

#import "Localization.h"
#import "OAColors.h"

#include <OsmAndCore/Utilities.h>

@interface OAVoicePromptsViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAVoicePromptsViewController
{
    NSArray<NSArray *> *_data;
    OAAppSettings *_settings;
    BOOL _voiceOn;
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
    [self setupView];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setupView];
    [self.tableView reloadData];
}

- (void) setupView
{
    NSMutableArray *tableData = [NSMutableArray array];
    NSMutableArray *firstSection = [NSMutableArray array]; // change
    NSMutableArray *secondSection = [NSMutableArray array];
    NSMutableArray *thirdSection = [NSMutableArray array];
    NSMutableArray *fourthSection = [NSMutableArray array];
    NSMutableArray *fifthSection = [NSMutableArray array];
    
    _voiceOn = ![_settings.voiceMute get:self.appMode];
    NSDictionary *screenVoiceProviders = [OAUtilities getSortedVoiceProviders];
    NSString *selectedLanguage = @"";
    NSString *selectedValue = [_settings.voiceProvider get:self.appMode];
    for (NSString *key in screenVoiceProviders.allKeys)
    {
        if ([screenVoiceProviders[key] isEqualToString:selectedValue])
            selectedLanguage = key;
    }
    NSArray<NSNumber *> *arrivalValues = @[ @1.5f, @1.f, @0.5f, @0.25f ];
    NSArray<NSString *> *arrivalNames =  @[ OALocalizedString(@"arrival_distance_factor_early"),
                                            OALocalizedString(@"arrival_distance_factor_normally"),
                                            OALocalizedString(@"arrival_distance_factor_late"),
                                            OALocalizedString(@"arrival_distance_factor_at_last") ];
    NSString *arrivalAnnouncementValue = nil;
    NSInteger index = [arrivalValues indexOfObject:@([_settings.arrivalDistanceFactor get:self.appMode])];
    if (index != NSNotFound)
        arrivalAnnouncementValue = arrivalNames[index];
    
    NSArray<NSNumber *> *speedLimitsKm = @[ @0.f, @5.f, @7.f, @10.f, @15.f, @20.f ];
    NSArray<NSNumber *> *speedLimitsMiles = @[ @0.f, @3.f, @5.f, @7.f, @10.f, @15.f ];
    
    [firstSection addObject:@{
        @"type" : [OASettingSwitchCell getCellIdentifier],
        @"title" : OALocalizedString(@"voice_provider"),
        @"icon" : @"ic_custom_sound",
        @"value" : _settings.voiceMute,
        @"key" : @"voiceGuidance",
    }];
    [firstSection addObject:@{
        @"type" : [OAIconTitleValueCell getCellIdentifier],
        @"title" : OALocalizedString(@"language"),
        @"value" : selectedLanguage,
        @"icon" : @"ic_custom_map_languge",
        @"isOn" : @NO,
        @"key" : @"language",
    }];
    
    [secondSection addObject:@{
        @"type" : [OASwitchTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"speak_street_names"),
        @"value" : _settings.speakStreetNames,
        @"key" : @"streetNames",
    }];
    [secondSection addObject:@{
        @"type" : [OASwitchTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"show_traffic_warnings"),
        @"value" : _settings.speakTrafficWarnings,
        @"key" : @"trafficWarnings",
    }];
    [secondSection addObject:@{
        @"type" : [OASwitchTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"show_pedestrian_warnings"),
        @"value" : _settings.speakPedestrian,
        @"key" : @"pedestrianCrosswalks",
    }];
    
    [thirdSection addObject:@{
        @"type" : [OASwitchTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"speak_speed_limit"),
        @"value" : _settings.speakSpeedLimit,
        @"key" : @"speedLimit",
    }];
    
    NSString *value = nil;
    if ([_settings.metricSystem get] == KILOMETERS_AND_METERS)
    {
        value = [NSString stringWithFormat:@"%d %@", (int)[_settings.speedLimitExceedKmh get:self.appMode], OALocalizedString(@"units_kmh")];
    }
    else
    {
        NSUInteger index = [speedLimitsKm indexOfObject:@([_settings.speedLimitExceedKmh get:self.appMode])];
        if (index != NSNotFound)
            value = [NSString stringWithFormat:@"%d %@", speedLimitsMiles[index].intValue, OALocalizedString(@"units_mph")];
    }
    [thirdSection addObject:@{
        @"type" : [OASettingsTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"speed_limit_exceed"),
        @"value" : value,
        @"key" : @"speedLimitTolerance",
    }];
    
    [fourthSection addObject:@{
        @"type" : [OASwitchTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"speak_cameras"),
        @"value" : _settings.speakCameras,
        @"key" : @"speedCameras",
    }];
    [fourthSection addObject:@{
        @"type" : [OASwitchTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"speak_tunnels"),
        @"value" : _settings.speakTunnels,
        @"key" : @"tunnels",
    }];
    [fourthSection addObject:@{
        @"type" : [OASwitchTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"announce_gpx_waypoints"),
        @"value" : _settings.announceWpt,
        @"key" : @"GPXWaypoints",
    }];
    [fourthSection addObject:@{
        @"type" : [OASwitchTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"speak_favorites"),
        @"value" : _settings.announceNearbyFavorites,
        @"key" : @"nearbyFavorites",
    }];
    [fourthSection addObject:@{
        @"type" : [OASwitchTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"speak_poi"),
        @"value" : _settings.announceNearbyPoi,
        @"key" : @"nearbyPOI",
    }];
    
    NSString *val;
    if ([_settings.keepInforming get:self.appMode] == 0)
        val = OALocalizedString(@"only_manually");
    else
        val = [NSString stringWithFormat:@"%d %@", [_settings.keepInforming get:self.appMode], OALocalizedString(@"units_min")];
    
    [fifthSection addObject:@{
        @"type" : [OASettingsTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"keep_informing"),
        @"value" : val,
        @"key" : @"repeatInstructions",
    }];
    [fifthSection addObject:@{
        @"type" : [OASettingsTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"arrival_distance"),
        @"value" : arrivalAnnouncementValue,
        @"key" : @"arrivalAnnouncement",
    }];
    [tableData addObject:firstSection];
    [tableData addObject:secondSection];
    [tableData addObject:thirdSection];
    [tableData addObject:fourthSection];
    [tableData addObject:fifthSection];
    _data = [NSArray arrayWithArray:tableData];
}

#pragma mark - TableView

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:[OASettingSwitchCell getCellIdentifier]])
    {
        OASettingSwitchCell* cell = [tableView dequeueReusableCellWithIdentifier:[OASettingSwitchCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASettingSwitchCell getCellIdentifier] owner:self options:nil];
            cell = (OASettingSwitchCell *)[nib objectAtIndex:0];
            cell.descriptionView.hidden = YES;
            cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.imgView.image = [[UIImage imageNamed:item[@"icon"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.imgView.tintColor = _voiceOn ? UIColorFromRGB(self.appMode.getIconColor) : UIColorFromRGB(color_icon_inactive);
                                  
            id v = item[@"value"];
            [cell.switchView removeTarget:NULL action:NULL forControlEvents:UIControlEventAllEvents];
            if ([v isKindOfClass:[OAProfileBoolean class]])
            {
                OAProfileBoolean *value = v;
                cell.switchView.on = [[v key] isEqualToString:@"voiceMute"] ? ![value get:self.appMode] : [value get:self.appMode];
            }
            else
            {
                cell.switchView.on = [v boolValue];
            }
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView addTarget:self action:@selector(applyParameter:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OAIconTitleValueCell getCellIdentifier]])
    {
        static NSString* const identifierCell = [OAIconTitleValueCell getCellIdentifier];
        OAIconTitleValueCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OAIconTitleValueCell *)[nib objectAtIndex:0];
            cell.iconView.image = [[UIImage imageNamed:@"ic_custom_arrow_right"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate].imageFlippedForRightToLeftLayoutDirection;
            cell.iconView.tintColor = UIColorFromRGB(color_tint_gray);
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.descriptionView.text = item[@"value"];
            cell.leftImageView.image = [[UIImage imageNamed:item[@"icon"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.leftImageView.tintColor = UIColorFromRGB(self.appMode.getIconColor);
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
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
            id v = item[@"value"];
            [cell.switchView removeTarget:NULL action:NULL forControlEvents:UIControlEventAllEvents];
            if ([v isKindOfClass:[OAProfileBoolean class]])
            {
                OAProfileBoolean *value = v;
                cell.switchView.on = [value get:self.appMode];
            }
            else
            {
                cell.switchView.on = [v boolValue];
            }
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView addTarget:self action:@selector(applyParameter:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OASettingsTableViewCell getCellIdentifier]])
    {
        static NSString* const identifierCell = [OASettingsTableViewCell getCellIdentifier];
        OASettingsTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:[OASettingsTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OASettingsTableViewCell *)[nib objectAtIndex:0];
            cell.descriptionView.font = [UIFont systemFontOfSize:17.0];
            cell.iconView.image = [[UIImage imageNamed:@"ic_custom_arrow_right"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate].imageFlippedForRightToLeftLayoutDirection;
            cell.iconView.tintColor = UIColorFromRGB(color_tint_gray);
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.descriptionView.text = item[@"value"];
        }
        return cell;
    }
    return nil;
}

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _voiceOn ? _data[section].count : 1;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _voiceOn ? _data.count : 1;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return section == 1 ? OALocalizedString(@"announce") : @"";
}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return section == 0 ? OALocalizedString(@"speak_descr") : @"";
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

- (NSIndexPath *) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    return cell.selectionStyle == UITableViewCellSelectionStyleNone ? nil : indexPath;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *itemKey = item[@"key"];
    OABaseSettingsViewController* settingsViewController = nil;
    if ([itemKey isEqualToString:@"language"])
        settingsViewController = [[OANavigationLanguageViewController alloc] initWithAppMode:self.appMode];
    else if ([itemKey isEqualToString:@"speedLimitTolerance"])
        settingsViewController = [[OASpeedLimitToleranceViewController alloc] initWithAppMode:self.appMode];
    else if ([itemKey isEqualToString:@"repeatInstructions"])
        settingsViewController = [[OARepeatNavigationInstructionsViewController alloc] initWithAppMode:self.appMode];
    else if ([itemKey isEqualToString:@"arrivalAnnouncement"])
        settingsViewController = [[OAArrivalAnnouncementViewController alloc] initWithAppMode:self.appMode];
    [self showViewController:settingsViewController];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Switch

- (void) updateTableView
{
    if (_voiceOn)
    {
        [self.tableView beginUpdates];
        [self.tableView insertSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, _data.count - 1)] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:(UITableViewRowAnimation)UITableViewRowAnimationFade];
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }
    else
    {
        [self.tableView beginUpdates];
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, _data.count - 1)] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }
}

- (void) applyParameter:(id)sender
{
    UISwitch *sw = (UISwitch *) sender;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sw.tag & 0x3FF inSection:sw.tag >> 10];
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    BOOL isChecked = ((UISwitch *) sender).on;
    id v = item[@"value"];
    if ([v isKindOfClass:[OAProfileBoolean class]])
    {
        OAProfileBoolean *value = v;
        if ([[v key] isEqualToString:@"voiceMute"])
        {
            [value set:!isChecked mode:self.appMode];
            [OARoutingHelper.sharedInstance.getVoiceRouter setMute:!isChecked];
            _voiceOn = isChecked;
            [self updateTableView];
        }
        else
        {
            [value set:isChecked mode:self.appMode];
        }
    }
    if (self.delegate)
        [self.delegate onSettingsChanged];
}

@end
