//
//  OAPlugin.m
//  OsmAnd
//
//  Created by Alexey Kulish on 29/10/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAPlugin.h"
#import "OsmAndApp.h"
#import "Localization.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OAMapHudViewController.h"
#import "OAIAPHelper.h"
#import "OAProducts.h"
#import "OAObservable.h"
#import "OAAutoObserverProxy.h"
#import "OAMapButtonsHelper.h"
#import "OACustomPlugin.h"
#import "OAPluginInstalledViewController.h"
#import "OAResourcesBaseViewController.h"
#import "OAMonitoringPlugin.h"
#import "OAParkingPositionPlugin.h"
#import "OAOsmEditingPlugin.h"
#import "OAOsmandDevelopmentPlugin.h"
#import "OAMapillaryPlugin.h"
#import "OASkiMapsPlugin.h"
#import "OANauticalMapsPlugin.h"
#import "OASRTMPlugin.h"
#import "OAWikipediaPlugin.h"
#import "OAPOIUIFilter.h"
#import "OAWeatherPlugin.h"
#import "OAExternalSensorsPlugin.h"
#import "OAPluginsHelper.h"
#import "OsmAnd_Maps-Swift.h"

@implementation OAPlugin
{
    BOOL _enabled;
    NSString *_titleId;
    NSString *_shortDescriptionId;
    NSString *_descriptionId;
    NSMutableArray<OACommonPreference *> *_pluginPreferences;
    
    OAAutoObserverProxy* _addonsSwitchObserver;
}

static NSMutableArray<OAPlugin *> *allPlugins;

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        [self processNames];
        _pluginPreferences = [NSMutableArray array];
        _addonsSwitchObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                          withHandler:@selector(onAddonsSwitch:withKey:andValue:)
                                                           andObserve:[OsmAndApp instance].addonsSwitchObservable];
    }
    return self;
}

- (void) onAddonsSwitch:(id)observable withKey:(id)key andValue:(id)value
{
    NSString *productIdentifier = key;
    if ([productIdentifier isEqualToString:[self getId]])
    {
        BOOL active = [value boolValue];
        dispatch_async(dispatch_get_main_queue(), ^{
            [OAPluginsHelper enablePlugin:self enable:active];
        });
    }
}

- (OAMapPanelViewController *) getMapPanelViewController
{
    return [OARootViewController instance].mapPanel;
}

- (OAMapViewController *) getMapViewController
{
    return [OARootViewController instance].mapPanel.mapViewController;
}

- (OAMapInfoController *) getMapInfoController
{
    return [self getMapPanelViewController].hudViewController.mapInfoController;
}

- (NSString *) getId
{
    return nil;
}

- (void) processNames
{
    NSString *pluginId = [self getId];
    if (pluginId)
    {
        NSString *postfix = [[pluginId componentsSeparatedByString:@"."] lastObject];
        _titleId = [@"product_title_" stringByAppendingString:postfix];
        _shortDescriptionId = [@"product_desc_" stringByAppendingString:postfix];
        _descriptionId = [@"product_desc_ext_" stringByAppendingString:postfix];
    }
}

- (NSString *) getShortDescription
{
    return OALocalizedString(_shortDescriptionId);
}

- (NSString *) getDescription
{
    return OALocalizedString(_descriptionId);
}

- (NSString *) getName
{
    return OALocalizedString(_titleId);
}

- (UIImage *) getLogoResource
{
    return [UIImage imageNamed:self.getLogoResourceId];
}

- (NSString *) getLogoResourceId
{
    NSString *identifier = [self getId];
    OAProduct *product = [[OAIAPHelper sharedInstance] product:identifier];
    if (product)
        return [product productIconName];
    else
        return @"ic_custom_puzzle_piece";
}

- (UIImage *) getAssetResourceImage
{
    return [UIImage imageNamed:self.getAssetResourceName];
}

- (NSString *) getAssetResourceName
{
    NSString *identifier = [self getId];
    OAProduct *product = [[OAIAPHelper sharedInstance] product:identifier];
    if (product)
        return [product productScreenshotName];
    else
        return nil;
}

- (UIViewController *) getSettingsController
{
    return nil;
}

- (NSString *) getVersion
{
    return @"";
}

- (void) createWidgets:(id<OAWidgetRegistrationDelegate>)delegate appMode:(OAApplicationMode *)appMode widgetParams:(NSDictionary *)widgetParams
{
    // Override
}

/**
 * Plugin was installed
 */
- (void)onInstall
{
    for (OAApplicationMode *appMode in self.getAddedAppModes)
    {
        [OAApplicationMode changeProfileAvailability:appMode isSelected:YES];
    }
    [self showInstalledScreen];
}

- (void) showInstalledScreen
{
    if ([OAPluginsHelper getPluginById:self.getId])
    {
        OAPluginInstalledViewController *pluginInstalled = [[OAPluginInstalledViewController alloc] initWithPluginId:self.getId];
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:pluginInstalled];
        [OARootViewController.instance presentViewController:navigationController animated:YES completion:nil];
    }
}

/**
 * Initialize plugin runs just after creation
 */
