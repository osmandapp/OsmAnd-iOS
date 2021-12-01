//
//  OAOsmAndLiveSelectionViewController.m
//  OsmAnd
//
//  Created by Paul on 12/18/18.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAOsmAndLiveSelectionViewController.h"
#import "Localization.h"
#import "Reachability.h"
#import "OAOsmAndLiveHelper.h"
#import "OsmAndApp.h"
#import "OASettingsTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OASettingsTitleTableViewCell.h"
#import "OAIAPHelper.h"
#import "OAAppSettings.h"
#import "OAColors.h"

#include <OsmAndCore/IncrementalChangesManager.h>

@interface OAOsmAndLiveSelectionViewController ()

@end

@implementation OAOsmAndLiveSelectionViewController
{
   
    QString _regionName;
    NSString *_regionNameNSString;
    NSString *_titleName;
    OsmAndAppInstance _app;
    
    BOOL _initialStateEnabled;
    BOOL _initialStateWifi;
    ELiveUpdateFrequency _initialFrequency;
    
    UIView *_footerView;
    
    NSArray *_data;
}

static const NSInteger settingsIndex = 0;
static const NSInteger groupCount = 1;


- (id) initWithRegionName:(QString)regionName titleName:(NSString *)title
{
    self = [super init];
    if (self)
    {
        _regionName = regionName;
        _titleName = title;
        _regionNameNSString = _regionName.toNSString();
        _app = [OsmAndApp instance];
        _settingsScreen = ELiveSettingsScreenMain;
        [self setInitialValues];
    }
    return self;
}

- (id) initWithType:(ELiveSettingsScreen)type regionName:(QString)regionName titleName:(NSString *)title
{
    self = [super init];
    if (self)
    {
        _regionName = regionName;
        _titleName = title;
        _regionNameNSString = _regionName.toNSString();
        _app = [OsmAndApp instance];
        _settingsScreen = type;
    }
    return self;
}

-(void) setInitialValues
{
    _initialStateEnabled = [OAOsmAndLiveHelper getPreferenceEnabledForLocalIndex:_regionNameNSString];
    if (!_initialStateEnabled)
        [OAOsmAndLiveHelper setDefaultPreferencesForLocalIndex:_regionNameNSString];
    else
    {
        _initialStateWifi = [OAOsmAndLiveHelper getPreferenceWifiForLocalIndex:_regionNameNSString];
        _initialFrequency = [OAOsmAndLiveHelper getPreferenceFrequencyForLocalIndex:_regionNameNSString];
    }
}

-(void) restoreInitialSettings
{
    [OAOsmAndLiveHelper setPreferenceEnabledForLocalIndex:_regionNameNSString value:_initialStateEnabled];
    [OAOsmAndLiveHelper setPreferenceWifiForLocalIndex:_regionNameNSString value:_initialStateWifi];
    [OAOsmAndLiveHelper setPreferenceFrequencyForLocalIndex:_regionNameNSString value:_initialFrequency];
}

-(void) applyLocalization
{
    _titleView.text = _settingsScreen == ELiveSettingsScreenMain ? _titleName : OALocalizedString(@"osmand_live_upd_frequency");
    [_cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [_applyButton setTitle:OALocalizedString(@"shared_string_apply") forState:UIControlStateNormal];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.estimatedRowHeight = kEstimatedRowHeight;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    if (_settingsScreen == ELiveSettingsScreenMain)
    {
        _footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 55.0)];
        NSDictionary *attrs = @{ NSFontAttributeName : [UIFont systemFontOfSize:16.0],
                                 NSForegroundColorAttributeName : [UIColor whiteColor] };
        NSAttributedString *text = [[NSAttributedString alloc] initWithString:OALocalizedString(@"osmand_live_update_now") attributes:attrs];
        UIButton *updateNow = [UIButton buttonWithType:UIButtonTypeSystem];
        BOOL canUpdate = [OAAppSettings sharedManager].settingOsmAndLiveEnabled.get && [OAIAPHelper sharedInstance].subscribedToLiveUpdates;
        updateNow.userInteractionEnabled = canUpdate;
        [updateNow setAttributedTitle:text forState:UIControlStateNormal];
        [updateNow addTarget:self action:@selector(updateNow) forControlEvents:UIControlEventTouchUpInside];
        updateNow.backgroundColor = canUpdate ? UIColorFromRGB(color_active_light) : UIColorFromRGB(color_disabled_light);
        updateNow.layer.cornerRadius = 5;
        updateNow.frame = CGRectMake(10, 0, _footerView.frame.size.width - 20.0, 44.0);
        [_footerView addSubview:updateNow];
        
        self.tableView.tableFooterView = _footerView;
    }
}

