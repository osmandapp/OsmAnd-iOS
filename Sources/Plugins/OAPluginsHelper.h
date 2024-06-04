//
//  OAPluginsHepler.h
//  OsmAnd Maps
//
//  Created by Alexey K on 31.03.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

const static NSString *ONLINE_PLUGINS_URL = @"https://osmand.net/api/plugins/list";
const static NSString *OSMAND_URL = @"https://osmand.net";

@class OAPlugin, OACustomPlugin, OAWorldRegion, OAQuickActionType, OAApplicationMode, OAPOIUIFilter, OAGPXTrackAnalysis, OAPointAttributes, OAWidgetType, OABaseWidgetView, OAOnlinePlugin;

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
+ (OAPlugin * _Nullable) getEnabledPlugin:(Class) cl;
+ (OAPlugin * _Nullable) getPlugin:(Class) cl;
+ (OAPlugin * _Nullable) getPluginById:(NSString *)pluginId;
+ (BOOL) isEnabled:(Class) cl;
+ (BOOL) onDestinationReached;
+ (void) createLayers;
+ (void) updateLocationPlugins:(CLLocation *)location;
+ (void) registerQuickActionTypesPlugins:(NSMutableArray<OAQuickActionType *> *)allTypes enabledTypes:(NSMutableArray<OAQuickActionType *> *)enabledTypes;
+ (void) createMapWidgets:(id<OAWidgetRegistrationDelegate> _Nullable)delegate appMode:(OAApplicationMode *)appMode widgetParams:(NSDictionary * _Nullable)widgetParams;
+ (void) enablePluginsByMapWidgets:(NSSet<NSString *> *)widgetIds;

+ (NSArray<OACustomPlugin *> *) getCustomPlugins;
+ (void) addCustomPlugin:(OACustomPlugin *)plugin;
+ (void) removeCustomPlugin:(OACustomPlugin *)plugin;
+ (NSArray<OAWorldRegion *> *) getCustomDownloadRegions;
+ (NSString *)onGetMapObjectsLocale:(NSObject *)object preferredLocale:(NSString *)preferredLocale;
+ (void)registerCustomPoiFilters:(NSMutableArray<OAPOIUIFilter *> *)poiUIFilters;
+ (void)onPrepareExtraTopPoiFilters:(NSSet<OAPOIUIFilter *> *)poiUIFilters;
+ (NSString *) getAbsoulutePluginPathByRegion:(OAWorldRegion *)region;
+ (OABaseWidgetView * _Nullable)createMapWidget:(OAWidgetType *)widgetType customId:(NSString * _Nullable)customId appMode:(OAApplicationMode *)appMode widgetParams:(NSDictionary * _Nullable)widgetParams;
+ (void)attachAdditionalInfoToRecordedTrack:(CLLocation *)location json:(NSMutableData *)json;
+ (void)analysePoint:(OAGPXTrackAnalysis *)analysis point:(NSObject *)point attribute:(OAPointAttributes *)attribute;
+ (void)getAvailableGPXDataSetTypes:(OAGPXTrackAnalysis *)analysis
                     availableTypes:(NSMutableArray<NSArray<NSNumber *> *> *)availableTypes;
+ (void) fetchOnlinePlugins:(id<OAOnlinePluginsCallback> _Nullable)callback;

@end

NS_ASSUME_NONNULL_END
