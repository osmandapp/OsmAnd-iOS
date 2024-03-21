//
//  OATripRecordingSettingsViewController.m
//  OsmAnd
//
//  Created by Paul on 8/29/18.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OATripRecordingSettingsViewController.h"
#import "OASwitchTableViewCell.h"
#import "OAAppSettings.h"
#import "Localization.h"
#import "OAUtilities.h"
#import "OsmAndApp.h"
#import "OARoutingHelper.h"
#import "OAFileNameTranslationHelper.h"
#import "OASavingTrackHelper.h"
#import "OAValueTableViewCell.h"
#import "OASimpleTableViewCell.h"
#import "OARightIconTableViewCell.h"
#import "OAColors.h"
#import "OASizes.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

#include <generalRouter.h>

#define kCellTypeCheck @"check"

@interface OATripRecordingSettingsViewController ()

@property (nonatomic) NSDictionary *settingItem;

@end

@implementation OATripRecordingSettingsViewController
{
    NSArray *_data;
    
    OAAppSettings *_settings;
    OASavingTrackHelper *_recHelper;
    
    int _navigationSection;
}

static NSArray<NSNumber *> *minTrackDistanceValues;
static NSArray<NSString *> *minTrackDistanceNames;
static NSArray<NSNumber *> *trackPrecisionValues;
static NSArray<NSString *> *trackPrecisionNames;
static NSArray<NSNumber *> *minTrackSpeedValues;
static NSArray<NSString *> *minTrackSpeedNames;

#pragma mark - Initialization

+ (void) initialize
{
    if (self == [OATripRecordingSettingsViewController class])
    {
        minTrackDistanceValues = @[@0.f, @2.f, @5.f, @10.f, @20.f, @30.f, @50.f];
        minTrackDistanceNames = [OAUtilities arrayOfMeterValues:minTrackDistanceValues];
        
        trackPrecisionValues = @[@0.f, @1.f, @2.f, @5.f, @10.f, @15.f, @20.f, @50.f, @100.f];
        trackPrecisionNames = [OAUtilities arrayOfMeterValues:trackPrecisionValues];
        
        minTrackSpeedValues = @[@0.f, @0.000001f, @1.f, @2.f, @3.f, @4.f, @5.f, @6.f, @7.f];
        minTrackSpeedNames = [OAUtilities arrayOfSpeedValues:minTrackSpeedValues];
        
    }
}

- (id) initWithSettingsType:(kTripRecordingSettingsScreen)settingsType applicationMode:(OAApplicationMode *)applicationMode
{
    self = [super initWithAppMode:applicationMode];
    if (self)
    {
        _settingsType = settingsType;
        _settings = [OAAppSettings sharedManager];
        _recHelper = [OASavingTrackHelper sharedInstance];
        _navigationSection = -1;
    }
    return self;
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    switch (self.settingsType)
    {
        case kTripRecordingSettingsScreenRecInterval:
        case kTripRecordingSettingsScreenNavRecInterval:
            return OALocalizedString(@"save_track_interval_globally");
        case kTripRecordingSettingsScreenAccuracy:
            return OALocalizedString(@"monitoring_min_accuracy");
        case kTripRecordingSettingsScreenMinSpeed:
            return OALocalizedString(@"monitoring_min_speed");
        case kTripRecordingSettingsScreenMinDistance:
            return OALocalizedString(@"monitoring_min_distance");
        default:
            return OALocalizedString(@"record_plugin_name");
    }
}

- (BOOL) refreshOnAppear
{
    return YES;
}

- (NSArray<UIBarButtonItem *> *)getRightNavbarButtons
{
    UIBarButtonItem *rightButton = [self createRightNavbarButton:nil iconName:@"ic_navbar_reset" action:@selector(onRightNavbarButtonPressed) menu:nil];
    rightButton.accessibilityLabel = OALocalizedString(@"reset_to_default");
    return @[rightButton];
}

