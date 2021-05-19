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
#import "OAMapStyleTitles.h"
#import "OAMapStyleSettings.h"
#import "OARouteProvider.h"
#import "OARoutingHelper.h"
#import "OAVoiceRouter.h"
#import "OrderedDictionary.h"

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

- (NSString *) publicName
{
    if (_appMode.isCustomProfile)
        return _appMode.getUserProfileName;
    return _appMode.name;
}

- (NSString *) defaultFileName
{
    return [NSString stringWithFormat:@"profile_%@%@", self.name, self.defaultFileExtension];
}

- (BOOL) exists
{
    return [OAApplicationMode valueOfStringKey:_appMode.stringKey def:nil] != nil;
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

- (void) applyRendererPreferences:(NSDictionary<NSString *, NSString *> *)prefs
{
    NSString *renderer = [OAAppSettings.sharedManager.renderer get:_appMode];
    NSString *resName = [OAProfileSettingsItem getRendererByName:renderer];
    NSString *ext = @".render.xml";
    renderer = OAMapStyleTitles.getMapStyleTitles[resName];
    BOOL isTouringView = [resName hasPrefix:@"Touring"];
    if (!renderer && isTouringView)
        renderer = OAMapStyleTitles.getMapStyleTitles[@"Touring-view_(more-contrast-and-details).render"];
    else if (!renderer && [resName isEqualToString:@"offroad"])
        renderer = OAMapStyleTitles.getMapStyleTitles[@"Offroad by ZLZK"];
    
    if (!renderer)
        return;
    OAMapStyleSettings *styleSettings = [[OAMapStyleSettings alloc] initWithStyleName:resName mapPresetName:_appMode.variantKey];
    OAAppData *data = OsmAndApp.instance.data;
    // if the last map source was offline set it to the selected source
    if ([[data getLastMapSource:_appMode].resourceId hasSuffix:ext])
        [data setLastMapSource:[[OAMapSource alloc] initWithResource:[resName.lowerCase stringByAppendingString:ext] andVariant:_appMode.variantKey name:renderer] mode:_appMode];
    [prefs enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        if ([key isEqualToString:@"displayed_transport_settings"])
        {
            [styleSettings setCategoryEnabled:obj.length > 0 categoryName:@"transport"];
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
                [[settings getCustomRoutingProperty:paramName defaultValue:param->second.type == RoutingParameterType::NUMERIC ? @"0.0" : @"-"] set:obj mode:self.appMode];
            }
        }
    }];
}

+ (NSString *) getRendererByName:(NSString *)rendererName
{
    if ([rendererName isEqualToString:@"OsmAnd"])
        return @"default";
    else if ([rendererName isEqualToString:@"Touring view (contrast and details)"])
        return @"Touring-view_(more-contrast-and-details)";
    else if (![rendererName isEqualToString:@"LightRS"] && ![rendererName isEqualToString:@"UniRS"])
        return [rendererName lowerCase];
    
    return rendererName;
}

+ (NSString *) getRendererStringValue:(NSString *)renderer
{
    if ([renderer hasPrefix:@"Touring"])
        return @"Touring view (contrast and details)";
    else if (OAMapStyleTitles.getMapStyleTitles[renderer])
        return OAMapStyleTitles.getMapStyleTitles[renderer];
    else
        return renderer;
}

