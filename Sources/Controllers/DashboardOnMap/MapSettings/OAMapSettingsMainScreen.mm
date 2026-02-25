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
#import "OABaseSettingsListViewController.h"
#import "OARootViewController.h"
#import "OAMapSettingsMapTypeScreen.h"
#import "OAAppModeCell.h"
#import "OASimpleTableViewCell.h"
#import "OARightIconTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OAValueTableViewCell.h"
#import "OAButtonTableViewCell.h"
#import "OAChoosePlanHelper.h"
#import "OAMapStyleSettings.h"
#import "OAGPXDatabase.h"
#import "OAObservable.h"
#import "Localization.h"
#import "OASavingTrackHelper.h"
#import "OAIAPHelper.h"
#import "OAAppData.h"
#import "OAPOIFiltersHelper.h"
#import "OAPOIHelper.h"
#import "OAProducts.h"
#import "OASizes.h"
#import "OAColors.h"
#import "OAWikipediaPlugin.h"
#import "OAWeatherPlugin.h"
#import "OAAutoObserverProxy.h"
#import <AFNetworking/AFNetworkReachabilityManager.h>
#import "GeneratedAssetSymbols.h"
#import "OAPluginsHelper.h"
#import "OAMapSource.h"
#import "OsmAnd_Maps-Swift.h"

#define kContourLinesDensity @"contourDensity"
#define kContourLinesWidth @"contourWidth"
#define kContourLinesColorScheme @"contourColorScheme"

#define kRoadStyleCategory @"roadStyle"
#define kDetailsCategory @"details"
#define kHideCategory @"hide"
#define kRoutesCategory @"routes"
#define kOtherCategory @"other"

#define kUIHiddenCategory @"ui_hidden"
#define kOSMAssistantCategory @"osm_assistant"
#define k3DBuildingsCategory @"3D Buildings"

#define kMaxCountRoutesWithoutGroup 5

#define kOSMGroupOpen @"osm_group_open"
#define kRoutesGroupOpen @"routes_group_open"

@interface OAMapSettingsMainScreen () <OAAppModeCellDelegate, OAMapTypeDelegate>

@end

@implementation OAMapSettingsMainScreen
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    OAIAPHelper *_iapHelper;
    OACoordinatesGridSettings *_coordinatesGridSettings;

    OAMapStyleSettings *_styleSettings;
    NSArray<OAMapStyleParameter *> *_filteredTopLevelParams;
    NSArray<NSString *> *_allCategories;

    NSArray<OAMapStyleParameter *> *_routesParameters;
    NSArray<NSString *> *_routesWithoutGroup;
    NSArray<NSString *> *_routesWithGroup;

    NSInteger _osmSettingsCount;
    NSArray<OAMapStyleParameter *> *_osmParameters;

    OAAppModeCell *_appModeCell;
    OAAutoObserverProxy *_applicationModeObserver;
    FreeBackupBanner *_freeBackupBanner;
}

@synthesize settingsScreen, tableData, vwController, tblView, title, isOnlineMapSource;

- (id)initWithTable:(UITableView *)tableView viewController:(OAMapSettingsViewController *)viewController
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
        _iapHelper = [OAIAPHelper sharedInstance];
        _coordinatesGridSettings = [[OACoordinatesGridSettings alloc] init];
        _styleSettings = [OAMapStyleSettings sharedInstance];

        title = OALocalizedString(@"configure_map");

        settingsScreen = EMapSettingsScreenMain;

        vwController = viewController;
        tblView = tableView;
        [self registerCells];

        _filteredTopLevelParams = [NSArray array];
        _allCategories = [NSArray array];
        _routesParameters = [NSArray array];
        _routesWithoutGroup = [NSArray array];
        _routesWithGroup = [NSArray array];
        _osmParameters = [NSArray array];
    }
    return self;
}

- (void)initView
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchased:) name:OAIAPProductPurchasedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productsRestored:) name:OAIAPProductsRestoredNotification object:nil];
    _applicationModeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                         withHandler:@selector(onApplicationModeChanged)
                                                          andObserve:_app.applicationModeChangedObservable];
}

- (void)deinitView
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (_applicationModeObserver)
    {
        [_applicationModeObserver detach];
        _applicationModeObserver = nil;
    }
}

- (void)registerCells
{
    [self.tblView registerNib:[UINib nibWithNibName:OASimpleTableViewCell.reuseIdentifier bundle:nil] forCellReuseIdentifier:OASimpleTableViewCell.reuseIdentifier];
    [self.tblView registerNib:[UINib nibWithNibName:OAValueTableViewCell.reuseIdentifier bundle:nil] forCellReuseIdentifier:OAValueTableViewCell.reuseIdentifier];
    [self.tblView registerNib:[UINib nibWithNibName:OASwitchTableViewCell.reuseIdentifier bundle:nil] forCellReuseIdentifier:OASwitchTableViewCell.reuseIdentifier];
    [self.tblView registerNib:[UINib nibWithNibName:OAButtonTableViewCell.reuseIdentifier bundle:nil] forCellReuseIdentifier:OAButtonTableViewCell.reuseIdentifier];
    [self.tblView registerNib:[UINib nibWithNibName:OARightIconTableViewCell.reuseIdentifier bundle:nil] forCellReuseIdentifier:OARightIconTableViewCell.reuseIdentifier];
    [self.tblView registerClass:[FreeBackupBannerCell class] forCellReuseIdentifier:FreeBackupBannerCell.reuseIdentifier];
}

