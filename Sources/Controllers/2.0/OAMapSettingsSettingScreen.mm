//
//  OAMapSettingsSettingScreen.m
//  OsmAnd
//
//  Created by Alexey Kulish on 23/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAMapSettingsSettingScreen.h"
#import "OAMapSettingsViewController.h"
#import "OAMapStyleSettings.h"
#import "OASettingsTableViewCell.h"
#import "Localization.h"

@implementation OAMapSettingsSettingScreen
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;

    NSArray* data;
}

@synthesize settingsScreen, tableData, vwController, tblView, title, isOnlineMapSource, settingKeyName;


- (id) initWithTable:(UITableView *)tableView viewController:(OAMapSettingsViewController *)viewController param:(id)param
{
    self = [super init];
    if (self) {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
        
        settingKeyName = param;
        
        settingsScreen = EMapSettingsScreenSetting;
        
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
}

- (void) setupView
{
    if ([settingKeyName isEqualToString:settingAppModeKey])
    {
        title = OALocalizedString(@"map_settings_mode");
        int mode = _settings.settingAppMode;
        data = @[
                 @{
                     @"name" : OALocalizedString(@"daynight_mode_auto"),
                     @"value" : @"",
                     @"img" : mode == APPEARANCE_MODE_AUTO ? @"menu_cell_selected.png" : @"" },
                 @{
                     @"name" : OALocalizedString(@"map_settings_day"),
                     @"value" : @"",
                     @"img" : mode == APPEARANCE_MODE_DAY ? @"menu_cell_selected.png" : @"" },
                 @{
                     @"name" : OALocalizedString(@"map_settings_night"),
                     @"value" : @"",
                     @"img" : mode == APPEARANCE_MODE_NIGHT ? @"menu_cell_selected.png" : @"" }
                 ];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return data.count;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
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
        [cell.textView setText: [data[indexPath.row] objectForKey:@"name"]];
        [cell.descriptionView setText: [data[indexPath.row] objectForKey:@"value"]];
        NSString *imgName = [data[indexPath.row] objectForKey:@"img"];
        if (imgName.length > 0)
            [cell.iconView setImage:[UIImage imageNamed:imgName]];
        else
            [cell.iconView setImage:nil];
    }
    
    return cell;
    
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = data[indexPath.row];
    return [OASettingsTableViewCell getHeight:[item objectForKey:@"name"] value:[item objectForKey:@"value"] cellWidth:tableView.bounds.size.width];
}

#pragma mark - UITableViewDelegate

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.01;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([settingKeyName isEqualToString:settingAppModeKey])
    {
        int index = (int)indexPath.row;
        if (index == 1)
            [_settings setSettingAppMode:APPEARANCE_MODE_DAY];
        else if (index == 2)
            [_settings setSettingAppMode:APPEARANCE_MODE_NIGHT];
        else
            [_settings setSettingAppMode:APPEARANCE_MODE_AUTO];
    }
    
    [self setupView];
    [tableView reloadData];
}

@end
