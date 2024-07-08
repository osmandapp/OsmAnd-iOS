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
        @"osmand.sensor": kInAppId_Addon_External_Sensors
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
    return [OAAppSettings.sharedManager getLastGloblalSettingsModifiedTime];
}

- (void)setLocalModifiedTime:(long)localModifiedTime
{
    [OAAppSettings.sharedManager setLastGlobalModifiedTime:localModifiedTime];
}

- (long)getEstimatedSize
{
    return OAAppSettings.sharedManager.getGlobalPreferences.count * APPROXIMATE_PREFERENCE_SIZE_BYTES;
}

- (OASettingsItemReader *)getReader
{
    return [[OAGlobalSettingsItemReader alloc] initWithItem:self];
}

- (OASettingsItemWriter *)getWriter
{
    return self.getJsonWriter;
}

- (void) readPreferenceFromJson:(NSString *)key value:(NSString *)value
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
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
    else if ([key isEqualToString:@"enabled_plugins"] && [[OAAppSettings sharedManager] getGlobalPreference:key].shared)
    {
        NSArray<NSString *> *enabledPlugins = [[[settings getGlobalPreference:key] toStringValue:nil] componentsSeparatedByString:@","];
        NSArray<NSString *> *futureEnabledPlugins = [value componentsSeparatedByString:@","];
        for (NSString *pluginId in enabledPlugins)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [OAIAPHelper.sharedInstance disableProduct:pluginId];
            });
        }
        [settings setGlobalPreference:@"" key:key];
        for (NSString *pluginId in futureEnabledPlugins)
        {
            NSString *correctedId = _pluginIdMapping[pluginId];
            if (correctedId)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [OAIAPHelper.sharedInstance enableProduct:correctedId];
                });
            }
        }
        return;
    }

    if ([settings getGlobalPreference:key].shared)
        [settings setGlobalPreference:value key:key];
}

// MARK: OASettingsItemWriter

- (void)writeItemsToJson:(id)json
{
    NSMapTable<NSString *, OACommonPreference *> *globalPreferences = [OAAppSettings.sharedManager getPreferences:YES];
    for (NSString *key in globalPreferences.keyEnumerator)
    {
        OACommonPreference *setting = [globalPreferences objectForKey:key];
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
        else if (setting.shared)
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

    [settings enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        [self.item readPreferenceFromJson:key value:obj];
    }];

    self.item.read = YES;
    return YES;
}

@end
