//
//  OAPlugin.h
//  OsmAnd
//
//  Created by Alexey Kulish on 29/10/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class OAMapPanelViewController, OAMapInfoController, OAMapViewController, OAQuickActionType, OACustomPlugin, OAWorldRegion, OAResourceItem, OAApplicationMode, OAPOIUIFilter, OAPOI, OABaseWidgetView, OAWidgetType, OAGPXTrackAnalysis, OAPointAttributes, OACommonPreference, OACommonString;

@protocol OAWidgetRegistrationDelegate;

@protocol OAPluginInstallListener <NSObject>

- (void) onPluginInstall;

@end

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

- (void) createWidgets:(id<OAWidgetRegistrationDelegate>)delegate appMode:(OAApplicationMode *)appMode widgetParams:(NSDictionary *)widgetParams;
- (OABaseWidgetView *)createMapWidgetForParams:(OAWidgetType *)widgetType customId:(NSString *)customId appMode:(OAApplicationMode *)appMode  widgetParams:(NSDictionary *)widgetParams;

- (NSArray<OACommonPreference *> * _Nonnull)getPreferences;
- (OACommonString * _Nonnull)registerStringPreference:(NSString * _Nonnull)prefId defValue:(NSString * _Nullable)defValue;

- (BOOL) initPlugin;
- (void) setEnabled:(BOOL)enabled;
- (BOOL) isEnabled;
- (BOOL) isVisible;
- (BOOL) isEnableByDefault;
- (void) disable;
- (void) install:(id<OAPluginInstallListener> _Nullable)callback;

- (NSString *) getHelpFileName;
- (NSArray<OAQuickActionType *> *) getQuickActionTypes;

- (NSString *)getMapObjectsLocale:(NSObject *)object preferredLocale:(NSString *)preferredLocale;
- (NSArray<OAPOIUIFilter *> *)getCustomPoiFilters;
- (void)prepareExtraTopPoiFilters:(NSSet<OAPOIUIFilter *> *)poiUIFilters;
- (void)onAnalysePoint:(OAGPXTrackAnalysis *)analysis point:(NSObject *)point attribute:(OAPointAttributes *)attribute;
- (void)getAvailableGPXDataSetTypes:(OAGPXTrackAnalysis *)analysis
                     availableTypes:(NSMutableArray<NSArray<NSNumber *> *> *)availableTypes;

- (void)attachAdditionalInfoToRecordedTrack:(CLLocation *)location json:(NSMutableData *)json;

- (void) onInstall;
- (void) updateLayers;
- (void) registerLayers;
- (BOOL) destinationReached;
- (void) updateLocation:(CLLocation *)location;
- (void) showInstalledScreen;

@end
