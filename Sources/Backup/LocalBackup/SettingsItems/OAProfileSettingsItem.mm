//
//  OAProfileSettingsItem.mm
//  OsmAnd
//
//  Created by Anna Bibyk on 19.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAProfileSettingsItem.h"
#import "OAApplicationMode.h"
#import "OAAppSettings.h"
#import "OsmAndApp.h"
#import "OARendererRegistry.h"
#import "OAMapStyleSettings.h"
#import "OARouteProvider.h"
#import "OARoutingHelper.h"
#import "OAVoiceRouter.h"
#import "OrderedDictionary.h"
#import "OAIndexConstants.h"
#import "OARoutePreferencesParameters.h"
#import "OAMapWidgetRegistry.h"
#import "OAPluginsHelper.h"
#import "OAMapSource.h"
#import "OAAppData.h"
#import "OsmAnd_Maps-Swift.h"

static NSDictionary *platformCompatibilityKeysDictionary = @{
    @"widget_top_panel_order": @"top_widget_panel_order",
    @"widget_bottom_panel_order": @"bottom_widget_panel_order"
};

@implementation OAProfileSettingsItem
{
    NSDictionary *_additionalPrefs;
    NSSet<NSString *> *_appModeBeanPrefsIds;
    OAApplicationModeBuilder *_builder;
}

@dynamic type, name, fileName;

- (instancetype) initWithAppMode:(OAApplicationMode *)appMode
{
    self = [super init];
    if (self) {
        _appMode = appMode;
    }
    return self;
}

- (EOASettingsItemType) type
{
    return EOASettingsItemTypeProfile;
}

- (NSString *) name
{
    return _appMode.stringKey;
}

- (NSString *) getPublicName
{
    if (_appMode.isCustomProfile)
        return _modeBean.userProfileName;
    else if (_appMode.name.length > 0)
        return _appMode.name;
    return self.name;
}

- (NSString *) defaultFileName
{
    return [NSString stringWithFormat:@"profile_%@%@", self.name, self.defaultFileExtension];
}

- (BOOL) exists
{
    return [OAApplicationMode valueOfStringKey:_appMode.stringKey def:nil] != nil;
}

- (void)remove
{
    [super remove];
    [OAApplicationMode deleteCustomModes:@[_appMode]];
}

- (long)localModifiedTime
{
    return [OAAppSettings.sharedManager getLastProfileSettingsModifiedTime:_appMode] * 1000;
}

- (void)setLocalModifiedTime:(long)localModifiedTime
{
    [OAAppSettings.sharedManager setLastProfileModifiedTime:localModifiedTime / 1000 mode:_appMode];
}

- (void)readFromJson:(id)json error:(NSError * _Nullable __autoreleasing *)error
{
    [super readFromJson:json error:error];
    NSDictionary *appModeJson = json[@"appMode"];
    _modeBean = [OAApplicationModeBean fromJson:appModeJson];
    _builder = [OAApplicationMode fromModeBean:_modeBean];
    OAApplicationMode *am = _builder.am;
    if (![am isCustomProfile])
        am = [OAApplicationMode valueOfStringKey:am.stringKey def:am];
    _appMode = am;
}

- (void) readItemsFromJson:(id)json error:(NSError * _Nullable __autoreleasing *)error
{
    _additionalPrefs = json[@"prefs"];
}

- (long)getEstimatedSize
{
    return OAAppSettings.sharedManager.getRegisteredPreferences.count * APPROXIMATE_PREFERENCE_SIZE_BYTES;
}

- (void) applyRendererPreferences:(NSDictionary<NSString *, NSString *> *)prefs
{
    OsmAndAppInstance app = [OsmAndApp instance];
    OAAppData *appData = app.data;
    NSString *renderer = [[OAAppSettings sharedManager].renderer get:_appMode];
    if ([renderer isEqualToString:ONLINE_TILES_DIR])
        return;
    NSDictionary *mapStyleInfo = [OARendererRegistry getMapStyleInfo:renderer];

    OAMapStyleSettings *styleSettings = [[OAMapStyleSettings alloc] initWithStyleName:mapStyleInfo[@"id"]
                                                                        mapPresetName:_appMode.variantKey];
    // if the last map source was offline set it to the selected source
    if ([[appData getLastMapSource:_appMode].resourceId hasSuffix:RENDERER_INDEX_EXT])
    {
        [appData setLastMapSource:[[OAMapSource alloc] initWithResource:[[mapStyleInfo[@"id"] lowercaseString] stringByAppendingString:RENDERER_INDEX_EXT]
                                                             andVariant:_appMode.variantKey
                                                                   name:mapStyleInfo[@"title"]]
                             mode:_appMode];
    }
    [prefs enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        if ([key isEqualToString:@"displayed_transport_settings"])
        {
            [styleSettings setCategoryEnabled:obj.length > 0 categoryName:TRANSPORT_CATEGORY];
            return;
        }
        
        NSString *paramName = [key substringFromIndex:[key lastIndexOf:@"_"] + 1];
        OAMapStyleParameter *param = [styleSettings getParameter:paramName];
        if (param)
        {
            param.value = obj;
            [styleSettings save:param refreshMap:NO];
        }
    }];
}

