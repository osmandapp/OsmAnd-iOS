//
//  OAOsmAndLiveSelectionViewController.m
//  OsmAnd
//
//  Created by Paul on 12/18/18.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAOsmAndLiveSelectionViewController.h"
#import "OAMenuSimpleCellNoIcon.h"
#import "Localization.h"
#import "Reachability.h"
#import "OAOsmAndLiveHelper.h"
#import "OsmAndApp.h"
#import "OASettingsTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OASettingsTitleTableViewCell.h"

#include <OsmAndCore/IncrementalChangesManager.h>

#define kCellTypeSwitch @"switch"
#define kCellTypeSingleSelectionList @"single_selection_list"
#define kCellTypeCheck @"check"

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
    NSInteger _initialFrequency;
    
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
    [_backButton setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
    [_cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [_applyButton setTitle:OALocalizedString(@"shared_string_apply") forState:UIControlStateNormal];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
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
               @"type" : kCellTypeSwitch
               }];
            
            [dataArr addObject:
             @{
               @"name" : @"wifi_only",
               @"title" : OALocalizedString(@"osmand_live_wifi_only"),
               @"value" : @([OAOsmAndLiveHelper getPreferenceWifiForLocalIndex:_regionNameNSString]),
               @"type" : kCellTypeSwitch,
               }];
            
            [dataArr addObject:
             @{
               @"name" : @"update_frequency",
               @"title" : OALocalizedString(@"osmand_live_upd_frequency"),
               @"value" : [OAOsmAndLiveHelper getFrequencyString:[OAOsmAndLiveHelper getPreferenceFrequencyForLocalIndex:_regionNameNSString]],
               @"img" : @"menu_cell_pointer.png",
               @"type" : kCellTypeSingleSelectionList }
             ];
            
            [dataArr addObject:
             @{
               @"name" : @"updates_size",
               @"title" : @"Downloaded updates size",
               @"value" : [NSByteCountFormatter stringFromByteCount:_app.resourcesManager->changesManager->getUpdatesSize(_regionName)
                                                         countStyle:NSByteCountFormatterCountStyleFile],
               @"type" : kCellTypeSingleSelectionList }
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
               @"type" : kCellTypeCheck }
             ];
            
            [dataArr addObject:
             @{
               @"name" : @"daily_freq",
               @"title" : OALocalizedString(@"osmand_live_daily"),
               @"img" : currentFrequency == ELiveUpdateFrequencyDaily ? @"menu_cell_selected.png" : @"",
               @"type" : kCellTypeCheck }
             ];
            
            [dataArr addObject:
             @{
               @"name" : @"weekly_freq",
               @"title" : OALocalizedString(@"osmand_live_weekly"),
               @"img" : currentFrequency == ELiveUpdateFrequencyWeekly ? @"menu_cell_selected.png" : @"",
               @"type" : kCellTypeCheck }
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
            cell.switchView.on = [v boolValue];
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView addTarget:self action:@selector(applyParameter:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    else if ([type isEqualToString:kCellTypeSingleSelectionList])
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
            [cell.iconView setImage:[UIImage imageNamed:item[@"img"]]];
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
            [cell.iconView setImage:[UIImage imageNamed:item[@"img"]]];
        }
        return cell;
    }
    return nil;
}

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForRow:indexPath tableView:tableView];
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForRow:indexPath tableView:tableView];
}

- (CGFloat) heightForRow:(NSIndexPath *)indexPath tableView:(UITableView *)tableView
{
    NSDictionary *item = [self getItem:indexPath];
    NSString *value = item[@"description"];
    NSString *text = item[@"title"];
    
    return [OAMenuSimpleCellNoIcon getHeight:text desc:value cellWidth:tableView.bounds.size.width];
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
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:selectionViewController];
        navController.navigationBarHidden = YES;
        navController.automaticallyAdjustsScrollViewInsets = NO;
        navController.edgesForExtendedLayout = UIRectEdgeNone;

        [self.navigationController presentViewController:navController animated:YES completion:nil];
    }
    else if (_settingsScreen == ELiveSettingsScreenFrequency)
    {
        [OAOsmAndLiveHelper setPreferenceFrequencyForLocalIndex:_regionNameNSString value:indexPath.row];
        [self backInSelectionClicked:nil];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:true];
}
- (IBAction)backButtonClicked:(id)sender
{
    if (!_initialStateEnabled)
    {
        [OAOsmAndLiveHelper removePreferencesForLocalIndex:_regionNameNSString];
        [self removeUpdates];
    }
    else
        [self restoreInitialSettings];

    [self dismissViewControllerAnimated:YES completion:nil];
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
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)backInSelectionClicked:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void) removeUpdates
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        _app.resourcesManager->changesManager->deleteUpdates(_regionName);
    });
}

@end
