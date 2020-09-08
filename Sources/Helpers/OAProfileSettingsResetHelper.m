//
//  OAProfileSettingsResetHelper.m
//  OsmAnd
//
//  Created by nnngrach on 08.09.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAProfileSettingsResetHelper.h"
#import "OsmAndApp.h"
#import "OAMapStyleSettings.h"

#define kResetingAppModeKey @"resettingAppModeKey"

@implementation OAProfileSettingsResetHelper

+ (void) resetProfileSettingsForAppMode:(OAApplicationMode *)appMode
{
    [OAAppSettings.sharedManager resetAllProfileSettingsForMode:appMode];
    [OAAppData.defaults resetProfileSettingsForMode:appMode];
    
    NSDictionary* appModeDict = [NSDictionary dictionaryWithObject:appMode forKey:kResetingAppModeKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:kResetWidgetsSettingsNotification object:nil userInfo:appModeDict];
    
    if ([OAAppSettings sharedManager].applicationMode == appMode)
        [[NSNotificationCenter defaultCenter] postNotificationName:kUpdateWidgestsVisibilityNotification object:nil userInfo:nil];
    
    if (appMode.isCustomProfile)
        [self restoreCustomProfileFromBackup:appMode];
    else
        [OAMapStyleSettings.sharedInstance resetMapStyleForAppMode:appMode.variantKey];
}

+ (void) restoreCustomProfileFromBackup:(OAApplicationMode *)appMode
{
    NSError *err = nil;
    NSDictionary *initialJson = @{
        @"type" : @"PROFILE",
        @"file" : [NSString stringWithFormat:@"profile_%@.json", appMode.stringKey],
        @"appMode" : appMode.toJson
    };
    
    OASettingsItem *item = [[OAProfileSettingsItem alloc] initWithJson:initialJson error:&err];
    OASettingsItemJsonReader *jsonReader = [[OASettingsItemJsonReader alloc] initWithItem:item];
    [OAProfileSettingsResetHelper restoreFromBackup:[NSString stringWithFormat:@"profile_%@", appMode.stringKey] actor:jsonReader];
    [[[OsmAndApp instance] mapSettingsChangeObservable] notifyEvent];
}

+ (void) applyReadedSettings:(NSDictionary<NSString *, NSString *> *)settings actor:(OASettingsItemJsonReader *)actor
{
    NSMutableDictionary<NSString *, NSString *> *rendererSettings = [NSMutableDictionary new];
    NSMutableDictionary<NSString *, NSString *> *routingSettings = [NSMutableDictionary new];

    [settings enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        if ([key hasPrefix:@"nrenderer_"] || [key isEqualToString:@"displayed_transport_settings"])
            [rendererSettings setObject:obj forKey:key];
        else if ([key hasPrefix:@"prouting_"])
            [routingSettings setObject:obj forKey:key];
        else
            [actor.item readPreferenceFromJson:key value:obj];
    }];

    [actor.item applyRendererPreferences:rendererSettings];
    [actor.item applyRoutingPreferences:routingSettings];

    [OsmAndApp.instance.data.mapLayerChangeObservable notifyEvent];
}

+ (void) saveToBackup:(NSDictionary<NSString *, NSString *> *)settings withFilename:(NSString *)filename
{
    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSString *backupFolderPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"osfBackup"];
    
    BOOL isDir = YES;
    if (![fileManager fileExistsAtPath:backupFolderPath isDirectory:&isDir])
          [fileManager createDirectoryAtPath:backupFolderPath withIntermediateDirectories:YES attributes:nil error:nil];
    
    NSString *backupFilename = [filename add:@"_data"];
    NSString *backupFilePath = [[backupFolderPath stringByAppendingPathComponent:backupFilename] stringByAppendingPathExtension:@"plst"];
    [settings writeToFile:backupFilePath atomically:YES];
}

+ (void) restoreFromBackup:(NSString *)filename actor:(OASettingsItemJsonReader *)actor
{
    NSString *backupFilename = [filename add:@"_data"];
    NSString *backupFilePath = [[[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"osfBackup"] stringByAppendingPathComponent:backupFilename] stringByAppendingPathExtension:@"plst"];
    
    NSDictionary<NSString *, NSString *> *restoredSettings = (NSDictionary<NSString *, NSString *> *)[NSDictionary dictionaryWithContentsOfFile:backupFilePath];
    
    if (restoredSettings)
        [self applyReadedSettings:restoredSettings actor:actor];
}

@end
