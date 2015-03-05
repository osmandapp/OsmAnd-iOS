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
#import "OAMapStyleSettings.h"
#import "OAGPXDatabase.h"


@implementation OAMapSettingsMainScreen {
    
    OAMapStyleSettings *styleSettings;
    
}


@synthesize settingsScreen, app, tableData, vwController, tblView, settings, title, isOnlineMapSource;


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
    
    NSMutableDictionary *section0fav = [NSMutableDictionary dictionary];
    [section0fav setObject:@"Favorite" forKey:@"name"];
    [section0fav setObject:@"" forKey:@"value"];
    [section0fav setObject:@"OASwitchCell" forKey:@"type"];

    NSMutableDictionary *section0tracks = [NSMutableDictionary dictionary];
    [section0tracks setObject:@"Tracks" forKey:@"name"];
    [section0tracks setObject:@"" forKey:@"value"];
    [section0tracks setObject:@"OASettingsCell" forKey:@"type"];

    NSMutableArray *section0 = [NSMutableArray array];
    [section0 addObject:section0fav];
    if ([[[OAGPXDatabase sharedDb] gpxList] count] > 0)
        [section0 addObject:section0tracks];
    
    
    NSArray *arrTop = @[@{@"groupName": @"Show on Map",
                          @"cells": section0
                          },
                        @{@"groupName": @"Map Type",
                          @"cells": @[
                                  @{@"name": @"Map Type",
                                    @"value": app.data.lastMapSource.name,
                                    @"type": @"OASettingsCell"}
                                  ],
                          }
                        ];
    
    if (isOnlineMapSource) {
        tableData = arrTop;
        
    } else {
        
        styleSettings = [[OAMapStyleSettings alloc] init];
        
        NSArray *categories = [styleSettings getAllCategories];
        
        NSMutableArray *categoriesList = [NSMutableArray array];
        [categoriesList addObject:@{@"name": @"Application mode",
                                    @"value": settings.settingAppMode == 0 ? @"Day" : @"Night",
                                    @"type": @"OASettingsCell"}];
        
        for (NSString *cName in categories)
            [categoriesList addObject:@{@"name": [styleSettings getCategoryTitle:cName],
                                        @"value": @"",
                                        @"type": @"OASettingsCell"}];
        
        NSArray *arrStyles = @[@{@"groupName": @"Map Style",
                                 @"cells": categoriesList,
                                 }
                               ];

        
        tableData = [arrTop arrayByAddingObjectsFromArray:arrStyles];
    }

    
    NSArray *arrOverlayUnderlay = @[@{@"groupName": @"Overlay / Underlay",
                                      @"cells": @[
                                              @{@"name": @"Overlay",
                                                @"value": (app.data.overlayMapSource != nil) ? app.data.overlayMapSource.name : @"None",
                                                @"type": @"OASettingsCell"},
                                              @{@"name": @"Underlay",
                                                @"value": (app.data.underlayMapSource != nil) ? app.data.underlayMapSource.name : @"None",
                                                @"type": @"OASettingsCell"}
                                              ]
                                      }
                                    ];

    tableData = [tableData arrayByAddingObjectsFromArray:arrOverlayUnderlay];

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
    UISwitch *switchView = (UISwitch*)sender;
    if (switchView) {
        [settings setMapSettingShowFavorites:switchView.isOn];
    }
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 34.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    switch (indexPath.section) {
        case 0:
        {
            if (indexPath.row == 1) {
                OAMapSettingsViewController *mapSourcesViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenGpx];
                [vwController.navigationController pushViewController:mapSourcesViewController animated:YES];
            }
                
            break;
        }
        
        case 1: // Map Type
        {
            OAMapSettingsViewController *mapSourcesViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenMapType];
            [vwController.navigationController pushViewController:mapSourcesViewController animated:YES];

            break;
        }
            
        case 2: // Map Style
        {
            if (indexPath.row == 0) {
                OAMapSettingsViewController *mapSourcesViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenSetting param:settingAppModeKey];
                [vwController.navigationController pushViewController:mapSourcesViewController animated:YES];
                
            } else {
                
                NSArray *categories = [styleSettings getAllCategories];
                
                OAMapSettingsViewController *mapSourcesViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenCategory param:categories[indexPath.row - 1]];
                [vwController.navigationController pushViewController:mapSourcesViewController animated:YES];
            }
            break;
        }
            
        default:
            break;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}


@end
