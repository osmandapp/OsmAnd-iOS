//
//  OAMapSettingsMainScreen.m
//  OsmAnd
//
//  Created by Alexey Kulish on 21/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAMapSettingsMainScreen.h"
#import "OAMapSettingsViewController.h"
#import "OAFirstMapillaryBottomSheetViewController.h"
#import "OASettingsTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OAMapStyleSettings.h"
#import "OAGPXDatabase.h"
#import "OAMapSource.h"
#import "OAAppModeCell.h"
#import "Localization.h"
#import "OASavingTrackHelper.h"
#import "OAAppSettings.h"
#import "OAIAPHelper.h"
#import "OAUtilities.h"
#import "OAPOIFiltersHelper.h"
#import "OAPOIUIFilter.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/IMapStylesCollection.h>

#define kMapStyleTopSettingsCount 3

@interface OAMapSettingsMainScreen () <OAAppModeCellDelegate>

@end

@implementation OAMapSettingsMainScreen
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    OAIAPHelper *_iapHelper;
    
    OAMapStyleSettings *styleSettings;
    
    OAAppModeCell *appModeCell;
    
    BOOL mapStyleCellPresent;
    NSInteger favSection;
    NSInteger favRow;
    NSInteger tripsRow;
}


@synthesize settingsScreen, tableData, vwController, tblView, title, isOnlineMapSource;


- (id) initWithTable:(UITableView *)tableView viewController:(OAMapSettingsViewController *)viewController
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
        _iapHelper = [OAIAPHelper sharedInstance];
        
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

