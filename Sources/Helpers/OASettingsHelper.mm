//
//  OASettingsHelper.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 25.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OASettingsHelper.h"
#import "OASettingsImporter.h"
#import "OASettingsExporter.h"
#import "OARootViewController.h"
#import "OAIndexConstants.h"
#import "OAPluginSettingsItem.h"
#import "Localization.h"
#import "OAImportSettingsViewController.h"

#define kID_KEY @"id"
#define kTEXT_KEY @"text"
#define kLAT_KEY @"lat"
#define kLON_KEY @"lon"
#define kAUTHOR_KEY @"author"
#define kACTION_KEY @"action"
#define kNAME_KEY @"name"
#define kCOMMENT_KEY @"comment"
#define kTYPE_KEY @"type"
#define kTAGS_KEY @"tags"
#define kENTITY_KEY @"entity"

NSString *const kSettingsHelperErrorDomain = @"SettingsHelper";

NSInteger const kSettingsHelperErrorCodeNoTypeField = 1;
NSInteger const kSettingsHelperErrorCodeIllegalType = 2;
NSInteger const kSettingsHelperErrorCodeUnknownFileSubtype = 3;
NSInteger const kSettingsHelperErrorCodeUnknownFilePath = 4;
NSInteger const kSettingsHelperErrorCodeEmptyJson = 5;

@implementation OASettingsItemType

+ (NSString * _Nullable) typeName:(EOASettingsItemType)type
{
    switch (type)
    {
        case EOASettingsItemTypeGlobal:
            return @"GLOBAL";
        case EOASettingsItemTypeProfile:
            return @"PROFILE";
        case EOASettingsItemTypePlugin:
            return @"PLUGIN";
        case EOASettingsItemTypeData:
            return @"DATA";
        case EOASettingsItemTypeFile:
            return @"FILE";
        case EOASettingsItemTypeQuickActions:
            return @"QUICK_ACTIONS";
        case EOASettingsItemTypePoiUIFilters:
            return @"POI_UI_FILTERS";
        case EOASettingsItemTypeMapSources:
            return @"MAP_SOURCES";
        case EOASettingsItemTypeAvoidRoads:
            return @"AVOID_ROADS";
        case EOASettingsItemTypeOsmNotes:
            return @"OSM_NOTES";
        case EOASettingsItemTypeOsmEdits:
            return @"OSM_EDITS";
        default:
            return nil;
    }
}

+ (EOASettingsItemType) parseType:(NSString *)typeName
{
    if ([typeName isEqualToString:@"GLOBAL"])
        return EOASettingsItemTypeGlobal;
    if ([typeName isEqualToString:@"PROFILE"])
        return EOASettingsItemTypeProfile;
    if ([typeName isEqualToString:@"PLUGIN"])
        return EOASettingsItemTypePlugin;
    if ([typeName isEqualToString:@"DATA"])
        return EOASettingsItemTypeData;
    if ([typeName isEqualToString:@"FILE"])
        return EOASettingsItemTypeFile;
    if ([typeName isEqualToString:@"QUICK_ACTIONS"])
        return EOASettingsItemTypeQuickActions;
    if ([typeName isEqualToString:@"POI_UI_FILTERS"])
        return EOASettingsItemTypePoiUIFilters;
    if ([typeName isEqualToString:@"MAP_SOURCES"])
        return EOASettingsItemTypeMapSources;
    if ([typeName isEqualToString:@"AVOID_ROADS"])
        return EOASettingsItemTypeAvoidRoads;
    if ([typeName isEqualToString:@"OSM_NOTES"])
        return EOASettingsItemTypeOsmNotes;
    if ([typeName isEqualToString:@"OSM_EDITS"])
        return EOASettingsItemTypeOsmEdits;
    
    return EOASettingsItemTypeUnknown;
}

@end

@implementation OAExportSettingsType

