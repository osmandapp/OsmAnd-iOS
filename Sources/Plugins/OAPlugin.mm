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
#import "OAMapHudViewController.h"
#import "OAIAPHelper.h"
#import "OAAutoObserverProxy.h"
#import "OAQuickActionRegistry.h"
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

- (NSArray<OAQuickActionType *> *) getQuickActionTypes
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

/*
- (void) addMyPlacesTab(FavoritesActivity favoritesActivity, List<TabItem> mTabs, Intent intent) {
}

- (void) contextMenuFragment(Activity activity, Fragment fragment, Object info, ContextMenuAdapter adapter) {
}

- (void) optionsMenuFragment(Activity activity, Fragment fragment, ContextMenuAdapter optionsMenuAdapter) {
}

public List<String> indexingFiles(IProgress progress) {
    return null;
}

- (BOOL) mapActivityKeyUp(MapActivity mapActivity, int keyCode) {
    return false;
}

- (void) onMapActivityExternalResult(int requestCode, int resultCode, Intent data) {
}
*/

/*
public static List<String> onIndexingFiles(IProgress progress) {
    List<String> l = new ArrayList<String>();
    for (OsmandPlugin plugin : getEnabledPlugins()) {
        List<String> ls = plugin.indexingFiles(progress);
        if (ls != null && ls.size() > 0) {
            l.addAll(ls);
        }
    }
    return l;
}

public static void onMapActivityCreate(MapActivity activity) {
    for (OsmandPlugin plugin : getEnabledPlugins()) {
        plugin.mapActivityCreate(activity);
    }
}

public static void onMapActivityResume(MapActivity activity) {
    for (OsmandPlugin plugin : getEnabledPlugins()) {
        plugin.mapActivityResume(activity);
    }
}

public static void onMapActivityPause(MapActivity activity) {
    for (OsmandPlugin plugin : getEnabledPlugins()) {
        plugin.mapActivityPause(activity);
    }
}

public static void onMapActivityDestroy(MapActivity activity) {
    for (OsmandPlugin plugin : getEnabledPlugins()) {
        plugin.mapActivityDestroy(activity);
    }
}

public static void onMapActivityResult(int requestCode, int resultCode, Intent data) {
    for (OsmandPlugin plugin : getEnabledPlugins()) {
        plugin.onMapActivityExternalResult(requestCode, resultCode, data);
    }
}

public static void onMapActivityScreenOff(MapActivity activity) {
    for (OsmandPlugin plugin : getEnabledPlugins()) {
        plugin.mapActivityScreenOff(activity);
    }
}
*/

/*
+ (void) registerMapContextMenu(MapActivity map, double latitude, double longitude, ContextMenuAdapter adapter, Object selectedObj) {
    for (OsmandPlugin plugin : getEnabledPlugins()) {
        if (plugin instanceof ParkingPositionPlugin) {
            plugin.registerMapContextMenuActions(map, latitude, longitude, adapter, selectedObj);
        } else if (plugin instanceof OsmandMonitoringPlugin) {
            plugin.registerMapContextMenuActions(map, latitude, longitude, adapter, selectedObj);
        }
    }
    for (OsmandPlugin plugin : getEnabledPlugins()) {
        if (!(plugin instanceof ParkingPositionPlugin) && !(plugin instanceof OsmandMonitoringPlugin)) {
            int itemsCount = adapter.length();
            plugin.registerMapContextMenuActions(map, latitude, longitude, adapter, selectedObj);
            if (adapter.length() > itemsCount) {
                adapter.addItem(new ContextMenuItem.ItemBuilder()
                                .setPosition(itemsCount)
                                .setLayout(R.layout.context_menu_list_divider)
                                .createItem());
            }
        }
    }
}

public static void registerLayerContextMenu(OsmandMapTileView mapView, ContextMenuAdapter adapter, MapActivity mapActivity) {
    for (OsmandPlugin plugin : getEnabledPlugins()) {
        plugin.registerLayerContextMenuActions(mapView, adapter, mapActivity);
    }
}

public static void registerOptionsMenu(MapActivity map, ContextMenuAdapter helper) {
    for (OsmandPlugin plugin : getEnabledPlugins()) {
        plugin.registerOptionsMenuItems(map, helper);
    }
}

public static void onContextMenuActivity(Activity activity, Fragment fragment, Object info, ContextMenuAdapter adapter) {
    for (OsmandPlugin plugin : getEnabledPlugins()) {
        plugin.contextMenuFragment(activity, fragment, info, adapter);
    }
}


public static void onOptionsMenuActivity(Activity activity, Fragment fragment, ContextMenuAdapter optionsMenuAdapter) {
    for (OsmandPlugin plugin : getEnabledPlugins()) {
        plugin.optionsMenuFragment(activity, fragment, optionsMenuAdapter);
    }
}

public static boolean onMapActivityKeyUp(MapActivity mapActivity, int keyCode) {
    for (OsmandPlugin p : getEnabledPlugins()) {
        if (p.mapActivityKeyUp(mapActivity, keyCode))
            return true;
    }
    return false;
}
 */

/*
public static boolean isDevelopment() {
    return getEnabledPlugin(OsmandDevelopmentPlugin.class) != null;
}

public static void addMyPlacesTabPlugins(FavoritesActivity favoritesActivity, List<TabItem> mTabs, Intent intent) {
    for (OsmandPlugin p : getEnabledPlugins()) {
        p.addMyPlacesTab(favoritesActivity, mTabs, intent);
    }
}
 */

- (void)onAnalysePoint:(OAGPXTrackAnalysis *)analysis point:(NSObject *)point attribute:(OAPointAttributes *)attribute
{
}

- (void)getAvailableGPXDataSetTypes:(OAGPXTrackAnalysis *)analysis
                     availableTypes:(NSMutableArray<NSArray<NSNumber *> *> *)availableTypes
{
}

@end
