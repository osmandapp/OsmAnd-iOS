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
    return self.getJsonReader;
}

- (OASettingsItemWriter *)getWriter
{
    return self.getJsonWriter;
}

// MARK: OASettingsItemReader

- (BOOL) readFromFile:(NSString *)filePath error:(NSError * _Nullable *)error
{
    // TODO: migrate all settings to a class and use the references for import
    return YES;
}

// MARK: OASettingsItemWriter

- (NSDictionary *) getSettingsJson
{
    NSMutableDictionary *json = [NSMutableDictionary new];
    NSMapTable<NSString *, NSString *> *globalSettings = OAAppSettings.sharedManager.getGlobalSettings;
    for (NSString *key in globalSettings.keyEnumerator)
    {
        NSString *val = [globalSettings objectForKey:key];
        if (key && val)
            json[key] = val;
    }
    return json;
}

@end