- (void) applyRoutingPreferences:(NSDictionary<NSString *,NSString *> *)prefs
{
    const auto router = [OsmAndApp.instance getRouter:self.appMode];
    if (router == nullptr)
        return;
    OAAppSettings *settings = OAAppSettings.sharedManager;
    const auto& params = router->getParameters();
    [prefs enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        NSString *paramName = key;
        if ([key hasPrefix:kRoutingPreferencePrefix])
        {
            paramName = [key substringFromIndex:kRoutingPreferencePrefix.length];
        }
        const auto& param = params.find(std::string([paramName UTF8String]));
        if (param != params.end())
        {
            if (param->second.type == RoutingParameterType::BOOLEAN)
            {
                [[settings getCustomRoutingBooleanProperty:paramName defaultValue:param->second.defaultBoolean] set:[obj isEqualToString:@"true"] mode:self.appMode];
            }
            else
            {
                [[settings getCustomRoutingProperty:paramName defaultValue:@(param->second.getDefaultString().c_str())] set:obj mode:self.appMode];
            }
        }
    }];
}

- (void)readPreferenceFromJson:(NSString *)key value:(NSString *)value
{
    OAAppSettings *settings = OAAppSettings.sharedManager;
    if (!_appModeBeanPrefsIds)
        _appModeBeanPrefsIds = [NSSet setWithArray:settings.appModeBeanPrefsIds];
    
    if (![_appModeBeanPrefsIds containsObject:key])
    {
        OsmAndAppInstance app = OsmAndApp.instance;
        OACommonPreference *setting = [settings getPreferenceByKey:key];
        if (setting)
        {
            if ([key isEqualToString:@"voice_provider"])
            {
                [setting setValueFromString:[value stringByReplacingOccurrencesOfString:@"-tts" withString:@""] appMode:_appMode];
                [[OsmAndApp instance] initVoiceCommandPlayer:_appMode warningNoneProvider:NO showDialog:NO force:NO];
            }
            else if (!setting.global)
            {
                [setting setValueFromString:value appMode:_appMode];
                if ([key isEqualToString:@"voice_mute"])
                    [OARoutingHelper.sharedInstance.getVoiceRouter setMute:[OAAppSettings.sharedManager.voiceMute get:_appMode]];
                else if ([key isEqualToString:@"map_info_controls"])
                {
                    NSMutableSet<NSString *> *enabledWidgets = [NSMutableSet set];
                    for (key in [value componentsSeparatedByString:@";"])
                    {
                        if (![key hasPrefix:HIDE_PREFIX])
                        {
                            NSInteger indexOfDelimiter = [key indexOf:OAMapWidgetInfo.DELIMITER];
                            if (indexOfDelimiter > -1)
                                [enabledWidgets addObject:[key substringToIndex:indexOfDelimiter]];
                            else
                                [enabledWidgets addObject:key];
                        }
                    }
                    if (enabledWidgets.count > 0)
                        [OAPluginsHelper enablePluginsByMapWidgets:enabledWidgets];
                }
            }
        }
        else
        {
            __weak __typeof(self) weakSelf = self;
            [app.data setSettingValue:value forKey:key mode:_appMode notHandled:^(NSString *value, NSString *key, OAApplicationMode *mode) {
                [weakSelf configureStringValue:value forKey:key mode:_appMode];
            }];
        }
    }
}

