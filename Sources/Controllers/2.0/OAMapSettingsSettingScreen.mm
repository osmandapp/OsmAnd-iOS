//
//  OAMapSettingsSettingScreen.m
//  OsmAnd
//
//  Created by Alexey Kulish on 23/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAMapSettingsSettingScreen.h"
#import "OAMapStyleSettings.h"
#import "OASettingsTableViewCell.h"

@implementation OAMapSettingsSettingScreen {
    
    NSArray* data;
}


@synthesize settingsScreen, app, tableData, vwController, tblView, settings, title, isOnlineMapSource, settingKeyName;


-(id)initWithTable:(UITableView *)tableView viewController:(OAMapSettingsViewController *)viewController param:(id)param
{
    self = [super init];
    if (self) {
        app = [OsmAndApp instance];
        settings = [OAAppSettings sharedManager];
        
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
        title = @"Application mode";
        data = @[@{@"name": @"Day", @"value": @"", @"img": settings.settingAppMode == 0 ? @"menu_cell_selected.png" : @""},
                 @{@"name": @"Night", @"value": @"", @"img": settings.settingAppMode == 1 ? @"menu_cell_selected.png" : @""}
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
    
    if (cell) {
        [cell.textView setText: [data[indexPath.row] objectForKey:@"name"]];
        [cell.descriptionView setText: [data[indexPath.row] objectForKey:@"value"]];
        [cell.iconView setImage:[UIImage imageNamed:[data[indexPath.row] objectForKey:@"img"]]];
    }
    
    return cell;
    
}


#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 5.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([settingKeyName isEqualToString:settingAppModeKey]) {
        [settings setSettingAppMode:indexPath.row];
    }
    
    [self setupView];
    [tableView reloadData];
}



@end