- (void)setupView
{
    NSMutableArray *data = [NSMutableArray array];
    BOOL hasWiki = [_iapHelper.wiki isPurchased];
    BOOL hasSRTM = [_iapHelper.srtm isPurchased];
    BOOL hasWeather = [_iapHelper.weather isPurchased];
    BOOL hasCoordinatesGrid = [_coordinatesGridSettings isEnabled];

    [data addObject:@{
            @"group_name": @"",
            @"cells": @[@{
                    @"type": [OAAppModeCell getCellIdentifier],
            }]
    }];

    NSMutableArray *showSectionData = [NSMutableArray array];
    [showSectionData addObject:@{
            @"name": OALocalizedString(@"favorites_item"),
            @"image": @"ic_custom_favorites",
            @"type": OASwitchTableViewCell.reuseIdentifier,
            @"key": @"favorites"
    }];

    [showSectionData addObject:@{
            @"name": OALocalizedString(@"poi_overlay"),
            @"value": [self getPOIDescription],
            @"image": @"ic_custom_info",
            @"type": OAValueTableViewCell.reuseIdentifier,
            @"key": @"poi_layer"
    }];

    [showSectionData addObject:@{
            @"name": OALocalizedString(@"layer_amenity_label"),
            @"image": @"ic_custom_point_labels",
            @"type": OASwitchTableViewCell.reuseIdentifier,
            @"key": @"layer_amenity_label"
    }];

    if (!hasWiki || !_iapHelper.wiki.disabled)
    {
        [showSectionData addObject:@{
                @"name": [(OAWikipediaPlugin *)[OAPluginsHelper getPlugin:OAWikipediaPlugin.class] popularPlacesTitle],
                @"image": @"ic_custom_popular_places",
                hasWiki ? @"has_options" : @"desc": hasWiki ? @YES : OALocalizedString(@"explore_wikipedia_offline"),
                @"type": hasWiki ? OASwitchTableViewCell.reuseIdentifier : OAButtonTableViewCell.reuseIdentifier,
                @"key": @"wikipedia_layer"
        }];
    }

    if ([_iapHelper.mapillary isActive])
    {
        [showSectionData addObject:@{
                @"name": OALocalizedString(@"street_level_imagery"),
                @"image": @"ic_custom_mapillary_symbol",
                @"has_options": @YES,
                @"type": OASwitchTableViewCell.reuseIdentifier,
                @"key": @"mapillary_layer"
        }];
    }
    
    [showSectionData addObject:@{
        @"name": OALocalizedString(@"shared_string_gpx_tracks"),
        @"image": @"ic_custom_trip",
        @"value": [NSString stringWithFormat:@"%d", (int)_settings.mapSettingVisibleGpx.get.count],
        @"type": OAValueTableViewCell.reuseIdentifier,
        @"key": @"tracks"
    }];
    
    [showSectionData addObject:@{
            @"name": OALocalizedString(@"show_borders_of_downloaded_maps"),
            @"image": @"ic_custom_download_map",
            @"type": OASwitchTableViewCell.reuseIdentifier,
            @"key": @"show_borders_of_downloaded_maps"
    }];
    
    [showSectionData addObject:@{
        @"name": OALocalizedString(@"layer_coordinates_grid"),
        @"image": hasCoordinatesGrid ? @"ic_custom_coordinates_grid" : @"ic_custom_coordinates_grid_disabled",
        @"value": OALocalizedString(hasCoordinatesGrid ? @"shared_string_on" : @"shared_string_off"),
        @"type": OAValueTableViewCell.reuseIdentifier,
        @"key": @"coordinates_grid"
    }];

    [data addObject:@{
            @"group_name": OALocalizedString(@"shared_string_show_on_map"),
            @"cells": showSectionData
    }];

    if ([_iapHelper.osmEditing isActive])
    {
        OATableCollapsableGroup *group = [[OATableCollapsableGroup alloc] init];
        group.isOpen = [[NSUserDefaults standardUserDefaults] boolForKey:kOSMGroupOpen];
        group.groupName = OALocalizedString(@"shared_string_open_street_map");
        group.type = OARightIconTableViewCell.reuseIdentifier;
        group.groupType = EOATableCollapsableGroupMapSettingsOSM;

        NSMutableArray<NSDictionary *> *osmCells = [NSMutableArray array];

        [group.groupItems addObject:@{
                @"name": OALocalizedString(@"osm_edits_offline_layer"),
                @"image": @"ic_action_openstreetmap_logo",
                @"type": OASwitchTableViewCell.reuseIdentifier,
                @"key": @"osm_edits_offline_layer"
        }];
        [group.groupItems addObject:@{
                @"name": OALocalizedString(@"osm_notes_online_layer"),
                @"image": @"ic_action_osm_note",
                @"type": OASwitchTableViewCell.reuseIdentifier,
                @"key": @"osm_notes_online_layer"
        }];
        _osmSettingsCount = group.groupItems.count + 1;
        [self generateOSMData];
        if (_osmParameters.count > 0)
        {
            for (OAMapStyleParameter *osmParameter in _osmParameters)
            {
                [group.groupItems addObject:@{
                        @"name": osmParameter.title,
                        @"has_empty_icon": @YES,
                        @"type": OASwitchTableViewCell.reuseIdentifier,
                        @"key": [NSString stringWithFormat:@"osm_%@", osmParameter.name]
                }];
            }
        }
        [osmCells addObject:@{
                @"group": group,
                @"type": NSStringFromClass([group class]),
                @"key": @"collapsed_osm"
        }];

        [data addObject:@{
                @"group_name": @"",
                @"is_collapsable_group": @YES,
                @"cells": osmCells
        }];
    }
    else
    {
        _osmSettingsCount = 0;
    }

    [self generateRoutesData];
    if (_routesParameters.count > 0)
    {
        BOOL isOpen = [[NSUserDefaults standardUserDefaults] boolForKey:kRoutesGroupOpen]
                && _routesParameters.count > kMaxCountRoutesWithoutGroup;
        [[NSUserDefaults standardUserDefaults] setBool:isOpen forKey:kRoutesGroupOpen];
        OATableCollapsableGroup *group = [[OATableCollapsableGroup alloc] init];
        group.isOpen = isOpen;
        group.groupName = OALocalizedString(group.isOpen ? @"shared_string_collapse" : @"shared_string_show_all");
        group.type = OARightIconTableViewCell.reuseIdentifier;
        group.groupType = EOATableCollapsableGroupMapSettingsRoutes;

        NSMutableArray<NSDictionary *> *routeCells = [NSMutableArray array];
        NSArray<NSString *> *hasParameters = @[SHOW_CYCLE_ROUTES_ATTR, SHOW_MTB_ROUTES, SHOW_ALPINE_HIKING_SCALE_SCHEME_ROUTES, HIKING_ROUTES_OSMC_ATTR, TRAVEL_ROUTES];
        for (OAMapStyleParameter *routeParameter in _routesParameters)
        {
            NSString *value = @"";
            BOOL isMountainBike = [routeParameter.name isEqualToString:SHOW_MTB_ROUTES];
            if (isMountainBike)
            {
                OAMapStyleParameter *mtbRoutes = [_styleSettings getParameter:SHOW_MTB_ROUTES];
                if (mtbRoutes && mtbRoutes.storedValue.length > 0 && [mtbRoutes.storedValue isEqualToString:@"true"])
                {
                    OAMapStyleParameter *imbaTrails = [_styleSettings getParameter:SHOW_MTB_SCALE_IMBA_TRAILS];
                    if (imbaTrails && imbaTrails.storedValue.length > 0 && [imbaTrails.storedValue isEqualToString:@"true"])
                        value = imbaTrails.title;
                    if (value.length == 0)
                    {
                        OAMapStyleParameter *mtbScale = [_styleSettings getParameter:SHOW_MTB_SCALE];
                        if (mtbScale && mtbScale.storedValue.length > 0 && [mtbScale.storedValue isEqualToString:@"true"])
                            value = mtbScale.title;
                    }
                }
                else
                {
                    value = OALocalizedString(@"shared_string_off");
                }
            }
            BOOL isDifficultyClassification = [routeParameter.name isEqualToString:SHOW_ALPINE_HIKING_SCALE_SCHEME_ROUTES];
            if (isDifficultyClassification)
            {
                OAMapStyleParameter *alpineHikingAttr = [_styleSettings getParameter:ALPINE_HIKING_ATTR];
                if (alpineHikingAttr)
                {
                    if ([alpineHikingAttr.value isEqualToString:@"true"])
                    {
                        OAMapStyleParameter *alpineHikingScaleSchemeRoutes = [_styleSettings getParameter:SHOW_ALPINE_HIKING_SCALE_SCHEME_ROUTES];
                        if (alpineHikingScaleSchemeRoutes)
                        {
                            value = [OALocalizedString(([NSString stringWithFormat:@"rendering_value_%@_name", alpineHikingScaleSchemeRoutes.value])) upperCase];
                        }
                    }
                    else
                    {
                        value = OALocalizedString(@"shared_string_off");
                    }
                }
                else
                {
                    value = OALocalizedString(@"shared_string_off");
                }
            }
            NSDictionary *routeData = @{
                    @"name": [self getNameFromConditions:routeParameter.title isMountainBike:isMountainBike isDifficultyClassification:isDifficultyClassification],
                    @"image": [self getImageForParameterOrCategory:routeParameter.name],
                    @"key": [NSString stringWithFormat:@"routes_%@", routeParameter.name],
                    @"type": [hasParameters containsObject:routeParameter.name]
                                ? isMountainBike || isDifficultyClassification ? OAValueTableViewCell.reuseIdentifier : OASimpleTableViewCell.reuseIdentifier
                                : OASwitchTableViewCell.reuseIdentifier,
                    @"value": value
            };

            if ([_routesWithoutGroup containsObject:routeParameter.name])
                [routeCells addObject:routeData];
            else if ([_routesWithGroup containsObject:routeParameter.name])
                [group.groupItems addObject:routeData];
        }
        if ([self hasCollapsableRoutesGroup])
        {
            [routeCells addObject:@{
                    @"group": group,
                    @"type": NSStringFromClass([group class]),
                    @"key": @"collapsed_routes"
            }];
        }

        [data addObject:@{
                @"group_name": OALocalizedString(@"rendering_category_routes"),
                @"is_collapsable_group": @YES,
                @"cells": routeCells
        }];
    }

    NSString *mapStyleName = _app.data.lastMapSource.name;
    if ([_app.data.lastMapSource.resourceId isEqualToString:@"mapnik.render.xml"])
        mapStyleName = @"Mapnik";
    [data addObject:@{
            @"group_name": OALocalizedString(@"map_settings_type"),
            @"cells": @[@{
                    @"name": OALocalizedString(@"map_settings_type"),
                    @"value": mapStyleName,
                    @"image": @"ic_custom_map_style",
                    @"type": OAValueTableViewCell.reuseIdentifier,
                    @"key": @"map_type"
            }]
    }];

    if (!isOnlineMapSource)
    {
        DayNightMode dayNightMode = (DayNightMode) [_settings.appearanceMode get];
        NSMutableArray *mapStyleSectionData = [NSMutableArray array];
        [mapStyleSectionData addObject:@{
                @"name": OALocalizedString(@"map_mode"),
                @"value": [DayNightModeWrapper getTitleForType:dayNightMode],
                @"image": @"ic_custom_sun",
                @"type": OAValueTableViewCell.reuseIdentifier,
                @"key": @"mapMode"
        }];
        [mapStyleSectionData addObject:@{
                @"name": OALocalizedString(@"map_magnifier"),
                @"value": [NSNumberFormatter.percentFormatter stringFromNumber:@([_settings.mapDensity get])],
                @"image": @"ic_custom_magnifier",
                @"type": OAValueTableViewCell.reuseIdentifier,
                @"key": @"map_magnifier"
        }];
        [mapStyleSectionData addObject:@{
                @"name": OALocalizedString(@"text_size"),
                @"value": [NSNumberFormatter.percentFormatter stringFromNumber:@([_settings.textSize get:_settings.applicationMode.get])],
                @"image": @"ic_custom_text_size",
                @"type": OAValueTableViewCell.reuseIdentifier,
                @"key": @"text_size"
        }];

        [self generateAllCategories];
        for (NSString *cName in _allCategories)
        {
            if ([cName isEqualToString:kOtherCategory])
            {
                NSArray<OAMapStyleParameter *> *_otherParameters = [_styleSettings getParameters:kOtherCategory sorted:NO];
                NSArray<OAMapStyleParameter *> * additionalItems = [_otherParameters filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(name != %@) AND (name != %@)", SHOW_ALPINE_HIKING_SCALE_SCHEME_ROUTES, ALPINE_HIKING_ATTR]];
                if (additionalItems.count > 0)
                {
                    [mapStyleSectionData addObject:@{
                            @"name": [_styleSettings getCategoryTitle:cName],
                            @"image": [self getImageForParameterOrCategory:cName],
                            @"key": [NSString stringWithFormat:@"category_%@", cName],
                            @"type": OASimpleTableViewCell.reuseIdentifier,
                            @"value": @""
                    }];
                }
            } else {
                BOOL isTransport = [[cName lowercaseString] isEqualToString:TRANSPORT_CATEGORY];
                [mapStyleSectionData addObject:@{
                        @"name": [_styleSettings getCategoryTitle:cName],
                        @"image": [self getImageForParameterOrCategory:cName],
                        @"key": [NSString stringWithFormat:@"category_%@", cName],
                        @"type": isTransport ? OASwitchTableViewCell.reuseIdentifier : OASimpleTableViewCell.reuseIdentifier,
                        isTransport ? @"has_options" : @"value": isTransport ? @YES : @""
                }];
            }
        }

        _filteredTopLevelParams = [[_styleSettings getParameters:@""] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(_name != %@) AND (_name != %@) AND (_name != %@) AND (_name != %@) AND (_name != %@)", CONTOUR_DENSITY_ATTR, CONTOUR_WIDTH_ATTR, CONTOUR_COLOR_SCHEME_ATTR, NAUTICAL_DEPTH_CONTOUR_WIDTH_ATTR, NAUTICAL_DEPTH_CONTOUR_COLOR_SCHEME_ATTR]];
        for (OAMapStyleParameter *parameter in _filteredTopLevelParams)
        {
            if (parameter.title)
            {
                NSString *val = [parameter getValueTitle];
                [mapStyleSectionData addObject:@{
                    @"name": parameter.title,
                    @"image": [self getImageForParameterOrCategory:parameter.name],
                    @"value": val ? val : @"",
                    @"type": parameter.dataType == OABoolean ? OASwitchTableViewCell.reuseIdentifier : OAValueTableViewCell.reuseIdentifier,
                    @"key": [NSString stringWithFormat:@"filtered_%@", parameter.name]
                }];
            }
        }

        [data addObject:@{
                @"group_name": OALocalizedString(@"map_widget_renderer"),
                @"cells": mapStyleSectionData
        }];
    }
    
    NSMutableArray *topographySectionData = [NSMutableArray array];
    if (!hasSRTM)
    {
        [topographySectionData addObject:@{
                @"type": FreeBackupBannerCell.reuseIdentifier,
                @"key": @"terrain_layer"
        }];
    }
    if (hasSRTM && !_iapHelper.srtm.disabled)
    {
        [topographySectionData addObject:@{
                @"name": OALocalizedString(@"map_settings_topography"),
                @"image": @"ic_custom_contour_lines",
                @"has_options": @YES,
                @"type": OASwitchTableViewCell.reuseIdentifier,
                @"key": @"contour_lines_layer"
        }];
    }
    if (hasSRTM && !_iapHelper.srtm.disabled)
    {
        [topographySectionData addObject:@{
                @"name": OALocalizedString(@"shared_string_terrain"),
                @"image": @"ic_custom_terrain",
                @"has_options": @YES,
                @"type": OASwitchTableViewCell.reuseIdentifier,
                @"key": @"terrain_layer"
        }];
    }
    BOOL useDepthContours = [_iapHelper.nautical isActive] && ([OAIAPHelper isPaidVersion] || [OAIAPHelper isDepthContoursPurchased]);
    if (useDepthContours)
    {
        OAMapStyleParameter *nauticalDepthControursParameter = [_styleSettings getParameter:NAUTICAL_DEPTH_CONTOURS];
        if (nauticalDepthControursParameter)
        {
            [topographySectionData addObject:@{
                @"name": OALocalizedString(@"nautical_depth"),
                @"image": @"ic_custom_nautical_depth",
                @"has_options": @YES,
                @"type": OASwitchTableViewCell.reuseIdentifier,
                @"key": @"nautical_depth"
            }];
        }
    }

    if (topographySectionData.count > 0)
    {
        [data addObject:@{
            @"group_name": OALocalizedString(@"srtm_plugin_name"),
            @"cells": topographySectionData
        }];
    }

    NSMutableArray *overlayUnderlaySectionData = [NSMutableArray array];
    
    [overlayUnderlaySectionData addObject:@{
            @"name": OALocalizedString(@"map_settings_over"),
            @"image": @"ic_custom_overlay_map",
            @"has_options": @YES,
            @"type": OASwitchTableViewCell.reuseIdentifier,
            @"key": @"overlay_layer"
    }];
    [overlayUnderlaySectionData addObject:@{
            @"name": OALocalizedString(@"map_settings_under"),
            @"image": @"ic_custom_underlay_map",
            @"has_options": @YES,
            @"type": OASwitchTableViewCell.reuseIdentifier,
            @"key": @"underlay_layer"
    }];

    if (!hasWeather || !_iapHelper.weather.disabled)
    {
        [overlayUnderlaySectionData addObject:@{
                @"name": OALocalizedString(@"shared_string_weather"),
                @"image": @"ic_custom_umbrella",
                hasWeather ? @"has_options" : @"desc": hasWeather ? @YES : OALocalizedString(@"offline_weather_forecast"),
                @"type": hasWeather ? OASwitchTableViewCell.reuseIdentifier : OAButtonTableViewCell.reuseIdentifier,
                @"key": @"weather_layer"
        }];
    }

    [data addObject:@{
            @"group_name": OALocalizedString(@"map_settings_overunder"),
            @"cells": overlayUnderlaySectionData
    }];

    [data addObject:@{
            @"group_name": OALocalizedString(@"shared_string_language"),
            @"cells": @[@{
                    @"name": OALocalizedString(@"map_locale"),
                    @"value": [self getMapLangValueStr],
                    @"image": @"ic_custom_map_languge",
                    @"type": OAValueTableViewCell.reuseIdentifier,
                    @"key": @"map_language"
            }]
    }];

    tableData = data;
    [UIView transitionWithView: tblView
                      duration: 0.35f
                       options: UIViewAnimationOptionTransitionCrossDissolve
                    animations: ^(void)
                    {
                        [tblView reloadData];
                    }
                    completion: nil];
}

- (void)generateOSMData
{
    _osmParameters = [_styleSettings getParameters:kOSMAssistantCategory];
}

- (void)generateRoutesData
{
    const auto resource = _app.resourcesManager->getResource(QString::fromNSString(_app.data.lastMapSource.resourceId)
            .remove(QStringLiteral(".sqlitedb")));
    NSMutableArray<OAMapStyleParameter *> *result = [@[] mutableCopy];
    if (!([_app.data.lastMapSource.type isEqualToString:@"sqlitedb"] || (resource != nullptr && resource->type == OsmAnd::ResourcesManager::ResourceType::OnlineTileSources)))
    {
        result = [[_styleSettings getParameters:kRoutesCategory sorted:NO] mutableCopy];
    }
    
    NSArray<OAMapStyleParameter *> *_otherParameters = [_styleSettings getParameters:kOtherCategory sorted:NO];
    id additionalItem = [[_otherParameters filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name == %@", SHOW_ALPINE_HIKING_SCALE_SCHEME_ROUTES]] firstObject];
    if (additionalItem)
    {
        [result addObject:additionalItem];
    }
    _routesParameters = [result copy];

    if (_routesParameters.count > 0)
    {
        NSArray<NSString *> *orderedNames = @[SHOW_CYCLE_ROUTES_ATTR, SHOW_MTB_ROUTES, SHOW_ALPINE_HIKING_SCALE_SCHEME_ROUTES, HIKING_ROUTES_OSMC_ATTR,
                ALPINE_HIKING_ATTR, PISTE_ROUTES_ATTR, HORSE_ROUTES_ATTR, WHITE_WATER_SPORTS_ATTR];
        _routesParameters = [_routesParameters sortedArrayUsingComparator:^NSComparisonResult(OAMapStyleParameter *obj1, OAMapStyleParameter *obj2) {
            return [@([orderedNames indexOfObject:obj1.name]) compare:@([orderedNames indexOfObject:obj2.name])];
        }];
        NSMutableArray<OAMapStyleParameter *> *routesParameters = [NSMutableArray arrayWithArray:_routesParameters];
        [routesParameters removeObject:[_styleSettings getParameter:CYCLE_NODE_NETWORK_ROUTES_ATTR]];
        [routesParameters removeObject:[_styleSettings getParameter:SHOW_MTB_SCALE_IMBA_TRAILS]];
        [routesParameters removeObject:[_styleSettings getParameter:SHOW_MTB_SCALE]];
        [routesParameters removeObject:[_styleSettings getParameter:SHOW_MTB_SCALE_UPHILL]];
        _routesParameters = routesParameters;

        NSMutableArray<NSString *> *routesWithoutGroup = [NSMutableArray array];
        NSMutableArray<NSString *> *routesWithGroup = [NSMutableArray array];
        for (NSInteger i = 0; i < _routesParameters.count; i++)
        {
            OAMapStyleParameter *routesParameter = routesParameters[i];
            if (i < kMaxCountRoutesWithoutGroup - 1 || ((i == _routesParameters.count - 1) && (i == routesWithoutGroup.count)))
                [routesWithoutGroup addObject:routesParameter.name];
            else
                [routesWithGroup addObject:routesParameter.name];
        }
        _routesWithoutGroup = routesWithoutGroup;
        _routesWithGroup = routesWithGroup;
    }
}

- (void)generateAllCategories
{
    NSMutableArray<NSString *> *res = [NSMutableArray array];
    for (NSString *cName in [_styleSettings getAllCategories])
    {
        if (![[cName lowercaseString] isEqualToString:kUIHiddenCategory]
                && ![[cName lowercaseString] isEqualToString:kRoutesCategory]
                && ![[cName lowercaseString] isEqualToString:kOSMAssistantCategory]
                && ![cName isEqualToString:k3DBuildingsCategory])
            [res addObject:cName];
    }
    _allCategories = res;
}

- (NSString *)getMapLangValueStr
{
    NSString *prefLangId = _settings.settingPrefMapLanguage.get;
    NSString *prefLang = prefLangId.length > 0 ? [[OAUtilities displayNameForLang:prefLangId] capitalizedStringWithLocale:[NSLocale currentLocale]] : OALocalizedString(@"local_map_names");
    switch (_settings.settingMapLanguage.get)
    {
        case 0: // NativeOnly
            return OALocalizedString(@"download_tab_local");
        case 4: // LocalizedAndNative
            return [NSString stringWithFormat:@"%@ %@ %@", prefLang, OALocalizedString(@"shared_string_and"), [OALocalizedString(@"download_tab_local") lowercaseStringWithLocale:[NSLocale currentLocale]]];
        case 1: // LocalizedOrNative
            return [NSString stringWithFormat:@"%@ %@ %@", prefLang, OALocalizedString(@"shared_string_or"), [OALocalizedString(@"download_tab_local") lowercaseStringWithLocale:[NSLocale currentLocale]]];
        case 5: // LocalizedOrTransliteratedAndNative
            return [NSString stringWithFormat:@"%@ (%@) %@ %@", prefLang, [OALocalizedString(@"sett_lang_trans") lowercaseStringWithLocale:[NSLocale currentLocale]], OALocalizedString(@"shared_string_and"), [OALocalizedString(@"download_tab_local") lowercaseStringWithLocale:[NSLocale currentLocale]]];
        case 6: // LocalizedOrTransliterated
            return [NSString stringWithFormat:@"%@ (%@)", prefLang, [OALocalizedString(@"sett_lang_trans") lowercaseStringWithLocale:[NSLocale currentLocale]]];
        default:
            return @"";
    }
}

- (NSString *)getPOIDescription
{
    NSMutableString *descr = [[NSMutableString alloc] init];
    OAPOIFiltersHelper *filtersHelper = [OAPOIFiltersHelper sharedInstance];
    NSMutableArray<OAPOIUIFilter *> *filtersToExclude = [NSMutableArray array];
    OAPOIUIFilter *topWikiPoiFilter = [filtersHelper getTopWikiPoiFilter];
    if (topWikiPoiFilter)
        [filtersToExclude addObject:topWikiPoiFilter];
    NSArray<OAPOIUIFilter *> *selectedFilters = [[filtersHelper getSelectedPoiFilters:filtersToExclude] allObjects];
    NSUInteger size = [selectedFilters count];
    if (size > 0)
    {
        [descr appendString:selectedFilters[0].name];
        if (size > 1)
            [descr appendString:@" ..."];
    }
    return descr;
}

- (NSString *)getNameFromConditions:(NSString *)defaultValue
                     isMountainBike:(BOOL)isMountainBike
         isDifficultyClassification:(BOOL)isDifficultyClassification
{
    NSString *result = defaultValue;
    if (isMountainBike)
    {
        result = OALocalizedString(@"activity_type_mountainbike_name");
    }
    else if (isDifficultyClassification)
    {
        result = OALocalizedString(@"rendering_attr_alpineHiking_name");
    }
    return result;
}

- (NSString *)getImageForParameterOrCategory:(NSString *)paramName
{
    if ([paramName isEqualToString:SHOW_CYCLE_ROUTES_ATTR] || [paramName isEqualToString:SHOW_MTB_ROUTES] || [paramName isEqualToString:SHOW_MTB_SCALE_IMBA_TRAILS])
        return @"ic_action_bicycle_dark";
    else if([paramName isEqualToString:WHITE_WATER_SPORTS_ATTR])
        return @"ic_action_kayak";
    else if([paramName isEqualToString:HORSE_ROUTES_ATTR])
        return @"ic_action_horse";
    else if([paramName isEqualToString:HIKING_ROUTES_OSMC_ATTR] || [paramName isEqualToString:ALPINE_HIKING_ATTR] || [paramName isEqualToString:SHOW_ALPINE_HIKING_SCALE_SCHEME_ROUTES])
        return @"ic_action_trekking_dark";
    else if([paramName isEqualToString:PISTE_ROUTES_ATTR] || [paramName isEqualToString:SKI_SLOPES_ATTR])
        return @"ic_action_skiing";
    else if([paramName isEqualToString:TRAVEL_ROUTES])
        return @"mm_routes";
    else if([paramName isEqualToString:SHOW_FITNESS_TRAILS_ATTR])
        return @"mx_sport_athletics";
    else if([paramName isEqualToString:SHOW_RUNNING_ROUTES_ATTR])
        return @"mx_running";
    else if([paramName isEqualToString:kRoadStyleCategory])
        return @"ic_custom_road_style";
    else if([paramName isEqualToString:kDetailsCategory])
        return @"ic_custom_overlay_map";
    else if([paramName isEqualToString:kHideCategory])
        return @"ic_custom_hide";
    else if([paramName isEqualToString:TRANSPORT_CATEGORY])
        return @"ic_custom_transport_bus";
    else if([paramName isEqualToString:DIRTBIKE_ROUTES_ATTR])
        return @"ic_action_dirt_motorcycle";
    else if([paramName isEqualToString:CLIMBING_ROUTES])
        return @"ic_action_hill_climbing";

    return @"";
}

- (BOOL)isEnabled:(NSString *)key index:(NSInteger)index
{
    if ([key isEqualToString:@"favorites"])
        return [_settings.mapSettingShowFavorites get];
    if ([key isEqualToString:@"poi_layer"])
        return [[_settings.selectedPoiFilters get] stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"std_%@", OSM_WIKI_CATEGORY] withString:@""].length > 0;
    else if ([key isEqualToString:@"layer_amenity_label"])
        return [_settings.mapSettingShowPoiLabel get];
    else if ([key isEqualToString:@"show_borders_of_downloaded_maps"])
        return [_settings.mapSettingShowBordersOfDownloadedMaps get];
    else if ([key isEqualToString:@"wikipedia_layer"])
        return _app.data.wikipedia;
    else if ([key isEqualToString:@"osm_edits_offline_layer"])
        return [_settings.mapSettingShowOfflineEdits get];
    else if ([key isEqualToString:@"osm_notes_online_layer"])
        return [_settings.mapSettingShowOnlineNotes get];
    else if ([key isEqualToString:@"mapillary_layer"])
        return _app.data.mapillary;
    else if ([key isEqualToString:@"tracks"])
        return _settings.mapSettingVisibleGpx.get.count > 0;
    else if ([key isEqualToString:@"coordinates_grid"])
        return [_coordinatesGridSettings isEnabled];
    else if ([key isEqualToString:@"category_transport"])
        return ![_styleSettings isCategoryDisabled:TRANSPORT_CATEGORY];
    else if ([key isEqualToString:@"contour_lines_layer"])
        return ![[_styleSettings getParameter:CONTOUR_LINES].value isEqualToString:@"disabled"];
    else if ([key isEqualToString:@"terrain_layer"])
        return [((OASRTMPlugin *) [OAPluginsHelper getPlugin:OASRTMPlugin.class]) isTerrainLayerEnabled];
    else if ([key isEqualToString:@"overlay_layer"])
        return _app.data.overlayMapSource != nil;
    else if ([key isEqualToString:@"underlay_layer"])
        return _app.data.underlayMapSource != nil;
    else if ([key isEqualToString:@"weather_layer"])
        return _app.data.weather;
    else if ([key isEqualToString:@"nautical_depth"])
        return [[_styleSettings getParameter:NAUTICAL_DEPTH_CONTOURS].value isEqualToString:@"true"];
    else if ([key containsString:SHOW_ALPINE_HIKING_SCALE_SCHEME_ROUTES])
        return [[_styleSettings getParameter:ALPINE_HIKING_ATTR].value isEqualToString:@"true"];

    if ([key hasPrefix:@"routes_"] && _routesParameters.count > index)
    {
        NSString *routesValue = _routesParameters[index].value;
        return routesValue.length > 0 ? [key hasSuffix:HIKING_ROUTES_OSMC_ATTR] ? ![routesValue isEqualToString:@"disabled"] : [routesValue isEqualToString:@"true"] : NO;
    }
    else if ([key hasPrefix:@"osm_"] && _osmParameters.count > index - _osmSettingsCount)
    {
        NSString *osmValue = _osmParameters[index - _osmSettingsCount].value;
        return osmValue.length > 0 ? [osmValue isEqualToString:@"true"] : NO;
    }
    else if ([key hasPrefix:@"filtered_"])
    {
        OAMapStyleParameter *param = [_styleSettings getParameter:[key substringFromIndex:[@"filtered_" length]]];
        return [param.value isEqualToString:@"true"];
    }

    return YES;
}

- (OATableCollapsableGroup *)getCollapsableGroup:(NSInteger)section
{
    OATableCollapsableGroup *group;
    if (tableData[section][@"is_collapsable_group"])
    {
        NSArray *cells = tableData[section][@"cells"];
        for (NSDictionary *cell in cells)
        {
            if ([cell[@"type"] isEqualToString:NSStringFromClass(OATableCollapsableGroup.class)])
                group = cell[@"group"];
        }
    }
    return group;
}

- (BOOL)hasCollapsableRoutesGroup
{
    return _routesParameters.count > kMaxCountRoutesWithoutGroup;
}

- (NSDictionary *)getItem:(NSIndexPath *)indexPath
{
    NSArray *cells = tableData[indexPath.section][@"cells"];
    OATableCollapsableGroup *group = [self getCollapsableGroup:indexPath.section];
    if (group)
    {
        if (group.groupType == EOATableCollapsableGroupMapSettingsRoutes)
        {
            if (indexPath.row >= _routesWithoutGroup.count)
            {
                if ((group.isOpen && (indexPath.row == (cells.count + group.groupItems.count) - 1))
                        || (!group.isOpen && indexPath.row == cells.count - 1))
                    return cells.lastObject;

                return group.groupItems[indexPath.row - _routesWithoutGroup.count];
            }
        }
        else if (group.groupType == EOATableCollapsableGroupMapSettingsOSM)
        {
            return group.isOpen && indexPath.row > 0 ? group.groupItems[indexPath.row - 1] : cells.firstObject;
        }
    }

    return cells[indexPath.row];
}

- (CGFloat)heightForHeader:(NSInteger)section
{
    NSArray *cells = tableData[section][@"cells"];
    if (cells.count > 0)
        return [cells[0][@"type"] isEqualToString:[OAAppModeCell getCellIdentifier]]
            ? 0.01
            : ([OAUtilities calculateTextBounds:tableData[section][@"group_name"]
                                          width:tblView.frame.size.width - ([OAUtilities getLeftMargin] + kPaddingOnSideOfContent) * 2
                                           font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]].height + 19.);

    return 0.01;
}

- (void)openCloseGroup:(NSIndexPath *)indexPath
{
    OATableCollapsableGroup *group = [self getCollapsableGroup:indexPath.section];
    if (group && group.groupItems.count > 0)
    {
        if (group.groupType == EOATableCollapsableGroupMapSettingsRoutes)
        {
            group.isOpen = !group.isOpen;
            group.groupName = OALocalizedString(group.isOpen ? @"shared_string_collapse" : @"shared_string_show_all");
            [[NSUserDefaults standardUserDefaults] setBool:group.isOpen forKey:kRoutesGroupOpen];

            NSMutableArray<NSIndexPath *> *indexPaths = [NSMutableArray array];
            for (NSInteger i = _routesWithoutGroup.count + 1; i <= _routesParameters.count; i++)
            {
                [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:indexPath.section]];
            }
            [tblView beginUpdates];
            if (group.isOpen)
            {
                [tblView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_routesWithoutGroup.count
                                                                     inSection:indexPath.section]]
                               withRowAnimation:UITableViewRowAnimationNone];
                [tblView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
            }
            else
            {
                [tblView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
                [tblView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_routesWithoutGroup.count
                                                                     inSection:indexPath.section]]
                               withRowAnimation:UITableViewRowAnimationNone];
            }
            [tblView endUpdates];
            [UIView setAnimationsEnabled:NO];
            [tblView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_routesWithoutGroup.count - 1
                                                                 inSection:indexPath.section]]
                           withRowAnimation:UITableViewRowAnimationNone];
            [UIView setAnimationsEnabled:YES];
        }
        else if (group.groupType == EOATableCollapsableGroupMapSettingsOSM)
        {
            group.isOpen = !group.isOpen;
            [[NSUserDefaults standardUserDefaults] setBool:group.isOpen forKey:kOSMGroupOpen];

            NSMutableArray<NSIndexPath *> *indexPaths = [NSMutableArray array];
            for (NSInteger i = 0; i < group.groupItems.count; i++)
            {
                [indexPaths addObject:[NSIndexPath indexPathForRow:i + 1 inSection:indexPath.section]];
            }
            [tblView beginUpdates];
            if (group.isOpen)
            {
                [tblView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:indexPath.section]]
                               withRowAnimation:UITableViewRowAnimationNone];
                [tblView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
            }
            else
            {
                [tblView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
                [tblView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:indexPath.section]]
                               withRowAnimation:UITableViewRowAnimationNone];
            }
            [tblView endUpdates];
        }

        if (group.isOpen && [tblView indexPathForCell:[tblView visibleCells].lastObject].section <= indexPath.section)
        {
            NSInteger row = group.groupType == EOATableCollapsableGroupMapSettingsRoutes ? _routesWithoutGroup.count : 0;
            [tblView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:indexPath.section]
                           atScrollPosition:UITableViewScrollPositionMiddle
                                   animated:YES];
        }
    }
}

