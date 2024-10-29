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
#import "OAValueTableViewCell.h"
#import "Localization.h"
#import "OADayNightHelper.h"
#import "OAObservable.h"
#import "OsmAndApp.h"

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
    if ([settingKeyName isEqualToString:mapDensityKey])
    {
        title = OALocalizedString(@"map_magnifier");
        double value = [_settings.mapDensity get];
        
        data = @[
                 @{
                     @"name" : @"25 %",
                     @"val" : @(0.25),
                     @"img" : value == 0.25 ? @"menu_cell_selected.png" : @"" },
                 @{
                     @"name" : @"33 %",
                     @"val" : @(0.33),
                     @"img" : value == 0.33 ? @"menu_cell_selected.png" : @"" },
                 @{
                     @"name" : @"50 %",
                     @"val" : @(0.5),
                     @"img" : value == 0.5 ? @"menu_cell_selected.png" : @"" },
                 @{
                     @"name" : @"75 %",
                     @"val" : @(0.75),
                     @"img" : value == 0.75 ? @"menu_cell_selected.png" : @"" },
                 @{
                     @"name" : @"100 %",
                     @"val" : @(1.0),
                     @"img" : value == 1.0 ? @"menu_cell_selected.png" : @"" },
                 @{
                     @"name" : @"125 %",
                     @"val" : @(1.25),
                     @"img" : value == 1.25 ? @"menu_cell_selected.png" : @"" },
                 @{
                     @"name" : @"150 %",
                     @"val" : @(1.5),
                     @"img" : value == 1.5 ? @"menu_cell_selected.png" : @"" },
                 @{
                     @"name" : @"200 %",
                     @"val" : @(2.0),
                     @"img" : value == 2.0 ? @"menu_cell_selected.png" : @"" },
                 @{
                     @"name" : @"300 %",
                     @"val" : @(3.0),
                     @"img" : value == 3.0 ? @"menu_cell_selected.png" : @"" },
                 @{
                     @"name" : @"400 %",
                     @"val" : @(4.0),
                     @"img" : value == 4.0 ? @"menu_cell_selected.png" : @"" }
                 ];
    }
    else if ([settingKeyName isEqualToString:textSizeKey])
    {
        title = OALocalizedString(@"text_size");
        double value = [_settings.textSize get:_settings.applicationMode.get];
        
        data = @[
                 @{
                     @"name" : @"75 %",
                     @"val" : @(0.75),
                     @"img" : value == 0.75 ? @"menu_cell_selected.png" : @"" },
                 @{
                     @"name" : @"100 %",
                     @"val" : @(1.0),
                     @"img" : value == 1.0 ? @"menu_cell_selected.png" : @"" },
                 @{
                     @"name" : @"125 %",
                     @"val" : @(1.25),
                     @"img" : value == 1.25 ? @"menu_cell_selected.png" : @"" },
                 @{
                     @"name" : @"150 %",
                     @"val" : @(1.5),
                     @"img" : value == 1.5 ? @"menu_cell_selected.png" : @"" },
                 @{
                     @"name" : @"200 %",
                     @"val" : @(2.0),
                     @"img" : value == 2.0 ? @"menu_cell_selected.png" : @"" },
                 @{
                     @"name" : @"300 %",
                     @"val" : @(3.0),
                     @"img" : value == 3.0 ? @"menu_cell_selected.png" : @"" }
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
        [cell.titleLabel setText: [data[indexPath.row] objectForKey:@"name"]];
        [cell.valueLabel setText: [data[indexPath.row] objectForKey:@"value"]];
        NSString *imgName = [data[indexPath.row] objectForKey:@"img"];
        if (imgName.length > 0)
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        else
            cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.01;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([settingKeyName isEqualToString:mapDensityKey])
    {
        NSDictionary *item = data[indexPath.row];
        [_settings.mapDensity set:[item[@"val"] doubleValue] mode:_settings.applicationMode.get];
        [[[OsmAndApp instance] mapSettingsChangeObservable] notifyEvent];
    }
    else if ([settingKeyName isEqualToString:textSizeKey])
    {
        NSDictionary *item = data[indexPath.row];
        [_settings.textSize set:[item[@"val"] doubleValue] mode:_settings.applicationMode.get];
        [[[OsmAndApp instance] mapSettingsChangeObservable] notifyEvent];
    }
    
    [self setupView];
    [tableView reloadData];
}

@end
