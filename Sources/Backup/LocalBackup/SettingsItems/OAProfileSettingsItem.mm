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
#import "OACustomPlugin.h"
#import "OsmAnd_Maps-Swift.h"

@implementation OAProfileSettingsItem
{
    NSMutableDictionary *_additionalPrefs;
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
    return [OAApplicationMode valueOfStringKey:[self name] def:nil] != nil;
}

- (void)remove
{
    [super remove];
    [OAApplicationMode deleteCustomModes:@[_appMode]];
}

- (long)localModifiedTime
{
    return [OAAppSettings.sharedManager getLastProfileSettingsModifiedTime:_appMode];
}

- (void)setLocalModifiedTime:(long)localModifiedTime
{
    [OAAppSettings.sharedManager setLastProfileModifiedTime:localModifiedTime mode:_appMode];
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
    _additionalPrefs = [NSMutableDictionary dictionaryWithDictionary:json[@"prefs"]];
}

- (long)getEstimatedSize
{
    return OAAppSettings.sharedManager.getRegisteredPreferences.count * APPROXIMATE_PREFERENCE_SIZE_BYTES;
}


//TODO: delete?

- (void) applyRendererPreferences:(NSDictionary<NSString *, NSString *> *)prefs
{
    OsmAndAppInstance app = [OsmAndApp instance];
    OAAppData *appData = app.data;
    NSString *renderer = [[OAAppSettings sharedManager].renderer get:_appMode];
    if ([renderer isEqualToString:@"OsmAnd (online tiles)"])
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

//TODO: delete?

- (void) applyRoutingPreferences:(NSDictionary<NSString *,NSString *> *)prefs
{
    const auto router = [OsmAndApp.instance getRouter:self.appMode];
    if (router == nullptr)
        return;
    OAAppSettings *settings = OAAppSettings.sharedManager;
    const auto& params = router->getParameters();
    [prefs enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        NSString *paramName = [key substringFromIndex:[key lastIndexOf:@"_"] + 1];
        const auto& param = params.find(std::string([paramName UTF8String]));
        if (param != params.end())
        {
            if (param->second.type == RoutingParameterType::BOOLEAN)
            {
                [[settings getCustomRoutingBooleanProperty:paramName defaultValue:param->second.defaultBoolean] set:[obj isEqualToString:@"true"] mode:self.appMode];
            }
            else
            {
                [[settings getCustomRoutingProperty:paramName defaultValue:param->second.type == RoutingParameterType::NUMERIC ? kDefaultNumericValue : kDefaultSymbolicValue] set:obj mode:self.appMode];
            }
        }
    }];
}




// TODO: test new version

- (void) readPreferenceFromJson:(OACommonPreference *)preference json:(NSDictionary<NSString *, NSString *> *)json
{
    if (![_appModeBeanPrefsIds containsObject:preference.key])
    {
        [preference readFromJson:json appMode:_appMode];
    }
}

// TODO: test new version

- (void) readPreferencesFromJson:(NSDictionary<NSString *, NSString *> *)json
{
    OAAppSettings *settings = OAAppSettings.sharedManager;
    
    [json enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        
        OACommonPreference *p = [settings getPreferenceByKey:key];
        if (!p)
        {
            if ([settings isRoutingPreference:key])
                p = [settings registerStringPreference:key defValue:@""];
        }
        if (p)
        {
            [self readPreferenceFromJson:p json:json];
            if ([settings isRoutingPreference:p.key])
            {
                if ([p.key hasSuffix:kRouteParamShortWay])
                {
                    BOOL newNalue = [[settings getCustomRoutingBooleanProperty:kRouteParamShortWay defaultValue:NO] get:_appMode];
                    [settings.fastRouteMode set:!newNalue mode:_appMode];
                }
            }
        }
        else
        {
            NSLog(@"No preference while importing settings: %@", key);
        }
    }];
    
    [settings setLastProfileModifiedTime:[self lastModifiedTime] mode:_appMode];
}




