//
//  OAMapSettingsViewController.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 12.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAMapSettingsViewController.h"

#import "OASettingsTableViewCell.h"
#import "OASwitchTableViewCell.h"

#import "OAAutoObserverProxy.h"
#import "OANativeUtilities.h"
#import "OAMapRendererView.h"
#import "OAMapViewController.h"
#import "OARootViewController.h"

#import "OAMapSettingsMainScreen.h"
#import "OAMapSettingsMapTypeScreen.h"
#import "OAMapSettingsCategoryScreen.h"
#import "OAMapSettingsParameterScreen.h"
#import "OAMapSettingsSettingScreen.h"
#import "OAMapSettingsGpxScreen.h"
#import "OAMapSettingsPOIScreen.h"
#import "OAMapSettingsOverlayUnderlayScreen.h"
#import "OAMapSettingsLanguageScreen.h"
#import "OAMapSettingsPreferredLanguageScreen.h"
#import "Localization.h"
#import "OAUtilities.h"

#import <CoreLocation/CoreLocation.h>

#include <QtMath>
#include <QStandardPaths>
#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/IMapStylesCollection.h>
#include <OsmAndCore/Map/OnlineTileSources.h>
#include <OsmAndCore/Map/OnlineRasterMapLayerProvider.h>
#include <OsmAndCore/Map/ObfMapObjectsProvider.h>
#include <OsmAndCore/Map/MapPrimitivesProvider.h>
#include <OsmAndCore/Map/MapRasterLayerProvider_Software.h>
#include <OsmAndCore/Map/MapObjectsSymbolsProvider.h>
#include <OsmAndCore/Map/MapPresentationEnvironment.h>
#include <OsmAndCore/Map/MapPrimitiviser.h>
#include <OsmAndCore/Map/MapMarker.h>
#include <OsmAndCore/Map/MapMarkerBuilder.h>
#include <OsmAndCore/Map/MapMarkersCollection.h>
#include <OsmAndCore/Map/FavoriteLocationsPresenter.h>
#if defined(OSMAND_IOS_DEV)
#   include <OsmAndCore/Map/ObfMapObjectsMetricsLayerProvider.h>
#   include <OsmAndCore/Map/MapPrimitivesMetricsLayerProvider.h>
#   include <OsmAndCore/Map/MapRasterMetricsLayerProvider.h>
#endif // defined(OSMAND_IOS_DEV)



@interface OAMapSettingsViewController ()
{
    BOOL isOnlineMapSource;
}

@end

@implementation OAMapSettingsViewController
{
    OsmAndAppInstance _app;
}

@dynamic screenObj;

- (instancetype) init
{
    return [super initWithScreenType:EMapSettingsScreenMain];
}

- (instancetype) initWithSettingsScreen:(EMapSettingsScreen)settingsScreen
{
    return [super initWithScreenType:settingsScreen];
}

- (instancetype) initWithSettingsScreen:(EMapSettingsScreen)settingsScreen param:(id)param
{
    return [super initWithScreenType:settingsScreen param:param];
}

- (void) commonInit
{
    _app = [OsmAndApp instance];
    _settingsScreen = (EMapSettingsScreen) self.screenType;

    [super commonInit];
}

- (BOOL) isMainScreen
{
    return _settingsScreen == EMapSettingsScreenMain;
}

- (void) applyLocalization
{
    [super applyLocalization];
    
    self.titleView.text = OALocalizedString(@"map_settings_map");
}

- (void) setupView
{
    switch (_settingsScreen)
    {
        case EMapSettingsScreenMain:
            if (!self.screenObj)
                self.screenObj = [[OAMapSettingsMainScreen alloc] initWithTable:self.tableView viewController:self];
            break;
        case EMapSettingsScreenPOI:
            if (!self.screenObj)
                self.screenObj = [[OAMapSettingsPOIScreen alloc] initWithTable:self.tableView viewController:self];
            break;
        case EMapSettingsScreenGpx:
            if (!self.screenObj)
                self.screenObj = [[OAMapSettingsGpxScreen alloc] initWithTable:self.tableView viewController:self];
            break;
        case EMapSettingsScreenMapType:
            if (!self.screenObj)
                self.screenObj = [[OAMapSettingsMapTypeScreen alloc] initWithTable:self.tableView viewController:self];
            break;
        case EMapSettingsScreenCategory:
            if (!self.screenObj)
                self.screenObj = [[OAMapSettingsCategoryScreen alloc] initWithTable:self.tableView viewController:self param:self.customParam];
            break;
        case EMapSettingsScreenParameter:
            if (!self.screenObj)
                self.screenObj = [[OAMapSettingsParameterScreen alloc] initWithTable:self.tableView viewController:self param:self.customParam];
            break;
        case EMapSettingsScreenSetting:
            if (!self.screenObj)
                self.screenObj = [[OAMapSettingsSettingScreen alloc] initWithTable:self.tableView viewController:self param:self.customParam];
            break;
        case EMapSettingsScreenOverlay:
            if (!self.screenObj)
                self.screenObj = [[OAMapSettingsOverlayUnderlayScreen alloc] initWithTable:self.tableView viewController:self param:@"overlay"];
        case EMapSettingsScreenUnderlay:
            if (!self.screenObj)
                self.screenObj = [[OAMapSettingsOverlayUnderlayScreen alloc] initWithTable:self.tableView viewController:self param:@"underlay"];
        case EMapSettingsScreenLanguage:
            if (!self.screenObj)
                self.screenObj = [[OAMapSettingsLanguageScreen alloc] initWithTable:self.tableView viewController:self];
            break;
        case EMapSettingsScreenPreferredLanguage:
            if (!self.screenObj)
                self.screenObj = [[OAMapSettingsPreferredLanguageScreen alloc] initWithTable:self.tableView viewController:self];
            break;
            
        default:
            break;
    }

    OAMapSource* mapSource = _app.data.lastMapSource;
    const auto resource = _app.resourcesManager->getResource(QString::fromNSString(mapSource.resourceId));
    
    BOOL _isOnlineMapSourcePrev = isOnlineMapSource;
    isOnlineMapSource = (resource->type == OsmAnd::ResourcesManager::ResourceType::OnlineTileSources);
    
    self.screenObj.isOnlineMapSource = isOnlineMapSource;
    
    if (_isOnlineMapSourcePrev != isOnlineMapSource)
        [self.view setNeedsLayout];

    [super setupView];
}
        
@end