- (void)configureStringValue:(NSString *)strValue
                      forKey:(NSString *)key
                        mode:(OAApplicationMode *)mode
{
    NSString *modeKey = [NSString stringWithFormat:@"%@_%@", key, mode.stringKey];

    if (strValue.length == 0)
    {
        NSLog(@"[WARNING] Empty value for key: %@", modeKey);
        return;
    }
    
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;

    NSString *lowerStr = strValue.lowercaseString;
    
    // === Bool ===
    if ([lowerStr isEqualToString:@"true"]) {
        [defaults setBool:YES forKey:modeKey];
        return;
    }
    if ([lowerStr isEqualToString:@"false"]) {
        [defaults setBool:NO forKey:modeKey];
        return;
    }

    // === Integer ===
    NSInteger intValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:strValue];
    if ([scanner scanInteger:&intValue] && scanner.isAtEnd) {
        [defaults setInteger:intValue forKey:modeKey];
        return;
    }

    // === Double ===
    double doubleValue = 0.0;
    scanner = [NSScanner scannerWithString:strValue];
    if ([scanner scanDouble:&doubleValue] && scanner.isAtEnd) {
        [defaults setDouble:doubleValue forKey:modeKey];
        return;
    }

    // === Nested Array ("a,b;c,d") ===
    if ([strValue containsString:@";"]) {
        NSMutableArray<NSArray<NSString *> *> *nestedArray = [NSMutableArray array];
        for (NSString *subStr in [strValue componentsSeparatedByString:@";"]) {
            if (subStr.length > 0) {
                [nestedArray addObject:[subStr componentsSeparatedByString:@","]];
            }
        }
        [defaults setObject:nestedArray forKey:modeKey];
        return;
    }

    // === Flat Array ("a,b,c") ===
    if ([strValue containsString:@","]) {
        NSArray<NSString *> *array = [strValue componentsSeparatedByString:@","];
        [defaults setObject:array forKey:modeKey];
        return;
    }

    // === Preferences ===
    OACommonPreference *preference = [self findPreferenceForImportedKey:modeKey];
    if (preference && !preference.global)
    {
        if ([preference isKindOfClass:[OACommonUnit class]])
        {
            NSUnit *unit = [NSUnit unitFromString:strValue];
            if (unit)
            {
                NSData *data = [NSKeyedArchiver archivedDataWithRootObject:unit
                                                    requiringSecureCoding:NO
                                                                    error:nil];
                [defaults setObject:data forKey:modeKey];

                [[NSNotificationQueue defaultQueue] enqueueNotification:
                 [NSNotification notificationWithName:kNotificationSetProfileSetting
                                               object:self
                                             userInfo:nil]
                                                           postingStyle:NSPostASAP
                                                           coalesceMask:(NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender)
                                                               forModes:nil];
            }
            else
            {
                NSLog(@"[WARNING] Invalid UNIT for %@", modeKey);
            }
        } else if ([preference isMemberOfClass:[OACommonDownloadMode class]])
        {
            OACommonDownloadMode *commonDownloadMode = (OACommonDownloadMode *)preference;
            if (commonDownloadMode)
            {
                OADownloadMode *value = [commonDownloadMode valueFromString:strValue appMode:mode];
                NSUInteger idx = [commonDownloadMode.values indexOfObject:value];
                [defaults setInteger:(idx != NSNotFound ? idx : 0) forKey:modeKey];
            }
        } else if ([preference isMemberOfClass:[OACommonColoringType class]])
        {
            OACommonColoringType *commonColoringType = (OACommonColoringType *)preference;
            if (commonColoringType)
            {
                OAColoringType *value = [commonColoringType valueFromString:strValue appMode:mode];
                NSUInteger idx = [commonColoringType.values indexOfObject:value];
                [defaults setInteger:(idx != NSNotFound ? idx : 0) forKey:modeKey];
            }
        }
        else if ([preference isMemberOfClass:[OACommonString class]])
        {
            NSNumber *value = [preference valueFromString:strValue appMode:mode];
            if (value)
                [defaults setObject:value.stringValue forKey:modeKey];
            else
                NSLog(@"[WARNING] Invalid value for preference %@", modeKey);
        }
        else if ([preference isMemberOfClass:[OACommonInteger class]])
        {
            NSLog(@"[WARNING] Enum not implemented for %@", modeKey);
        }
        else
        {
            NSNumber *value = [preference valueFromString:strValue appMode:mode];
            if (value)
                [defaults setInteger:value.integerValue forKey:modeKey];
            else
                NSLog(@"[WARNING] Invalid value for preference %@", modeKey);
        }
    }
    else
        NSLog(@"[WARNING] No preference found for %@", modeKey);
}