-(void) updateNow
{
    [OAOsmAndLiveHelper downloadUpdatesForRegion:_regionName resourcesManager:_app.resourcesManager];
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

- (void) viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    CGFloat btnMargin = MAX(10, [OAUtilities getLeftMargin]);
    _footerView.subviews[0].frame = CGRectMake(btnMargin, 0, _footerView.frame.size.width - btnMargin * 2, 44.0);
}

-(UIView *) getTopView
{
    return _navBarView;
}

-(UIView *) getMiddleView
{
    return _tableView;
}

- (void) setupView
{
    [self applySafeAreaMargins];
    NSMutableArray *dataArr = [NSMutableArray array];
    
    switch (_settingsScreen) {
        case ELiveSettingsScreenMain: {
            _backButton.hidden = YES;
            _cancelButton.hidden = NO;
            _applyButton.hidden = NO;
            [dataArr addObject:
             @{
               @"name" : @"osm_live_enabled",
               @"title" : OALocalizedString(@"osmand_live_updates"),
               @"value" : @([OAOsmAndLiveHelper getPreferenceEnabledForLocalIndex:_regionNameNSString]),
               @"type" : [OASwitchTableViewCell getCellIdentifier]
               }];
            
            [dataArr addObject:
             @{
               @"name" : @"wifi_only",
               @"title" : OALocalizedString(@"osmand_live_wifi_only"),
               @"value" : @([OAOsmAndLiveHelper getPreferenceWifiForLocalIndex:_regionNameNSString]),
               @"type" : [OASwitchTableViewCell getCellIdentifier],
               }];
            
            [dataArr addObject:
             @{
               @"name" : @"update_frequency",
               @"title" : OALocalizedString(@"osmand_live_upd_frequency"),
               @"value" : [OAOsmAndLiveHelper getFrequencyString:[OAOsmAndLiveHelper getPreferenceFrequencyForLocalIndex:_regionNameNSString]],
               @"img" : @"menu_cell_pointer.png",
               @"type" : [OASettingsTableViewCell getCellIdentifier] }
             ];
            
            [dataArr addObject:
             @{
               @"name" : @"updates_size",
               @"title" : OALocalizedString(@"osmand_live_updates_size"),
               @"value" : [NSByteCountFormatter stringFromByteCount:_app.resourcesManager->changesManager->getUpdatesSize(_regionName)
                                                         countStyle:NSByteCountFormatterCountStyleFile],
               @"type" : [OASettingsTableViewCell getCellIdentifier] }
             ];
            
            _data = [NSArray arrayWithArray:dataArr];
            [dataArr removeAllObjects];
            break;
        }
        case ELiveSettingsScreenFrequency: {
            _backButton.hidden = NO;
            _cancelButton.hidden = YES;
            _applyButton.hidden = YES;
            NSInteger currentFrequency = [OAOsmAndLiveHelper getPreferenceFrequencyForLocalIndex:_regionNameNSString];
            [dataArr addObject:
             @{
               @"name" : @"hourly_freq",
               @"title" : OALocalizedString(@"osmand_live_hourly"),
               @"img" : currentFrequency == ELiveUpdateFrequencyHourly ? @"menu_cell_selected.png" : @"",
               @"type" : [OASettingsTitleTableViewCell getCellIdentifier] }
             ];
            
            [dataArr addObject:
             @{
               @"name" : @"daily_freq",
               @"title" : OALocalizedString(@"osmand_live_daily"),
               @"img" : currentFrequency == ELiveUpdateFrequencyDaily ? @"menu_cell_selected.png" : @"",
               @"type" : [OASettingsTitleTableViewCell getCellIdentifier] }
             ];
            
            [dataArr addObject:
             @{
               @"name" : @"weekly_freq",
               @"title" : OALocalizedString(@"osmand_live_weekly"),
               @"img" : currentFrequency == ELiveUpdateFrequencyWeekly ? @"menu_cell_selected.png" : @"",
               @"type" : [OASettingsTitleTableViewCell getCellIdentifier] }
             ];
            
            _data = [NSArray arrayWithArray:dataArr];
            [dataArr removeAllObjects];
            break;
        }
        default: {
            break;
        }
    }
    
    [self.tableView reloadData];
    
}

