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
#import "OASettingSwitchCell.h"
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
#import "OAMapSettingsOverlayUnderlayScreen.h"
#import "Reachability.h"
#import "OAPublicTransportStyleSettingsHelper.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/IMapStylesCollection.h>

#define kMapStyleTopSettingsCount 3
#define kContourLinesDensity @"contourDensity"
#define kContourLinesWidth @"contourWidth"
#define kContourLinesColorScheme @"contourColorScheme"

@interface OAMapSettingsMainScreen () <OAAppModeCellDelegate>

@end

@implementation OAMapSettingsMainScreen
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    OAIAPHelper *_iapHelper;
    
    OAMapStyleSettings *styleSettings;
    OAPublicTransportStyleSettingsHelper* _transportSettings;
    NSArray *_filteredTopLevelParams;
    
    OAAppModeCell *appModeCell;
    
    BOOL mapStyleCellPresent;
    NSInteger favSection;
    NSInteger favRow;
    NSInteger tripsRow;
    NSInteger mapillaryRow;
    NSInteger contourLinesRow;
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
        _transportSettings = [OAPublicTransportStyleSettingsHelper sharedInstance];
        
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
    [section0fav setObject:OALocalizedString(@"favorites") forKey:@"name"];
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
    [section0mapillary setObject:@"" forKey:@"description"];
    [section0mapillary setObject:@"ic_action_additional_option" forKey:@"secondaryImg"];
    [section0mapillary setObject:@"OASettingSwitchCell" forKey:@"type"];
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
    mapillaryRow = section0.count - 1;
    tripsRow = -1;
    if ([[[OAGPXDatabase sharedDb] gpxList] count] > 0 || [[OASavingTrackHelper sharedInstance] hasData])
    {
        tripsRow = section0.count;
        [section0 addObject:section0tracks];
    }
    
    NSString *mapSourceName;
    if ([_app.data.lastMapSource.name isEqualToString:@"sqlitedb"])
        mapSourceName = [[_app.data.lastMapSource.resourceId stringByDeletingPathExtension] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
    else
        mapSourceName = _app.data.lastMapSource.name;
    
    NSArray *arrTop = @[@{@"groupName": OALocalizedString(@"map_settings_show"),
                          @"cells": section0
                          },
                        @{@"groupName": OALocalizedString(@"map_settings_type"),
                          @"cells": @[
                                  @{@"name": OALocalizedString(@"map_settings_type"),
                                    @"value": mapSourceName,
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
        _filteredTopLevelParams = [[styleSettings getParameters:@""] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(_name != %@) AND (_name != %@) AND (_name != %@)", kContourLinesDensity, kContourLinesWidth, kContourLinesColorScheme]];
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
            {
                if ([[t lowercaseString] isEqualToString:@"transport"])
                {
                    [categoriesList addObject:@{@"name": t,
                                                @"value": @"",
                                                @"key": @"transport_layer",
                                                @"type": @"OASettingSwitchCell",
                                                @"secondaryImg": @"ic_action_additional_option"}];
                }
                else
                {
                    [categoriesList addObject:@{@"name": t,
                                                @"value": @"",
                                                @"type": @"OASettingsCell"}];
                }
            }
        }
        
        for (OAMapStyleParameter *p in _filteredTopLevelParams)
        {
            [categoriesList addObject:@{@"name": p.title,
                                        @"value": [p getValueTitle],
                                        @"type": @"OASettingsCell"}];
        }
        
        if ([[OAIAPHelper sharedInstance].srtm isActive])
        {
            NSMutableDictionary *section1contourLines = [NSMutableDictionary dictionary];
            [section1contourLines setObject:OALocalizedString(@"product_title_srtm") forKey:@"name"];
            [section1contourLines setObject:@"" forKey:@"description"];
            [section1contourLines setObject:@"ic_action_additional_option" forKey:@"secondaryImg"];
            [section1contourLines setObject:@"OASettingSwitchCell" forKey:@"type"];
            [section1contourLines setObject:@"contour_lines_layer" forKey:@"key"];
            [categoriesList addObject:section1contourLines];
            contourLinesRow = categoriesList.count - 1;
        }
        
        NSArray *arrStyles = @[@{@"groupName": OALocalizedString(@"map_settings_style"),
                                 @"cells": categoriesList,
                                 }
                               ];

        
        tableData = [arr arrayByAddingObjectsFromArray:arrStyles];
    }

    
    NSMutableArray *arrOverlayUnderlay = [NSMutableArray array];
    
    if ([_iapHelper.srtm isActive])
    {
        NSMutableDictionary *terrain = [NSMutableDictionary dictionary];
        [terrain setObject:OALocalizedString(@"map_settings_terrain") forKey:@"name"];
        [terrain setObject:@"" forKey:@"description"];
        [terrain setObject:@"ic_action_additional_option" forKey:@"secondaryImg"];
        [terrain setObject:@"OASettingSwitchCell" forKey:@"type"];
        [terrain setObject:@"terrain_layer" forKey:@"key"];
        [arrOverlayUnderlay addObject: terrain];
    }

    NSMutableDictionary *overlay = [NSMutableDictionary dictionary];
    [overlay setObject:OALocalizedString(@"map_settings_over") forKey:@"name"];
    [overlay setObject:@"" forKey:@"description"];
    [overlay setObject:@"ic_action_additional_option" forKey:@"secondaryImg"];
    [overlay setObject:@"OASettingSwitchCell" forKey:@"type"];
    [overlay setObject:@"overlay_layer" forKey:@"key"];
    [arrOverlayUnderlay addObject: overlay];

    NSMutableDictionary *underlay = [NSMutableDictionary dictionary];
    [underlay setObject:OALocalizedString(@"map_settings_under") forKey:@"name"];
    [underlay setObject:@"" forKey:@"description"];
    [underlay setObject:@"ic_action_additional_option" forKey:@"secondaryImg"];
    [underlay setObject:@"OASettingSwitchCell" forKey:@"type"];
    [underlay setObject:@"underlay_layer" forKey:@"key"];
    [arrOverlayUnderlay addObject: underlay];


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
        }
        outCell = cell;
    }
    else if ([data[@"type"] isEqualToString:@"OASettingSwitchCell"])
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
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            if ([data[@"key"] isEqualToString:@"mapillary_layer"])
            {
                [cell.switchView setOn:[OsmAndApp instance].data.mapillary];
                [cell.switchView addTarget:self action:@selector(mapillaryChanged:) forControlEvents:UIControlEventValueChanged];
            }
            if ([data[@"key"] isEqualToString:@"contour_lines_layer"])
            {
                BOOL contourLinesOn = true;
                OAMapStyleParameter *parameter = [styleSettings getParameter:@"contourLines"];
                if ([parameter.value  isEqual: @"disabled"])
                    contourLinesOn = false;
                [cell.switchView setOn: contourLinesOn];
                [cell.switchView addTarget:self action:@selector(contourLinesChanged:) forControlEvents:UIControlEventValueChanged];
            }
            if ([data[@"key"] isEqualToString:@"overlay_layer"])
            {
                [cell.switchView setOn:_app.data.overlayMapSource != nil];
                [cell.switchView addTarget:self action:@selector(overlayChanged:) forControlEvents:UIControlEventValueChanged];
            }
            if ([data[@"key"] isEqualToString:@"underlay_layer"])
            {
                [cell.switchView setOn:_app.data.underlayMapSource != nil];
                [cell.switchView addTarget:self action:@selector(underlayChanged:) forControlEvents:UIControlEventValueChanged];
            }
            if ([data[@"key"] isEqualToString:@"terrain_layer"])
            {
                [cell.switchView setOn:_app.data.terrainType != EOATerrainTypeDisabled];
                [cell.switchView addTarget:self action:@selector(terrainChanged:) forControlEvents:UIControlEventValueChanged];
            }
            if ([data[@"key"] isEqualToString:@"transport_layer"])
            {
                [cell.switchView setOn: [_transportSettings getVisibilityForTransportLayer]];
                [cell.switchView addTarget:self action:@selector(transportChanged:) forControlEvents:UIControlEventValueChanged];
            }
            cell.textView.text = data[@"name"];
            NSString *desc = data[@"description"];
            NSString *secondaryImg = data[@"secondaryImg"];
            cell.descriptionView.text = desc;
            cell.descriptionView.hidden = desc.length == 0;
            [cell setSecondaryImage:secondaryImg.length > 0 ? [UIImage imageNamed:data[@"secondaryImg"]] : nil];
            if ([cell needsUpdateConstraints])
                [cell setNeedsUpdateConstraints];
        }
        outCell = cell;
    }
    return outCell;
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