- (nullable OACommonPreference *)findPreferenceForImportedKey:(NSString *)key {
    NSString *formattedKey = [key componentsSeparatedByString:@"__"].firstObject;
    
    NSMapTable<NSString *, OACommonPreference *> *registered = [OAAppSettings.sharedManager getRegisteredPreferences];
    
    OACommonPreference *pref = [registered objectForKey:formattedKey];
    if (pref)
        return pref;
    
    NSArray *keys = registered.keyEnumerator.allObjects;
    for (NSString *registeredKey in keys)
    {
        if ([formattedKey hasPrefix:registeredKey])
            return [registered objectForKey:registeredKey];
    }
    // NOTE: during import, the CommonWidgetSizeStyle preference may be missing, so we will create a new instance
    if ([key hasPrefix:kSizeStylePref])
        return [OACommonWidgetSizeStyle withKey:kSizeStylePref defValue:EOAWidgetSizeStyleMedium];
    
    return nil;
}

- (void) renameProfile
{
    NSArray<OAApplicationMode *> *values = OAApplicationMode.allPossibleValues;
    if (_modeBean.userProfileName.length == 0)
    {
        OAApplicationMode *appMode = [OAApplicationMode valueOfStringKey:_modeBean.stringKey def:nil];
        if (appMode != nil)
        {
            _modeBean.userProfileName = _appMode.toHumanString;
            _modeBean.parent = _appMode.stringKey;
        }
    }
    int number = 0;
    while (true) {
        number++;
        NSString *key = [NSString stringWithFormat:@"%@_%d", _modeBean.stringKey, number];
        NSString *name = [NSString stringWithFormat:@"%@ %d", _modeBean.userProfileName, number];
        if ([OAApplicationMode valueOfStringKey:key def:nil] == nil && [self isNameUnique:values name:name])
        {
            _modeBean.userProfileName = name;
            _modeBean.stringKey = key;
            break;
        }
    }
}

- (void)apply
{
    @synchronized(self.class)
    {
        if (!_appMode.isCustomProfile && !self.shouldReplace)
        {
            OAApplicationMode *parent = [OAApplicationMode valueOfStringKey:_modeBean.stringKey def:nil];
            [self renameProfile];
            OAApplicationModeBuilder *builder = [OAApplicationMode createCustomMode:parent stringKey:_modeBean.stringKey];
            [builder setIconResName:_modeBean.iconName];
            [builder setUserProfileName:_modeBean.userProfileName];
            [builder setDerivedProfile:_modeBean.derivedProfile];
            [builder setRoutingProfile:_modeBean.routingProfile];
            [builder setRouteService:_modeBean.routeService];
            [builder setIconColor:_modeBean.iconColor];
            [builder setCustomIconColor:_modeBean.customIconColor];
            [builder setLocationIcon:_modeBean.locIcon];
            [builder setNavigationIcon:_modeBean.navIcon];
            [builder setLocationIconSize:_modeBean.locIconSize];
            [builder setCourseIconSize:_modeBean.navIconSize];
            //        app.getSettings().copyPreferencesFromProfile(parent, builder.getApplicationMode());
            _appMode = [OAApplicationMode saveProfile:builder];
        }
        else if (!self.shouldReplace && [self exists])
        {
            [self renameProfile];
            _builder = [OAApplicationMode fromModeBean:_modeBean];
            _appMode = [OAApplicationMode saveProfile:_builder];
        }
        else
        {
            _builder = [OAApplicationMode fromModeBean:_modeBean];
            _appMode = [OAApplicationMode saveProfile:_builder];
        }
        [OAApplicationMode changeProfileAvailability:_appMode isSelected:YES];
    }
}

- (BOOL) isNameUnique:(NSArray<OAApplicationMode *> *)values name:(NSString *) name
{
    for (OAApplicationMode *mode in values)
    {
        if ([mode.getUserProfileName isEqualToString:name])
            return NO;
    }
    return YES;
}

- (void) writeToJson:(id)json
{
    [super writeToJson:json];
    json[@"appMode"] = [_appMode toJson];
}

// Due to different configuration keys in iOS and Android, they need to be standardized. This has been done on our side.
// For internal use, we use the keys 'widget_top_panel_order' from platformCompatibilityKeysDictionary for exporting as @"top_widget_panel_order", etc."
- (BOOL)updateJSONWithPlatformCompatibilityKeys:(NSMutableDictionary *)json
                                   key:(NSString *)key
                                  value:(NSString *)value
{
    NSString *newKey = platformCompatibilityKeysDictionary[key];
    if (newKey)
    {
        json[newKey] = value;
        return YES;
    }
    return NO;
}