#pragma mark - OAAppModeCellDelegate

- (void)appModeChanged:(OAApplicationMode *)mode
{
    [_settings setApplicationModePref:mode];
    [self setupView];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return tableData.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return tableData[section][@"group_name"];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    OATableCollapsableGroup *group = [self getCollapsableGroup:section];
    if (group)
    {
        if (group.groupType == EOATableCollapsableGroupMapSettingsRoutes)
            return 1 + (group.isOpen ? _routesParameters.count : _routesWithoutGroup.count);
        else if (group.groupType == EOATableCollapsableGroupMapSettingsOSM)
            return group.isOpen ? 1 + group.groupItems.count : 1;
    }

    return ((NSArray *) tableData[section][@"cells"]).count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    BOOL isOn = [self isEnabled:item[@"key"] index:indexPath.row];
    BOOL hasOptions = [item[@"has_options"] boolValue];

    OATableCollapsableGroup *group = [self getCollapsableGroup:indexPath.section];
    BOOL isLastGroupIndex;
    if (group)
    {
        if (group.groupType == EOATableCollapsableGroupMapSettingsRoutes)
            isLastGroupIndex = indexPath.row == (group.isOpen ? _routesParameters.count : _routesWithoutGroup.count) - 1;
        else if (group.groupType == EOATableCollapsableGroupMapSettingsOSM)
            isLastGroupIndex = indexPath.row == 0;
    }

    if ([item[@"type"] isEqualToString:[OAAppModeCell getCellIdentifier]])
    {
        if (!_appModeCell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAAppModeCell getCellIdentifier] owner:self options:nil];
            _appModeCell = (OAAppModeCell *) nib[0];
            _appModeCell.showDefault = YES;
            _appModeCell.selectedMode = [OAAppSettings sharedManager].applicationMode.get;
            _appModeCell.delegate = self;
        }
        return _appModeCell;
    }
    else if ([item[@"type"] isEqualToString:OASimpleTableViewCell.reuseIdentifier])
    {
        OASimpleTableViewCell *cell = (OASimpleTableViewCell *)[tableView dequeueReusableCellWithIdentifier:OASimpleTableViewCell.reuseIdentifier forIndexPath:indexPath];
        [cell descriptionVisibility:NO];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.separatorInset = UIEdgeInsetsMake(0., [OAUtilities getLeftMargin] + kPaddingToLeftOfContentWithIcon, 0., 0.);
        cell.titleLabel.text = item[@"name"];

        BOOL hasLeftIcon = [item.allKeys containsObject:@"image"];
        cell.leftIconView.image = hasLeftIcon ? [UIImage templateImageNamed:item[@"image"]] : nil;
        cell.leftIconView.tintColor = isOn ? [UIColor colorNamed:ACColorNameIconColorSelected] : [UIColor colorNamed:ACColorNameIconColorDisabled];
        return cell;
    }
    else if ([item[@"type"] isEqualToString:OAValueTableViewCell.reuseIdentifier])
    {
        OAValueTableViewCell *cell = (OAValueTableViewCell *)[tableView dequeueReusableCellWithIdentifier:OAValueTableViewCell.reuseIdentifier forIndexPath:indexPath];
        [cell descriptionVisibility:NO];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.separatorInset = UIEdgeInsetsMake(0., [OAUtilities getLeftMargin] + kPaddingToLeftOfContentWithIcon, 0., 0.);
        cell.titleLabel.text = item[@"name"];
        cell.valueLabel.text = item[@"value"];
        NSString *iconName = item[@"image"];
        BOOL hasLeftIcon = iconName && iconName.length > 0;
        [cell leftIconVisibility:hasLeftIcon];
        cell.leftIconView.image = hasLeftIcon ? [UIImage templateImageNamed:iconName] : nil;
        cell.leftIconView.tintColor = isOn ? [UIColor colorNamed:ACColorNameIconColorSelected] : [UIColor colorNamed:ACColorNameIconColorDisabled];
        return cell;
    }
    else if ([item[@"type"] isEqualToString:OASwitchTableViewCell.reuseIdentifier])
    {
        OASwitchTableViewCell *cell = (OASwitchTableViewCell *)[tableView dequeueReusableCellWithIdentifier:OASwitchTableViewCell.reuseIdentifier forIndexPath:indexPath];
        [cell descriptionVisibility:NO];
        cell.selectionStyle = hasOptions ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
        cell.separatorInset = UIEdgeInsetsMake(0., [OAUtilities getLeftMargin] + (isLastGroupIndex ? kPaddingOnSideOfContent : kPaddingToLeftOfContentWithIcon), 0., 0.);
        [cell dividerVisibility:![item[@"key"] isEqualToString:@"nautical_depth"] ? hasOptions : NO];
        cell.titleLabel.text = item[@"name"];
        [cell leftIconVisibility:[item[@"image"] length] > 0 || item[@"has_empty_icon"]];
        if (item[@"has_empty_icon"])
        {
            cell.leftIconView.image = nil;
            cell.leftIconView.backgroundColor = isOn ? [UIColor colorNamed:ACColorNameIconColorSelected] : [UIColor colorNamed:ACColorNameIconColorDisabled];
            cell.leftIconView.layer.cornerRadius = cell.leftIconView.layer.frame.size.width / 2;
            cell.leftIconView.clipsToBounds = YES;
        }
        else
        {
            cell.leftIconView.backgroundColor = UIColor.clearColor;
            NSString *iconName = item[@"image"];
            UIImage *icon;
            if ([iconName hasPrefix:@"mx_"])
                icon = [[OAUtilities getMxIcon:iconName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            else
                icon = iconName && iconName.length > 0 ? [UIImage templateImageNamed:iconName] : nil;

            cell.leftIconView.image = icon;
            cell.leftIconView.tintColor = isOn ? [UIColor colorNamed:ACColorNameIconColorSelected] : [UIColor colorNamed:ACColorNameIconColorDisabled];
        }

        cell.switchView.on = isOn;
        cell.switchView.tag = indexPath.section << 10 | indexPath.row;
        [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
        [cell.switchView addTarget:self action:@selector(onSwitchPressed:) forControlEvents:UIControlEventValueChanged];
        return cell;
    }
    else if ([item[@"type"] isEqualToString:OAButtonTableViewCell.reuseIdentifier])
    {
        OAButtonTableViewCell *cell = (OAButtonTableViewCell *)[tableView dequeueReusableCellWithIdentifier:OAButtonTableViewCell.reuseIdentifier forIndexPath:indexPath];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.separatorInset = UIEdgeInsetsMake(0., [OAUtilities getLeftMargin] + kPaddingToLeftOfContentWithIcon, 0., 0.);
        cell.titleLabel.text = item[@"name"];
        cell.descriptionLabel.text = item[@"desc"];
        BOOL hasLeftIcon = [item.allKeys containsObject:@"image"];
        cell.leftIconView.image = hasLeftIcon ? [UIImage rtlImageNamed:item[@"image"]] : nil;
        NSString *title = OALocalizedString(@"shared_string_get");
        cell.button.configuration = [ButtonConfigurationHelper purchasePlanButtonConfigurationWithTitle:title];
        cell.button.layer.cornerRadius = 6;
        cell.button.layer.masksToBounds = YES;
        cell.button.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
        [cell.button setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [cell.button setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        cell.button.accessibilityLabel = title;
        cell.button.tag = indexPath.section << 10 | indexPath.row;
        [cell.button removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
        [cell.button addTarget:self action:@selector(onButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        return cell;
    }
    else if ([item[@"type"] isEqualToString:FreeBackupBannerCell.reuseIdentifier])
    {
        FreeBackupBannerCell *cell = (FreeBackupBannerCell *)[tableView dequeueReusableCellWithIdentifier:FreeBackupBannerCell.reuseIdentifier forIndexPath:indexPath];
        if (!_freeBackupBanner)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"FreeBackupBanner" owner:self options:nil];
            _freeBackupBanner = (FreeBackupBanner *)nib[0];
            _freeBackupBanner.didOsmAndCloudButtonAction = ^{
                OAProduct *product;
                if ([item[@"key"] isEqualToString:@"terrain_layer"])
                    product = _iapHelper.srtm;
                [OAChoosePlanHelper showChoosePlanScreenWithProduct:product navController:[OARootViewController instance].navigationController];
            };
            
            [_freeBackupBanner configureWithBannerType:BannerTypeMapSettingsTopography];
            _freeBackupBanner.translatesAutoresizingMaskIntoConstraints = NO;
            [cell.contentView addSubview:_freeBackupBanner];
            [NSLayoutConstraint activateConstraints:@[
                [_freeBackupBanner.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor],
                [_freeBackupBanner.bottomAnchor constraintEqualToAnchor:cell.contentView.bottomAnchor],
                [_freeBackupBanner.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor],
                [_freeBackupBanner.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor],
            ]];
        }
        return cell;
    }
    else if (group)
    {
        OARightIconTableViewCell *cell = (OARightIconTableViewCell *)[tableView dequeueReusableCellWithIdentifier:OARightIconTableViewCell.reuseIdentifier forIndexPath:indexPath];

        [cell leftIconVisibility:NO];
        [cell descriptionVisibility:NO];
        cell.separatorInset = UIEdgeInsetsMake(0., [OAUtilities getLeftMargin] + kPaddingOnSideOfContent, 0., 0.);
        cell.titleLabel.text = group.groupName;
        if (indexPath.row > 0)
            cell.titleLabel.textColor = [UIColor colorNamed:ACColorNameTextColorActive];
        
        cell.rightIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
        cell.rightIconView.image = [UIImage templateImageNamed:group.isOpen ? @"ic_custom_arrow_up" : ACImageNameIcCustomArrowDown];
        if (!group.isOpen && [cell isDirectionRTL])
            cell.rightIconView.image = cell.rightIconView.image.imageFlippedForRightToLeftLayoutDirection;
        
        return cell;
    }

    return nil;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [self heightForHeader:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"type"] isEqualToString:FreeBackupBannerCell.reuseIdentifier])
    {
        CGFloat titleHeight = [OAUtilities calculateTextBounds:_freeBackupBanner.titleLabel.text width:tableView.frame.size.width - _freeBackupBanner.leadingTrailingOffset font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]].height;
        
        CGFloat descriptionHeight = [OAUtilities calculateTextBounds:_freeBackupBanner.descriptionLabel.text width:tableView.frame.size.width - _freeBackupBanner.leadingTrailingOffset font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]].height;
        return _freeBackupBanner.defaultFrameHeight + titleHeight + descriptionHeight;
    }
    else
    {
        return UITableViewAutomaticDimension;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    OAMapSettingsViewController *mapSettingsViewController;
    BOOL isPromoButton = [item[@"type"] isEqualToString:OAButtonTableViewCell.reuseIdentifier] || [item[@"type"] isEqualToString:FreeBackupBannerCell.reuseIdentifier];
    BOOL isGroup = [self getCollapsableGroup:indexPath.section] != nil;

    if (isGroup && [item[@"type"] isEqualToString:OARightIconTableViewCell.reuseIdentifier])
        [self openCloseGroup:indexPath];
    else if ([item[@"key"] hasPrefix:@"collapsed_"])
        [self openCloseGroup:indexPath];
    else if ([item[@"key"] isEqualToString:@"poi_layer"])
        mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenPOI];
    else if ([item[@"key"] isEqualToString:@"mapillary_layer"])
        mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenMapillaryFilter];
    else if ([item[@"key"] isEqualToString:@"wikipedia_layer"] && !isPromoButton)
        mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenWikipedia];
    else if ([item[@"key"] isEqualToString:@"map_magnifier"])
        mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenSetting param:mapDensityKey];
    else if ([item[@"key"] isEqualToString:@"text_size"])
        mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenSetting param:textSizeKey];
    else if ([item[@"key"] isEqualToString:@"contour_lines_layer"])
        mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenContourLines];
    else if ([item[@"key"] isEqualToString:@"terrain_layer"] && !isPromoButton)
        mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenTerrain];
    else if ([item[@"key"] isEqualToString:@"overlay_layer"])
        mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenOverlay];
    else if ([item[@"key"] isEqualToString:@"underlay_layer"])
        mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenUnderlay];
    else if ([item[@"key"] isEqualToString:@"map_language"])
        mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenLanguage];
    else if ([item[@"key"] isEqualToString:@"weather_layer"] && !isPromoButton)
        mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenWeather];
    else if ([item[@"key"] isEqualToString:@"nautical_depth"])
        mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenNauticalDepth];
    else if ([item[@"key"] isEqualToString:@"coordinates_grid"])
        mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenCoordinatesGrid];

    if ([item[@"key"] hasPrefix:@"routes_"])
    {
        NSArray<NSString *> *hasParameters = @[SHOW_CYCLE_ROUTES_ATTR, SHOW_MTB_ROUTES, ALPINE_HIKING_ATTR, SHOW_ALPINE_HIKING_SCALE_SCHEME_ROUTES,HIKING_ROUTES_OSMC_ATTR, TRAVEL_ROUTES];
        NSString *parameterName = [item[@"key"] substringFromIndex:7];
        if ([hasParameters containsObject:parameterName])
            mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenRoutes param:parameterName];
    }
    else if ([item[@"key"] isEqualToString:@"map_type"])
    {
        mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenMapType];
        ((OAMapSettingsMapTypeScreen *) mapSettingsViewController.screenObj).delegate = self;
    }
    else if ([item[@"key"] hasPrefix:@"filtered_"])
    {
        for (OAMapStyleParameter *parameter in _filteredTopLevelParams)
        {
            if (parameter.dataType != OABoolean && [item[@"key"] isEqualToString:[NSString stringWithFormat:@"filtered_%@", parameter.name]])
            {
                OAMapSettingsViewController *parameterViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenParameter param:parameter.name];
                [parameterViewController show:vwController.parentViewController parentViewController:vwController animated:YES];
            }
        }
    }
    else if ([item[@"key"] hasPrefix:@"category_"])
    {
        for (NSString *cName in _allCategories)
        {
            if ([item[@"key"] isEqualToString:[NSString stringWithFormat:@"category_%@", cName]])
                mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenCategory param:cName];
        }
    }

    if (mapSettingsViewController)
        [mapSettingsViewController show:vwController.parentViewController parentViewController:vwController animated:YES];
    
    if ([item[@"key"] isEqualToString:@"tracks"])
        [self.vwController.navigationController pushViewController:[OAMapSettingsGpxViewController new] animated:YES];

    if ([item[@"key"] isEqualToString:@"mapMode"])
    {
        [self.vwController hide:YES animated:YES];

        MapSettingsMapModeParametersViewController *vc = [[MapSettingsMapModeParametersViewController alloc] init];
        [OARootViewController.instance.mapPanel showScrollableHudViewController:vc];
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UISwitch pressed

- (void)onSwitchPressed:(id)sender
{
    UISwitch *switchView = (UISwitch *) sender;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:switchView.tag & 0x3FF inSection:switchView.tag >> 10];
    NSDictionary *item = [self getItem:indexPath];

    if ([item[@"key"] isEqualToString:@"favorites"])
        [_settings setShowFavorites:switchView.on];
    else if ([item[@"key"] isEqualToString:@"layer_amenity_label"])
        [_settings setShowPoiLabel:switchView.isOn];
    else if ([item[@"key"] isEqualToString:@"show_borders_of_downloaded_maps"])
        [_settings setShowBordersOfDownloadedMaps:switchView.isOn];
    else if ([item[@"key"] isEqualToString:@"wikipedia_layer"])
        [self wikipediaChanged:switchView.isOn];
    else if ([item[@"key"] isEqualToString:@"osm_edits_offline_layer"])
        [_settings setShowOfflineEdits:switchView.isOn];
    else if ([item[@"key"] isEqualToString:@"osm_notes_online_layer"])
        [_settings setShowOnlineNotes:switchView.isOn];
    else if ([item[@"key"] isEqualToString:@"mapillary_layer"])
        [self mapillaryChanged:switchView.isOn];
    else if ([item[@"key"] hasPrefix:@"routes_"])
        [self groupItemSwitchChanged:switchView.isOn indexPath:indexPath];
    else if ([item[@"key"] hasPrefix:@"osm_"])
        [self groupItemSwitchChanged:switchView.isOn indexPath:indexPath];
    else if ([item[@"key"] isEqualToString:@"category_transport"])
        [self transportChanged:switchView.isOn];
    else if ([item[@"key"] isEqualToString:@"contour_lines_layer"])
        [self contourLinesChanged:switchView.isOn];
    else if ([item[@"key"] isEqualToString:@"terrain_layer"])
        [self terrainChanged:switchView.isOn];
    else if ([item[@"key"] isEqualToString:@"overlay_layer"])
        [self overlayChanged:switchView.isOn];
    else if ([item[@"key"] isEqualToString:@"underlay_layer"])
        [self underlayChanged:switchView.isOn];
    else if ([item[@"key"] isEqualToString:@"weather_layer"])
        [self weatherChanged:switchView.isOn];
    else if ([item[@"key"] isEqualToString:@"nautical_depth"])
        [self nauticalDepthChanged:switchView.isOn];
    else if ([item[@"key"] hasPrefix:@"filtered_"])
        [self filteredBooleanMapStyleParamChanged:switchView.isOn key:item[@"key"]];

    [tblView beginUpdates];
    [tblView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    [tblView endUpdates];
}

- (void)mapillaryChanged:(BOOL)isOn
{
    [_app.data setMapillary:isOn];
    if (isOn && !_settings.mapillaryFirstDialogShown.get)
    {
        [_settings.mapillaryFirstDialogShown set:YES];
        OAFirstMapillaryBottomSheetViewController *screen = [[OAFirstMapillaryBottomSheetViewController alloc] init];
        [screen show];
    }
}

- (void)groupItemSwitchChanged:(BOOL)isOn indexPath:(NSIndexPath *)indexPath
{
    OATableCollapsableGroup *group = [self getCollapsableGroup:indexPath.section];
    OAMapStyleParameter *parameter;
    if ((group && group.groupType == EOATableCollapsableGroupMapSettingsRoutes)
            || ([tableData[indexPath.section][@"group_name"] isEqualToString:OALocalizedString(@"rendering_category_routes")]
            && _routesParameters.count <= kMaxCountRoutesWithoutGroup))
        parameter = _routesParameters[indexPath.row];
    else if (group.groupType == EOATableCollapsableGroupMapSettingsOSM)
        parameter = _osmParameters[indexPath.row - _osmSettingsCount];

    if (parameter) {
        parameter.value = isOn ? @"true" : @"false";
        [_styleSettings save:parameter];
    }
}

- (void)transportChanged:(BOOL)isOn
{
    [_styleSettings setCategoryEnabled:isOn categoryName:TRANSPORT_CATEGORY];
    if (isOn && ![_styleSettings isCategoryEnabled:TRANSPORT_CATEGORY])
    {
        OAMapSettingsViewController *transportSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenCategory param:TRANSPORT_CATEGORY];
        [transportSettingsViewController show:vwController.parentViewController parentViewController:vwController animated:YES];
    }
}