- (void) contourLinesChanged:(id)sender
{
    UISwitch *switchView = (UISwitch *)sender;
    if (switchView)
    {
        OAMapStyleParameter *parameter = [styleSettings getParameter:@"contourLines"];
        parameter.value = switchView.isOn ? [_settings.contourLinesZoom get] : @"disabled";
        [styleSettings save:parameter];
    }
}

- (void) overlayChanged:(id)sender
{
    UISwitch *switchView = (UISwitch *)sender;
    if (switchView)
    {
        if (switchView.isOn)
        {
            BOOL hasLastMapSource = _app.data.lastOverlayMapSource != nil;
            if (!hasLastMapSource)
                _app.data.lastOverlayMapSource = [OAMapSource getOsmAndOnlineTilesMapSource];
            
            _app.data.overlayMapSource = _app.data.lastOverlayMapSource;
            if (!hasLastMapSource)
            {
                OAMapSettingsViewController *mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenOverlay];
                [mapSettingsViewController show:vwController.parentViewController parentViewController:vwController animated:YES];
            }
        }
        else
            _app.data.overlayMapSource = nil;
    }
}

- (void) installMapLayerFor:(id)param
{
    if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus != NotReachable)
    {
        OAMapSettingsViewController *mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenOnlineSources param:param];
        [mapSettingsViewController show:vwController.parentViewController parentViewController:vwController animated:YES];
    }
    else
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:OALocalizedString(@"osm_upload_no_internet") preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleCancel handler:nil]];
        [self.vwController presentViewController:alert animated:YES completion:nil];
    }
}

