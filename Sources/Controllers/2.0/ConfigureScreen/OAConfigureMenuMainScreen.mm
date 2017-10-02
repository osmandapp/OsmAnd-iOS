//
//  OAConfigureMenuMainScreen.m
//  OsmAnd
//
//  Created by Alexey Kulish on 29/09/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAConfigureMenuMainScreen.h"
#import "OAConfigureMenuViewController.h"
#import "Localization.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "OAAppModeCell.h"
#import "OASettingsTableViewCell.h"
#import "OASwitchTableViewCell.h"

@interface OAConfigureMenuMainScreen () <OAAppModeCellDelegate>

@end

@implementation OAConfigureMenuMainScreen
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    
    OAAppModeCell *_appModeCell;
}

@synthesize configureMenuScreen, tableData, vwController, tblView, title;

- (id) initWithTable:(UITableView *)tableView viewController:(OAConfigureMenuViewController *)viewController
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
        
        title = OALocalizedString(@"layer_map_appearance");
        configureMenuScreen = EConfigureMenuScreenMain;
        
        vwController = viewController;
        tblView = tableView;
        [self initData];
    }
    return self;
}

- (void) initData
{
}

- (void) setupView
{
    NSMutableDictionary *sectionMapStyle = [NSMutableDictionary dictionary];
    [sectionMapStyle setObject:@"OAAppModeCell" forKey:@"type"];
    
    NSMutableArray *arr = [NSMutableArray array];
    
    NSDictionary *mapStyles = @{@"groupName": @"",
                                @"cells": @[sectionMapStyle]
                                };
    [arr addObject:mapStyles];
    
    // Right panel
    NSMutableArray *controlsList = [NSMutableArray array];
    [controlsList addObject:@{@"name": OALocalizedString(@"map_settings_mode"),
                                @"value": _settings.settingAppMode == 0 ? OALocalizedString(@"map_settings_day") : OALocalizedString(@"map_settings_night"),
                                @"type": @"OASettingsCell"}];
    
    NSArray *leftControls = @[ @{@"groupName": OALocalizedString(@"map_widget_right"),
                                 @"cells": controlsList,
                                 }
                               ];
    
    tableData = [arr arrayByAddingObjectsFromArray:leftControls];

    // Left panel

}

#pragma mark - OAAppModeCellDelegate

- (void) appModeChanged:(OAApplicationMode *)mode
{
    [vwController waitForIdle];
    _settings.applicationMode = mode;
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return [tableData count];
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [((NSDictionary*)tableData[section]) objectForKey:@"groupName"];
}


- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [((NSArray*)[((NSDictionary*)tableData[section]) objectForKey:@"cells"]) count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary* data = (NSDictionary*)[((NSArray*)[((NSDictionary*)tableData[indexPath.section]) objectForKey:@"cells"]) objectAtIndex:indexPath.row];
    if ([[data objectForKey:@"type"] isEqualToString:@"OAAppModeCell"])
    {
        return 44.0;
    }
    else if ([[data objectForKey:@"type"] isEqualToString:@"OASettingsCell"])
    {
        return [OASettingsTableViewCell getHeight:[data objectForKey:@"name"] value:[data objectForKey:@"value"] cellWidth:tableView.bounds.size.width];
    }
    else if ([[data objectForKey:@"type"] isEqualToString:@"OASwitchCell"])
    {
        return [OASwitchTableViewCell getHeight:[data objectForKey:@"name"] cellWidth:tableView.bounds.size.width];
    }
    else
    {
        return 44.0;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary* data = (NSDictionary*)[((NSArray*)[((NSDictionary*)tableData[indexPath.section]) objectForKey:@"cells"]) objectAtIndex:indexPath.row];
    
    UITableViewCell* outCell = nil;
    if ([[data objectForKey:@"type"] isEqualToString:@"OAAppModeCell"])
    {
        if (!_appModeCell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAAppModeCell" owner:self options:nil];
            _appModeCell = (OAAppModeCell *)[nib objectAtIndex:0];
            _appModeCell.showDefault = YES;
            _appModeCell.selectedMode = [OAAppSettings sharedManager].applicationMode;
            _appModeCell.delegate = self;
        }
        
        outCell = _appModeCell;
    }
    else if ([[data objectForKey:@"type"] isEqualToString:@"OASettingsCell"])
    {
        static NSString* const identifierCell = @"OASettingsTableViewCell";
        OASettingsTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASettingsCell" owner:self options:nil];
            cell = (OASettingsTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            [cell.textView setText:[data objectForKey:@"name"]];
            [cell.descriptionView setText:[data objectForKey:@"value"]];
        }
        outCell = cell;
    }
    else if ([[data objectForKey:@"type"] isEqualToString:@"OASwitchCell"])
    {
        static NSString* const identifierCell = @"OASwitchTableViewCell";
        OASwitchTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASwitchCell" owner:self options:nil];
            cell = (OASwitchTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            [cell.textView setText: [data objectForKey:@"name"]];
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            
            //[cell.switchView setOn:_settings.mapSettingShowFavorites];
            //[cell.switchView addTarget:self action:@selector(showFavoriteChanged:) forControlEvents:UIControlEventValueChanged];
        }
        outCell = cell;
    }
    
    return outCell;
}

#pragma mark - UITableViewDelegate

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSDictionary* data = (NSDictionary*)[((NSArray*)[((NSDictionary*)tableData[section]) objectForKey:@"cells"]) objectAtIndex:0];
    if ([[data objectForKey:@"type"] isEqualToString:@"OAAppModeCell"])
        return 0.01;
    else
        return 34.0;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAConfigureMenuViewController *configureMenuViewController;
    /*
    NSInteger section = indexPath.section;
    if (mapStyleCellPresent)
        section--;
    
    switch (section)
    {
        case 0:
        {
            if (indexPath.row == 1) {
                mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenGpx];
            }
            
            break;
        }
            
        case 1: // Map Type
        {
            mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenMapType];
            
            break;
        }
            
        case 2: // Map Style
        {
            if (mapStyleCellPresent)
            {
                NSArray *categories = [styleSettings getAllCategories];
                NSArray *topLevelParams = [styleSettings getParameters:@""];
                
                if (indexPath.row == 0)
                {
                    mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenSetting param:settingAppModeKey];
                }
                else if (indexPath.row <= categories.count)
                {
                    mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenCategory param:categories[indexPath.row - 1]];
                }
                else
                {
                    OAMapStyleParameter *p = topLevelParams[indexPath.row - categories.count - 1];
                    if (p.dataType != OABoolean)
                    {
                        OAMapSettingsViewController *mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenParameter param:p.name];
                        
                        [mapSettingsViewController show:vwController.parentViewController parentViewController:vwController animated:YES];
                    }
                }
                break;
            }
        }
        case 3:
        {
            NSInteger index = 0;
            if ([[OAIAPHelper sharedInstance] productPurchased:kInAppId_Addon_Srtm])
                index++;
            
            if (indexPath.row == index)
                mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenOverlay];
            else if (indexPath.row == index + 1)
                mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenUnderlay];
            
            break;
        }
        case 4:
        {
            mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenLanguage];
            break;
        }
            
        default:
            break;
    }
    */
    
    if (configureMenuViewController)
        [configureMenuViewController show:vwController.parentViewController parentViewController:vwController animated:YES];
    
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

@end