- (void)onRightNavbarButtonPressed
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:OALocalizedString(@"reset_to_default") message:OALocalizedString(@"reset_plugin_to_default") preferredStyle:UIAlertControllerStyleActionSheet];
    UIPopoverPresentationController *popPresenter = [alert popoverPresentationController];
    popPresenter.sourceView = self.view;
    popPresenter.barButtonItem = self.navigationItem.rightBarButtonItem;
    popPresenter.permittedArrowDirections = UIPopoverArrowDirectionAny;

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel") style:UIAlertActionStyleCancel handler:nil];

    UIAlertAction *resetAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_reset") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action)
    {
        [_settings.mapSettingSaveTrackIntervalApproved resetModeToDefault:self.appMode];
        [_settings.mapSettingSaveTrackIntervalGlobal resetModeToDefault:self.appMode];
        [_settings.mapSettingSaveTrackInterval resetModeToDefault:self.appMode];
        [_settings.saveTrackMinDistance resetModeToDefault:self.appMode];
        [_settings.saveTrackPrecision resetModeToDefault:self.appMode];
        [_settings.saveTrackMinSpeed resetModeToDefault:self.appMode];
        [_settings.saveHeadingToGpx resetModeToDefault:self.appMode];
        [_settings.saveTrackToGPX resetModeToDefault:self.appMode];
        [_settings.autoSplitRecording resetModeToDefault:self.appMode];
        [_settings.mapSettingSaveTrackIntervalGlobal resetModeToDefault:self.appMode];
        [_settings.mapSettingSaveTrackInterval resetModeToDefault:self.appMode];
        [self generateData];
        [self.tableView reloadData];
    }];

    [alert addAction:resetAction];
    [alert addAction:cancelAction];
    alert.preferredAction = resetAction;

    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Table data