- (NSDictionary *) getItem:(NSIndexPath *)indexPath
{
    long section = indexPath.section;
    switch (section) {
        case settingsIndex:
            return _data[indexPath.row];
        default:
            return nil;
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return groupCount;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == settingsIndex)
        return _data.count;
    
    return 0;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    NSString *type = item[@"type"];
    
    if ([type isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
    {
        OASwitchTableViewCell* cell = nil;
        cell = [tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *)[nib objectAtIndex:0];
            cell.textView.numberOfLines = 0;
        }
        
        if (cell)
        {
            [cell.textView setText: item[@"title"]];
            id v = item[@"value"];
            cell.switchView.on = [v boolValue];
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView removeTarget:nil action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(applyParameter:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    else if ([type isEqualToString:[OASettingsTableViewCell getCellIdentifier]])
    {
        OASettingsTableViewCell* cell = nil;
        cell = [tableView dequeueReusableCellWithIdentifier:[OASettingsTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASettingsTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASettingsTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            [cell.textView setText: item[@"title"]];
            [cell.descriptionView setText: item[@"value"]];
            [cell.iconView setImage:[UIImage imageNamed:item[@"img"]]];
        }
        return cell;
    }
    else if ([type isEqualToString:[OASettingsTitleTableViewCell getCellIdentifier]])
    {
        OASettingsTitleTableViewCell* cell = nil;
        
        cell = [tableView dequeueReusableCellWithIdentifier:[OASettingsTitleTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASettingsTitleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASettingsTitleTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            [cell.textView setText: item[@"title"]];
            [cell.iconView setImage:[UIImage imageNamed:item[@"img"]]];
        }
        return cell;
    }
    return nil;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return nil;
}

- (void) applyParameter:(id)sender
{
    if ([sender isKindOfClass:[UISwitch class]])
    {
        UISwitch *sw = (UISwitch *) sender;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sw.tag & 0x3FF inSection:sw.tag >> 10];
        NSDictionary *item = [self getItem:indexPath];
    
        
        BOOL isChecked = ((UISwitch *) sender).on;
        NSString *name = item[@"name"];

        if ([name isEqualToString:@"osm_live_enabled"])
            [OAOsmAndLiveHelper setPreferenceEnabledForLocalIndex:_regionNameNSString value:isChecked];
        else if ([name isEqualToString:@"wifi_only"])
            [OAOsmAndLiveHelper setPreferenceWifiForLocalIndex:_regionNameNSString value:isChecked];

    }
}

#pragma mark - UITableViewDelegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([@"update_frequency" isEqualToString:item[@"name"]])
    {
        OAOsmAndLiveSelectionViewController* selectionViewController = [[OAOsmAndLiveSelectionViewController alloc] initWithType:ELiveSettingsScreenFrequency regionName:_regionName titleName:_titleName];
        [self.navigationController pushViewController:selectionViewController animated:YES];
    }
    else if (_settingsScreen == ELiveSettingsScreenFrequency)
    {
        [OAOsmAndLiveHelper setPreferenceFrequencyForLocalIndex:_regionNameNSString value:(ELiveUpdateFrequency)indexPath.row];
        [self backInSelectionClicked:nil];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:true];
}

- (IBAction)backButtonClicked:(id)sender
{
    [self onDissmissViewContoller];
}

- (void)onDissmissViewContoller
{
    if (!_initialStateEnabled)
    {
        [OAOsmAndLiveHelper removePreferencesForLocalIndex:_regionNameNSString];
        [self removeUpdates];
    }
    else
        [self restoreInitialSettings];
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)applyButtonClicked:(id)sender
{
    NSString *regionNameStr = _regionName.toNSString();
    if (![OAOsmAndLiveHelper getPreferenceEnabledForLocalIndex:regionNameStr])
    {
        [OAOsmAndLiveHelper removePreferencesForLocalIndex:regionNameStr];
        [self removeUpdates];
    }
    [OAOsmAndLiveHelper downloadUpdatesForRegion:_regionName resourcesManager:_app.resourcesManager];
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)backInSelectionClicked:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void) removeUpdates
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        _app.resourcesManager->changesManager->deleteUpdates(_regionName);
        [_app.data.mapLayerChangeObservable notifyEvent];
    });
}

@end
