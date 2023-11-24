//
//  OAPlugin.h
//  OsmAnd
//
//  Created by Alexey Kulish on 29/10/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class OAMapPanelViewController, OAMapInfoController, OAMapViewController, OAQuickActionType, OACustomPlugin, OAWorldRegion, OAResourceItem, OAApplicationMode, OAPOIUIFilter, OAPOI, OABaseWidgetView, OAWidgetType;

@protocol OAWidgetRegistrationDelegate;

@interface OAPlugin : NSObject

- (OAMapPanelViewController *) getMapPanelViewController;
- (OAMapViewController *) getMapViewController;
- (OAMapInfoController *) getMapInfoController;

- (NSString *) getId;
- (NSString *) getDescription;
- (NSString *) getName;
- (NSString *) getLogoResourceId;
- (NSString *) getAssetResourceName;
- (UIImage *) getAssetResourceImage;
- (UIImage *) getLogoResource;

- (UIViewController *) getSettingsController;
- (NSString *) getVersion;

- (NSArray<OAWorldRegion *> *) getDownloadMaps;
- (NSArray<OAResourceItem *> *) getSuggestedMaps;
- (NSArray<OAApplicationMode *> *) getAddedAppModes;
- (NSArray<NSString *> *) getWidgetIds;

- (BOOL) initPlugin;
- (void) setEnabled:(BOOL)enabled;
- (BOOL) isEnabled;
- (BOOL) isVisible;
- (BOOL) isEnableByDefault;
- (void) disable;
- (NSString *) getHelpFileName;
- (NSArray<OAQuickActionType *> *) getQuickActionTypes;

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
+ (OAPlugin *) getEnabledPlugin:(Class) cl;
+ (OAPlugin *) getPlugin:(Class) cl;
+ (OAPlugin *) getPluginById:(NSString *)pluginId;
+ (BOOL) isEnabled:(Class) cl;
+ (BOOL) onDestinationReached;
+ (void) createLayers;
+ (void) updateLocationPlugins:(CLLocation *)location;
+ (void) registerQuickActionTypesPlugins:(NSMutableArray<OAQuickActionType *> *)types disabled:(BOOL)disabled;
+ (void) createMapWidgets:(id<OAWidgetRegistrationDelegate>)delegate appMode:(OAApplicationMode *)appMode;
+ (void) enablePluginsByMapWidgets:(NSSet<NSString *> *)widgetIds;

+ (NSArray<OACustomPlugin *> *) getCustomPlugins;
+ (void) addCustomPlugin:(OACustomPlugin *)plugin;
+ (void) removeCustomPlugin:(OACustomPlugin *)plugin;
+ (NSArray<OAWorldRegion *> *) getCustomDownloadRegions;
- (NSString *)getMapObjectsLocale:(NSObject *)object preferredLocale:(NSString *)preferredLocale;
+ (NSString *)onGetMapObjectsLocale:(NSObject *)object preferredLocale:(NSString *)preferredLocale;
- (NSArray<OAPOIUIFilter *> *)getCustomPoiFilters;
+ (void)registerCustomPoiFilters:(NSMutableArray<OAPOIUIFilter *> *)poiUIFilters;
- (void)prepareExtraTopPoiFilters:(NSSet<OAPOIUIFilter *> *)poiUIFilters;
+ (void)onPrepareExtraTopPoiFilters:(NSSet<OAPOIUIFilter *> *)poiUIFilters;

+ (NSString *) getAbsoulutePluginPathByRegion:(OAWorldRegion *)region;
+ (OABaseWidgetView *)createMapWidget:(OAWidgetType *)widgetType customId:(NSString *)customId;
- (void)attachAdditionalInfoToRecordedTrack:(CLLocation *)location json:(NSMutableData *)json;
+ (void)attachAdditionalInfoToRecordedTrack:(CLLocation *)location json:(NSMutableData *)json;

- (void) onInstall;
- (void) updateLayers;
- (void) registerLayers;
- (BOOL) destinationReached;
- (void) updateLocation:(CLLocation *)location;
- (void) showInstalledScreen;

@end