+ (NSString * _Nullable) typeName:(EOAExportSettingsType)type
{
    switch (type)
    {
        case EOAExportSettingsTypeProfile:
            return @"PROFILE";
        case EOAExportSettingsTypeQuickActions:
            return @"QUICK_ACTIONS";
        case EOAExportSettingsTypePoiTypes:
            return @"POI_TYPES";
        case EOAExportSettingsTypeMapSources:
            return @"MAP_SOURCES";
        case EOAExportSettingsTypeCustomRendererStyles:
            return @"CUSTOM_RENDER_STYLE";
        case EOAExportSettingsTypeCustomRouting:
            return @"CUSTOM_ROUTING";
        case EOAExportSettingsTypeGPX: // check
            return @"GPX"; // check
        case EOAExportSettingsTypeMapFiles: // check
            return @"MAP_FILE"; // check
        case EOAExportSettingsTypeAvoidRoads:
            return @"AVOID_ROADS";
        case EOAExportSettingsTypeOsmNotes:
            return @"OSM_NOTES";
        case EOAExportSettingsTypeOsmEdits:
            return @"OSM_EDITS";
        default:
            return nil;
    }
}

+ (EOAExportSettingsType) parseType:(NSString *)typeName
{
    if ([typeName isEqualToString:@"PROFILE"])
        return EOAExportSettingsTypeProfile;
    if ([typeName isEqualToString:@"QUICK_ACTIONS"])
        return EOAExportSettingsTypeQuickActions;
    if ([typeName isEqualToString:@"POI_TYPES"])
        return EOAExportSettingsTypePoiTypes;
    if ([typeName isEqualToString:@"MAP_SOURCES"])
        return EOAExportSettingsTypeMapSources;
    if ([typeName isEqualToString:@"CUSTOM_RENDER_STYLE"])
        return EOAExportSettingsTypeCustomRendererStyles;
    if ([typeName isEqualToString:@"CUSTOM_ROUTING"])
        return EOAExportSettingsTypeCustomRouting;
    if ([typeName isEqualToString:@"GPX"]) // check
        return EOAExportSettingsTypeGPX; // check
    if ([typeName isEqualToString:@"MAP_FILE"]) // check
        return EOAExportSettingsTypeMapFiles; // check
    if ([typeName isEqualToString:@"AVOID_ROADS"])
        return EOAExportSettingsTypeAvoidRoads;
    if ([typeName isEqualToString:@"OSM_NOTES"])
        return EOAExportSettingsTypeOsmNotes;
    if ([typeName isEqualToString:@"OSM_EDITS"])
        return EOAExportSettingsTypeOsmEdits;
    return EOAExportSettingsTypeUnknown;
}

@end


@interface OASettingsHelper() <OASettingsImportExportDelegate>

@end

@implementation OASettingsHelper

+ (OASettingsHelper *) sharedInstance
{
    static OASettingsHelper *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[OASettingsHelper alloc] init];
    });
    return _sharedInstance;
}

- (void) collectSettings:(NSString *)settingsFile latestChanges:(NSString *)latestChanges version:(NSInteger)version
{
    [self collectSettings:settingsFile latestChanges:latestChanges version:version delegate:self];
}

- (void) collectSettings:(NSString *)settingsFile latestChanges:(NSString *)latestChanges version:(NSInteger)version delegate:(id<OASettingsImportExportDelegate>)delegate
{
    OAImportAsyncTask *task = [[OAImportAsyncTask alloc] initWithFile:settingsFile latestChanges:latestChanges version:version];
    task.delegate = delegate;
    [task execute];
}
 
- (void) checkDuplicates:(NSString *)settingsFile items:(NSArray<OASettingsItem *> *)items selectedItems:(NSArray<OASettingsItem *> *)selectedItems
{
    [self checkDuplicates:settingsFile items:items selectedItems:selectedItems delegate:self];
}

- (void) checkDuplicates:(NSString *)settingsFile items:(NSArray<OASettingsItem *> *)items selectedItems:(NSArray<OASettingsItem *> *)selectedItems delegate:(id<OASettingsImportExportDelegate>)delegate
{
    OAImportAsyncTask *task = [[OAImportAsyncTask alloc] initWithFile:settingsFile items:items selectedItems:selectedItems];
    task.delegate = delegate;
    [task execute];
}

