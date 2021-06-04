//
//  OAGlobalSettingsItem.m
//  OsmAnd
//
//  Created by Anna Bibyk on 19.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAGlobalSettingsItem.h"
#import "OAAppSettings.h"
#import "Localization.h"

@implementation OAGlobalSettingsItem

@dynamic type, name, fileName;

- (EOASettingsItemType) type
{
    return EOASettingsItemTypeGlobal;
}

- (NSString *) name
{
    return @"general_settings";
}

- (NSString *) publicName
{
    return OALocalizedString(@"general_settings_2");
}

- (BOOL)exists
{
    return YES;
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
    [OAAppSettings.sharedManager setGlobalPreference:value key:key];
}

// MARK: OASettingsItemWriter

- (NSDictionary *) getSettingsJson
{
    NSMutableDictionary *json = [NSMutableDictionary new];
    NSMapTable<NSString *, OACommonPreference *> *globalPreferences = [OAAppSettings.sharedManager getPreferences:YES];
    for (NSString *key in globalPreferences.keyEnumerator)
    {
        OACommonPreference *setting = [globalPreferences objectForKey:key];
        if (setting.shared)
            json[key] = [setting toStringValue:nil];
    }
    return json;
}

@end

// MARK: OASettingsItemReader

#pragma mark - OAGlobalSettingsItemReader

@implementation OAGlobalSettingsItemReader

- (BOOL) readFromFile:(NSString *)filePath error:(NSError * _Nullable *)error
{
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

    return YES;
}

@end