- (void)generateData
{
    OAAppSettings* settings = [OAAppSettings sharedManager];
    NSMutableArray *dataArr = [NSMutableArray array];
    switch (self.settingsType)
    {
        case kTripRecordingSettingsScreenGeneral:
        {
            NSString *recIntervalValue = [settings getFormattedTrackInterval:[settings.mapSettingSaveTrackIntervalGlobal get:self.appMode]];
            NSString *navIntervalValue = [settings getFormattedTrackInterval:[settings.mapSettingSaveTrackInterval get:self.appMode]];
            
            NSString *minDistValue = [OAUtilities appendMeters:[settings.saveTrackMinDistance get:self.appMode]];
            NSString *minPrecision = [OAUtilities appendMeters:[settings.saveTrackPrecision get:self.appMode]];
            NSString *minSpeed = [OAUtilities appendSpeed:[settings.saveTrackMinSpeed get:self.appMode] * MPS_TO_KMH_MULTIPLIER];
            
            [dataArr addObject:
             @[@{
                   @"header" : OALocalizedString(@"save_track_logging_accuracy"),
                   @"name" : @"rec_interval",
                   @"title" : OALocalizedString(@"save_global_track_interval"),
                   @"description" : OALocalizedString(@"save_global_track_interval_descr"),
                   @"value" : ![settings.mapSettingSaveTrackIntervalApproved get:self.appMode] ? OALocalizedString(@"confirm_every_run") : recIntervalValue,
                   @"type" : [OAValueTableViewCell getCellIdentifier] }
             ]];
            
            [dataArr addObject:
             @[@{
                   @"name" : @"logging_min_distance",
                   @"title" : OALocalizedString(@"monitoring_min_distance"),
                   @"description" : OALocalizedString(@"logging_min_distance_descr"),
                   @"value" : minDistValue,
                   @"type" : [OAValueTableViewCell getCellIdentifier] }
             ]];
            
            [dataArr addObject:
             @[@{
                   @"name" : @"logging_min_accuracy",
                   @"title" : OALocalizedString(@"monitoring_min_accuracy"),
                   @"description" : OALocalizedString(@"logging_min_accuracy_descr"),
                   @"value" : minPrecision,
                   @"type" : [OAValueTableViewCell getCellIdentifier] }
             ]];
            
            [dataArr addObject:
             @[@{
                   @"name" : @"logging_min_speed",
                   @"title" : OALocalizedString(@"monitoring_min_speed"),
                   @"description" : OALocalizedString(@"logging_min_speed_descr"),
                   @"value" : minSpeed,
                   @"type" : [OAValueTableViewCell getCellIdentifier] }
             ]];
            
            [dataArr addObject:
             @[@{
                 @"name" : @"incl_heading",
                 @"title" : OALocalizedString(@"save_heading"),
                 @"description" : OALocalizedString(@"save_heading_descr"),
                 @"value" : @([_settings.saveHeadingToGpx get:self.appMode]),
                 @"type" : [OASwitchTableViewCell getCellIdentifier]
                }
             ]];
            
            _navigationSection = (int) dataArr.count;
            [dataArr addObject:
             @[@{
                   @"header" : OALocalizedString(@"routing_settings"),
                   @"name" : @"track_during_nav",
                   @"title" : OALocalizedString(@"save_track_to_gpx"),
                   @"description" : [NSString stringWithFormat:@"%@ %@", OALocalizedString(@"save_track_to_gpx_descrp"), OALocalizedString(@"logging_interval_navigation_descr")],
                   @"value" : _settings.saveTrackToGPX,
                   @"img" : @"ic_custom_navigation",
                   @"type" : [OASwitchTableViewCell getCellIdentifier] },
               @{
                   @"name" : @"logging_interval_navigation",
                   @"title" : OALocalizedString(@"save_track_interval"),
                   @"value" : navIntervalValue,
                   @"img" : @"ic_custom_timer",
                   @"type" : [OAValueTableViewCell getCellIdentifier],
                   @"key" : @"nav_interval"
               }
             ]];
            
            [dataArr addObject:
             @[@{
                 @"header" : OALocalizedString(@"other_location"),
                 @"name" : @"auto_split_gap",
                 @"title" : OALocalizedString(@"auto_split_recording_title"),
                 @"description" : OALocalizedString(@"auto_split_gap_descr"),
                 @"value" : @([_settings.autoSplitRecording get:self.appMode]),
                 @"type" : [OASwitchTableViewCell getCellIdentifier] }]];

            if ([OAPlugin isEnabled:OAExternalSensorsPlugin.class])
            {
                NSInteger devices = 0;
                NSInteger devicesAll = 0;
                OAExternalSensorsPlugin *plugin = (OAExternalSensorsPlugin *) [OAPlugin getEnabledPlugin:OAExternalSensorsPlugin.class];
                if (plugin)
                {
                    NSArray<OAWidgetType *> *externalSensorTrackDataType = [plugin getExternalSensorTrackDataType];
                    devicesAll = externalSensorTrackDataType.count;
                    for (OAWidgetType *widgetType in externalSensorTrackDataType)
                    {
                        OACommonString *deviceIdPref = [plugin getWriteToTrackDeviceIdPref:widgetType];
                        if (deviceIdPref)
                        {
                            NSString *deviceId = [deviceIdPref get:self.appMode];
                            if (deviceId && deviceId.length > 0)
                            {
                                if ([deviceId isEqualToString:[plugin getAnyConnectedDeviceId]])
                                {
                                    if ([[OADeviceHelper shared] getConnectedDevicesForWidgetWithType:widgetType].firstObject)
                                    {
                                        devices++;
                                    }
                                }
                                else
                                {
                                    if ([[OADeviceHelper shared] getPairedDevicesForType:widgetType deviceId:deviceId])
                                    {
                                        devices++;
                                    }
                                }
                            }
                        }
                    }
                }
                [dataArr addObject:
                 @[@{
                     @"name" : @"externalSensors",
                     @"title" : OALocalizedString(@"external_sensors_plugin_name"),
                     @"value" : [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_slash"), @(devices).stringValue, @(devicesAll).stringValue],
                     @"type" : [OAValueTableViewCell getCellIdentifier] }]];
            }

            NSString *menuPath = [NSString stringWithFormat:@"%@ — %@ — %@", OALocalizedString(@"shared_string_menu"), OALocalizedString(@"shared_string_my_places"), OALocalizedString(@"menu_my_trips")];
            NSString *actionsDescr = [NSString stringWithFormat:OALocalizedString(@"trip_rec_actions_descr"), menuPath];
            NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:actionsDescr attributes:@{NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline], NSForegroundColorAttributeName : [UIColor colorNamed:ACColorNameTextColorSecondary]}];
            [str addAttributes:@{NSFontAttributeName : [UIFont scaledSystemFontOfSize:15 weight:UIFontWeightSemibold]} range:[actionsDescr rangeOfString:menuPath]];
            
            [dataArr addObject:@[
                @{
                    @"type" : [OASimpleTableViewCell getCellIdentifier],
                    @"title" : str,
                    @"header" : OALocalizedString(@"shared_string_actions")
                },
                @{
                    @"type" : [OARightIconTableViewCell getCellIdentifier],
                    @"title" : OALocalizedString(@"shared_string_gpx_tracks"),
                    @"img" : @"ic_custom_folder",
                    @"name" : @"open_trips"
                },
                @{
                    @"type" : [OARightIconTableViewCell getCellIdentifier],
                    @"title" : OALocalizedString(@"reset_plugin_to_default"),
                    @"img" : @"ic_custom_reset",
                    @"name" : @"reset_plugin"
                },
                // TODO: add copy from profile
//                @{
//                    @"type" : [OARightIconTableViewCell getCellIdentifier],
//                    @"title" : OALocalizedString(@"shared_string_gpx_tracks"),
//                    @"img" : @"ic_custom_folder",
//                    @"key" : @"open_trips"
//                }
            ]];
            
            break;
        }
        case kTripRecordingSettingsScreenRecInterval:
        {
            BOOL alwaysAsk = ![settings.mapSettingSaveTrackIntervalApproved get:self.appMode];
            [dataArr addObject:@{
                @"title" : OALocalizedString(@"confirm_every_run"),
                @"value" : @"always_ask",
                @"img" : alwaysAsk ? @"menu_cell_selected.png" : @"",
                @"type" : kCellTypeCheck
            }];
            for (NSNumber *num in settings.trackIntervalArray)
            {
                [dataArr addObject: @{
                                  @"title" : [settings getFormattedTrackInterval:[num intValue]],
                                  @"value" : @"",
                                  @"img" : ([settings.mapSettingSaveTrackIntervalGlobal get:self.appMode] == [num intValue] && !alwaysAsk)
                                  ? @"menu_cell_selected.png" : @"",
                                  @"type" : kCellTypeCheck }];
            }
            break;
        }
        case kTripRecordingSettingsScreenNavRecInterval:
        {
            for (NSNumber *num in settings.trackIntervalArray)
            {
                [dataArr addObject: @{
                                      @"title" : [settings getFormattedTrackInterval:[num intValue]],
                                      @"value" : @"",
                                      @"img" : ([settings.mapSettingSaveTrackInterval get:self.appMode] == [num intValue])
                                      ? @"menu_cell_selected.png" : @"", @"type" : kCellTypeCheck }];
            }
            break;
        }
        case kTripRecordingSettingsScreenAccuracy:
            for (int i = 0; i < trackPrecisionValues.count; i++)
            {
                [dataArr addObject: @{
                                      @"title" : trackPrecisionNames[i],
                                      @"value" : @"",
                                      @"img" : ([settings.saveTrackPrecision get:self.appMode] == trackPrecisionValues[i].floatValue)
                                      ? @"menu_cell_selected.png" : @"", @"type" : kCellTypeCheck }];
            }
            break;
        case kTripRecordingSettingsScreenMinSpeed:
            for (int i = 0; i < minTrackSpeedValues.count; i++)
            {
                [dataArr addObject: @{
                                      @"title" : minTrackSpeedNames[i],
                                      @"value" : @"",
                                      @"img" : ([settings.saveTrackMinSpeed get:self.appMode] == minTrackSpeedValues[i].floatValue / MPS_TO_KMH_MULTIPLIER)
                                      ? @"menu_cell_selected.png" : @"", @"type" : kCellTypeCheck }];
            }
            break;
        case kTripRecordingSettingsScreenMinDistance:
            for (int i = 0; i < minTrackDistanceValues.count; i++)
            {
                [dataArr addObject: @{
                                      @"title" : minTrackDistanceNames[i],
                                      @"value" : @"",
                                      @"img" : ([settings.saveTrackMinDistance get:self.appMode] == minTrackDistanceValues[i].floatValue)
                                      ? @"menu_cell_selected.png" : @"", @"type" : kCellTypeCheck }];
            }
            break;
        default:
            break;
    }
    
    _data = [NSArray arrayWithArray:dataArr];
}