- (void)contourLinesChanged:(BOOL)isOn
{
    OAMapStyleParameter *parameter = [_styleSettings getParameter:CONTOUR_LINES];
    if (parameter)
    {
        parameter.value = isOn ? [_settings.contourLinesZoom get] : @"disabled";
        [_styleSettings save:parameter];
    }
}

- (void)terrainChanged:(BOOL)isOn
{
    [((OASRTMPlugin *) [OAPluginsHelper getPlugin:OASRTMPlugin.class]) setTerrainLayerEnabled:isOn];
}

- (void)nauticalDepthChanged:(BOOL)isOn
{
    OAMapStyleParameter *parameter = [_styleSettings getParameter:NAUTICAL_DEPTH_CONTOURS];
    if (parameter)
    {
        parameter.value = isOn ? @"true" : @"false";
        [_styleSettings save:parameter];
    }
}

- (void)filteredBooleanMapStyleParamChanged:(BOOL)isOn key:(NSString *)key
{
    OAMapStyleParameter *param = [_styleSettings getParameter:[key substringFromIndex:[@"filtered_" length]]];
    param.value = isOn ? @"true" : @"false";
    [_styleSettings save:param];
}

- (void)overlayChanged:(BOOL)isOn
{
    if (isOn)
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
    {
        _app.data.overlayMapSource = nil;
    }
}

