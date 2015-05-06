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
#import "OAMapSource.h"
#import "OAMapStylesCell.h"
#import "Localization.h"
#import "OASavingTrackHelper.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/IMapStylesCollection.h>
#include <OsmAndCore/Map/IMapStylesPresetsCollection.h>


@implementation OAMapSettingsMainScreen {
    
    OAMapStyleSettings *styleSettings;
    NSInteger mapStyleIndex;
    
    OAMapStylesCell *mapStylesCell;
    
    BOOL mapStyleCellPresent;
    NSInteger favSection;
    NSInteger favRow;
}


@synthesize settingsScreen, app, tableData, vwController, tblView, settings, title, isOnlineMapSource;


-(id)initWithTable:(UITableView *)tableView viewController:(OAMapSettingsViewController *)viewController
{
    self = [super init];
    if (self) {
        app = [OsmAndApp instance];
        settings = [OAAppSettings sharedManager];
        title = OALocalizedString(@"map_settings_map");

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

- (void)changeMapTypeButtonClicked:(id)sender
{    
    int tag = ((UIButton*)sender).tag;
    
    OAMapSource* mapSource = app.data.lastMapSource;
    NSString *name = mapSource.name;
    const auto resource = app.resourcesManager->getResource(QString::fromNSString(mapSource.resourceId));
    NSString* resourceId = resource->id.toNSString();
    
    // Get the style
    const auto& mapStyle = std::static_pointer_cast<const OsmAnd::ResourcesManager::MapStyleMetadata>(resource->metadata)->mapStyle;
    const auto& presets = self.app.resourcesManager->mapStylesPresetsCollection->getCollectionFor(mapStyle->name);
    
    OsmAnd::MapStylePreset::Type selectedType = [OAMapSettingsMainScreen tagToMapStyle:tag];
    
    BOOL foundPreset = NO;
    for(const auto& preset : presets)
    {
        if (preset->type == selectedType) {
            
            OAMapSource* mapSource = [[OAMapSource alloc] initWithResource:resourceId andVariant:preset->name.toNSString() name:name];
            app.data.lastMapSource = mapSource;
            
            foundPreset = YES;
            break;
        }
    }
    
    if (!foundPreset) {
        [mapStylesCell setupMapTypeButtons:0];
    }
    
    [self setupView];
    
}

-(void)setupView
{
    
    NSMutableDictionary *sectionMapStyle = [NSMutableDictionary dictionary];
    [sectionMapStyle setObject:@"OAMapStylesCell" forKey:@"type"];

    NSMutableDictionary *section0fav = [NSMutableDictionary dictionary];
    [section0fav setObject:OALocalizedString(@"favorite") forKey:@"name"];
    [section0fav setObject:@"" forKey:@"value"];
    [section0fav setObject:@"OASwitchCell" forKey:@"type"];

    NSMutableDictionary *section0tracks = [NSMutableDictionary dictionary];
    [section0tracks setObject:OALocalizedString(@"tracks") forKey:@"name"];
    [section0tracks setObject:@"" forKey:@"value"];
    [section0tracks setObject:@"OASettingsCell" forKey:@"type"];

    NSMutableArray *section0 = [NSMutableArray array];
    [section0 addObject:section0fav];
    if ([[[OAGPXDatabase sharedDb] gpxList] count] > 0 || [[OASavingTrackHelper sharedInstance] hasData])
        [section0 addObject:section0tracks];
    
    OsmAnd::MapStylePreset::Type mapStyle = [OAMapSettingsMainScreen variantToMapStyle:app.data.lastMapSource.variant];
    mapStyleIndex = [OAMapSettingsMainScreen mapStyleToTag:mapStyle];
    
    NSArray *arrTop = @[@{@"groupName": OALocalizedString(@"map_settings_show"),
                          @"cells": section0
                          },
                        @{@"groupName": OALocalizedString(@"map_settings_type"),
                          @"cells": @[
                                  @{@"name": OALocalizedString(@"map_settings_type"),
                                    @"value": app.data.lastMapSource.name,
                                    @"type": @"OASettingsCell"}
                                  ],
                          }
                        ];
    
    if (isOnlineMapSource) {
        tableData = arrTop;
        mapStyleCellPresent = NO;
        favSection = 0;
        favRow = 0;
        
    } else {
        
        NSMutableArray *arr = [NSMutableArray arrayWithArray:arrTop];

        NSDictionary *mapStyles = @{@"groupName": @"",
                                    @"cells": @[sectionMapStyle]
                                    };
        [arr insertObject:mapStyles atIndex:0];

        mapStyleCellPresent = YES;
        favSection = 1;
        favRow = 0;
        
        styleSettings = [[OAMapStyleSettings alloc] init];
        
        NSArray *categories = [styleSettings getAllCategories];
        NSArray *topLevelParams = [styleSettings getParameters:@""];
        
        NSMutableArray *categoriesList = [NSMutableArray array];
        [categoriesList addObject:@{@"name": OALocalizedString(@"map_settings_mode"),
                                    @"value": settings.settingAppMode == 0 ? OALocalizedString(@"map_settings_day") : OALocalizedString(@"map_settings_night"),
                                    @"type": @"OASettingsCell"}];
        
        for (NSString *cName in categories)
            [categoriesList addObject:@{@"name": [styleSettings getCategoryTitle:cName],
                                        @"value": @"",
                                        @"type": @"OASettingsCell"}];
        for (OAMapStyleParameter *p in topLevelParams)
            [categoriesList addObject:@{@"name": p.title,
                                        @"value": [p getValueTitle],
                                        @"type": @"OASettingsCell"}];
        
        NSArray *arrStyles = @[@{@"groupName": OALocalizedString(@"map_settings_style"),
                                 @"cells": categoriesList,
                                 }
                               ];

        
        tableData = [arr arrayByAddingObjectsFromArray:arrStyles];
    }

    
    NSArray *arrOverlayUnderlay = @[@{@"groupName": OALocalizedString(@"map_settings_overunder"),
                                      @"cells": @[
                                              @{@"name": OALocalizedString(@"map_settings_over"),
                                                @"value": (app.data.overlayMapSource != nil) ? app.data.overlayMapSource.name : OALocalizedString(@"map_settings_none"),
                                                @"type": @"OASettingsCell"},
                                              @{@"name": OALocalizedString(@"map_settings_under"),
                                                @"value": (app.data.underlayMapSource != nil) ? app.data.underlayMapSource.name : OALocalizedString(@"map_settings_none"),
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
    return [((NSDictionary*)tableData[section]) objectForKey:@"groupName"];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [((NSArray*)[((NSDictionary*)tableData[section]) objectForKey:@"cells"]) count];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary* data = (NSDictionary*)[((NSArray*)[((NSDictionary*)tableData[indexPath.section]) objectForKey:@"cells"]) objectAtIndex:indexPath.row];
    if ([[data objectForKey:@"type"] isEqualToString:@"OAMapStylesCell"])
        return 70.0;
    else
        return 44.0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary* data = (NSDictionary*)[((NSArray*)[((NSDictionary*)tableData[indexPath.section]) objectForKey:@"cells"]) objectAtIndex:indexPath.row];
    
    UITableViewCell* outCell = nil;
    if ([[data objectForKey:@"type"] isEqualToString:@"OAMapStylesCell"]) {
        
        if (!mapStylesCell) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAMapStylesCell" owner:self options:nil];
            mapStylesCell = (OAMapStylesCell *)[nib objectAtIndex:0];
            [mapStylesCell.mapTypeButtonView addTarget:self action:@selector(changeMapTypeButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
            [mapStylesCell.mapTypeButtonCar addTarget:self action:@selector(changeMapTypeButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
            [mapStylesCell.mapTypeButtonWalk addTarget:self action:@selector(changeMapTypeButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
            [mapStylesCell.mapTypeButtonBike addTarget:self action:@selector(changeMapTypeButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        }
        
        [mapStylesCell setSelectedIndex:mapStyleIndex];
        
        outCell = mapStylesCell;
        
    } else if ([[data objectForKey:@"type"] isEqualToString:@"OASettingsCell"]) {
        
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
        
        if (cell)
        {
            [cell.textView setText: [data objectForKey:@"name"]];
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            
            if (indexPath.section == favSection && indexPath.row == favRow) {
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

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSDictionary* data = (NSDictionary*)[((NSArray*)[((NSDictionary*)tableData[section]) objectForKey:@"cells"]) objectAtIndex:0];
    if ([[data objectForKey:@"type"] isEqualToString:@"OAMapStylesCell"])
        return 0.01;
    else
        return 34.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    OAMapSettingsViewController *mapSettingsViewController;
    
    NSInteger section = indexPath.section;
    if (mapStyleCellPresent)
        section--;
    
    switch (section) {
        case 0:
        {
            if (indexPath.row == 1) {
                mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenGpx popup:vwController.isPopup];
            }
                
            break;
        }
        
        case 1: // Map Type
        {
            mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenMapType popup:vwController.isPopup];

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
                    mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenSetting param:settingAppModeKey popup:vwController.isPopup];
                }
                else if (indexPath.row <= categories.count)
                {
                    mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenCategory param:categories[indexPath.row - 1] popup:vwController.isPopup];
                }
                else
                {
                    OAMapStyleParameter *p = topLevelParams[indexPath.row - categories.count - 1];
                    if (p.dataType != OABoolean) {
                        OAMapSettingsViewController *mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenParameter param:p.name popup:vwController.isPopup];
                        
                        if (!vwController.isPopup)
                            [vwController.navigationController pushViewController:mapSettingsViewController animated:YES];
                        else
                            [mapSettingsViewController showPopupAnimated:vwController.parentViewController parentViewController:vwController];
                    }
                }
                break;
            }
        }
        case 3:
        {
            if (indexPath.row == 0) {
                mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenOverlay popup:vwController.isPopup];
                
            } else {
                mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenUnderlay popup:vwController.isPopup];
            }
            
            break;
        }
            
        default:
            break;
    }
    
    if (mapSettingsViewController) {
        if (!vwController.isPopup)
            [vwController.navigationController pushViewController:mapSettingsViewController animated:YES];
        else
            [mapSettingsViewController showPopupAnimated:vwController.parentViewController parentViewController:vwController];
    }

    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

+(OsmAnd::MapStylePreset::Type)tagToMapStyle:(int)type {
    OsmAnd::MapStylePreset::Type mapStyle = OsmAnd::MapStylePreset::Type::General;
    if (type == 1) {
        mapStyle = OsmAnd::MapStylePreset::Type::Car;
    } else if (type == 2) {
        mapStyle = OsmAnd::MapStylePreset::Type::Pedestrian;
    } else if (type == 3) {
        mapStyle = OsmAnd::MapStylePreset::Type::Bicycle;
    }
    return mapStyle;
}

+(OsmAnd::MapStylePreset::Type)variantToMapStyle:(NSString*)variant {
    OsmAnd::MapStylePreset::Type mapStyle = OsmAnd::MapStylePreset::Type::General;
    if ([variant isEqualToString:@"type_car"]) {
        mapStyle = OsmAnd::MapStylePreset::Type::Car;
    } else if ([variant isEqualToString:@"type_pedestrian"]) {
        mapStyle = OsmAnd::MapStylePreset::Type::Pedestrian;
    } else if ([variant isEqualToString:@"type_bicycle"]) {
        mapStyle = OsmAnd::MapStylePreset::Type::Bicycle;
    }
    return mapStyle;
}

+(int)mapStyleToTag:(OsmAnd::MapStylePreset::Type)mapStyle {
    int type = 0;
    if (mapStyle == OsmAnd::MapStylePreset::Type::Car) {
        type = 1;
    } else if (mapStyle == OsmAnd::MapStylePreset::Type::Pedestrian) {
        type = 2;
    } else if (mapStyle == OsmAnd::MapStylePreset::Type::Bicycle) {
        type = 3;
    }
    return type;
}

@end
