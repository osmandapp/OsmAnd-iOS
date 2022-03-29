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
#import "OAQuickActionType.h"
#import "OAQuickActionRegistry.h"
#import "OACustomPlugin.h"
#import "OAPluginInstalledViewController.h"
#import "OAResourcesBaseViewController.h"
#import "OAMonitoringPlugin.h"
#import "OAParkingPositionPlugin.h"
#import "OAOsmEditingPlugin.h"
#import "OAMapillaryPlugin.h"
#import "OASkiMapsPlugin.h"
#import "OANauticalMapsPlugin.h"
#import "OASRTMPlugin.h"
#import "OAWikipediaPlugin.h"
#import "OAPOIUIFilter.h"
#import "OAOpenPlaceReviews.h"

@implementation OAPlugin
{
    BOOL _enabled;
    NSString *_titleId;
    NSString *_shortDescriptionId;
    NSString *_descriptionId;
    
    OAAutoObserverProxy* _addonsSwitchObserver;
}

static NSMutableArray<OAPlugin *> *allPlugins;

+ (void) initialize
{
    if (self == [OAPlugin class])
    {
        allPlugins = [NSMutableArray array];
    }
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        [self processNames];
        
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
            [self.class enablePlugin:self enable:active];
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
    if ([OAPlugin getPluginById:self.getId])
    {
        OAPluginInstalledViewController *pluginInstalled = [[OAPluginInstalledViewController alloc] initWithPluginId:self.getId];
        [OARootViewController.instance presentViewController:pluginInstalled animated:YES completion:nil];
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

+ (void) initPlugins
{
    NSMutableSet<NSString *> *enabledPlugins = [[[OAAppSettings sharedManager] getEnabledPlugins] mutableCopy];
    [allPlugins removeAllObjects];

    /*
    allPlugins.add(new OsmandRasterMapsPlugin(app));
    allPlugins.add(new AudioVideoNotesPlugin(app));
    allPlugins.add(new AccessibilityPlugin(app));
    allPlugins.add(new OsmandDevelopmentPlugin(app));
    */

    [allPlugins addObject:[[OAWikipediaPlugin alloc] init]];
    [allPlugins addObject:[[OAMonitoringPlugin alloc] init]];
    [allPlugins addObject:[[OASRTMPlugin alloc] init]];
    [allPlugins addObject:[[OANauticalMapsPlugin alloc] init]];
    [allPlugins addObject:[[OASkiMapsPlugin alloc] init]];
    [allPlugins addObject:[[OAParkingPositionPlugin alloc] init]];
    [allPlugins addObject:[[OAOsmEditingPlugin alloc] init]];
    [allPlugins addObject:[[OAOpenPlaceReviews alloc] init]];
    [allPlugins addObject:[[OAMapillaryPlugin alloc] init]];

    [self loadCustomPlugins];
    [self enablePluginsByDefault:enabledPlugins];
    [self activatePlugins:enabledPlugins];
}

+ (void) loadCustomPlugins
{
    NSString *customPluginsJson = OAAppSettings.sharedManager.customPluginsJson;
    if (customPluginsJson.length > 0)
    {
        NSData* data = [customPluginsJson dataUsingEncoding:NSUTF8StringEncoding];
        NSArray *plugins = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
        for (NSDictionary *pluginJson in plugins)
        {
            OACustomPlugin *plugin = [[OACustomPlugin alloc] initWithJson:pluginJson];
            if (plugin)
                [allPlugins addObject:plugin];
        }
    }
}

+ (void)enablePluginsByDefault:(NSMutableSet<NSString *> *)enabledPlugins
{
    for (OAPlugin *plugin in allPlugins)
    {
        if ([plugin isEnableByDefault]
                && ![enabledPlugins containsObject:[plugin getId]]
                && ![self isPluginDisabledManually:plugin])
        {
            [enabledPlugins addObject:[plugin getId]];
            [[OAAppSettings sharedManager] enablePlugin:[plugin getId] enable:YES];
        }
    }
}

+ (BOOL)isPluginDisabledManually:(OAPlugin *)plugin
{
    return [[[OAAppSettings sharedManager] getPlugins] containsObject:[@"-" stringByAppendingString:[plugin getId]]];
}

+ (void) activatePlugins:(NSSet<NSString *> *)enabledPlugins
{
    for (OAPlugin *plugin in allPlugins)
    {
        if ([enabledPlugins containsObject:[plugin getId]] || [plugin isEnabled])
        {
            [self initPlugin:plugin];
        }
    }
    [OAQuickActionRegistry.sharedInstance updateActionTypes];
}

+ (void) initPlugin:(OAPlugin *)plugin
{
    @try
    {
        if ([plugin initPlugin])
            [plugin setEnabled:YES];
    }
    @catch (NSException *e)
    {
        NSLog(@"Plugin initialization failed %@ reason=%@", [plugin getId], e.reason);
    }
}

+ (NSArray<OAWorldRegion *> *) getCustomDownloadRegions
{
    NSMutableArray<OAWorldRegion *> *list = [NSMutableArray array];
    for (OAPlugin *plugin in self.getEnabledPlugins)
        [list addObjectsFromArray:plugin.getDownloadMaps];
    return list;
}

- (NSString *)getMapObjectsLocale:(NSObject *)object preferredLocale:(NSString *)preferredLocale
{
    return nil;
}

+ (NSString *)onGetMapObjectsLocale:(NSObject *)object preferredLocale:(NSString *)preferredLocale
{
    for (OAPlugin *plugin in [self getEnabledPlugins])
    {
        NSString *locale = [plugin getMapObjectsLocale:object preferredLocale:preferredLocale];
        if (locale)
            return locale;
    }
    return preferredLocale;
}

- (NSArray<OAPOIUIFilter *> *)getCustomPoiFilters
{
    return [NSArray new];
}

+ (void)registerCustomPoiFilters:(NSMutableArray<OAPOIUIFilter *> *)poiUIFilters
{
    for (OAPlugin *p in [self getAvailablePlugins])
    {
        [poiUIFilters addObjectsFromArray:[p getCustomPoiFilters]];
    }
}

- (void)prepareExtraTopPoiFilters:(NSSet<OAPOIUIFilter *> *)poiUIFilters
{
}

+ (void)onPrepareExtraTopPoiFilters:(NSSet<OAPOIUIFilter *> *)poiUIFilters
{
    for (OAPlugin *plugin in [self getEnabledPlugins])
    {
        [plugin prepareExtraTopPoiFilters:poiUIFilters];
    }
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

+ (BOOL) enablePlugin:(OAPlugin *)plugin enable:(BOOL)enable
{
    if (enable)
    {
        if (![plugin initPlugin])
        {
            [plugin setEnabled:NO];
            return NO;
        }
        else
        {
            [plugin setEnabled:YES];
        }
    }
    else
    {
        [plugin disable];
        [plugin setEnabled:NO];
    }
    [[OAAppSettings sharedManager] enablePlugin:[plugin getId] enable:enable];
    [OAQuickActionRegistry.sharedInstance updateActionTypes];
    [plugin updateLayers];
    
    if ([plugin isEnabled])
        [plugin showInstalledScreen];
    
    return YES;
}

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

+ (void) refreshLayers
{
    for (OAPlugin *plugin in [self.class getAvailablePlugins])
        [plugin updateLayers];
}

+ (NSArray<OAPlugin *> *) getAvailablePlugins
{
    return allPlugins;
}

+ (NSArray<OAPlugin *> *) getVisiblePlugins
{
    NSMutableArray<OAPlugin *> *list = [NSMutableArray arrayWithCapacity:allPlugins.count];
    for (OAPlugin *p in allPlugins)
    {
        if ([p isVisible])
            [list addObject:p];
    }
    return [NSArray arrayWithArray:list];
}

+ (NSArray<OAPlugin *> *) getEnabledPlugins
{
    NSMutableArray<OAPlugin *> *list = [NSMutableArray arrayWithCapacity:allPlugins.count];
    for (OAPlugin *p in allPlugins)
    {
        if ([p isEnabled])
            [list addObject:p];
    }
    return [NSArray arrayWithArray:list];
}

+ (NSArray<OAPlugin *> *) getEnabledVisiblePlugins
{
    NSMutableArray<OAPlugin *> *list = [NSMutableArray arrayWithCapacity:allPlugins.count];
    for (OAPlugin *p in allPlugins)
    {
        if ([p isEnabled] && [p isVisible])
            [list addObject:p];
    }
    return [NSArray arrayWithArray:list];
}

+ (NSArray<OAPlugin *> *) getNotEnabledPlugins
{
    NSMutableArray<OAPlugin *> *list = [NSMutableArray arrayWithCapacity:allPlugins.count];
    for (OAPlugin *p in allPlugins)
    {
        if (![p isEnabled])
            [list addObject:p];
    }
    return [NSArray arrayWithArray:list];
}

+ (NSArray<OAPlugin *> *) getNotEnabledVisiblePlugins
{
    NSMutableArray<OAPlugin *> *list = [NSMutableArray arrayWithCapacity:allPlugins.count];
    for (OAPlugin *p in allPlugins)
    {
        if (![p isEnabled] && [p isVisible])
            [list addObject:p];
    }
    return [NSArray arrayWithArray:list];
}

+ (OAPlugin *) getEnabledPlugin:(Class) cl
{
    for (OAPlugin *p in [self getEnabledPlugins])
    {
        if ([p isKindOfClass:cl])
            return p;
    }
    return nil;
}

+ (OAPlugin *) getPlugin:(Class) cl
{
    for (OAPlugin *p in [self getAvailablePlugins])
    {
        if ([p isKindOfClass:cl])
            return p;
    }
    return nil;
}

+ (OAPlugin *) getPluginById:(NSString *)pluginId
{
    for (OAPlugin *plugin in [self getAvailablePlugins])
    {
        if ([plugin.getId isEqualToString:pluginId])
            return plugin;
    }
    return nil;
}

+ (BOOL) isEnabled:(Class) cl
{
    return [self getEnabledPlugin:cl] != nil;
}

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

+ (BOOL) onDestinationReached
{
    BOOL b = YES;
    for (OAPlugin *plugin in [self getEnabledPlugins])
    {
        if (![plugin destinationReached])
            b = NO;
    }
    return b;
}

+ (void) createLayers
{
    for (OAPlugin *plugin in [self getEnabledPlugins])
    {
        [plugin registerLayers];
    }
}

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

+ (void) updateLocationPlugins:(CLLocation *)location
{
    for (OAPlugin *p in [self getEnabledPlugins])
    {
        [p updateLocation:location];
    }
}

+ (void) registerQuickActionTypesPlugins:(NSMutableArray<OAQuickActionType *> *)types disabled:(BOOL)disabled
{
    if (!disabled)
        for (OAPlugin *p in [self getEnabledPlugins])
            [types addObjectsFromArray:p.getQuickActionTypes];
    else
        for (OAPlugin *p in [self getNotEnabledPlugins])
            [types addObjectsFromArray:p.getQuickActionTypes];
}

+ (void) addCustomPlugin:(OACustomPlugin *)plugin
{
    OAPlugin *oldPlugin = [OAPlugin getPluginById:plugin.getId];
    if (oldPlugin != nil)
        [allPlugins removeObject:oldPlugin];
    
    [allPlugins addObject:plugin];
    [self enablePlugin:plugin enable:YES];
    [self saveCustomPlugins];
}

+ (void) removeCustomPlugin:(OACustomPlugin *)plugin
{
    [allPlugins removeObject:plugin];
    NSFileManager *fileManager = NSFileManager.defaultManager;
    if (plugin.isEnabled)
    {
        [plugin removePluginItems:^{
            [fileManager removeItemAtPath:plugin.getPluginDir error:nil];
        }];
    }
    else
    {
        [fileManager removeItemAtPath:plugin.getPluginDir error:nil];
    }
    [self saveCustomPlugins];
}

+ (void) saveCustomPlugins
{
    NSArray<OACustomPlugin *> *customOsmandPlugins = [self getCustomPlugins];
    OAAppSettings *settings = OAAppSettings.sharedManager;
    NSString *customPlugins = settings.customPluginsJson;
    NSMutableArray<NSDictionary *> *itemsJson = [NSMutableArray array];
    for (OACustomPlugin *plugin in customOsmandPlugins)
    {
        NSMutableDictionary *json = [NSMutableDictionary dictionary];
        json[@"pluginId"] = plugin.getId;
        json[@"version"] = plugin.getVersion;
        [plugin writeAdditionalDataToJson:json];
        [plugin writeDependentFilesJson:json];
        [itemsJson addObject:json];
    }
    NSData *data = [NSJSONSerialization dataWithJSONObject:itemsJson options:0 error:nil];
    NSString *jsonStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (![jsonStr isEqualToString:customPlugins])
        [settings setCustomPluginsJson:jsonStr];
}

+ (NSArray<OACustomPlugin *> *) getCustomPlugins
{
    NSMutableArray<OACustomPlugin *> *lst = [NSMutableArray arrayWithCapacity:allPlugins.count];
    for (OAPlugin *plugin in allPlugins)
    {
        if ([plugin isKindOfClass:OACustomPlugin.class])
            [lst addObject:(OACustomPlugin *)plugin];
    }
    return lst;
}

+ (NSString *) getAbsoulutePluginPathByRegion:(OAWorldRegion *)region
{
    for (OACustomPlugin *plugin in self.getCustomPlugins)
    {
        for (OAWorldRegion *reg in plugin.getDownloadMaps)
        {
            if ([self regionContainsRegion:region toSearch:reg])
                return plugin.getPluginDir;
        }
    }
    return @"";
}

+ (BOOL) regionContainsRegion:(OAWorldRegion *)target toSearch:(OAWorldRegion *)toSearch
{
    if ([target.regionId isEqualToString:toSearch.regionId])
        return YES;
    else
    {
        BOOL match = NO;
        for (OAWorldRegion *reg in toSearch.subregions)
        {
            match = [self regionContainsRegion:target toSearch:reg];
            if (match)
                break;
        }
        return match;
    }
}

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

@end
