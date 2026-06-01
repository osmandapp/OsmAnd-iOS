//
//  OAGlobalSettingsItem.m
//  OsmAnd
//
//  Created by Anna Bibyk on 19.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAGlobalSettingsItem.h"
#import "OAAppSettings.h"
#import "OAProducts.h"
#import "OAIAPHelper.h"
#import "OAPlugin.h"
#import "OAApplicationMode.h"
#import "OASettingsHelper.h"
#import "Localization.h"

@implementation OAGlobalSettingsItem

static NSDictionary<NSString *, NSString *> *_pluginIdMapping;

+ (void)initialize
{
    _pluginIdMapping = @{
        @"osmand.monitoring": kInAppId_Addon_TrackRecording,
        @"osmand.mapillary": kInAppId_Addon_Mapillary,
        @"osmand.development": kInAppId_Addon_OsmandDevelopment,
        @"nauticalPlugin.plugin": kInAppId_Addon_Nautical,
        @"osm.editing": kInAppId_Addon_OsmEditing,
        @"osmand.parking.position": kInAppId_Addon_Parking,
        @"skimaps.plugin": kInAppId_Addon_SkiMap,
        @"osmand.srtm.paid": kInAppId_Addon_Srtm,
        @"osmand.wikipedia": kInAppId_Addon_Wiki,
        @"osmand.weather": kInAppId_Addon_Weather,
        @"osmand.sensor": kInAppId_Addon_External_Sensors,
        @"osmand.vehicle.metrics": kInAppId_Addon_Vehicle_Metrics
        //        @"osmand.antplus"
        //        @"osmand.accessibility":
        //        @"osmand.rastermaps"
        //        @"osmand.audionotes":
    };
}

@dynamic type, name, fileName;

- (EOASettingsItemType) type
{
    return EOASettingsItemTypeGlobal;
}

- (NSString *) name
{
    return @"general_settings";
}

- (NSString *)getPublicName
{
    return OALocalizedString(@"general_settings_2");
}

- (BOOL)exists
{
    return YES;
}

- (long)localModifiedTime
{
    return [OAAppSettings.sharedManager getLastGloblalSettingsModifiedTime] * 1000;
}

- (void)setLocalModifiedTime:(long)localModifiedTime
{
    [OAAppSettings.sharedManager setLastGlobalModifiedTime:localModifiedTime / 1000];
}

- (long)getEstimatedSize
{
    NSInteger count = 0;
    NSMapTable<NSString *, OACommonPreference *> *prefs = [OAAppSettings.sharedManager getRegisteredPreferences];
    for (NSString *key in prefs.keyEnumerator)
    {
        OACommonPreference *setting = [prefs objectForKey:key];
        if ([self isExportAvailableForPreference:setting])
            count++;
    }
    return count * APPROXIMATE_PREFERENCE_SIZE_BYTES;
}

- (OASettingsItemReader *)getReader
{
    return [[OAGlobalSettingsItemReader alloc] initWithItem:self];
}

- (OASettingsItemWriter *)getWriter
{
    return self.getJsonWriter;
}

- (NSString *)getAndroidPluginId:(NSString *)iosPluginId
{
    NSString __block *res = @"";
    [_pluginIdMapping enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull _androidPluginId, NSString * _Nonnull _iosPluginId, BOOL * _Nonnull stop) {
        if ([_iosPluginId isEqualToString:iosPluginId])
            res = _androidPluginId;
    }];
    return res;
}

- (NSString *)getIosPluginId:(NSString *)androidPluginId
{
    return _pluginIdMapping[androidPluginId];
}

- (void) readPreferenceFromJson:(NSString *)key value:(NSString *)value
{
    if ([key isEqualToString:@"available_application_modes"])
    {
        NSMutableArray<NSString *> *appModesKeys = [[value componentsSeparatedByString:@","] mutableCopy];
        NSMutableArray<NSString *> *nonexistentAppModesKeys = [NSMutableArray new];
        for (NSString *appModeKey in appModesKeys)
        {
            if ([OAApplicationMode valueOfStringKey:appModeKey def: nil] == nil)
                [nonexistentAppModesKeys addObject:appModeKey];
        }
        if (nonexistentAppModesKeys.count != 0)
            [appModesKeys removeObjectsInArray:nonexistentAppModesKeys];

        value = [[appModesKeys componentsJoinedByString:@","] stringByAppendingString:@","];
    }
    else if ([key isEqualToString:@"enabled_plugins"])
    {
        OACommonPreference *pref = [self preferenceForKey:key];
        if (!pref || !pref.shared)
            return;

        NSArray<NSString *> *enabledPlugins = [[pref toStringValue:nil] componentsSeparatedByString:@","];
        NSArray<NSString *> *androidEnabledPlugins = [value componentsSeparatedByString:@","];
        for (NSString *iosPluginId in enabledPlugins)
        {
            NSString *androidPluginId = [self getAndroidPluginId:iosPluginId];
            if (androidPluginId.length > 0 && ![androidEnabledPlugins containsObject:androidPluginId])
                dispatch_async(dispatch_get_main_queue(), ^{
                    [OAIAPHelper.sharedInstance disableProduct:iosPluginId];
                });
        }
        for (NSString *androidPluginId in androidEnabledPlugins)
        {
            NSString *iosPluginId = [self getIosPluginId:androidPluginId];
            if (iosPluginId.length > 0 && ![enabledPlugins containsObject:iosPluginId])
                dispatch_async(dispatch_get_main_queue(), ^{
                    [OAIAPHelper.sharedInstance enableProduct:iosPluginId];
                });
        }
        return;
    }

    OACommonPreference *setting = [self preferenceForKey:key];
    if (setting && [self isImportAvailableForPreference:setting])
        [setting setValueFromString:value appMode:nil];
}

