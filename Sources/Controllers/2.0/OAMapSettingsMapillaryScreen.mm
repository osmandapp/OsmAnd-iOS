//
//  OAMapSettingsMapillaryScreen.m
//  OsmAnd
//
//  Created by Paul on 31/05/19.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAMapSettingsMapillaryScreen.h"
#import "OAMapSettingsViewController.h"
#import "OASearchUICore.h"
#import "OAQuickSearchHelper.h"
#import "OAQuickSearchListItem.h"
#import "Localization.h"
#import "OACustomSearchPoiFilter.h"
#import "OAUtilities.h"
#import "OAIconTextDescCell.h"
#import "OAIconTextTableViewCell.h"
#import "OAQuickSearchButtonListItem.h"
#import "OAIconButtonCell.h"
#import "OAPOIUIFilter.h"
#import "OAPOIFiltersHelper.h"
#import "OAMapViewController.h"
#import "OARootViewController.h"
#import "OAIconTitleButtonCell.h"
#import "OASettingSwitchCell.h"

@implementation OAMapSettingsMapillaryScreen
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    
    NSArray *_data;
}

@synthesize settingsScreen, tableData, vwController, tblView, title, isOnlineMapSource;

- (id) initWithTable:(UITableView *)tableView viewController:(OAMapSettingsViewController *)viewController
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
        settingsScreen = EMapSettingsScreenPOI;
        vwController = viewController;
        tblView = tableView;
        
        [self commonInit];
        [self initData];
    }
    return self;
}

- (void) dealloc
{
    [self deinit];
}

- (void) commonInit
{
}

- (void) deinit
{
}

- (void) initData
{
    NSMutableArray *dataArr = [NSMutableArray new];
    NSMutableArray *sectionArray = [NSMutableArray new];
    
    BOOL mapillaryEnabled = _app.data.mapillary;
    
    // Visibility/cache section
    [sectionArray addObject:@{
                         @"type" : @"OASettingSwitchCell",
                         @"title" : mapillaryEnabled ? OALocalizedString(@"shared_string_enabled") : OALocalizedString(@"rendering_value_disabled_name"),
                         @"description" : @"",
                         @"img" : mapillaryEnabled ? @"ic_custom_show.png" : @"ic_custom_hide.png",
                         @"value" : @(mapillaryEnabled)
                         }];
    
    [sectionArray addObject:@{
                              @"type" : @"OAIconTitleButtonCell",
                              @"title" : OALocalizedString(@"tile_cache"),
                              @"btnTitle" : OALocalizedString(@"shared_string_reload"),
                              @"description" : @"",
                              @"img" : @"ic_custom_overlay_map.png"
                              }];
    
    [dataArr addObject:[NSArray arrayWithArray:sectionArray]];
    [sectionArray removeAllObjects];
    
    _data = [NSArray arrayWithArray:dataArr];
}

- (NSDictionary *)getItem:(NSIndexPath *)indexPath
{
    NSArray *section = _data[indexPath.section];
    return section[indexPath.row];
}

- (void) setupView
{
    title = OALocalizedString(@"poi_overlay");
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *sectionItems = _data[section];
    return sectionItems.count;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    
    if ([item[@"type"] isEqualToString:@"OASettingSwitchCell"])
    {
        static NSString* const identifierCell = @"OASettingSwitchCell";
        OASettingSwitchCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASettingSwitchCell" owner:self options:nil];
            cell = (OASettingSwitchCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            cell.textView.text = item[@"title"];
            NSString *desc = item[@"description"];
            cell.descriptionView.text = desc;
            cell.descriptionView.hidden = desc.length == 0;
            cell.imgView.image = [UIImage imageNamed:item[@"img"]];
            [cell.switchView setOn:[item[@"value"] boolValue]];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:@"OAIconTitleButtonCell"])
    {
        static NSString* const identifierCell = @"OAIconTitleButtonCell";
        OAIconTitleButtonCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAIconTitleButtonCell" owner:self options:nil];
            cell = (OAIconTitleButtonCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            cell.titleView.text = item[@"title"];
            cell.iconView.image = [UIImage imageNamed:item[@"img"]];
            [cell setButtonText:item[@"btnTitle"]];
        }
        return cell;
    }
    return nil;
}

#pragma mark - UITableViewDelegate

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return 0.01;
        case 1:
            return 30.0;

        default:
            return 0.01;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return OALocalizedString(@"mapil_reload_cache");
            
        default:
            return nil;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return nil;
        case 1:
            return OALocalizedString(@"shared_string_filter");
            
        default:
            return nil;
    }
}

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50.0;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50.0;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}
@end