- (NSDictionary *) getItem:(NSIndexPath *)indexPath
{
    if (_settingsType == kTripRecordingSettingsScreenGeneral)
        return _data[indexPath.section][indexPath.row];
    else
        return _data[indexPath.row];
}

- (NSString *)getTitleForHeader:(NSInteger)section
{
    if (_settingsType == kTripRecordingSettingsScreenGeneral)
    {
        NSDictionary *item = ((NSArray *)_data[section]).firstObject;
        return item[@"header"];
    }
    return nil;
}

- (NSString *)getTitleForFooter:(NSInteger)section
{
    if (_settingsType == kTripRecordingSettingsScreenGeneral)
    {
        NSDictionary *item = ((NSArray *)_data[section]).firstObject;
        return item[@"description"];
    }
    else
    {
        return nil;
    }
}

- (NSInteger)rowsCount:(NSInteger)section
{
    if (section == _navigationSection)
    {
        OACommonBoolean *value = [self getItem:[NSIndexPath indexPathForRow:0 inSection:_navigationSection]][@"value"];
        BOOL isAutoRecordOn = [value get:self.appMode];
        return isAutoRecordOn ? 2 : 1;
    }
    
    if (_settingsType == kTripRecordingSettingsScreenGeneral)
    {
        NSArray *sectionData = _data[section];
        return sectionData.count;
    }
    else
    {
        return _data.count;
    }
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    NSString *type = item[@"type"];
    
    if ([type isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
    {
        OASwitchTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *) nib[0];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            id v = item[@"value"];
            if ([v isKindOfClass:[OACommonBoolean class]])
            {
                OACommonBoolean *value = v;
                [cell.switchView removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
                cell.switchView.on = [value get:self.appMode];
            }
            else
            {
                cell.switchView.on = [v boolValue];
            }
            
            cell.titleLabel.text = item[@"title"];

            NSString *iconName = item[@"img"];
            [cell leftIconVisibility:iconName && iconName.length > 0];
            cell.leftIconView.tintColor = cell.switchView.isOn ? UIColorFromRGB(self.appMode.getIconColor) : [UIColor colorNamed:ACColorNameIconColorDisabled];
            cell.leftIconView.image = [UIImage templateImageNamed:iconName];
            cell.separatorInset = UIEdgeInsetsMake(0., iconName && iconName.length > 0 ? kPaddingToLeftOfContentWithIcon : kPaddingOnSideOfContent, 0., 0.);

            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView addTarget:self action:@selector(applyParameter:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    else if ([type isEqualToString:[OAValueTableViewCell getCellIdentifier]])
    {
        OAValueTableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAValueTableViewCell *)[nib objectAtIndex:0];
            [cell descriptionVisibility:NO];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            cell.valueLabel.text = item[@"value"];
            
            if ([item[@"key"] isEqualToString:@"nav_interval"] && ![_settings.saveTrackToGPX get:self.appMode])
            {
                for (UIView *vw in cell.subviews)
                    vw.alpha = 0.4;
                cell.userInteractionEnabled = NO;
                cell.leftIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorDisabled];
            }
            else
            {
                for (UIView *vw in cell.subviews)
                    vw.alpha = 1;
                cell.userInteractionEnabled = YES;
                cell.leftIconView.tintColor = UIColorFromRGB(self.appMode.getIconColor);
            }
            
            NSString *img = item[@"img"];
            if (img)
                cell.leftIconView.image = [UIImage templateImageNamed:img];

            [cell leftIconVisibility:img != nil];
        }
        return cell;
    }
    else if ([type isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        OASimpleTableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASimpleTableViewCell *)[nib objectAtIndex:0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
            [cell setCustomLeftSeparatorInset:YES];
            cell.separatorInset = UIEdgeInsetsMake(0., DBL_MAX, 0., 0.);
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        }
        if (cell)
        {
            cell.titleLabel.attributedText = item[@"title"];
        }
        return cell;
    }
    else if ([type isEqualToString:[OARightIconTableViewCell getCellIdentifier]])
    {
        OARightIconTableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OARightIconTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OARightIconTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OARightIconTableViewCell *)[nib objectAtIndex:0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
            cell.titleLabel.textColor = [UIColor colorNamed:ACColorNameTextColorActive];
            cell.rightIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
            cell.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            [cell.rightIconView setImage:[UIImage templateImageNamed:item[@"img"]]];
        }
        return cell;
    }
    else if ([type isEqualToString:kCellTypeCheck])
    {
        OASimpleTableViewCell* cell = nil;
        
        cell = [self.tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASimpleTableViewCell *)[nib objectAtIndex:0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
        }
        
        if (cell)
        {
            [cell.titleLabel setText: item[@"title"]];
            UIImage *image = [UIImage imageNamed:item[@"img"]];
            cell.accessoryType = image ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        }
        return cell;
    }
    return nil;
}

