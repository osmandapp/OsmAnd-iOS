//
//  OATripRecordingSettingsViewController.m
//  OsmAnd
//
//  Created by Paul on 8/29/18.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OATripRecordingSettingsViewController.h"
#import "OAIconTextDescSwitchCell.h"
#import "OASettingsTableViewCell.h"
#import "OASettingsTitleTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OAAppSettings.h"
#import "Localization.h"
#import "OAUtilities.h"
#import "OsmAndApp.h"
#import "PXAlertView.h"
#import "OARoutingHelper.h"
#import "OAFileNameTranslationHelper.h"
#import "OASettingsViewController.h"
#import "OASavingTrackHelper.h"
#include <generalRouter.h>

#define kCellTypeProfileSwitch @"OAIconTextDescSwitchCell"
#define kCellTypeSwitch @"switch"
#define kCellTypeSingleSelectionList @"single_selection_list"
#define kCellTypeMultiSelectionList @"multi_selection_list"
#define kCellTypeCheck @"check"

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
            NSString *recIntervalValue = [settings getFormattedTrackInterval:settings.mapSettingSaveTrackIntervalGlobal];
            NSString *navIntervalValue = [settings getFormattedTrackInterval:[settings.mapSettingSaveTrackInterval get:self.appMode]];
            
            NSString *minDistValue = [OAUtilities appendMeters:[settings.saveTrackMinDistance get:self.appMode]];
            NSString *minPrecision = [OAUtilities appendMeters:[settings.saveTrackPrecision get:self.appMode]];
            NSString *minSpeed = [OAUtilities appendSpeed:[settings.saveTrackMinSpeed get:self.appMode]];
            if (_settings.mapSettingSaveTrackIntervalApproved) {
                [dataArr addObject:
                 @{
                   @"name" : @"rec_interval",
                   @"title" : OALocalizedString(@"save_global_track_interval"),
                   @"description" : OALocalizedString(@"save_global_track_interval_descr"),
                   @"value" : recIntervalValue,
                   @"img" : @"menu_cell_pointer.png",
                   @"type" : kCellTypeSingleSelectionList }
                 ];
            }
            
            [dataArr addObject:
             @{
               @"name" : @"save_track",
               @"title" : OALocalizedString(@"track_save"),
               @"description" : [OALocalizedString(@"track_save_descr") stringByAppendingString:[NSString stringWithFormat:@" (%@)",
                                                                                                 [[OsmAndApp instance] getFormattedDistance:_recHelper.distance]]],
               @"value" : @"",
               @"type" : kCellTypeCheck }
             ];
            
            [dataArr addObject:@{
                                 @"name" : @"track_during_nav",
                                 @"title" : OALocalizedString(@"track_during_nav"),
                                 @"description" : OALocalizedString(@"track_during_nav_descr"),
                                 @"value" : _settings.saveTrackToGPX,
                                 @"img" : @"menu_cell_pointer.png",
                                 @"type" : kCellTypeSwitch }];
            
            [dataArr addObject:
             @{
               @"name" : @"logging_interval_navigation",
               @"title" : OALocalizedString(@"logging_interval_navigation"),
               @"description" : OALocalizedString(@"logging_interval_navigation_descr"),
               @"value" : navIntervalValue,
               @"img" : @"menu_cell_pointer.png",
               @"type" : kCellTypeSingleSelectionList }
             ];
            
            [dataArr addObject:
             @{
               @"name" : @"logging_min_distance",
               @"title" : OALocalizedString(@"logging_min_distance"),
               @"description" : OALocalizedString(@"logging_min_distance_descr"),
               @"value" : minDistValue,
               @"img" : @"menu_cell_pointer.png",
               @"type" : kCellTypeSingleSelectionList }
             ];
            
            [dataArr addObject:
             @{
               @"name" : @"logging_min_accuracy",
               @"title" : OALocalizedString(@"logging_min_accuracy"),
               @"description" : OALocalizedString(@"logging_min_accuracy_descr"),
               @"value" : minPrecision,
               @"img" : @"menu_cell_pointer.png",
               @"type" : kCellTypeSingleSelectionList }
             ];
            
            [dataArr addObject:
             @{
               @"name" : @"logging_min_speed",
               @"title" : OALocalizedString(@"logging_min_speed"),
               @"description" : OALocalizedString(@"logging_min_speed_descr"),
               @"value" : minSpeed,
               @"img" : @"menu_cell_pointer.png",
               @"type" : kCellTypeSingleSelectionList }
             ];
            
            [dataArr addObject:
             @{
               @"name" : @"auto_split_gap",
               @"title" : OALocalizedString(@"auto_split_gap"),
               @"description" : OALocalizedString(@"auto_split_gap_descr"),
               @"value" : @([_settings.autoSplitRecording get:self.appMode]),
               @"img" : @"menu_cell_pointer.png",
               @"type" : kCellTypeSwitch }];
            
            break;
        }
        case kTripRecordingSettingsScreenRecInterval:
        {
            self.titleLabel.text = OALocalizedString(@"rec_interval");
            for (NSNumber *num in settings.trackIntervalArray)
            {
                [dataArr addObject: @{
                                  @"title" : [settings getFormattedTrackInterval:[num intValue]],
                                  @"value" : @"",
                                  @"img" : (settings.mapSettingSaveTrackIntervalGlobal == [num intValue])
                                  ? @"menu_cell_selected.png" : @"", @"type" : kCellTypeCheck }];
            }
            [dataArr addObject:@{
                                 @"title" : OALocalizedString(@"shared_setting_always_ask"),
                                 @"value" : @"always_ask",
                                 @"img" : !settings.mapSettingSaveTrackIntervalApproved ? @"menu_cell_selected.png" : @"",
                                 @"type" : kCellTypeCheck }];
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

- (IBAction) appModeButtonClicked:(id)sender
{
    [self showAppModeDialog];
}

- (void) showAppModeDialog
{
    NSMutableArray *titles = [NSMutableArray array];
    NSMutableArray *images = [NSMutableArray array];
    NSMutableArray *modes = [NSMutableArray array];
    
    NSArray<OAApplicationMode *> *values = [OAApplicationMode values];
    for (OAApplicationMode *v in values)
    {
        if (v == [OAApplicationMode DEFAULT])
            continue;
        
        [titles addObject:v.name];
        [images addObject:v.getIconName];
        [modes addObject:v];
    }
    
    [PXAlertView showAlertWithTitle:OALocalizedString(@"map_settings_mode")
                            message:nil
                        cancelTitle:OALocalizedString(@"shared_string_cancel")
                        otherTitles:titles
                          otherDesc:nil
                        otherImages:images
                         completion:^(BOOL cancelled, NSInteger buttonIndex) {
                             if (!cancelled)
                             {
                                 self.appMode = modes[buttonIndex];
                                 [self setupView];
                             }
                         }];
}

- (NSDictionary *) getItem:(NSIndexPath *)indexPath
{
    if (_settingsType == kTripRecordingSettingsScreenGeneral)
        return _data[indexPath.section];
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
        }
        else if ([name isEqualToString:@"auto_split_gap"])
        {
            [_settings.autoSplitRecording set:isChecked mode:self.appMode];
        }
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
    if (_settingsType == kTripRecordingSettingsScreenGeneral)
        return 1;
    else
        return _data.count;
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
            if ([item[@"img"] isEqualToString:@"menu_cell_pointer.png"])
                image = [image imageFlippedForRightToLeftLayoutDirection];
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
            if ([item[@"img"] isEqualToString:@"menu_cell_pointer.png"])
                image = [image imageFlippedForRightToLeftLayoutDirection];
            [cell.iconView setImage:image];
        }
        return cell;
    }
    return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    NSString *type = item[@"type"];
    
    if ([type isEqualToString:kCellTypeSwitch])
    {
        return UITableViewAutomaticDimension;
    }
    else if ([type isEqualToString:kCellTypeSingleSelectionList] || [type isEqualToString:kCellTypeMultiSelectionList] || [type isEqualToString:kCellTypeCheck])
    {
        return [OASettingsTableViewCell getHeight:item[@"title"] value:item[@"value"] cellWidth:tableView.bounds.size.width];
    }
    else if ([type isEqualToString:kCellTypeCheck])
    {
        return [OASettingsTitleTableViewCell getHeight:item[@"title"] cellWidth:tableView.bounds.size.width];
    }
    else
    {
        return 44.0;
    }
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (_settingsType == kTripRecordingSettingsScreenGeneral)
    {
        NSDictionary *item = _data[section];
        return item[@"header"];
    }
    return nil;
}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (_settingsType == kTripRecordingSettingsScreenGeneral)
    {
        NSDictionary *item = _data[section];
        return item[@"description"];
    }
    else
    {
        return nil;
    }
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
                _settings.mapSettingSaveTrackIntervalApproved = NO;
                [self backButtonClicked:nil];
            } else {
                [self selectRecInterval:indexPath.row];
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
    [_settings setMapSettingSaveTrackIntervalGlobal:[_settings.trackIntervalArray[index] intValue]];
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
    else if ([@"save_track" isEqualToString:name])
    {
        if ([_recHelper hasDataToSave] && _recHelper.distance < 10.0)
        {
            [PXAlertView showAlertWithTitle:OALocalizedString(@"track_save_short_q")
                                    message:nil
                                cancelTitle:OALocalizedString(@"shared_string_no")
                                 otherTitle:OALocalizedString(@"shared_string_yes")
                                  otherDesc:nil
                                 otherImage:nil
                                 completion:^(BOOL cancelled, NSInteger buttonIndex) {
                                     if (!cancelled) {
                                         _settings.mapSettingTrackRecording = NO;
                                         [self saveTrack:YES];
                                     }
                                 }];
        }
        else if ([_recHelper hasDataToSave])
        {
            _settings.mapSettingTrackRecording = NO;
            [self saveTrack:YES];
        }
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
}

- (void) saveTrack:(BOOL)askForRec
{
    if ([_recHelper hasDataToSave])
        [_recHelper saveDataToGpx];
    if (askForRec)
    {
        [PXAlertView showAlertWithTitle:OALocalizedString(@"track_continue_rec_q")
                                message:nil
                            cancelTitle:OALocalizedString(@"shared_string_no")
                             otherTitle:OALocalizedString(@"shared_string_yes")
                              otherDesc:nil
                             otherImage:nil
                             completion:^(BOOL cancelled, NSInteger buttonIndex) {
                                 if (!cancelled) {
                                     _settings.mapSettingTrackRecording = YES;
                                 }
                             }];
    }
}
@end