- (void) importSettings:(NSString *)settingsFile items:(NSArray<OASettingsItem*> *)items latestChanges:(NSString *)latestChanges version:(NSInteger)version
{
    [self importSettings:settingsFile items:items latestChanges:latestChanges version:version delegate:self];
}

- (void) importSettings:(NSString *)settingsFile items:(NSArray<OASettingsItem*> *)items latestChanges:(NSString *)latestChanges version:(NSInteger)version delegate:(id<OASettingsImportExportDelegate>)delegate
{
    OAImportAsyncTask *task = [[OAImportAsyncTask alloc] initWithFile:settingsFile items:items latestChanges:latestChanges version:version];
    task.delegate = delegate;
    [task execute];
}

- (void) exportSettings:(NSString *)fileDir fileName:(NSString *)fileName items:(NSArray<OASettingsItem *> *)items exportItemFiles:(BOOL)exportItemFiles
{
    NSString *file = [fileDir stringByAppendingPathComponent:fileName];
    file = [file stringByAppendingPathExtension:@"osf"];
    OAExportAsyncTask *exportAsyncTask = [[OAExportAsyncTask alloc] initWithFile:file items:items exportItemFiles:exportItemFiles];
    exportAsyncTask.settingsExportDelegate = self;
    [_exportTasks setObject:exportAsyncTask forKey:file];
    [exportAsyncTask execute];
}

- (void) exportSettings:(NSString *)fileDir fileName:(NSString *)fileName settingsItem:(OASettingsItem *)item exportItemFiles:(BOOL)exportItemFiles
{
    [self exportSettings:fileDir fileName:fileName items:@[item] exportItemFiles:exportItemFiles];
}

#pragma mark - OASettingsImportExportDelegate

- (void) onSettingsImportFinished:(BOOL)succeed items:(NSArray<OASettingsItem *> *)items
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:OALocalizedString(OALocalizedString(@"profile_import_success")) preferredStyle:UIAlertControllerStyleAlert];
    [NSFileManager.defaultManager removeItemAtPath:_importTask.getFile error:nil];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleCancel handler:nil]];
    [OARootViewController.instance presentViewController:alert animated:YES completion:nil];
    _importTask = nil;
}

- (void) onSettingsCollectFinished:(BOOL)succeed empty:(BOOL)empty items:(NSArray<OASettingsItem *> *)items
{
    if (succeed)
    {
        NSMutableArray<OASettingsItem *> *pluginIndependentItems = [NSMutableArray new];
        NSMutableArray<OAPluginSettingsItem *> *pluginSettingsItems = [NSMutableArray new];
        for (OASettingsItem *item in items)
        {
            if ([item isKindOfClass:OAPluginSettingsItem.class])
                [pluginSettingsItems addObject:((OAPluginSettingsItem *) item)];
            else if (item.pluginId.length == 0)
                [pluginIndependentItems addObject:item];
        }
//        for (OAPluginSettingsItem *pluginItem in pluginSettingsItems)
//        {
//            handlePluginImport(pluginItem, file);
//        }
        if (pluginIndependentItems.count > 0)
        {
            OAImportSettingsViewController* incomingURLViewController = [[OAImportSettingsViewController alloc] initWithItems:pluginIndependentItems];
            [OARootViewController.instance.navigationController pushViewController:incomingURLViewController animated:YES];
        }
    }
    else if (empty)
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:[NSString stringWithFormat:OALocalizedString(@"err_profile_import"), items.firstObject.name] preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleCancel handler:nil]];
        [OARootViewController.instance presentViewController:alert animated:YES completion:nil];
    }
}

- (void) onSettingsExportFinished:(NSString *)file succeed:(BOOL)succeed
{
    
}

- (void) onDuplicatesChecked:(NSArray<OASettingsItem *>*)duplicates items:(NSArray<OASettingsItem *>*)items
{
    
}

@end
