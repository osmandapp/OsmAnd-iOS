//
//  OAPluginsHepler.m
//  OsmAnd Maps
//
//  Created by Alexey K on 31.03.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import "OAPluginsHelper.h"
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
#import "OAOsmandDevelopmentPlugin.h"
#import "OAMapillaryPlugin.h"
#import "OASkiMapsPlugin.h"
#import "OANauticalMapsPlugin.h"
#import "OASRTMPlugin.h"
#import "OAWikipediaPlugin.h"
#import "OAPOIUIFilter.h"
#import "OAWeatherPlugin.h"
#import "OAExternalSensorsPlugin.h"
#import "OAAppVersionDependentConstants.h"
#import "OAOnlinePlugin.h"
#import "OsmAnd_Maps-Swift.h"

@implementation OAPluginsHelper

static NSMutableArray<OAPlugin *> *allPlugins;

+ (void) initialize
{
    allPlugins = [NSMutableArray array];
}

+ (BOOL) enablePlugin:(OAPlugin *)plugin enable:(BOOL)enable
{
    return [self enablePlugin:plugin enable:enable recreateControls:YES];
}

+ (BOOL) enablePlugin:(OAPlugin *)plugin enable:(BOOL)enable recreateControls:(BOOL)recreateControls
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
    if (recreateControls)
        [OARootViewController.instance.mapPanel.hudViewController.mapInfoController recreateAllControls];
    [plugin updateLayers];

    return YES;
}

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
    [allPlugins addObject:[[OAMapillaryPlugin alloc] init]];
    [allPlugins addObject:[[OAWeatherPlugin alloc] init]];
    [allPlugins addObject:[[OAExternalSensorsPlugin alloc] init]];
    [allPlugins addObject:[[OAOsmandDevelopmentPlugin alloc] init]];

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

+ (void)registerCustomPoiFilters:(NSMutableArray<OAPOIUIFilter *> *)poiUIFilters
{
    for (OAPlugin *p in [self getAvailablePlugins])
    {
        [poiUIFilters addObjectsFromArray:[p getCustomPoiFilters]];
    }
}

+ (void)onPrepareExtraTopPoiFilters:(NSSet<OAPOIUIFilter *> *)poiUIFilters
{
    for (OAPlugin *plugin in [self getEnabledPlugins])
    {
        [plugin prepareExtraTopPoiFilters:poiUIFilters];
    }
}

+ (void)attachAdditionalInfoToRecordedTrack:(CLLocation *)location json:(NSMutableData *)json
{
    for (OAPlugin *plugin in [self getEnabledPlugins])
    {
        [plugin attachAdditionalInfoToRecordedTrack:location json:json];
    }
}

+ (void) refreshLayers
{
//    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground)
//        return;
    
    for (OAPlugin *plugin in [self.class getAvailablePlugins])
        [plugin updateLayers];
    dispatch_async(dispatch_get_main_queue(), ^{
        [OARootViewController.instance.mapPanel recreateControls];
    });
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

+ (void) createMapWidgets:(id<OAWidgetRegistrationDelegate>)delegate
                  appMode:(OAApplicationMode *)appMode
             widgetParams:(NSDictionary *)widgetParams;
{
    for (OAPlugin *plugin in [self getEnabledPlugins])
    {
        [plugin createWidgets:delegate appMode:appMode widgetParams:widgetParams];
    }
}

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
    OAPlugin *oldPlugin = [self.class getPluginById:plugin.getId];
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

+ (OABaseWidgetView *)createMapWidget:(OAWidgetType *)widgetType
                             customId:(NSString *)customId
                              appMode:(OAApplicationMode *)appMode
                         widgetParams:(NSDictionary *)widgetParams;
{
    for (OAPlugin *plugin in [self getEnabledPlugins])
    {
        OABaseWidgetView *widget = [plugin createMapWidgetForParams:widgetType customId:customId appMode:appMode widgetParams:widgetParams];
        if (widget)
            return widget;
    }
    return nil;
}

+ (void)enablePluginsByMapWidgets:(NSSet<NSString *> *)widgetIds
{
    for (OAPlugin *plugin in allPlugins)
    {
        NSArray<NSString *> *pluginWidgetIds = [plugin getWidgetIds];
        for (NSString *pluginWidgetId in pluginWidgetIds)
        {
            if ([widgetIds containsObject:pluginWidgetId])
            {
                if (![plugin isEnabled])
                {
                    NSString *identifier = [plugin getId];
                    OAProduct *product = [[OAIAPHelper sharedInstance] product:identifier];
                    if ([product isPurchased])
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if ([product disabled])
                                [[OAIAPHelper sharedInstance] enableProduct:product.productIdentifier];
                            else
                                [self.class enablePlugin:plugin enable:YES recreateControls:NO];
                        });
                    }
                }
            }
        }
    }
}

+ (void)analysePoint:(OAGPXTrackAnalysis *)analysis point:(NSObject *)point attribute:(OAPointAttributes *)attribute
{
    for (OAPlugin *plugin in [self getAvailablePlugins])
    {
        [plugin onAnalysePoint:analysis point:point attribute:attribute];
    }
}

+ (void)getAvailableGPXDataSetTypes:(OAGPXTrackAnalysis *)analysis
                     availableTypes:(NSMutableArray<NSArray<NSNumber *> *> *)availableTypes
{
    for (OAPlugin *plugin : [self getAvailablePlugins])
    {
        [plugin getAvailableGPXDataSetTypes:analysis availableTypes:availableTypes];
    }
}

+ (void) fetchOnlinePlugins:(id<OAOnlinePluginsCallback> _Nullable)callback
{
    OsmAndAppInstance app = OsmAndApp.instance;
    NSString *url = [NSString stringWithFormat:@"%@?os=ios&version=%@&nd=%d&ns=%d&lang=%@",
                     ONLINE_PLUGINS_URL, OAAppVersionDependentConstants.getVersion, app.getAppInstalledDays, app.getAppExecCount, app.getLanguageCode];
    NSString *aid = app.getUserIosId;
    if (aid.length > 0)
       url = [url stringByAppendingString:[NSString stringWithFormat:@"&aid=%@", aid]];

    url = [url stringByAppendingString:@"&nightly=true"];
    NSURL *urlObj = [NSURL URLWithString:url];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:urlObj
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:30.0];
    [request setHTTPMethod:@"GET"];
    [request addValue:@"OsmAndiOS" forHTTPHeaderField:@"User-Agent"];
    
    NSURLSessionDataTask *downloadTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {

        if (response)
        {
            @try
            {
                NSMutableArray<OAOnlinePlugin *> *plugins = [NSMutableArray array];
                NSMutableDictionary *map = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                if (map) 
                {
                    NSArray* pluginsArray = map[@"plugins"];
                    for (NSDictionary* pluginJson in pluginsArray)
                        [plugins addObject:[[OAOnlinePlugin alloc] initWithJson:pluginJson]];
                }
                if (callback)
                    [callback onOnlinePluginsFetchComplete:plugins];
            }
            @catch (NSException *e)
            {
                // ignore
            }
        }
    }];

    [downloadTask resume];
}

@end