// Аналог OsmandSettings.isExportAvailableForPref()
- (BOOL)isExportAvailableForPreference:(OACommonPreference *)setting
{
    if ([setting.key isEqualToString:@"application_mode"])
        return YES;
    return setting.global && setting.shared;
}

// Аналог GlobalSettingsItem.readPreferenceFromJson()
- (BOOL)isImportAvailableForPreference:(OACommonPreference *)setting
{
    if ([setting.key isEqualToString:@"application_mode"])
        return YES;
    return setting.global && setting.shared;
}

- (nullable OACommonPreference *)preferenceForKey:(NSString *)key
{
    return [OAAppSettings.sharedManager getPreferenceByKey:key];
}

// MARK: OASettingsItemWriter

- (void)writeItemsToJson:(id)json
{
    NSMapTable<NSString *, OACommonPreference *> *prefs = [OAAppSettings.sharedManager getRegisteredPreferences];
    for (NSString *key in prefs.keyEnumerator)
    {
        OACommonPreference *setting = [prefs objectForKey:key];
        if (![self isExportAvailableForPreference:setting])
                    continue;
        
        if ([key isEqualToString:@"enabled_plugins"])
        {
            NSString *stringValue = [setting toStringValue:nil];
            NSMutableString *correctedValue = [NSMutableString string];
            NSArray<NSString *> *ids = [stringValue componentsSeparatedByString:@","];
            for (NSInteger i = 0; i < ids.count; i++)
            {
                NSString *pluginId = ids[i];
                if (pluginId.length > 0 && ![pluginId hasPrefix:@"-"]) {
                    NSArray<NSString *> *keys = [_pluginIdMapping allKeysForObject:pluginId];
                    if (keys.count > 0)
                    {
                        [correctedValue appendString:keys.firstObject];
                    }
                    if (i < ids.count - 1)
                    {
                        [correctedValue appendString:@","];
                    }
                }
            }
            json[key] = correctedValue;
        }
        else if (setting.global)
        {
            NSString *stringValue = [setting toStringValue:nil];
            if (stringValue)
                json[key] = stringValue;
        }
    }
}

@end

// MARK: OASettingsItemReader

#pragma mark - OAGlobalSettingsItemReader

@implementation OAGlobalSettingsItemReader

- (BOOL) readFromFile:(NSString *)filePath error:(NSError * _Nullable *)error
{
    if (self.item.read)
    {
        if (error)
            *error = [NSError errorWithDomain:kSettingsItemErrorDomain code:kSettingsItemErrorCodeAlreadyRead userInfo:nil];

        return NO;
    }

    NSError *readError;
    NSData *data = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:&readError];
    if (readError)
    {
        if (error)
            *error = readError;

        return NO;
    }
    if (data.length == 0)
    {
        if (error)
            *error = [NSError errorWithDomain:kSettingsHelperErrorDomain code:kSettingsHelperErrorCodeEmptyJson userInfo:nil];

        return NO;
    }

    NSError *jsonError;
    id json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
    if (jsonError)
    {
        if (error)
            *error = jsonError;

        return NO;
    }

    NSDictionary<NSString *, NSString *> *settings = (NSDictionary *) json;

    void (^applySettings)(void) = ^{
        [settings enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
            [self.item readPreferenceFromJson:key value:obj];
        }];
    };
    // Apply prefs on main (Android: GlobalSettingsItem.runInUIThread). Required for preference listeners
    // (SmartFolderHelper / track_filters_settings_pref). Block background until main apply completes.
    if ([NSThread isMainThread]) {
        applySettings();
    } else {
        dispatch_semaphore_t sem = dispatch_semaphore_create(0);
        dispatch_async(dispatch_get_main_queue(), ^{
            applySettings();
            dispatch_semaphore_signal(sem);
        });
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    }
    self.item.read = YES;
    return YES;
}

@end
