//
//  OAPlugin.h
//  OsmAnd
//
//  Created by Alexey Kulish on 29/10/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class OAMapPanelViewController, OAMapInfoController, OAMapViewController, OAQuickActionType;

@interface OAPlugin : NSObject

- (OAMapPanelViewController *) getMapPanelViewController;
- (OAMapViewController *) getMapViewController;
- (OAMapInfoController *) getMapInfoController;

+ (NSString *) getId;
- (NSString *) getDescription;
- (NSString *) getName;
- (NSString *) getLogoResourceId;
- (NSString *) getAssetResourceName;

- (UIViewController *) getSettingsController;
- (NSString *) getVersion;

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
+ (BOOL) onDestinationReached;
+ (void) createLayers;
+ (void) updateLocationPlugins:(CLLocation *)location;
+ (void) registerQuickActionTypesPlugins:(NSMutableArray<OAQuickActionType *> *)types;
+ (void) registerAllQuickActionTypesPlugins:(NSMutableArray<OAQuickActionType *> *)types;

- (void) updateLayers;
- (void) registerLayers;
- (BOOL) destinationReached;
- (void) updateLocation:(CLLocation *)location;


@end
