//
//  OAPluginsHepler.h
//  OsmAnd Maps
//
//  Created by Alexey K on 31.03.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

static NSString * const ONLINE_PLUGINS_URL = @"https://osmand.net/api/plugins/list";
static NSString * const OSMAND_URL = @"https://osmand.net";

@class OAPlugin, OACustomPlugin, OAWorldRegion, QuickActionType, OAApplicationMode, OAPOIUIFilter, OAGPXTrackAnalysis, OAPointAttributes, OAWidgetType, OABaseWidgetView, OAOnlinePlugin;

@protocol OAWidgetRegistrationDelegate;

@protocol OAOnlinePluginsCallback <NSObject>

- (void) onOnlinePluginsFetchComplete:(NSArray<OAOnlinePlugin *> *)plugins;

@end

@interface OAPluginsHelper : NSObject

+ (void) initPlugins;
+ (BOOL) enablePlugin:(OAPlugin *)plugin enable:(BOOL)enable;
+ (BOOL) enablePlugin:(OAPlugin *)plugin enable:(BOOL)enable recreateControls:(BOOL)recreateControls;
+ (void) refreshLayers;
+ (NSArray<OAPlugin *> *) getVisiblePlugins;
+ (NSArray<OAPlugin *> *) getAvailablePlugins;
+ (NSArray<OAPlugin *> *) getEnabledPlugins;
+ (NSArray<OAPlugin *> *) getEnabledVisiblePlugins;
+ (NSArray<OAPlugin *> *) getNotEnabledPlugins;
+ (NSArray<OAPlugin *> *) getNotEnabledVisiblePlugins;
+ (nullable OAPlugin *) getEnabledPlugin:(Class) cl;
+ (nullable OAPlugin *) getPlugin:(Class) cl;
+ (nullable OAPlugin *) getPluginById:(NSString *)pluginId;
+ (BOOL) isEnabled:(Class) cl;
+ (BOOL) onDestinationReached;
+ (void) createLayers;
+ (void) updateLocationPlugins:(CLLocation *)location;
+ (void) registerQuickActionTypesPlugins:(NSMutableArray<QuickActionType *> *)allTypes enabledTypes:(NSMutableArray<QuickActionType *> *)enabledTypes;
+ (void) createMapWidgets:(nullable id<OAWidgetRegistrationDelegate>)delegate appMode:(OAApplicationMode *)appMode widgetParams:(nullable NSDictionary *)widgetParams;
+ (void) enablePluginsByMapWidgets:(NSSet<NSString *> *)widgetIds;

+ (NSArray<OACustomPlugin *> *) getCustomPlugins;
+ (void) addCustomPlugin:(OACustomPlugin *)plugin;
+ (void) removeCustomPlugin:(OACustomPlugin *)plugin;
+ (NSArray<OAWorldRegion *> *) getCustomDownloadRegions;
+ (NSString *)onGetMapObjectsLocale:(NSObject *)object preferredLocale:(NSString *)preferredLocale;
+ (void)registerCustomPoiFilters:(NSMutableArray<OAPOIUIFilter *> *)poiUIFilters;
+ (void)onPrepareExtraTopPoiFilters:(NSSet<OAPOIUIFilter *> *)poiUIFilters;
+ (NSString *) getAbsoulutePluginPathByRegion:(OAWorldRegion *)region;
+ (nullable OABaseWidgetView *)createMapWidget:(OAWidgetType *)widgetType customId:(nullable NSString *)customId appMode:(OAApplicationMode *)appMode widgetParams:(nullable NSDictionary *)widgetParams;
+ (void)attachAdditionalInfoToRecordedTrack:(CLLocation *)location json:(NSMutableData *)json;
+ (void)analysePoint:(OAGPXTrackAnalysis *)analysis point:(NSObject *)point attribute:(OAPointAttributes *)attribute;
+ (void)getAvailableGPXDataSetTypes:(OAGPXTrackAnalysis *)analysis
                     availableTypes:(NSMutableArray<NSArray<NSNumber *> *> *)availableTypes;
+ (void) fetchOnlinePlugins:(nullable id<OAOnlinePluginsCallback>)callback;

@end

NS_ASSUME_NONNULL_END
