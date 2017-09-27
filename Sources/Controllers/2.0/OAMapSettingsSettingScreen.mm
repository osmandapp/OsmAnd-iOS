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

- (void)dealloc
{
    [self deinit];
}

- (void)commonInit
{
}

- (void)deinit
{
}

-(void)initData
{
}

- (void)setupView
{
    if ([settingKeyName isEqualToString:settingAppModeKey]) {
        title = OALocalizedString(@"map_settings_mode");
        data = @[@{@"name": OALocalizedString(@"map_settings_day"), @"value": @"", @"img": _settings.settingAppMode == 0 ? @"menu_cell_selected.png" : @""},
                 @{@"name": OALocalizedString(@"map_settings_night"), @"value": @"", @"img": _settings.settingAppMode == 1 ? @"menu_cell_selected.png" : @""}
                 ];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return data.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
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
        [cell.iconView setImage:[UIImage imageNamed:[data[indexPath.row] objectForKey:@"img"]]];
    }
    
    return cell;
    
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = data[indexPath.row];
    return [OASettingsTableViewCell getHeight:[item objectForKey:@"name"] value:[item objectForKey:@"value"] cellWidth:tableView.bounds.size.width];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.01;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([settingKeyName isEqualToString:settingAppModeKey])
        [_settings setSettingAppMode:(int)indexPath.row];
    
    [self setupView];
    [tableView reloadData];
}



@end
