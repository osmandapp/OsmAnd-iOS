//
//  OAPlugin.m
//  OsmAnd
//
//  Created by Alexey Kulish on 29/10/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAPlugin.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "Localization.h"
#import "OARootViewController.h"
#import "OAMapHudViewController.h"
#import "OAIAPHelper.h"
#import "OAAutoObserverProxy.h"
#import "OAQuickActionType.h"
#import "OAQuickActionRegistry.h"

#import "OAMonitoringPlugin.h"
#import "OAParkingPositionPlugin.h"
#import "OAOsmEditingPlugin.h"
#import "OAMapillaryPlugin.h"

@implementation OAPlugin
{
    BOOL _active;
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
    if ([productIdentifier isEqualToString:[self.class getId]])
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

+ (NSString *) getId
{
    return nil;
}

- (void) processNames
{
    NSString *pluginId = [self.class getId];
    NSString *postfix = [[pluginId componentsSeparatedByString:@"."] lastObject];
    _titleId = [@"product_title_" stringByAppendingString:postfix];
    _shortDescriptionId = [@"product_desc_" stringByAppendingString:postfix];
    _descriptionId = [@"product_desc_ext_" stringByAppendingString:postfix];
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

- (NSString *) getLogoResourceId
{
    NSString *identifier = [self.class getId];
    OAProduct *product = [[OAIAPHelper sharedInstance] product:identifier];
    if (product)
        return [product productIconName];
    else
        return nil;
}

- (NSString *) getAssetResourceName
{
    NSString *identifier = [self.class getId];
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
 * Initialize plugin runs just after creation
 */
- (BOOL) initPlugin
{
    return YES;
}

- (void) setActive:(BOOL)active
{
    _active = active;
}

- (BOOL) isActive
{
    return _active;
}

- (BOOL) isVisible
{
    return YES;
}

- (void) disable
{
}

- (NSString *) getHelpFileName
{
    return nil;
}

- (NSArray<OAQuickActionType *> *) getQuickActionTypes
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
    OAAppSettings *settings = [OAAppSettings sharedManager];
    NSSet<NSString *> *enabledPlugins = [settings getEnabledPlugins];
    
    [allPlugins addObject:[[OAMapillaryPlugin alloc] init]];
    enabledPlugins = [enabledPlugins setByAddingObject:[OAMapillaryPlugin getId]];
    
    /*
    allPlugins.add(new OsmandRasterMapsPlugin(app));
    allPlugins.add(new OsmandMonitoringPlugin(app));
    checkMarketPlugin(app, new SRTMPlugin(app), true, SRTM_PLUGIN_COMPONENT_PAID, SRTM_PLUGIN_COMPONENT);
    
    checkMarketPlugin(app, new NauticalMapsPlugin(app), false, NauticalMapsPlugin.COMPONENT, null);
    checkMarketPlugin(app, new SkiMapsPlugin(app), false, SkiMapsPlugin.COMPONENT, null);
    
    allPlugins.add(new AudioVideoNotesPlugin(app));

    allPlugins.add(new AccessibilityPlugin(app));
    allPlugins.add(new OsmEditingPlugin(app));
    allPlugins.add(new OsmandDevelopmentPlugin(app));
    */
    
    [allPlugins addObject:[[OAParkingPositionPlugin alloc] init]];
    [allPlugins addObject:[[OAMonitoringPlugin alloc] init]];
    [allPlugins addObject:[[OAOsmEditingPlugin alloc] init]];
    
    [self activatePlugins:enabledPlugins];
}

+ (void) activatePlugins:(NSSet<NSString *> *)enabledPlugins
{
    for (OAPlugin *plugin in allPlugins)
    {
        if ([enabledPlugins containsObject:[plugin.class getId]] || [plugin isActive])
        {
            @try
            {
                if ([plugin initPlugin])
                    [plugin setActive:YES];
            }
            @catch (NSException *e)
            {
                NSLog(@"Plugin initialization failed %@ reason=%@", [plugin.class getId], e.reason);
            }
        }
    }
    [OAQuickActionRegistry.sharedInstance updateActionTypes];
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
            [plugin setActive:NO];
            return NO;
        }
        else
        {
            [plugin setActive:YES];
        }
    }
    else
    {
        [plugin disable];
        [plugin setActive:NO];
    }
    [[OAAppSettings sharedManager] enablePlugin:[plugin.class getId] enable:enable];
    [OAQuickActionRegistry.sharedInstance updateActionTypes];
    [plugin updateLayers];
    return true;
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
        if ([p isActive])
            [list addObject:p];
    }
    return [NSArray arrayWithArray:list];
}

+ (NSArray<OAPlugin *> *) getEnabledVisiblePlugins
{
    NSMutableArray<OAPlugin *> *list = [NSMutableArray arrayWithCapacity:allPlugins.count];
    for (OAPlugin *p in allPlugins)
    {
        if ([p isActive] && [p isVisible])
            [list addObject:p];
    }
    return [NSArray arrayWithArray:list];
}

+ (NSArray<OAPlugin *> *) getNotEnabledPlugins
{
    NSMutableArray<OAPlugin *> *list = [NSMutableArray arrayWithCapacity:allPlugins.count];
    for (OAPlugin *p in allPlugins)
    {
        if (![p isActive])
            [list addObject:p];
    }
    return [NSArray arrayWithArray:list];
}

+ (NSArray<OAPlugin *> *) getNotEnabledVisiblePlugins
{
    NSMutableArray<OAPlugin *> *list = [NSMutableArray arrayWithCapacity:allPlugins.count];
    for (OAPlugin *p in allPlugins)
    {
        if (![p isActive] && [p isVisible])
            [list addObject:p];
    }
    return [NSArray arrayWithArray:list];
}

+ (OAPlugin *) getEnabledPlugin:(Class) cl
{
    for (OAPlugin *p in [self.class getEnabledPlugins])
    {
        if ([p isKindOfClass:cl])
            return p;
    }
    return nil;
}

+ (OAPlugin *) getPlugin:(Class) cl
{
    for (OAPlugin *p in [self.class getAvailablePlugins])
    {
        if ([p isKindOfClass:cl])
            return p;
    }
    return nil;
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
    for (OAPlugin *plugin in [self.class getEnabledPlugins])
    {
        if (![plugin destinationReached])
            b = NO;
    }
    return b;
}

+ (void) createLayers
{
    for (OAPlugin *plugin in [self.class getEnabledPlugins])
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
    for (OAPlugin *p in [self.class getEnabledPlugins])
    {
        [p updateLocation:location];
    }
}

+ (void) registerQuickActionTypesPlugins:(NSMutableArray<OAQuickActionType *> *)types
{
    for (OAPlugin *p in [self.class getEnabledPlugins])
    {
        [types addObjectsFromArray:p.getQuickActionTypes];
    }
}

+ (void) registerAllQuickActionTypesPlugins:(NSMutableArray<OAQuickActionType *> *)types
{
    for (OAPlugin *p in allPlugins)
    {
        [types addObjectsFromArray:p.getQuickActionTypes];
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