- (void)readPreferenceFromJson:(NSString *)key value:(NSString *)value
{
    OAAppSettings *settings = OAAppSettings.sharedManager;
    if (!_appModeBeanPrefsIds)
        _appModeBeanPrefsIds = [NSSet setWithArray:settings.appModeBeanPrefsIds];
    
    if (![_appModeBeanPrefsIds containsObject:key])
    {
        OsmAndAppInstance app = OsmAndApp.instance;
        OACommonPreference *setting = [settings getSettingById:key];
        if (setting)
        {
            if ([key isEqualToString:@"voice_provider"])
            {
                [setting setValueFromString:[value stringByReplacingOccurrencesOfString:@"-tts" withString:@""] appMode:_appMode];
                [[OsmAndApp instance] initVoiceCommandPlayer:_appMode warningNoneProvider:NO showDialog:NO force:NO];
            }
            else
            {
                [setting setValueFromString:value appMode:_appMode];
                if ([key isEqualToString:@"voice_mute"])
                    [OARoutingHelper.sharedInstance.getVoiceRouter setMute:[OAAppSettings.sharedManager.voiceMute get:_appMode]];
            }
        }
        else if ([key isEqualToString:@"terrain_layer"])
        {
            if ([value isEqualToString:@"true"])
            {
                [app.data setTerrainType:[app.data getLastTerrainType:_appMode] mode:_appMode];
            }
            else
            {
                [app.data setLastTerrainType:[app.data getTerrainType:_appMode] mode:_appMode];
                [app.data setLastTerrainType:EOATerrainTypeDisabled mode:_appMode];
            }
        }
        else
        {
            [app.data setSettingValue:value forKey:key mode:_appMode];
        }
    }
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
//        app.getSettings().copyPreferencesFromProfile(parent, builder.getApplicationMode());
//        appMode = ApplicationMode.saveProfile(builder, app);
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

- (BOOL) isNameUnique:(NSArray<OAApplicationMode *> *)values name:(NSString *) name
{
    for (OAApplicationMode *mode in values)
    {
        if ([mode.getUserProfileName isEqualToString:name])
            return NO;
    }
    return YES;
}

//public void applyAdditionalPrefs() {
//    if (additionalPrefsJson != null) {
//        updatePluginResPrefs();
//
//        SettingsItemReader reader = getReader();
//        if (reader instanceof OsmandSettingsItemReader) {
//            ((OsmandSettingsItemReader) reader).readPreferencesFromJson(additionalPrefsJson);
//        }
//    }
//}
//
//private void updatePluginResPrefs() {
//    String pluginId = getPluginId();
//    if (Algorithms.isEmpty(pluginId)) {
//        return;
//    }
//    OsmandPlugin plugin = OsmandPlugin.getPlugin(pluginId);
//    if (plugin instanceof CustomOsmandPlugin) {
//        CustomOsmandPlugin customPlugin = (CustomOsmandPlugin) plugin;
//        String resDirPath = IndexConstants.PLUGINS_DIR + pluginId + "/" + customPlugin.getResourceDirName();
//
//        for (Iterator<String> it = additionalPrefsJson.keys(); it.hasNext(); ) {
//            try {
//                String prefId = it.next();
//                Object value = additionalPrefsJson.get(prefId);
//                if (value instanceof JSONObject) {
//                    JSONObject jsonObject = (JSONObject) value;
//                    for (Iterator<String> iterator = jsonObject.keys(); iterator.hasNext(); ) {
//                        String key = iterator.next();
//                        Object val = jsonObject.get(key);
//                        if (val instanceof String) {
//                            val = checkPluginResPath((String) val, resDirPath);
//                        }
//                        jsonObject.put(key, val);
//                    }
//                } else if (value instanceof String) {
//                    value = checkPluginResPath((String) value, resDirPath);
//                    additionalPrefsJson.put(prefId, value);
//                }
//            } catch (JSONException e) {
//                LOG.error(e);
//            }
//        }
//    }
//}
//
//private String checkPluginResPath(String path, String resDirPath) {
//    if (path.startsWith("@")) {
//        return resDirPath + "/" + path.substring(1);
//    }
//    return path;
//}

- (void) writeToJson:(id)json
{
    [super writeToJson:json];
    json[@"appMode"] = [_appMode toJson];
}

- (NSDictionary *) getSettingsJson
{
    MutableOrderedDictionary *res = [MutableOrderedDictionary new];
    OAAppSettings *settings = OAAppSettings.sharedManager;
    NSSet<NSString *> *appModeBeanPrefsIds = [NSSet setWithArray:settings.appModeBeanPrefsIds];
    for (NSString *key in settings.getRegisteredSettings)
    {
        if ([appModeBeanPrefsIds containsObject:key])
            continue;
        OACommonPreference *setting = [settings.getRegisteredSettings objectForKey:key];
        if (setting)
        {
            if ([setting.key isEqualToString:@"voice_provider"])
                res[key] = [[setting toStringValue:self.appMode] stringByAppendingString:@"-tts"];
            else
                res[key] = [setting toStringValue:self.appMode];
        }
    }
    
    [OsmAndApp.instance.data addPreferenceValuesToDictionary:res mode:self.appMode];
    OAMapStyleSettings *styleSettings = [OAMapStyleSettings sharedInstance];
    NSMutableString *enabledTransport = [NSMutableString new];
    if ([styleSettings isCategoryEnabled:@"transport"])
    {
        NSArray<OAMapStyleParameter *> *transportParams = [styleSettings getParameters:@"transport"];
        for (OAMapStyleParameter *p in transportParams)
        {
            if ([p.value isEqualToString:@"true"])
            {
                [enabledTransport appendString:[@"nrenderer_" stringByAppendingString:p.name]];
                [enabledTransport appendString:@","];
            }
        }
    }
    res[@"displayed_transport_settings"] = enabledTransport;
    
    NSString *renderer = nil;
    for (OAMapStyleParameter *param in [styleSettings getAllParameters])
    {
        if (!renderer)
            renderer = param.mapStyleName;
        res[[@"nrenderer_" stringByAppendingString:param.name]] = param.value;
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
                res[[@"prouting_" stringByAppendingString:[NSString stringWithUTF8String:p.id.c_str()]]] = [boolSetting toStringValue:self.appMode];
            }
            else
            {
                OACommonString *stringSetting = [settings getCustomRoutingProperty:[NSString stringWithUTF8String:p.id.c_str()] defaultValue:p.type == RoutingParameterType::NUMERIC ? @"0.0" : @"-"];
                res[[@"prouting_" stringByAppendingString:[NSString stringWithUTF8String:p.id.c_str()]]] = [stringSetting get:self.appMode];
                
            }
        }
    }
    if (renderer)
    {
        res[@"renderer"] = [OAProfileSettingsItem getRendererStringValue:renderer];
    }
    return res;
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
