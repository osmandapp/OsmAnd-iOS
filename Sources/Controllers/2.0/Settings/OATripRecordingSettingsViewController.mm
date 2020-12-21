//
//  OATripRecordingSettingsViewController.m
//  OsmAnd
//
//  Created by Paul on 8/29/18.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OATripRecordingSettingsViewController.h"
#import "OAGPXListViewController.h"
#import "OAIconTextDescSwitchCell.h"
#import "OASettingsTableViewCell.h"
#import "OASettingsTitleTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OAAppSettings.h"
#import "Localization.h"
#import "OAUtilities.h"
#import "OsmAndApp.h"
#import "OARoutingHelper.h"
#import "OAFileNameTranslationHelper.h"
#import "OASavingTrackHelper.h"
#import "OAIconTitleValueCell.h"
#import "OASettingSwitchCell.h"
#import "OAIconTextTableViewCell.h"
#import "OATitleRightIconCell.h"
#import "OAColors.h"

#include <generalRouter.h>

#define kCellTypeProfileSwitch @"OAIconTextDescSwitchCell"
#define kCellTypeIconTitleValue @"OAIconTitleValueCell"
#define kCellTypeSettingSwitch @"OASettingSwitchCell"
#define kCellTypeTitle @"OAIconTextCell"
#define kCellTypeAction @"OATitleRightIconCell"
#define kCellTypeSwitch @"switch"
#define kCellTypeSingleSelectionList @"single_selection_list"
#define kCellTypeMultiSelectionList @"multi_selection_list"
#define kCellTypeCheck @"check"
#define kNavigationSection 4

@interface OATripRecordingSettingsViewController ()

@property (nonatomic) NSDictionary *settingItem;

@end

@implementation OATripRecordingSettingsViewController
{
    NSArray *_data;
    
    OAAppSettings *_settings;
    OASavingTrackHelper *_recHelper;
}

static NSArray<NSNumber *> *minTrackDistanceValues;
static NSArray<NSString *> *minTrackDistanceNames;
static NSArray<NSNumber *> *trackPrecisionValues;
static NSArray<NSString *> *trackPrecisionNames;
static NSArray<NSNumber *> *minTrackSpeedValues;
static NSArray<NSString *> *minTrackSpeedNames;


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
    }
    return self;
}

