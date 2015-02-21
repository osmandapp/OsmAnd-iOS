//
//  OAMapSettingsMainScreen.m
//  OsmAnd
//
//  Created by Alexey Kulish on 21/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAMapSettingsMainScreen.h"
#import "OASettingsTableViewCell.h"
#import "OASwitchTableViewCell.h"


@implementation OAMapSettingsMainScreen {
    
    BOOL isFavoriteOn;
    
}

@synthesize settingsScreen, app, tableData, vwController, tblView, settings, title;


-(id)initWithTable:(UITableView *)tableView viewController:(OAMapSettingsViewController *)viewController
{
    self = [super init];
    if (self) {
        app = [OsmAndApp instance];
        settings = [OAAppSettings sharedManager];
        title = @"Map";

        settingsScreen = EMapSettingsScreenMain;
        
        vwController = viewController;
        tblView = tableView;
        [self initData];
    }
    return self;
}

- (void) initData
{
}

-(void)setupView
{
    isFavoriteOn = settings.mapSettingShowFavorites;
    
    tableData = @[@{@"groupName": @"Show on Map",
                         @"cells": @[
                                 @{@"name": @"Favorite",
                                   @"value": @"",
                                   @"type": @"OASwitchCell"},
                                 @{@"name": @"GPX",
                                   @"value": @"",
                                   @"type": @"OASettingsCell"}
                                 ]
                         },
                       @{@"groupName": @"Map Type",
                         @"cells": @[
                                 @{@"name": @"Map Type",
                                   @"value": app.data.lastMapSourceName,
                                   @"type": @"OASettingsCell"}
                                 ],
                         },
                       @{@"groupName": @"Map Style",
                         @"cells": @[
                                 @{@"name": @"Details",
                                   @"value": @"",
                                   @"type": @"OASettingsCell"},
                                 @{@"name": @"Routes",
                                   @"value": @"",
                                   @"type": @"OASettingsCell"},
                                 @{@"name": @"Hide",
                                   @"value": @"",
                                   @"type": @"OASettingsCell"}
                                 
                                 ],
                         }
                       ];

    [tblView reloadData];
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [tableData count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [((NSDictionary*)[tableData objectAtIndex:section]) objectForKey:@"groupName"];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [((NSArray*)[((NSDictionary*)[tableData objectAtIndex:section]) objectForKey:@"cells"]) count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary* data = (NSDictionary*)[((NSArray*)[((NSDictionary*)[tableData objectAtIndex:indexPath.section]) objectForKey:@"cells"]) objectAtIndex:indexPath.row];
    
    UITableViewCell* outCell = nil;
    if ([[data objectForKey:@"type"] isEqualToString:@"OASettingsCell"]) {
        
        static NSString* const identifierCell = @"OASettingsTableViewCell";
        OASettingsTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASettingsCell" owner:self options:nil];
            cell = (OASettingsTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell) {
            [cell.textView setText: [data objectForKey:@"name"]];
            [cell.descriptionView setText: [data objectForKey:@"value"]];
        }
        outCell = cell;
        
    } else if ([[data objectForKey:@"type"] isEqualToString:@"OASwitchCell"]) {
        
        static NSString* const identifierCell = @"OASwitchTableViewCell";
        OASwitchTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASwitchCell" owner:self options:nil];
            cell = (OASwitchTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell) {
            [cell.textView setText: [data objectForKey:@"name"]];
            
            if (indexPath.section == 0 && indexPath.row == 0) {
                [cell.switchView setOn:settings.mapSettingShowFavorites];
                [cell.switchView addTarget:self action:@selector(showFavoriteChanged:) forControlEvents:UIControlEventValueChanged];
            }
            
        }
        outCell = cell;
    }
    
    return outCell;
}

- (void)showFavoriteChanged:(id)sender
{
    isFavoriteOn = !isFavoriteOn;
    [settings setMapSettingShowFavorites:isFavoriteOn];
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    switch (indexPath.section) {
            
        case 1: // Map Type
        {
            OAMapSettingsViewController *mapSourcesViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenMapType];
            [vwController.navigationController pushViewController:mapSourcesViewController animated:YES];
            break;
        }
            
        case 2: // Map Style
        {
            /*
             OAMapSettingsSubviewController* settingsSubviewController;
             switch (indexPath.row) {
             case 0:
             settingsSubviewController = [[OAMapSettingsSubviewController alloc] initWithSettingsType:kMapSettingsScreenDetails];
             _action = EMapSettingsActionDetails;
             break;
             case 1:
             settingsSubviewController = [[OAMapSettingsSubviewController alloc] initWithSettingsType:kMapSettingsScreenRoutes];
             _action = EMapSettingsActionRoutes;
             break;
             case 2:
             settingsSubviewController = [[OAMapSettingsSubviewController alloc] initWithSettingsType:kMapSettingsScreenHide];
             _action = EMapSettingsActionHide;
             break;
             default:
             break;
             }
             
             if (settingsSubviewController) {
             [self.navigationController pushViewController:settingsSubviewController animated:YES];
             }
             */
            break;
        }
            
        default:
            break;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}


@end