- (void)writeItemsToJson:(id)json
{
    OAAppSettings *settings = OAAppSettings.sharedManager;
    NSSet<NSString *> *appModeBeanPrefsIds = [NSSet setWithArray:settings.appModeBeanPrefsIds];
    NSMapTable<NSString *, OACommonPreference *> *prefs = [settings getRegisteredPreferences];
    for (NSString *key in prefs.keyEnumerator)
    {
        if ([appModeBeanPrefsIds containsObject:key])
            continue;
        
        OACommonPreference *setting = [prefs objectForKey:key];
        if (setting && !setting.global && [setting isSetForMode:self.appMode])
        {
            NSString *stringValue = [setting toStringValue:self.appMode];
            if (stringValue)
            {
                if (![self updateJSONWithPlatformCompatibilityKeys:json key:key value:stringValue])
                {
                    if (([key isEqualToString:@"voice_provider"] || [setting.key isEqualToString:@"voice_provider"]) && ![stringValue hasSuffix:@"-tts"])
                    {
                        stringValue = [stringValue stringByAppendingString:@"-tts"];
                    }
                    json[key] = stringValue;
                }
            }
        }
    }
    
    [OsmAndApp.instance.data addPreferenceValuesToDictionary:json mode:self.appMode];
    OAMapStyleSettings *styleSettings = [self getMapStyleSettingsForMode:self.appMode];
    if ([styleSettings isCategoryEnabled:TRANSPORT_CATEGORY])
    {
        NSMutableString *enabledTransport = [NSMutableString new];
        NSArray<OAMapStyleParameter *> *transportParams = [styleSettings getParameters:TRANSPORT_CATEGORY];
        for (OAMapStyleParameter *p in transportParams)
        {
            if ([p.value isEqualToString:@"true"] && ![p.defaultValue isEqualToString:p.value])
            {
                [enabledTransport appendString:[@"nrenderer_" stringByAppendingString:p.name]];
                [enabledTransport appendString:@","];
            }
        }
        if (enabledTransport.length > 0)
        {
            json[@"displayed_transport_settings"] = enabledTransport;
        }
    }
    
    for (OAMapStyleParameter *param in [styleSettings getAllParameters])
    {
        if (param.value.length > 0 && ![param.defaultValue isEqualToString:param.value])
        {
            json[[@"nrenderer_" stringByAppendingString:param.name]] = param.value;
        }
    }
    
    const auto router = [OsmAndApp.instance getRouter:self.appMode];
    if (router)
    {
        const auto& parameters = router->getParametersList();
        for (const auto& p : parameters)
        {
            if (p.type == RoutingParameterType::BOOLEAN)
            {
                OACommonBoolean *boolSetting = [settings getCustomRoutingBooleanProperty:@(p.id.c_str()) defaultValue:p.defaultBoolean];
                
                NSString *paramDefaultString = boolSetting.defValue ? @"true" : @"false";
                NSString *stringValue = [boolSetting toStringValue:self.appMode];
                if (![paramDefaultString isEqualToString:stringValue])
                {
                    json[[kRoutingPreferencePrefix stringByAppendingString:@(p.id.c_str())]] = stringValue;
                }
            }
            else
            {
                NSString *defaultValue = @(p.getDefaultString().c_str());
                OACommonString *stringSetting = [settings getCustomRoutingProperty:@(p.id.c_str()) defaultValue:defaultValue];
                NSString *stringValue = [stringSetting toStringValue:self.appMode];
                if (![stringSetting.defValue isEqualToString:stringValue])
                {
                    json[[kRoutingPreferencePrefix stringByAppendingString:@(p.id.c_str())]] = stringValue;
                }
            }
        }
    }
    
    if ([[OAAppSettings sharedManager].renderer isSetForMode:self.appMode])
    {
        NSString *renderer = [[OAAppSettings sharedManager].renderer get:self.appMode];
        NSDictionary *mapStyleInfo = [OARendererRegistry getMapStyleInfo:renderer];
        json[@"renderer"] = mapStyleInfo[@"title"];
    }
}

- (OAMapStyleSettings *)getMapStyleSettingsForMode:(OAApplicationMode *)mode
{
    NSString *renderer = [OAAppSettings.sharedManager.renderer get:mode];
    NSDictionary *mapStyleInfo = [OARendererRegistry getMapStyleInfo:renderer];
    return [[OAMapStyleSettings alloc] initWithStyleName:mapStyleInfo[@"id"] mapPresetName:mode.variantKey];
}

- (OASettingsItemReader *) getReader
{
    return [[OASettingsItemJsonReader alloc] initWithItem:self];
}

- (OASettingsItemWriter *) getWriter
{
    return [[OASettingsItemJsonWriter alloc] initWithItem:self];
}

@end
