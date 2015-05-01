//
//  OADebugSettings.h
//  OsmAnd
//
//  Created by AntonRogachevskiy on 10/16/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#define settingShowMapRuletKey @"settingShowMapRuletKey"
#define settingMapLanguageKey @"settingMapLanguageKey"
#define settingAppModeKey @"settingAppModeKey"
#define settingMetricSystemKey @"settingMetricSystemKey"
#define settingZoomButtonKey @"settingZoomButtonKey"
#define settingGeoFormatKey @"settingGeoFormatKey"
#define settingMapArrowsKey @"settingMapArrowsKey"


#define mapSettingShowFavoritesKey @"mapSettingShowFavoritesKey"
#define mapSettingVisibleGpxKey @"mapSettingVisibleGpxKey"

#define mapSettingTrackRecordingKey @"mapSettingTrackRecordingKey"
#define mapSettingTrackRecordingGlobalKey @"mapSettingTrackRecordingGlobalKey"
#define mapSettingSaveTrackIntervalKey @"mapSettingSaveTrackIntervalKey"
#define mapSettingSaveTrackIntervalGlobalKey @"mapSettingSaveTrackIntervalGlobalKey"

#define mapSettingShowRecordingTrackKey @"mapSettingShowRecordingTrackKey"

@interface OAAppSettings : NSObject

+ (OAAppSettings *)sharedManager;
@property (assign, nonatomic) BOOL settingShowMapRulet;
@property (assign, nonatomic) int settingMapLanguage;

#define METRIC_SYSTEM_METERS 0
#define METRIC_SYSTEM_FEET 1
#define METRIC_SYSTEM_YARDS 2

#define APPEARANCE_MODE_DAY 0
#define APPEARANCE_MODE_NIGHT 1
#define APPEARANCE_MODE_AUTO 2

#define MAP_ARROWS_LOCATION 0
#define MAP_ARROWS_MAP_CENTER 1

#define SAVE_TRACK_INTERVAL_DEFAULT 1

@property (assign, nonatomic) int settingAppMode; // 0 - Day; 1 - Night; 2 - Auto
@property (assign, nonatomic) int settingMetricSystem; // 0 - Metric; 1 - English, 2 - 
@property (assign, nonatomic) BOOL settingShowZoomButton;
@property (assign, nonatomic) int settingGeoFormat; // 0 -

@property (assign, nonatomic) int settingMapArrows; // 0 - from Location; 1 - from Map Center
@property (assign, nonatomic) CLLocationCoordinate2D mapCenter;

@property (assign, nonatomic) BOOL mapSettingShowFavorites;
@property (nonatomic) NSArray *mapSettingVisibleGpx;

@property (assign, nonatomic) BOOL mapSettingTrackRecording;
@property (assign, nonatomic) BOOL mapSettingTrackRecordingGlobal;
@property (assign, nonatomic) int mapSettingSaveTrackInterval;
@property (assign, nonatomic) int mapSettingSaveTrackIntervalGlobal;

@property (assign, nonatomic) BOOL mapSettingShowRecordingTrack;

-(void)showGpx:(NSString *)fileName;
-(void)hideGpx:(NSString *)fileName;

@end