- (BOOL) initPlugin
{
    for (OAApplicationMode *appMode in [self getAddedAppModes])
    {
        [OAApplicationMode changeProfileAvailability:appMode isSelected:YES];
    }
    return YES;
}

- (void) setEnabled:(BOOL)enabled
{
    _enabled = enabled;
}

- (BOOL) isEnabled
{
    return _enabled;
}

- (BOOL) isVisible
{
    return YES;
}

- (BOOL)isEnableByDefault
{
    return NO;
}

- (void) disable
{
    for (OAApplicationMode *appMode in self.getAddedAppModes)
    {
        [OAApplicationMode changeProfileAvailability:appMode isSelected:NO];
    }
}

- (NSArray<OAApplicationMode *> *) getAddedAppModes
{
    return @[];
}

- (NSString *) getHelpFileName
{
    return nil;
}

- (NSArray<QuickActionType *> *) getQuickActionTypes
{
    return @[];
}

- (NSArray<OAWorldRegion *> *) getDownloadMaps
{
    return @[];
}

- (NSArray<OAResourceItem *> *) getSuggestedMaps
{
    return @[];
}

- (NSArray<NSString *> *) getWidgetIds
{
    return @[];
}

- (NSArray<OACommonPreference*> *)getPreferences
{
    return _pluginPreferences;
}

- (OACommonBoolean *)registerBooleanPreference:(NSString *)prefId defValue:(BOOL)defValue
{
    OACommonBoolean *preference = [[OAAppSettings sharedManager] registerBooleanPreference:prefId defValue:defValue];
    [_pluginPreferences addObject:preference];
    return preference;
}

- (OACommonString *)registerStringPreference:(NSString *)prefId defValue:(NSString *)defValue
{
    OACommonString *preference = [[OAAppSettings sharedManager] registerStringPreference:prefId defValue:defValue];
    [_pluginPreferences addObject:preference];
    return preference;
}

/*
 * Return true in case if plugin should fill the map context menu with buildContextMenuRows method.
 */
/*
- (BOOL) isMenuControllerSupported(Class<? extends MenuController> menuControllerClass) {
    return false;
}
 */

/*
 * Add menu rows to the map context menu.
 */
/*
- (void) buildContextMenuRows(@NonNull MenuBuilder menuBuilder, @NonNull View view) {
}
*/
/*
 * Clear resources after menu was closed
 */
/*
- (void) clearContextMenuRows() {
}
 */

- (NSString *)getMapObjectsLocale:(NSObject *)object preferredLocale:(NSString *)preferredLocale
{
    return nil;
}

- (NSArray<OAPOIUIFilter *> *)getCustomPoiFilters
{
    return [NSArray new];
}

- (void)prepareExtraTopPoiFilters:(NSSet<OAPOIUIFilter *> *)poiUIFilters
{
}

- (OABaseWidgetView *)createMapWidgetForParams:(OAWidgetType *)widgetType customId:(NSString *)customId appMode:(OAApplicationMode *)appMode  widgetParams:(NSDictionary *)widgetParams
{
    return nil;
}

- (void)attachAdditionalInfoToRecordedTrack:(CLLocation *)location json:(NSMutableData *)json
{
    
}

/*
private static void checkMarketPlugin(OsmandApplication app, OsmandPlugin srtm, boolean paid, NSString *id, NSString *id2) {
    boolean marketEnabled = Version.isMarketEnabled(app);
    boolean pckg = isPackageInstalled(id, app) ||
    isPackageInstalled(id2, app);
    if ((Version.isDeveloperVersion(app) || !Version.isProductionVersion(app)) && !paid) {
        // for test reasons
        marketEnabled = false;
    }
    if (pckg || (!marketEnabled && !paid)) {
        if (pckg && !app.getSettings().getPlugins().contains("-" + srtm.getId())) {
            srtm.setActive(true);
        }
        allPlugins.add(srtm);
    } else {
        if (marketEnabled) {
            srtm.setInstallURL(Version.getUrlWithUtmRef(app, id));
            allPlugins.add(srtm);
        }
    }
}
*/

- (void) updateLayers
{
}

- (void) registerLayers
{
}

/*
- (void) handleRequestPermissionsResult(int requestCode, String[] permissions,
                                           int[] grantResults) {
}

public static final void onRequestPermissionsResult(int requestCode, String[] permissions,
                                                    int[] grantResults) {
    for (OsmandPlugin plugin : getAvailablePlugins()) {
        plugin.handleRequestPermissionsResult(requestCode, permissions, grantResults);
    }
}
*/

- (BOOL) destinationReached
{
    return YES;
}

/*
- (void) registerLayerContextMenuActions(OsmandMapTileView mapView, ContextMenuAdapter adapter, MapActivity mapActivity) {
}

- (void) registerMapContextMenuActions(MapActivity mapActivity, double latitude, double longitude, ContextMenuAdapter adapter, Object selectedObj) {
}

- (void) registerOptionsMenuItems(MapActivity mapActivity, ContextMenuAdapter helper) {
}
*/

- (void) updateLocation:(CLLocation *)location
{
}

- (void)getAvailableGPXDataSetTypes:(OASGpxTrackAnalysis *)analysis
                     availableTypes:(NSMutableArray<NSArray<NSNumber *> *> *)availableTypes
{
}

@end