- (NSString *)getMapLangValueStr
{
    NSString *prefLang;
    NSString *prefLangId = _settings.settingPrefMapLanguage;
    if (prefLangId)
        prefLang = [[[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier value:prefLangId] capitalizedStringWithLocale:[NSLocale currentLocale]];
    else
        prefLang = OALocalizedString(@"local_names");
    
    NSString* languageValue;
    switch (_settings.settingMapLanguage)
    {
        case 0: // NativeOnly
            languageValue = OALocalizedString(@"sett_lang_local");
            break;
        case 4: // LocalizedAndNative
            languageValue = [NSString stringWithFormat:@"%@ %@ %@", prefLang, OALocalizedString(@"shared_string_and"), [OALocalizedString(@"sett_lang_local") lowercaseStringWithLocale:[NSLocale currentLocale]]];
            break;
        case 1: // LocalizedOrNative
            languageValue = [NSString stringWithFormat:@"%@ %@ %@", prefLang, OALocalizedString(@"shared_string_or"), [OALocalizedString(@"sett_lang_local") lowercaseStringWithLocale:[NSLocale currentLocale]]];
            break;
        case 5: // LocalizedOrTransliteratedAndNative
            languageValue = [NSString stringWithFormat:@"%@ (%@) %@ %@", prefLang, [OALocalizedString(@"sett_lang_trans") lowercaseStringWithLocale:[NSLocale currentLocale]], OALocalizedString(@"shared_string_and"), [OALocalizedString(@"sett_lang_local") lowercaseStringWithLocale:[NSLocale currentLocale]]];
            break;
        case 6: // LocalizedOrTransliterated
            languageValue = [NSString stringWithFormat:@"%@ (%@)", prefLang, [OALocalizedString(@"sett_lang_trans") lowercaseStringWithLocale:[NSLocale currentLocale]]];
            break;
            
        default:
            break;
    }
    
    return languageValue;
}

- (NSArray *) getAllCategories
{
    NSMutableArray *res = [NSMutableArray array];
    NSMutableArray *categories = [NSMutableArray arrayWithArray:[styleSettings getAllCategories]];
    for (NSString *cName in categories)
    {
        if (![[cName lowercaseString] isEqualToString:@"ui_hidden"])
        {
            [res addObject:cName];
        }
    }
    return [NSArray arrayWithArray:res];
}

- (void) setupView
{
    NSMutableDictionary *sectionMapStyle = [NSMutableDictionary dictionary];
    [sectionMapStyle setObject:@"OAAppModeCell" forKey:@"type"];

    NSMutableDictionary *section0fav = [NSMutableDictionary dictionary];
    [section0fav setObject:OALocalizedString(@"favorite") forKey:@"name"];
    [section0fav setObject:@"" forKey:@"value"];
    [section0fav setObject:@"OASwitchCell" forKey:@"type"];
    
    NSMutableDictionary *section0poi = [NSMutableDictionary dictionary];
    [section0poi setObject:OALocalizedString(@"poi_overlay") forKey:@"name"];
    NSString *description = [self getPOIDescription];
    [section0poi setObject:description forKey:@"value"];
    [section0poi setObject:@"OASettingsCell" forKey:@"type"];
    BOOL hasOsmEditing = [_iapHelper.osmEditing isActive];
    NSMutableDictionary *section0edits = [NSMutableDictionary dictionary];
    NSMutableDictionary *section0notes = [NSMutableDictionary dictionary];
    if (hasOsmEditing)
    {
        
        [section0edits setObject:OALocalizedString(@"osm_edits_offline_layer") forKey:@"name"];
        [section0edits setObject:@"" forKey:@"value"];
        [section0edits setObject:@"OASwitchCell" forKey:@"type"];
        [section0edits setObject:@"osm_edits_offline_layer" forKey:@"key"];
        
        [section0notes setObject:OALocalizedString(@"osm_notes_online_layer") forKey:@"name"];
        [section0notes setObject:@"" forKey:@"value"];
        [section0notes setObject:@"OASwitchCell" forKey:@"type"];
        [section0notes setObject:@"osm_notes_online_layer" forKey:@"key"];
    }
    
    NSMutableDictionary *section0mapillary = [NSMutableDictionary dictionary];
    [section0mapillary setObject:OALocalizedString(@"map_settings_mapillary") forKey:@"name"];
    [section0mapillary setObject:@"" forKey:@"value"];
    [section0mapillary setObject:@"OASwitchCell" forKey:@"type"];
    [section0mapillary setObject:@"mapillary_layer" forKey:@"key"];

    NSMutableDictionary *section0tracks = [NSMutableDictionary dictionary];
    [section0tracks setObject:OALocalizedString(@"tracks") forKey:@"name"];
    [section0tracks setObject:@"" forKey:@"value"];
    [section0tracks setObject:@"OASettingsCell" forKey:@"type"];

    NSMutableArray *section0 = [NSMutableArray array];
    [section0 addObject:section0fav];
    [section0 addObject:section0poi];
    if (hasOsmEditing)
    {
        [section0 addObject:section0edits];
        [section0 addObject:section0notes];
    }
    [section0 addObject:section0mapillary];
    tripsRow = -1;
    if ([[[OAGPXDatabase sharedDb] gpxList] count] > 0 || [[OASavingTrackHelper sharedInstance] hasData])
    {
        tripsRow = section0.count;
        [section0 addObject:section0tracks];
    }
    
    NSArray *arrTop = @[@{@"groupName": OALocalizedString(@"map_settings_show"),
                          @"cells": section0
                          },
                        @{@"groupName": OALocalizedString(@"map_settings_type"),
                          @"cells": @[
                                  @{@"name": OALocalizedString(@"map_settings_type"),
                                    @"value": _app.data.lastMapSource.name,
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
        
        styleSettings = [OAMapStyleSettings sharedInstance];
        
        NSArray *categories = [self getAllCategories];
        NSArray *topLevelParams = [styleSettings getParameters:@""];
        
        NSMutableArray *categoriesList = [NSMutableArray array];
        NSString *modeStr;
        if (_settings.settingAppMode == APPEARANCE_MODE_DAY)
            modeStr = OALocalizedString(@"map_settings_day");
        else if (_settings.settingAppMode == APPEARANCE_MODE_NIGHT)
            modeStr = OALocalizedString(@"map_settings_night");
        else if (_settings.settingAppMode == APPEARANCE_MODE_AUTO)
            modeStr = OALocalizedString(@"daynight_mode_auto");
        else
            modeStr = OALocalizedString(@"-");

        [categoriesList addObject:@{@"name": OALocalizedString(@"map_settings_mode"),
                                    @"value": modeStr,
                                    @"type": @"OASettingsCell"}];
        
        [categoriesList addObject:@{@"name": OALocalizedString(@"map_settings_map_magnifier"),
                                    @"value": [self getPercentString:[_settings.mapDensity get:_settings.applicationMode]],
                                    @"type": @"OASettingsCell"}];
        
        [categoriesList addObject:@{@"name": OALocalizedString(@"map_settings_text_size"),
                                    @"value": [self getPercentString:[_settings.textSize get:_settings.applicationMode]],
                                    @"type": @"OASettingsCell"}];
        
        for (NSString *cName in categories)
        {
            NSString *t = [styleSettings getCategoryTitle:cName];
            if (![[t lowercaseString] isEqualToString:@"ui_hidden"])
                [categoriesList addObject:@{@"name": t,
                                            @"value": @"",
                                            @"type": @"OASettingsCell"}];
        }
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

    
    NSMutableArray *arrOverlayUnderlay = [NSMutableArray array];
    
    if ([_iapHelper.srtm isActive])
    {
        [arrOverlayUnderlay addObject:@{@"name": OALocalizedString(@"map_settings_hillshade"),
                                    @"value": @"",
                                    @"type": @"OASwitchCell"}];
    }
    NSString *overlayMapSourceName;
    if ([_app.data.overlayMapSource.name isEqualToString:@"sqlitedb"])
        overlayMapSourceName = [[_app.data.overlayMapSource.resourceId stringByDeletingPathExtension] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
    else
        overlayMapSourceName = _app.data.overlayMapSource.name;
    
    [arrOverlayUnderlay addObject:@{@"name": OALocalizedString(@"map_settings_over"),
                                    @"value": (_app.data.overlayMapSource != nil) ? overlayMapSourceName : OALocalizedString(@"map_settings_none"),
                                    @"type": @"OASettingsCell"}];

    NSString *underlayMapSourceName;
    if ([_app.data.underlayMapSource.name isEqualToString:@"sqlitedb"])
        underlayMapSourceName = [[_app.data.underlayMapSource.resourceId stringByDeletingPathExtension] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
    else
        underlayMapSourceName = _app.data.underlayMapSource.name;

    [arrOverlayUnderlay addObject:@{@"name": OALocalizedString(@"map_settings_under"),
                                    @"value": (_app.data.underlayMapSource != nil) ? underlayMapSourceName : OALocalizedString(@"map_settings_none"),
                                    @"type": @"OASettingsCell"}];

    NSArray *arrOverlayUnderlaySection = @[@{@"groupName": OALocalizedString(@"map_settings_overunder"),
                                             @"cells": arrOverlayUnderlay,
                                             }
                                           ];

    tableData = [tableData arrayByAddingObjectsFromArray:arrOverlayUnderlaySection];

    NSString *languageValue = [self getMapLangValueStr];
    NSArray *arrayLanguage = @[@{@"groupName" : OALocalizedString(@"language"),
                                 @"cells": @[
                                         @{@"name": OALocalizedString(@"sett_lang"),
                                           @"value": languageValue,
                                           @"type": @"OASettingsCell"}
                                         ]}];
    
    tableData = [tableData arrayByAddingObjectsFromArray:arrayLanguage];

    [tblView reloadData];
}

- (NSString *) getPercentString:(double)value
{
    return [NSString stringWithFormat:@"%d %%", (int) (value * 100.0)];
}

- (NSString *) getPOIDescription
{
    NSMutableString *descr = [[NSMutableString alloc] init];
    NSArray<OAPOIUIFilter *> *selectedFilters = [[[OAPOIFiltersHelper sharedInstance] getSelectedPoiFilters] allObjects];
    NSUInteger size = [selectedFilters count];
    if (size > 0)
    {
        [descr appendString:selectedFilters[0].name];
        if (size > 1)
            [descr appendString:@" ..."];
    }
    return descr;
}

- (CGFloat) heightForHeader:(NSInteger)section
{
    NSDictionary* data = (NSDictionary*)[((NSArray*)[((NSDictionary*)tableData[section]) objectForKey:@"cells"]) objectAtIndex:0];
    if ([[data objectForKey:@"type"] isEqualToString:@"OAAppModeCell"])
        return 0.01;
    else
        return 34.0;
}

- (CGFloat) heightForRow:(NSIndexPath *)indexPath tableView:(UITableView *)tableView
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

#pragma mark - OAAppModeCellDelegate

- (void) appModeChanged:(OAApplicationMode *)mode
{
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


- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [((NSArray*)[((NSDictionary*)tableData[section]) objectForKey:@"cells"]) count];
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForRow:indexPath tableView:tableView];
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForRow:indexPath tableView:tableView];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary* data = (NSDictionary*)[((NSArray*)[((NSDictionary*)tableData[indexPath.section]) objectForKey:@"cells"]) objectAtIndex:indexPath.row];
    
    UITableViewCell* outCell = nil;
    if ([[data objectForKey:@"type"] isEqualToString:@"OAAppModeCell"])
    {
        if (!appModeCell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAAppModeCell" owner:self options:nil];
            appModeCell = (OAAppModeCell *)[nib objectAtIndex:0];
            appModeCell.showDefault = YES;
            appModeCell.selectedMode = [OAAppSettings sharedManager].applicationMode;
            appModeCell.delegate = self;
        }
        
        outCell = appModeCell;
        
    } else if ([[data objectForKey:@"type"] isEqualToString:@"OASettingsCell"]) {
        
        static NSString* const identifierCell = @"OASettingsTableViewCell";
        OASettingsTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASettingsCell" owner:self options:nil];
            cell = (OASettingsTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell) {
            [cell.textView setText:[data objectForKey:@"name"]];
            [cell.descriptionView setText:[data objectForKey:@"value"]];
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
                [cell.switchView setOn:_settings.mapSettingShowFavorites];
                [cell.switchView addTarget:self action:@selector(showFavoriteChanged:) forControlEvents:UIControlEventValueChanged];
            }
            else if ([data[@"key"] isEqualToString:@"osm_edits_offline_layer"])
            {
                [cell.switchView setOn:_settings.mapSettingShowOfflineEdits];
                [cell.switchView addTarget:self action:@selector(showOfflineEditsChanged:) forControlEvents:UIControlEventValueChanged];
            }
            else if ([data[@"key"] isEqualToString:@"osm_notes_online_layer"])
            {
                [cell.switchView setOn:_settings.mapSettingShowOnlineNotes];
                [cell.switchView addTarget:self action:@selector(showOnlineNotesChanged:) forControlEvents:UIControlEventValueChanged];
            }
            else if ([data[@"key"] isEqualToString:@"mapillary_layer"])
            {
                [cell.switchView setOn:[OsmAndApp instance].data.mapillary];
                [cell.switchView addTarget:self action:@selector(mapillaryChanged:) forControlEvents:UIControlEventValueChanged];
            }
            else // hillshade
            {
                [cell.switchView setOn:[OsmAndApp instance].data.hillshade];
                [cell.switchView addTarget:self action:@selector(hillshadeChanged:) forControlEvents:UIControlEventValueChanged];
            }
            
        }
        outCell = cell;
    }
    
    return outCell;
}

- (void) hillshadeChanged:(id)sender
{
    UISwitch *switchView = (UISwitch*)sender;
    if (switchView)
        [[OsmAndApp instance].data setHillshade:switchView.isOn];
}

- (void) mapillaryChanged:(id)sender
{
    UISwitch *switchView = (UISwitch*)sender;
    if (switchView)
    {
        BOOL mapillaryOn = switchView.isOn;
        [[OsmAndApp instance].data setMapillary:mapillaryOn];
        if (mapillaryOn && !_settings.mapillaryFirstDialogShown)
        {
            [_settings setMapillaryFirstDialogShown:YES];
            OAFirstMapillaryBottomSheetViewController *screen = [[OAFirstMapillaryBottomSheetViewController alloc] init];
            [screen show];
        }
    }
}

- (void) showFavoriteChanged:(id)sender
{
    UISwitch *switchView = (UISwitch*)sender;
    if (switchView)
        [_settings setMapSettingShowFavorites:switchView.isOn];
}

- (void) showOfflineEditsChanged:(id)sender
{
    UISwitch *switchView = (UISwitch*)sender;
    if (switchView)
        [_settings setMapSettingShowOfflineEdits:switchView.isOn];
}

- (void) showOnlineNotesChanged:(id)sender
{
    UISwitch *switchView = (UISwitch*)sender;
    if (switchView)
        [_settings setMapSettingShowOnlineNotes:switchView.isOn];
}

#pragma mark - UITableViewDelegate

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [self heightForHeader:section];
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAMapSettingsViewController *mapSettingsViewController;
    
    NSInteger section = indexPath.section;
    if (mapStyleCellPresent)
        section--;
    
    switch (section)
    {
        case 0:
        {
            if (indexPath.row == 1) {
                mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenPOI];
            }
            else if (indexPath.row == tripsRow) {
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
                NSArray *categories = [self getAllCategories];
                NSArray *topLevelParams = [styleSettings getParameters:@""];
                
                if (indexPath.row == 0)
                {
                    mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenSetting param:settingAppModeKey];
                }
                else if (indexPath.row == 1)
                {
                    mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenSetting param:mapDensityKey];
                }
                else if (indexPath.row == 2)
                {
                    mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenSetting param:textSizeKey];
                }
                else if (indexPath.row <= categories.count + 2)
                {
                    mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenCategory param:categories[indexPath.row - kMapStyleTopSettingsCount]];
                }
                else
                {
                    OAMapStyleParameter *p = topLevelParams[indexPath.row - categories.count - kMapStyleTopSettingsCount];
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
            if ([_iapHelper.srtm isActive])
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
    
    if (mapSettingsViewController)
            [mapSettingsViewController show:vwController.parentViewController parentViewController:vwController animated:YES];

    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

@end