- (void)underlayChanged:(BOOL)isOn
{
    [_settings setUnderlayOpacitySliderVisibility:isOn];
    if (isOn)
    {
        BOOL hasLastMapSource = _app.data.lastUnderlayMapSource != nil;
        if (!hasLastMapSource)
            _app.data.lastUnderlayMapSource = [OAMapSource getOsmAndOnlineTilesMapSource];

        _app.data.underlayMapSource = _app.data.lastUnderlayMapSource;
        if (!hasLastMapSource)
        {
            OAMapSettingsViewController *mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenUnderlay];
            [mapSettingsViewController show:vwController.parentViewController parentViewController:vwController animated:YES];
        }
    }
    else
    {
        _app.data.underlayMapSource = nil;
    }
}

- (void)wikipediaChanged:(BOOL)isOn
{
    [(OAWikipediaPlugin *) [OAPluginsHelper getPlugin:OAWikipediaPlugin.class] wikipediaChanged:isOn];
}

- (void)weatherChanged:(BOOL)isOn
{
    [(OAWeatherPlugin *) [OAPluginsHelper getPlugin:OAWeatherPlugin.class] weatherChanged:isOn];
}

- (void)installMapLayerFor:(id)param
{
    if (AFNetworkReachabilityManager.sharedManager.isReachable)
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

#pragma mark - UIButton pressed

- (BOOL)onButtonPressed:(id)sender
{
    UIButton *button = (UIButton *) sender;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:button.tag & 0x3FF inSection:button.tag >> 10];
    NSDictionary *item = [self getItem:indexPath];

    OAProduct *product;
    if ([item[@"key"] isEqualToString:@"wikipedia_layer"])
        product = _iapHelper.wiki;
    else if ([item[@"key"] isEqualToString:@"weather_layer"])
        product = _iapHelper.weather;

    [OAChoosePlanHelper showChoosePlanScreenWithProduct:product navController:[OARootViewController instance].navigationController];
    return NO;
}