- (NSInteger)sectionsCount
{
    if (_settingsType == kTripRecordingSettingsScreenGeneral)
        return _data.count;
    else
        return 1;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    switch (_settingsType)
    {
        case kTripRecordingSettingsScreenGeneral:
            [self selectGeneral:item];
            break;
        case kTripRecordingSettingsScreenRecInterval:
            if ([item[@"value"] isEqualToString:@"always_ask"]) {
                [_settings.mapSettingSaveTrackIntervalApproved set:NO mode:self.appMode];
                [self dismissViewController];
            } else {
                [self selectRecInterval:indexPath.row - 1];
            }
            break;
        case kTripRecordingSettingsScreenNavRecInterval:
            [self selectNavRecInterval:indexPath.row];
            break;
        case kTripRecordingSettingsScreenMinDistance:
            [self selectMinDistance:indexPath.row];
            break;
        case kTripRecordingSettingsScreenMinSpeed:
            [self selectMinSpeed:indexPath.row];
            break;
        case kTripRecordingSettingsScreenAccuracy:
            [self selectAccuracy:indexPath.row];
            break;
        default:
            break;
    }
}

#pragma mark - Selectors

- (void) applyParameter:(id)sender
{
    if ([sender isKindOfClass:[UISwitch class]])
    {
        UISwitch *sw = (UISwitch *) sender;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sw.tag & 0x3FF inSection:sw.tag >> 10];
        NSDictionary *item = [self getItem:indexPath];

        BOOL isChecked = ((UISwitch *) sender).on;
        id v = item[@"value"];
        NSString *name = item[@"name"];
        
        if ([v isKindOfClass:[OACommonBoolean class]])
        {
            OACommonBoolean *value = v;
            [value set:isChecked mode:self.appMode];
            if ([name isEqualToString:@"track_during_nav"])
            {
                [self updateNavigationSection:isChecked];
            }
        }
        else if ([name isEqualToString:@"auto_split_gap"])
        {
            [_settings.autoSplitRecording set:isChecked mode:self.appMode];
        }
        else if ([name isEqualToString:@"incl_heading"])
        {
            [_settings.saveHeadingToGpx set:isChecked mode:self.appMode];
        }
    }
}

