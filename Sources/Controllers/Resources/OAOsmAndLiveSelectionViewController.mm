//
//  OAOsmAndLiveSelectionViewController.m
//  OsmAnd
//
//  Created by Paul on 12/18/18.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAOsmAndLiveSelectionViewController.h"
#import "Localization.h"
#import <AFNetworking/AFNetworkReachabilityManager.h>
#import "OsmAndApp.h"
#import "OAValueTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OASimpleTableViewCell.h"
#import "OAIAPHelper.h"
#import "OAAppSettings.h"
#import "OAAppData.h"
#import "OAObservable.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

#include <OsmAndCore/IncrementalChangesManager.h>

@interface OAOsmAndLiveSelectionViewController ()

@end

@implementation OAOsmAndLiveSelectionViewController
{
   
    QString _regionName;
    NSString *_regionNameNSString;
    NSString *_titleName;
    OsmAndAppInstance _app;
    
    BOOL _isLiveUpdatesEnabled;
    BOOL _isWifiUpdatesOnly;
    ELiveUpdateFrequency _updatingFrequency;
    
    UIView *_footerView;
    
    UIBarButtonItem *_cancelButton;
    UIBarButtonItem *_applyButton;
    
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
    _isLiveUpdatesEnabled = [OAOsmAndLiveHelper getPreferenceEnabledForLocalIndex:_regionNameNSString];
    if (!_isLiveUpdatesEnabled && ![OAOsmAndLiveHelper isPreferencesInited: _regionNameNSString])
        [OAOsmAndLiveHelper setDefaultPreferencesForLocalIndex:_regionNameNSString];

    _isWifiUpdatesOnly = [OAOsmAndLiveHelper getPreferenceWifiForLocalIndex:_regionNameNSString];
    _updatingFrequency = [OAOsmAndLiveHelper getPreferenceFrequencyForLocalIndex:_regionNameNSString];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.estimatedRowHeight = kEstimatedRowHeight;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    self.navigationItem.title = _settingsScreen == ELiveSettingsScreenMain ? _titleName : OALocalizedString(@"update_frequency");

    if (_settingsScreen == ELiveSettingsScreenMain)
    {
        _footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 55.0)];
        NSDictionary *attrs = @{ NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleCallout],
                                 NSForegroundColorAttributeName : [UIColor whiteColor] };
        NSAttributedString *text = [[NSAttributedString alloc] initWithString:OALocalizedString(@"update_now") attributes:attrs];
        UIButton *updateNow = [UIButton buttonWithType:UIButtonTypeSystem];
        BOOL canUpdate = [OAAppSettings sharedManager].settingOsmAndLiveEnabled.get && [OAIAPHelper isSubscribedToLiveUpdates];
        updateNow.userInteractionEnabled = canUpdate;
        [updateNow setAttributedTitle:text forState:UIControlStateNormal];
        [updateNow addTarget:self action:@selector(updateNow) forControlEvents:UIControlEventTouchUpInside];
        updateNow.backgroundColor = canUpdate ? [UIColor colorNamed:ACColorNameButtonBgColorPrimary] : [UIColor colorNamed:ACColorNameButtonBgColorSecondary];
        updateNow.layer.cornerRadius = 5;
        updateNow.frame = CGRectMake(10, 0, _footerView.frame.size.width - 20.0, 44.0);
        [_footerView addSubview:updateNow];
        
        self.tableView.tableFooterView = _footerView;
    }
}

-(void) updateNow
{
    [OAOsmAndLiveHelper downloadUpdatesForRegion:_regionName resourcesManager:_app.resourcesManager checkUpdatesAsync:YES];
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
    [appearance configureWithOpaqueBackground];
    appearance.backgroundColor = [UIColor colorNamed:ACColorNameNavBarBgColorPrimary];
    appearance.shadowColor = [UIColor colorNamed:ACColorNameNavBarBgColorPrimary];
    appearance.titleTextAttributes = @{
        NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline],
        NSForegroundColorAttributeName : [UIColor colorNamed:ACColorNameNavBarTextColorPrimary]
    };
    UINavigationBarAppearance *blurAppearance = [[UINavigationBarAppearance alloc] init];
    blurAppearance.backgroundEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleRegular];
    blurAppearance.backgroundColor = [UIColor colorNamed:ACColorNameNavBarBgColorPrimary];
    blurAppearance.titleTextAttributes = @{
        NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline],
        NSForegroundColorAttributeName : [UIColor colorNamed:ACColorNameNavBarTextColorPrimary]
    };
    self.navigationController.navigationBar.standardAppearance = blurAppearance;
    self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
    self.navigationController.navigationBar.tintColor = [UIColor colorNamed:ACColorNameNavBarTextColorPrimary];
    self.navigationController.navigationBar.prefersLargeTitles = NO;
    
    if (_settingsScreen == ELiveSettingsScreenMain)
    {
        _cancelButton = [[UIBarButtonItem alloc] initWithTitle:OALocalizedString(@"shared_string_cancel") style:UIBarButtonItemStylePlain target:self action:@selector(backInSelectionClicked:)];
        _applyButton = [[UIBarButtonItem alloc] initWithTitle:OALocalizedString(@"shared_string_apply") style:UIBarButtonItemStylePlain target:self action:@selector(applyButtonClicked:)];
        [self.navigationController.navigationBar.topItem setLeftBarButtonItem:_cancelButton animated:YES];
        [self.navigationController.navigationBar.topItem setRightBarButtonItem:_applyButton animated:YES];
    }
    
    [self setupView];
}

