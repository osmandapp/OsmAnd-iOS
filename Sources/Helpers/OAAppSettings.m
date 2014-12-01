//
//  OADebugSettings.m
//  OsmAnd
//
//  Created by AntonRogachevskiy on 10/16/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAAppSettings.h"

#define settingShowMapRuletKey @"settingShowMapRuletKey"
#define settingMapLanguageKey @"settingMapLanguageKey"
#define settingAppModeKey @"settingAppModeKey"
#define settingMetricSystemKey @"settingMetricSystemKey"
#define settingZoomButtonKey @"settingZoomButtonKey"
#define settingGeoFormatKey @"settingGeoFormatKey"



@implementation OAAppSettings
@synthesize settingShowMapRulet=_settingShowMapRulet, settingMapLanguage=_settingMapLanguage, settingAppMode=_settingAppMode;

+ (OAAppSettings*)sharedManager
{
    static OAAppSettings *_sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[OAAppSettings alloc] init];
    });
    return _sharedManager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.settingShowMapRulet = [[NSUserDefaults standardUserDefaults] objectForKey:settingShowMapRuletKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:settingShowMapRuletKey] : YES;
        self.settingMapLanguage = [[NSUserDefaults standardUserDefaults] objectForKey:settingMapLanguageKey] ? [[NSUserDefaults standardUserDefaults] integerForKey:settingMapLanguageKey] : 0;
        self.settingAppMode = [[NSUserDefaults standardUserDefaults] objectForKey:settingAppModeKey] ? [[NSUserDefaults standardUserDefaults] integerForKey:settingAppModeKey] : 0;

        self.settingMetricSystem = [[NSUserDefaults standardUserDefaults] objectForKey:settingMetricSystemKey] ? [[NSUserDefaults standardUserDefaults] integerForKey:settingMetricSystemKey] : 0;
        self.settingShowZoomButton = [[NSUserDefaults standardUserDefaults] objectForKey:settingZoomButtonKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:settingZoomButtonKey] : YES;
        self.settingGeoFormat = [[NSUserDefaults standardUserDefaults] objectForKey:settingGeoFormatKey] ? [[NSUserDefaults standardUserDefaults] integerForKey:settingGeoFormatKey] : 0;
    
    }
    return self;
}

-(void)setSettingShowMapRulet:(BOOL)settingShowMapRulet {
    _settingShowMapRulet = settingShowMapRulet;
    [[NSUserDefaults standardUserDefaults] setBool:_settingShowMapRulet forKey:settingShowMapRuletKey];
}

-(void)setSettingMapLanguage:(int)settingMapLanguage {
    _settingMapLanguage = settingMapLanguage;
    [[NSUserDefaults standardUserDefaults] setInteger:_settingMapLanguage forKey:settingMapLanguageKey];
}

-(void)setSettingAppMode:(int)settingAppMode {
    _settingAppMode = settingAppMode;
    [[NSUserDefaults standardUserDefaults] setInteger:_settingAppMode forKey:settingAppModeKey];
}

-(void)setSettingMetricSystem:(int)settingMetricSystem {
    _settingMetricSystem = settingMetricSystem;
    [[NSUserDefaults standardUserDefaults] setInteger:_settingMetricSystem forKey:settingMetricSystemKey];
}

-(void)setSettingShowZoomButton:(BOOL)settingShowZoomButton {
    _settingShowZoomButton = settingShowZoomButton;
    [[NSUserDefaults standardUserDefaults] setInteger:_settingShowZoomButton forKey:settingZoomButtonKey];
}

-(void)setSettingGeoFormat:(int)settingGeoFormat {
    _settingGeoFormat = settingGeoFormat;
    [[NSUserDefaults standardUserDefaults] setInteger:_settingGeoFormat forKey:settingGeoFormatKey];
}

@end