- (void) updateNavigationSection:(BOOL)isOn
{
    if (isOn)
    {
        [self.tableView beginUpdates];
        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:_navigationSection]] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:_navigationSection] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }
    else
    {
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:_navigationSection]] withRowAnimation:(UITableViewRowAnimation)UITableViewRowAnimationFade];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:_navigationSection] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }
}

- (void) selectRecInterval:(NSInteger)index
{
    [_settings.mapSettingSaveTrackIntervalApproved set:YES mode:self.appMode];
    [_settings.mapSettingSaveTrackIntervalGlobal set:[_settings.trackIntervalArray[index] intValue] mode:self.appMode];
    [self dismissViewController];
}

- (void) selectNavRecInterval:(NSInteger)index
{
    [_settings.mapSettingSaveTrackInterval set:[_settings.trackIntervalArray[index] intValue] mode:self.appMode];
    [self dismissViewController];
}

- (void) selectMinDistance:(NSInteger)index
{
    [_settings.saveTrackMinDistance set:minTrackDistanceValues[index].doubleValue mode:self.appMode];
    [self dismissViewController];
}

- (void) selectMinSpeed:(NSInteger)index
{
    [_settings.saveTrackMinSpeed set:minTrackSpeedValues[index].doubleValue / MPS_TO_KMH_MULTIPLIER mode:self.appMode];
    [self dismissViewController];
}