- (void) viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    CGFloat btnMargin = MAX(10, [OAUtilities getLeftMargin]);
    _footerView.subviews[0].frame = CGRectMake(btnMargin, 0, _footerView.frame.size.width - btnMargin * 2, 44.0);
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
            [dataArr addObject:
             @{
               @"name" : @"osm_live_enabled",
               @"title" : OALocalizedString(@"live_updates"),
               @"value" : @(_isLiveUpdatesEnabled),
               @"type" : [OASwitchTableViewCell getCellIdentifier]
               }];
            
            [dataArr addObject:
             @{
               @"name" : @"wifi_only",
               @"title" : OALocalizedString(@"osmand_live_wifi_only"),
               @"value" : @(_isWifiUpdatesOnly),
               @"type" : [OASwitchTableViewCell getCellIdentifier],
               }];
            
            [dataArr addObject:
             @{
               @"name" : @"update_frequency",
               @"title" : OALocalizedString(@"update_frequency"),
               @"value" : [OAOsmAndLiveHelper getFrequencyString:_updatingFrequency],
               @"type" : [OAValueTableViewCell getCellIdentifier] }
             ];
            
            [dataArr addObject:
             @{
               @"name" : @"updates_size",
               @"title" : OALocalizedString(@"osmand_live_updates_size"),
               @"value" : [NSByteCountFormatter stringFromByteCount:_app.resourcesManager->changesManager->getUpdatesSize(_regionName)
                                                         countStyle:NSByteCountFormatterCountStyleFile],
               @"type" : [OAValueTableViewCell getCellIdentifier] }
             ];
            
            _data = [NSArray arrayWithArray:dataArr];
            [dataArr removeAllObjects];
            break;
        }
        case ELiveSettingsScreenFrequency: {
            [dataArr addObject:
             @{
               @"name" : @"hourly_freq",
               @"title" : OALocalizedString(@"hourly"),
               @"type" : [OASimpleTableViewCell getCellIdentifier] }
             ];
            
            [dataArr addObject:
             @{
               @"name" : @"daily_freq",
               @"title" : OALocalizedString(@"daily"),
               @"type" : [OASimpleTableViewCell getCellIdentifier] }
             ];
            
            [dataArr addObject:
             @{
               @"name" : @"weekly_freq",
               @"title" : OALocalizedString(@"weekly"),
               @"type" : [OASimpleTableViewCell getCellIdentifier] }
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
        OASwitchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
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

            id v = item[@"value"];
            cell.switchView.on = [v boolValue];
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView removeTarget:nil action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(applyParameter:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    else if ([type isEqualToString:[OAValueTableViewCell getCellIdentifier]])
    {
        OAValueTableViewCell* cell = nil;
        cell = [tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAValueTableViewCell *)[nib objectAtIndex:0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
        }
        
        if (cell)
        {
            [cell.titleLabel setText: item[@"title"]];
            [cell.valueLabel setText: item[@"value"]];
            if ([item[@"name"] isEqualToString:@"update_frequency"])
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            else
                cell.accessoryType = UITableViewCellAccessoryNone;
        }
        return cell;
    }
    else if ([type isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        OASimpleTableViewCell* cell = nil;
        
        cell = [tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
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
            cell.accessoryType = _updatingFrequency == ELiveUpdateFrequencyDaily ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
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
            _isLiveUpdatesEnabled = isChecked;
        else if ([name isEqualToString:@"wifi_only"])
            _isWifiUpdatesOnly = isChecked;
    }
}

#pragma mark - UITableViewDelegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([@"update_frequency" isEqualToString:item[@"name"]])
    {
        OAOsmAndLiveSelectionViewController* selectionViewController = [[OAOsmAndLiveSelectionViewController alloc] initWithType:ELiveSettingsScreenFrequency regionName:_regionName titleName:_titleName];
        selectionViewController.delegate = self;
        [selectionViewController updateFrequency:_updatingFrequency];
        [self.navigationController pushViewController:selectionViewController animated:YES];
    }
    else if (_settingsScreen == ELiveSettingsScreenFrequency)
    {
        if (self.delegate)
            [self.delegate updateFrequency:(ELiveUpdateFrequency)indexPath.row];
        [self backInSelectionClicked:nil];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:true];
}

- (IBAction)applyButtonClicked:(id)sender
{
    [OAOsmAndLiveHelper setPreferenceEnabledForLocalIndex:_regionNameNSString value:_isLiveUpdatesEnabled];
    [OAOsmAndLiveHelper setPreferenceWifiForLocalIndex:_regionNameNSString value:_isWifiUpdatesOnly];
    [OAOsmAndLiveHelper setPreferenceFrequencyForLocalIndex:_regionNameNSString value:_updatingFrequency];
    
    NSString *regionNameStr = _regionName.toNSString();
    if (_isLiveUpdatesEnabled)
    {
        [OAOsmAndLiveHelper downloadUpdatesForRegion:_regionName resourcesManager:_app.resourcesManager checkUpdatesAsync:YES];
    }
    else
    {
        [self removeUpdates];
    }
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
        [OAOsmAndLiveHelper setPreferenceLastUpdateForLocalIndex:_regionName.toNSString() value:-1.0];
        [_app.data.mapLayerChangeObservable notifyEvent];
    });
}

#pragma mark - OAOsmAndLiveSelectionDelegate

- (void) updateFrequency:(ELiveUpdateFrequency)frequency
{
    _updatingFrequency = frequency;
    [self setupView];
}

@end