#pragma mark - OAMapTypeDelegate

- (void)updateSkimapRoutesParameter:(OAMapSource *)source
{
    if (![source.resourceId hasPrefix:@"skimap"])
    {
        OAMapStyleParameter *ski = [_styleSettings getParameter:PISTE_ROUTES_ATTR];
        if (ski && ![ski.value isEqualToString:@"false"])
        {
            ski.value = @"false";
            [_styleSettings save:ski];

            if ([_routesWithGroup containsObject:PISTE_ROUTES_ATTR])
            {
                NSMutableArray *routesWithGroup = [_routesWithGroup mutableCopy];
                [routesWithGroup removeObject:PISTE_ROUTES_ATTR];
                _routesWithGroup = routesWithGroup;
            }
        }
    }
    else
    {
        _routesWithGroup = [@[PISTE_ROUTES_ATTR] arrayByAddingObjectsFromArray:_routesWithGroup];
    }
}

- (void)refreshMenu
{
    _styleSettings = [OAMapStyleSettings sharedInstance];
    [self setupView];
}

#pragma mark - OAIAPProductNotification

- (void)productPurchased:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setupView];
    });
}

- (void)productsRestored:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setupView];
    });
}

#pragma mark - Selectors

- (void)onApplicationModeChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_appModeCell)
            _appModeCell.selectedMode = [_settings.applicationMode get];
        [self refreshMenu];
    });
}

#pragma mark - OADashboardScreen

- (void)initData
{
}

@end