- (void) selectAccuracy:(NSInteger)index
{
    [_settings.saveTrackPrecision set:trackPrecisionValues[index].doubleValue mode:self.appMode];
    [self dismissViewController];
}

- (void) selectGeneral:(NSDictionary *)item
{
    NSString *name = item[@"name"];
    if ([@"rec_interval" isEqualToString:name])
    {
        OATripRecordingSettingsViewController* settingsViewController = [[OATripRecordingSettingsViewController alloc] initWithSettingsType:kTripRecordingSettingsScreenRecInterval applicationMode:self.appMode];
        [self.navigationController pushViewController:settingsViewController animated:YES];
    }
    else if ([@"logging_interval_navigation" isEqualToString:name])
    {
        OATripRecordingSettingsViewController* settingsViewController = [[OATripRecordingSettingsViewController alloc] initWithSettingsType:kTripRecordingSettingsScreenNavRecInterval applicationMode:self.appMode];
        [self.navigationController pushViewController:settingsViewController animated:YES];
    }
    else if ([@"logging_min_accuracy" isEqualToString:name])
    {
        OATripRecordingSettingsViewController* settingsViewController = [[OATripRecordingSettingsViewController alloc] initWithSettingsType:kTripRecordingSettingsScreenAccuracy applicationMode:self.appMode];
        [self.navigationController pushViewController:settingsViewController animated:YES];
    }
    else if ([@"logging_min_distance" isEqualToString:name])
    {
        OATripRecordingSettingsViewController* settingsViewController = [[OATripRecordingSettingsViewController alloc] initWithSettingsType:kTripRecordingSettingsScreenMinDistance applicationMode:self.appMode];
        [self.navigationController pushViewController:settingsViewController animated:YES];
    }
    else if ([@"logging_min_speed" isEqualToString:name])
    {
        OATripRecordingSettingsViewController* settingsViewController = [[OATripRecordingSettingsViewController alloc] initWithSettingsType:kTripRecordingSettingsScreenMinSpeed applicationMode:self.appMode];
        [self.navigationController pushViewController:settingsViewController animated:YES];
    }
    else if ([@"open_trips" isEqualToString:name])
    {
        UITabBarController* myPlacesViewController = [[UIStoryboard storyboardWithName:@"MyPlaces" bundle:nil] instantiateInitialViewController];
        [myPlacesViewController setSelectedIndex:1];
        
        TracksViewController *gpxController = myPlacesViewController.viewControllers[1];
        if (gpxController == nil)
            return;
        
        [self.navigationController pushViewController:myPlacesViewController animated:YES];
    }
    else if ([@"reset_plugin" isEqualToString:name])
    {
        [_settings.mapSettingSaveTrackIntervalApproved resetModeToDefault:self.appMode];
        [_settings.mapSettingSaveTrackIntervalGlobal resetModeToDefault:self.appMode];
        [_settings.mapSettingSaveTrackInterval resetModeToDefault:self.appMode];
        [_settings.saveTrackMinSpeed resetModeToDefault:self.appMode];
        [_settings.saveTrackMinDistance resetModeToDefault:self.appMode];
        [_settings.saveTrackPrecision resetModeToDefault:self.appMode];
        [_settings.saveTrackToGPX resetModeToDefault:self.appMode];
        [_settings.autoSplitRecording resetModeToDefault:self.appMode];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.tableView.numberOfSections)] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    else if ([name isEqualToString:@"externalSensors"])
    {
        OAExternalSettingsWriteToTrackSettingsViewController *contoller = [[OAExternalSettingsWriteToTrackSettingsViewController alloc] initWithApplicationMode:self.appMode];
        [self showViewController:contoller];
    }
}

@end