- (void) underlayChanged:(id)sender
{
    UISwitch *switchView = (UISwitch*)sender;
    if (switchView)
    {
        OAMapStyleSettings *_styleSettings = [OAMapStyleSettings sharedInstance];
        OAMapStyleParameter *_hidePolygonsParameter = [_styleSettings getParameter:@"noPolygons"];
        if (switchView.isOn)
        {
            BOOL hasLastMapSource = _app.data.lastUnderlayMapSource != nil;
            if (!hasLastMapSource)
                _app.data.lastUnderlayMapSource = [OAMapSource getOsmAndOnlineTilesMapSource];

            _hidePolygonsParameter.value = @"true";
            [_styleSettings save:_hidePolygonsParameter];
            _app.data.underlayMapSource = _app.data.lastUnderlayMapSource;
            if (!hasLastMapSource)
            {
                OAMapSettingsViewController *mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenUnderlay];
                [mapSettingsViewController show:vwController.parentViewController parentViewController:vwController animated:YES];
            }
        }
        else
        {
            _hidePolygonsParameter.value = @"false";
            [_styleSettings save:_hidePolygonsParameter];
            _app.data.underlayMapSource = nil;
        }
    }
}

- (void) terrainChanged:(id)sender
{
    if ([sender isKindOfClass:UISwitch.class])
    {
        UISwitch *switchView = (UISwitch *) sender;
        if (switchView.isOn)
        {
            EOATerrainType lastType = _app.data.lastTerrainType;
            _app.data.terrainType = lastType != EOATerrainTypeDisabled ? lastType : EOATerrainTypeHillshade;
        }
        else
        {
            _app.data.lastTerrainType = _app.data.terrainType;
            _app.data.terrainType = EOATerrainTypeDisabled;
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

- (void) transportChanged:(id)sender
{
    UISwitch *switchView = (UISwitch*)sender;
    if (switchView)
    {
        [_transportSettings setVisibilityForTransportLayer:switchView.isOn];
            
        if (switchView.isOn && [_transportSettings isAllTransportStylesHidden])
        {
            OAMapSettingsViewController *transportSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenCategory param:@"transport"];
            [transportSettingsViewController show:vwController.parentViewController parentViewController:vwController animated:YES];
        }
    }
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
            else if (indexPath.row == mapillaryRow) {
                mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenMapillaryFilter];
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
                else if (indexPath.row == contourLinesRow)
                {
                    mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenContourLines];
                }
                else if (indexPath.row <= categories.count + 2)
                {
                    mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenCategory param:categories[indexPath.row - kMapStyleTopSettingsCount]];
                }
                else
                {
                    OAMapStyleParameter *p = _filteredTopLevelParams[indexPath.row - categories.count - kMapStyleTopSettingsCount];
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
            {
                if (indexPath.row == index)
                {
                    mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenTerrain];
                    break;
                }
                index++;
            }
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