// TODO: delete old version?
/*
- (void)readPreferenceFromJson:(NSString *)key value:(NSString *)value
{
    OsmAndAppInstance app = OsmAndApp.instance;
    OAAppSettings *settings = OAAppSettings.sharedManager;
    if (!_appModeBeanPrefsIds)
        _appModeBeanPrefsIds = [NSSet setWithArray:settings.appModeBeanPrefsIds];
    
    if (![_appModeBeanPrefsIds containsObject:key])
    {
        OACommonPreference *p = [settings getPreferenceByKey:key];
        if (!p)
        {
            if ([settings isRoutingPreference:key])
                p = [settings registerStringPreference:key defValue:@""];
        }
        
        if (p)
        {
            // TODO: copy to new method?
            if ([key isEqualToString:@"voice_provider"])
            {
                [p setValueFromString:[value stringByReplacingOccurrencesOfString:@"-tts" withString:@""] appMode:_appMode];
                [[OsmAndApp instance] initVoiceCommandPlayer:_appMode warningNoneProvider:NO showDialog:NO force:NO];
            }
            else if (!p.global)
            {
                [p setValueFromString:value appMode:_appMode];
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
            [app.data setSettingValue:value forKey:key mode:_appMode];
        }
    }
}
 */

- (void) renameProfile
{
    NSArray<OAApplicationMode *> *values = OAApplicationMode.allPossibleValues;
    if (_modeBean.userProfileName.length == 0)
    {
        OAApplicationMode *appMode = [OAApplicationMode valueOfStringKey:_modeBean.stringKey def:nil];
        if (appMode != nil)
        {
            _modeBean.userProfileName = _appMode.toHumanString;
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
            [builder setRoutingProfile:_modeBean.routingProfile];
            [builder setRouteService:_modeBean.routeService];
            [builder setIconColor:_modeBean.iconColor];
            [builder setLocationIcon:_modeBean.locIcon];
            [builder setNavigationIcon:_modeBean.navIcon];
            
            // TODO: don't exists in android. compare? delete?
            // [builder setDerivedProfile:_modeBean.derivedProfile];
            // [builder setCustomIconColor:_modeBean.customIconColor];
            
            [OAAppSettings.sharedManager copyProfilePreferences:parent modeTo:builder.am];
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

- (void) applyAdditionalParams:(NSString *)filePath reader:(OASettingsItemReader *)reader
{
    if (_additionalPrefs)
    {
        [self updatePluginResPrefs];
        if ([reader isKindOfClass:OAOsmandSettingsJsonReader.class])
        {
            [self readPreferencesFromJson:_additionalPrefs];
        }
    }
}

- (void) updatePluginResPrefs
{
    NSString *pluginId = [self pluginId];
    if ([pluginId isEmpty])
        return;
    
    OAPlugin *plugin = [OAPluginsHelper getPluginById:pluginId];
    if ([plugin isKindOfClass:OACustomPlugin.class])
    {
        OACustomPlugin *customPlugin = (OACustomPlugin *)plugin;
        NSString *resDirPath = [NSString stringWithFormat:@"%@/%@/%@", PLUGINS_DIR, pluginId, [customPlugin resourceDirName]];
        
        for (NSString *prefId in _additionalPrefs.allKeys)
        {
            id value = _additionalPrefs[prefId];
            if ([value isKindOfClass:NSDictionary.class])
            {
                NSDictionary *jsonObject = ((NSDictionary *)value);
                for (NSString *key in jsonObject.allKeys)
                {
                    id val = jsonObject[key];
                    if ([val isKindOfClass:NSString.class])
                    {
                        val = [self checkPluginResPath:((NSString *)val) resDirPath:resDirPath];
                    }
                    _additionalPrefs[key] = val;
                }
            }
            else if ([value isKindOfClass:NSString.class])
            {
                value = [self checkPluginResPath:((NSString *)value) resDirPath:resDirPath];
                _additionalPrefs[prefId] = value;
            }
        }
    }
}

- (NSString *) checkPluginResPath:(NSString *)path resDirPath:(NSString *)resDirPath
{
    if ([path hasPrefix:@"@"])
        return [NSString stringWithFormat:@"%@/%@",resDirPath, [path substringFromIndex:1]];
    
    return path;
}

- (void) writeToJson:(id)json
{
    [super writeToJson:json];
    json[@"appMode"] = [_appMode toJson];
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
        if (setting && !setting.global)
        {
            NSString *stringValue = [setting toStringValue:self.appMode];
            if (stringValue)
            {
                if (([setting.key isEqualToString:@"voice_provider"] || [key isEqualToString:@"voice_provider"]) && ![stringValue hasSuffix:@"-tts"])
                    json[key] = [stringValue stringByAppendingString:@"-tts"];
                else
                    json[key] = stringValue;
            }
        }
    }
    
    [OsmAndApp.instance.data addPreferenceValuesToDictionary:json mode:self.appMode];
    OAMapStyleSettings *styleSettings = [OAMapStyleSettings sharedInstance];
    NSMutableString *enabledTransport = [NSMutableString new];
    if ([styleSettings isCategoryEnabled:TRANSPORT_CATEGORY])
    {
        NSArray<OAMapStyleParameter *> *transportParams = [styleSettings getParameters:TRANSPORT_CATEGORY];
        for (OAMapStyleParameter *p in transportParams)
        {
            if ([p.value isEqualToString:@"true"])
            {
                [enabledTransport appendString:[@"nrenderer_" stringByAppendingString:p.name]];
                [enabledTransport appendString:@","];
            }
        }
    }
    json[@"displayed_transport_settings"] = enabledTransport;
    
    for (OAMapStyleParameter *param in [styleSettings getAllParameters])
    {
        json[[@"nrenderer_" stringByAppendingString:param.name]] = param.value;
    }
    
    const auto router = [OsmAndApp.instance getRouter:self.appMode];
    if (router)
    {
        const auto& parameters = router->getParametersList();
        for (const auto& p : parameters)
        {
            if (p.type == RoutingParameterType::BOOLEAN)
            {
                OACommonBoolean *boolSetting = [settings getCustomRoutingBooleanProperty:[NSString stringWithUTF8String:p.id.c_str()] defaultValue:p.defaultBoolean];
                json[[@"prouting_" stringByAppendingString:[NSString stringWithUTF8String:p.id.c_str()]]] = [boolSetting toStringValue:self.appMode];
            }
            else
            {
                OACommonString *stringSetting = [settings getCustomRoutingProperty:[NSString stringWithUTF8String:p.id.c_str()] defaultValue:p.type == RoutingParameterType::NUMERIC ? kDefaultNumericValue : kDefaultSymbolicValue];
                json[[@"prouting_" stringByAppendingString:[NSString stringWithUTF8String:p.id.c_str()]]] = [stringSetting get:self.appMode];
                
            }
        }
    }
    NSString *renderer = [[OAAppSettings sharedManager].renderer get:_appMode];
    NSDictionary *mapStyleInfo = [OARendererRegistry getMapStyleInfo:renderer];
    json[@"renderer"] = mapStyleInfo[@"title"];
}

- (OASettingsItemReader *) getReader
{
    return [[OAProfileSettingsJsonReader alloc] initWithItem:self];
}

- (OASettingsItemWriter *) getWriter
{
    return [[OAProfileSettingsJsonWriter alloc] initWithItem:self];
}

@end


#pragma mark - OAProfileSettingsJsonReader

@implementation OAProfileSettingsJsonReader

@end

#pragma mark - OAProfileSettingsJsonWriter

@implementation OAProfileSettingsJsonWriter

@end
