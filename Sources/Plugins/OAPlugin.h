//
//  OAPlugin.h
//  OsmAnd
//
//  Created by Alexey Kulish on 29/10/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class OAMapPanelViewController, OAMapInfoController, OAMapViewController, QuickActionType, OAWorldRegion, OAResourceItem, OAApplicationMode, OAPOIUIFilter, OABaseWidgetView, OAWidgetType, OASGpxTrackAnalysis, OAPointAttributes, OACommonPreference, OACommonString, OACommonBoolean;

@protocol OAWidgetRegistrationDelegate;

@protocol OAPluginInstallListener <NSObject>

- (void) onPluginInstall;

@end

@interface OAPlugin : NSObject

- (OAMapPanelViewController *) getMapPanelViewController;
- (OAMapViewController *) getMapViewController;
- (OAMapInfoController *) getMapInfoController;

- (nullable NSString *) getId;
- (NSString *) getDescription;
- (NSString *) getName;
- (nullable NSString *) getLogoResourceId;
- (nullable NSString *) getAssetResourceName;
- (nullable UIImage *) getAssetResourceImage;
- (nullable UIImage *) getLogoResource;

- (nullable UIViewController *) getSettingsController;
- (NSString *) getVersion;

- (NSArray<OAWorldRegion *> *) getDownloadMaps;
- (NSArray<OAResourceItem *> *) getSuggestedMaps;
- (NSArray<OAApplicationMode *> *) getAddedAppModes;
- (NSArray<NSString *> *) getWidgetIds;

- (void) createWidgets:(id<OAWidgetRegistrationDelegate>)delegate appMode:(OAApplicationMode *)appMode widgetParams:(nullable NSDictionary *)widgetParams;
- (nullable OABaseWidgetView *)createMapWidgetForParams:(OAWidgetType *)widgetType customId:(nullable NSString *)customId appMode:(OAApplicationMode *)appMode  widgetParams:(nullable NSDictionary *)widgetParams;

- (NSArray<OACommonPreference *> *)getPreferences;
- (OACommonBoolean *)registerBooleanPreference:(NSString *)prefId defValue:(BOOL)defValue;
- (OACommonString *)registerStringPreference:(NSString *)prefId defValue:(nullable NSString *)defValue;

- (BOOL) initPlugin;
- (void) setEnabled:(BOOL)enabled;
- (BOOL) isEnabled;
- (BOOL) isVisible;
- (BOOL) isEnableByDefault;
- (void) disable;
- (void) install:(nullable id<OAPluginInstallListener>)callback;

- (nullable NSString *) getHelpFileName;
- (NSArray<QuickActionType *> *) getQuickActionTypes;

- (NSString *)getMapObjectsLocale:(NSObject *)object preferredLocale:(NSString *)preferredLocale;
- (NSArray<OAPOIUIFilter *> *)getCustomPoiFilters;
- (void)prepareExtraTopPoiFilters:(NSSet<OAPOIUIFilter *> *)poiUIFilters;
- (void)onAnalysePoint:(OASGpxTrackAnalysis *)analysis point:(NSObject *)point attribute:(OAPointAttributes *)attribute;
- (void)getAvailableGPXDataSetTypes:(OASGpxTrackAnalysis *)analysis
                     availableTypes:(NSMutableArray<NSArray<NSNumber *> *> *)availableTypes;

- (void)attachAdditionalInfoToRecordedTrack:(CLLocation *)location json:(NSMutableData *)json;

- (void) onInstall;
- (void) updateLayers;
- (void) registerLayers;
- (BOOL) destinationReached;
- (void) updateLocation:(CLLocation *)location;
- (void) showInstalledScreen;

@end

NS_ASSUME_NONNULL_END
