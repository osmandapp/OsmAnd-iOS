//
//  OAPlugin.h
//  OsmAnd
//
//  Created by Alexey Kulish on 29/10/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class OAMapPanelViewController, OAMapInfoController, OAMapViewController, OAQuickActionType, OACustomPlugin, OAWorldRegion;

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

- (BOOL) initPlugin;
- (void) setActive:(BOOL)active;
- (BOOL) isActive;
- (BOOL) isVisible;
- (void) disable;
- (NSString *) getHelpFileName;
- (NSArray<OAQuickActionType *> *) getQuickActionTypes;

+ (void) initPlugins;
+ (BOOL) enablePlugin:(OAPlugin *)plugin enable:(BOOL)enable;
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
+ (BOOL) onDestinationReached;
+ (void) createLayers;
+ (void) updateLocationPlugins:(CLLocation *)location;
+ (void) registerQuickActionTypesPlugins:(NSMutableArray<OAQuickActionType *> *)types disabled:(BOOL)disabled;

+ (NSArray<OACustomPlugin *> *) getCustomPlugins;
+ (void) addCustomPlugin:(OACustomPlugin *)plugin;
+ (void) removeCustomPlugin:(OACustomPlugin *)plugin;
+ (NSArray<OAWorldRegion *> *) getCustomDownloadRegions;

+ (NSString *) getAbsoulutePluginPathByRegion:(OAWorldRegion *)region;

- (void) onInstall;
- (void) updateLayers;
- (void) registerLayers;
- (BOOL) destinationReached;
- (void) updateLocation:(CLLocation *)location;


@end