- (void) applyLocalization
{
    [super applyLocalization];
    self.titleLabel.text = OALocalizedString(@"product_title_track_recording");
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.estimatedRowHeight = kEstimatedRowHeight;
    self.tableView.separatorColor =  UIColorFromRGB(color_tint_gray);
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillAppear:(BOOL)animated
{
    [self setupView];
}

- (void) setupView
{
    [self.backButton setImage:self.backButton.imageView.image.imageFlippedForRightToLeftLayoutDirection forState:UIControlStateNormal];
    [self applySafeAreaMargins];
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
            NSString *minSpeed = [OAUtilities appendSpeed:[settings.saveTrackMinSpeed get:self.appMode]];
            
            [dataArr addObject:
             @[@{
                   @"header" : OALocalizedString(@"logging_accuracy"),
                   @"name" : @"rec_interval",
                   @"title" : OALocalizedString(@"save_global_track_interval"),
                   @"description" : OALocalizedString(@"save_global_track_interval_descr"),
                   @"value" : ![settings.mapSettingSaveTrackIntervalApproved get:self.appMode] ? OALocalizedString(@"shared_setting_always_ask") : recIntervalValue,
                   @"type" : kCellTypeIconTitleValue }
             ]];
            
            [dataArr addObject:
             @[@{
                   @"name" : @"logging_min_distance",
                   @"title" : OALocalizedString(@"logging_min_distance"),
                   @"description" : OALocalizedString(@"logging_min_distance_descr"),
                   @"value" : minDistValue,
                   @"type" : kCellTypeIconTitleValue }
             ]];
            
            [dataArr addObject:
             @[@{
                   @"name" : @"logging_min_accuracy",
                   @"title" : OALocalizedString(@"logging_min_accuracy"),
                   @"description" : OALocalizedString(@"logging_min_accuracy_descr"),
                   @"value" : minPrecision,
                   @"type" : kCellTypeIconTitleValue }
             ]];
            
            [dataArr addObject:
             @[@{
                   @"name" : @"logging_min_speed",
                   @"title" : OALocalizedString(@"logging_min_speed"),
                   @"description" : OALocalizedString(@"logging_min_speed_descr"),
                   @"value" : minSpeed,
                   @"type" : kCellTypeIconTitleValue }
             ]];
            
            [dataArr addObject:
             @[@{
                   @"header" : OALocalizedString(@"routing_settings"),
                   @"name" : @"track_during_nav",
                   @"title" : OALocalizedString(@"track_during_nav"),
                   @"description" : [NSString stringWithFormat:@"%@ %@", OALocalizedString(@"track_during_nav_descr"), OALocalizedString(@"logging_interval_navigation_descr")],
                   @"value" : _settings.saveTrackToGPX,
                   @"img" : @"ic_custom_navigation",
                   @"type" : kCellTypeSettingSwitch },
               @{
                   @"name" : @"logging_interval_navigation",
                   @"title" : OALocalizedString(@"logging_interval_navigation"),
                   @"value" : navIntervalValue,
                   @"img" : @"ic_custom_timer",
                   @"type" : kCellTypeIconTitleValue,
                   @"key" : @"nav_interval"
               }
             ]];
            
            [dataArr addObject:
             @[@{
                 @"header" : OALocalizedString(@"help_other_header"),
                 @"name" : @"auto_split_gap",
                 @"title" : OALocalizedString(@"auto_split_gap"),
                 @"description" : OALocalizedString(@"auto_split_gap_descr"),
                 @"value" : @([_settings.autoSplitRecording get:self.appMode]),
                 @"img" : @"menu_cell_pointer.png",
                 @"type" : kCellTypeSwitch }]];
            
            NSString *menuPath = [NSString stringWithFormat:@"%@ — %@ — %@", OALocalizedString(@"menu"), OALocalizedString(@"menu_my_places"), OALocalizedString(@"menu_my_trips")];
            NSString *actionsDescr = [NSString stringWithFormat:OALocalizedString(@"trip_rec_actions_descr"), menuPath];
            NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:actionsDescr attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:15], NSForegroundColorAttributeName : UIColorFromRGB(color_text_footer)}];
            [str addAttributes:@{NSFontAttributeName : [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold]} range:[actionsDescr rangeOfString:menuPath]];
            
            [dataArr addObject:@[
                @{
                    @"type" : kCellTypeTitle,
                    @"title" : str,
                    @"header" : OALocalizedString(@"actions")
                },
                @{
                    @"type" : kCellTypeAction,
                    @"title" : OALocalizedString(@"tracks"),
                    @"img" : @"ic_custom_folder",
                    @"name" : @"open_trips"
                },
                @{
                    @"type" : kCellTypeAction,
                    @"title" : OALocalizedString(@"plugin_settings_reset"),
                    @"img" : @"ic_custom_reset",
                    @"name" : @"reset_plugin"
                },
                // TODO: add copy from profile
//                @{
//                    @"type" : kCellTypeAction,
//                    @"title" : OALocalizedString(@"tracks"),
//                    @"img" : @"ic_custom_folder",
//                    @"key" : @"open_trips"
//                }
            ]];
            
            break;
        }
        case kTripRecordingSettingsScreenRecInterval:
        {
            self.titleLabel.text = OALocalizedString(@"rec_interval");
            BOOL alwaysAsk = ![settings.mapSettingSaveTrackIntervalApproved get:self.appMode];
            [dataArr addObject:@{
                @"title" : OALocalizedString(@"shared_setting_always_ask"),
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
            self.titleLabel.text = OALocalizedString(@"rec_interval");
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
            self.titleLabel.text = OALocalizedString(@"logging_min_accuracy");
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
            self.titleLabel.text = OALocalizedString(@"logging_min_speed");
            for (int i = 0; i < minTrackSpeedValues.count; i++)
            {
                [dataArr addObject: @{
                                      @"title" : minTrackSpeedNames[i],
                                      @"value" : @"",
                                      @"img" : ([settings.saveTrackMinSpeed get:self.appMode] == minTrackSpeedValues[i].floatValue)
                                      ? @"menu_cell_selected.png" : @"", @"type" : kCellTypeCheck }];
            }
            break;
        case kTripRecordingSettingsScreenMinDistance:
            self.titleLabel.text = OALocalizedString(@"logging_min_distance");
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
    
    [self.tableView reloadData];
}

- (NSDictionary *) getItem:(NSIndexPath *)indexPath
{
    if (_settingsType == kTripRecordingSettingsScreenGeneral)
        return _data[indexPath.section][indexPath.row];
    else
        return _data[indexPath.row];
}

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
        
        if ([v isKindOfClass:[OAProfileBoolean class]])
        {
            OAProfileBoolean *value = v;
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
    }
}

- (void) updateNavigationSection:(BOOL)isOn
{
    if (isOn)
    {
        [self.tableView beginUpdates];
        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:kNavigationSection]] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:kNavigationSection] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }
    else
    {
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:kNavigationSection]] withRowAnimation:(UITableViewRowAnimation)UITableViewRowAnimationFade];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:kNavigationSection] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    if (_settingsType == kTripRecordingSettingsScreenGeneral)
        return _data.count;
    else
        return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == kNavigationSection)
    {
        OAProfileBoolean *value = [self getItem:[NSIndexPath indexPathForRow:0 inSection:kNavigationSection]][@"value"];
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

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    NSString *type = item[@"type"];
    
    if ([type isEqualToString:kCellTypeSwitch])
    {
        static NSString* const identifierCell = @"OASwitchTableViewCell";
        OASwitchTableViewCell* cell = nil;
        
        cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASwitchCell" owner:self options:nil];
            cell = (OASwitchTableViewCell *)[nib objectAtIndex:0];
            cell.textView.numberOfLines = 0;
        }
        
        if (cell)
        {
            [cell.textView setText: item[@"title"]];
            id v = item[@"value"];
            if ([v isKindOfClass:[OAProfileBoolean class]])
            {
                OAProfileBoolean *value = v;
                [cell.switchView removeTarget:NULL action:NULL forControlEvents:UIControlEventAllEvents];
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
    else if ([type isEqualToString:kCellTypeIconTitleValue])
    {
        static NSString* const identifierCell = kCellTypeIconTitleValue;
        OAIconTitleValueCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OAIconTitleValueCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
            cell.iconView.image = [[UIImage imageNamed:@"ic_custom_arrow_right"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate].imageFlippedForRightToLeftLayoutDirection;
            cell.iconView.tintColor = UIColorFromRGB(color_tint_gray);
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.descriptionView.text = item[@"value"];
            
            if ([item[@"key"] isEqualToString:@"nav_interval"] && ![_settings.saveTrackToGPX get:self.appMode])
            {
                for (UIView *vw in cell.subviews)
                    vw.alpha = 0.4;
                cell.userInteractionEnabled = NO;
                cell.leftImageView.tintColor = UIColorFromRGB(color_icon_inactive);
            }
            else
            {
                for (UIView *vw in cell.subviews)
                    vw.alpha = 1;
                cell.userInteractionEnabled = YES;
                cell.leftImageView.tintColor = UIColorFromRGB(self.appMode.getIconColor);
            }
            
            NSString *img = item[@"img"];
            if (img)
                cell.leftImageView.image = [[UIImage imageNamed:img] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            
            [cell showImage:img != nil];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:kCellTypeSettingSwitch])
    {
        static NSString* const identifierCell = kCellTypeSettingSwitch;
        OASettingSwitchCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kCellTypeSettingSwitch owner:self options:nil];
            cell = (OASettingSwitchCell *)[nib objectAtIndex:0];
            cell = (OASettingSwitchCell *)[nib objectAtIndex:0];
            cell.descriptionView.hidden = YES;
            cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        
        if (cell)
        {
            id v = item[@"value"];
            if ([v isKindOfClass:[OAProfileBoolean class]])
            {
                OAProfileBoolean *value = v;
                [cell.switchView removeTarget:NULL action:NULL forControlEvents:UIControlEventAllEvents];
                cell.switchView.on = [value get:self.appMode];
            }
            else
            {
                cell.switchView.on = [v boolValue];
            }
            cell.imgView.tintColor = cell.switchView.isOn ? UIColorFromRGB(self.appMode.getIconColor) : UIColorFromRGB(color_icon_inactive);
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView addTarget:self action:@selector(applyParameter:) forControlEvents:UIControlEventValueChanged];
            
            cell.textView.text = item[@"title"];
            cell.imgView.image = [[UIImage imageNamed:item[@"img"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        }
        return cell;
    }
    else if ([type isEqualToString:kCellTypeTitle])
    {
        static NSString* const identifierCell = kCellTypeTitle;
        OAIconTextTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OAIconTextTableViewCell *)[nib objectAtIndex:0];
            cell.arrowIconView.hidden = YES;
            cell.iconView.hidden = YES;
            cell.separatorInset = UIEdgeInsetsMake(0., DBL_MAX, 0., 0.);
            cell.textView.numberOfLines = 0;
            cell.textView.lineBreakMode = NSLineBreakByWordWrapping;
        }
        if (cell)
        {
            cell.textView.attributedText = item[@"title"];
        }
        return cell;
    }
    else if ([type isEqualToString:kCellTypeAction])
    {
        static NSString* const identifierCell = kCellTypeAction;
        OATitleRightIconCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kCellTypeAction owner:self options:nil];
            cell = (OATitleRightIconCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0.0, 16.0, 0.0, 0.0);
            cell.titleView.textColor = UIColorFromRGB(color_primary_purple);
            cell.iconView.tintColor = UIColorFromRGB(color_primary_purple);
            cell.titleView.font = [UIFont systemFontOfSize:17. weight:UIFontWeightSemibold];
        }
        cell.titleView.text = item[@"title"];
        [cell.iconView setImage:[[UIImage imageNamed:item[@"img"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        return cell;
    }
    else if ([type isEqualToString:kCellTypeSingleSelectionList] || [type isEqualToString:kCellTypeMultiSelectionList])
    {
        static NSString* const identifierCell = @"OASettingsTableViewCell";
        OASettingsTableViewCell* cell = nil;
        
        cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASettingsCell" owner:self options:nil];
            cell = (OASettingsTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            [cell.textView setText: item[@"title"]];
            [cell.descriptionView setText: item[@"value"]];
            UIImage *image = [UIImage imageNamed:item[@"img"]];
            [cell.iconView setImage:image];
        }
        return cell;
    }
    else if ([type isEqualToString:kCellTypeCheck])
    {
        static NSString* const identifierCell = @"OASettingsTitleTableViewCell";
        OASettingsTitleTableViewCell* cell = nil;
        
        cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASettingsTitleCell" owner:self options:nil];
            cell = (OASettingsTitleTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            [cell.textView setText: item[@"title"]];
            UIImage *image = [UIImage imageNamed:item[@"img"]];
            [cell.iconView setImage:image];
        }
        return cell;
    }
    return nil;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (_settingsType == kTripRecordingSettingsScreenGeneral)
    {
        NSDictionary *item = ((NSArray *)_data[section]).firstObject;
        return item[@"header"];
    }
    return nil;
}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
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

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    [header.textLabel setTextColor:UIColorFromRGB(color_text_footer)];
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *footer = (UITableViewHeaderFooterView *)view;
    [footer.textLabel setTextColor:UIColorFromRGB(color_text_footer)];
}

#pragma mark - UITableViewDelegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
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
                [self backButtonClicked:nil];
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
    [tableView deselectRowAtIndexPath:indexPath animated:true];
}

- (void) selectRecInterval:(NSInteger)index
{
    [_settings.mapSettingSaveTrackIntervalApproved set:YES mode:self.appMode];
    [_settings.mapSettingSaveTrackIntervalGlobal set:[_settings.trackIntervalArray[index] intValue] mode:self.appMode];
    [self backButtonClicked:nil];
}

- (void) selectNavRecInterval:(NSInteger)index
{
    [_settings.mapSettingSaveTrackInterval set:[_settings.trackIntervalArray[index] intValue] mode:self.appMode];
    [self backButtonClicked:nil];
}

- (void) selectMinDistance:(NSInteger)index
{
    [_settings.saveTrackMinDistance set:minTrackDistanceValues[index].doubleValue mode:self.appMode];
    [self backButtonClicked:nil];
}

- (void) selectMinSpeed:(NSInteger)index
{
    [_settings.saveTrackMinSpeed set:minTrackSpeedValues[index].doubleValue mode:self.appMode];
    [self backButtonClicked:nil];
}

- (void) selectAccuracy:(NSInteger)index
{
    [_settings.saveTrackPrecision set:trackPrecisionValues[index].doubleValue mode:self.appMode];
    [self backButtonClicked:nil];
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
        
        OAGPXListViewController *gpxController = myPlacesViewController.viewControllers[1];
        if (gpxController == nil)
            return;
        
        [gpxController setShouldPopToParent:YES];
        
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
}

@end
