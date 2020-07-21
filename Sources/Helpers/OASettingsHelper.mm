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
#import "OAResourcesUIHelper.h"
#import "OARootViewController.h"
#import "OAMapStyleSettings.h"

#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "OAQuickActionRegistry.h"
#import "OASQLiteTileSource.h"
#import "OAMapCreatorHelper.h"
#import "OAAvoidSpecificRoads.h"
#import "OAPOIFiltersHelper.h"
#import "OAQuickSearchHelper.h"
#import "OAPOIHelper.h"
#import "OARoutingHelper.h"
#import "OAApplicationMode.h"
#import "Localization.h"
#import "OAQuickAction.h"
#import "OAQuickActionType.h"
#import "OAColors.h"
#import "OAPlugin.h"

#include <OsmAndCore/ArchiveReader.h>
#include <OsmAndCore/ResourcesManager.h>
#include <OsmAndCore/Map/OnlineTileSources.h>

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
    
    return EOASettingsItemTypeUnknown;
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
    OAImportAsyncTask *task = [[OAImportAsyncTask alloc] initWithFile:settingsFile latestChanges:latestChanges version:version];
    task.delegate = self;
    [task execute];
}
 
- (void) checkDuplicates:(NSString *)settingsFile items:(NSArray<OASettingsItem *> *)items selectedItems:(NSArray<OASettingsItem *> *)selectedItems
{
    OAImportAsyncTask *task = [[OAImportAsyncTask alloc] initWithFile:settingsFile items:items selectedItems:selectedItems];
    task.delegate = self;
    [task execute];
}

- (void) importSettings:(NSString *)settingsFile items:(NSArray<OASettingsItem*> *)items latestChanges:(NSString *)latestChanges version:(NSInteger)version
{
    OAImportAsyncTask *task = [[OAImportAsyncTask alloc] initWithFile:settingsFile items:items latestChanges:latestChanges version:version];
    task.delegate = self;
    [task execute];
}

- (void) exportSettings:(NSString *)fileDir fileName:(NSString *)fileName items:(NSArray<OASettingsItem *> *)items exportItemFiles:(BOOL)exportItemFiles
{
    NSString *file = [fileDir stringByAppendingPathComponent:fileName];
    file = [file stringByAppendingPathExtension:@".osf"];
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
            // TODO: add ui dialogs as in Android
//            FragmentManager fragmentManager = activity.getSupportFragmentManager();
//            ImportSettingsFragment.showInstance(fragmentManager, pluginIndependentItems, file);
            [self importSettings:_importTask.getFile items:_importTask.getItems latestChanges:@"" version:1];
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


#pragma mark - OASettingsItem

@interface OASettingsItem()

@property (nonatomic) NSString *pluginId;
@property (nonatomic) NSString *defaultName;
@property (nonatomic) NSString *defaultFileExtension;
@property (nonatomic) NSMutableArray<NSString *> *warnings;

- (void) initialization;
- (void) readFromJson:(id)json error:(NSError * _Nullable *)error;
- (void) writeToJson:(id)json error:(NSError * _Nullable *)error;
- (void) readItemsFromJson:(id)json error:(NSError * _Nullable *)error;
- (void) writeItemsToJson:(id)json error:(NSError * _Nullable *)error;
- (void) readPreferenceFromJson:(NSString *)key value:(NSString *)value;

@end

@implementation OASettingsItem

- (instancetype) init
{
    self = [super init];
    if (self)
        [self initialization];
    
    return self;
}
 
- (instancetype _Nullable) initWithJson:(id)json error:(NSError * _Nullable *)error
{
    self = [super init];
    if (self)
    {
        [self initialization];
        NSError *readError;
        [self readFromJson:json error:&readError];
        if (readError)
        {
            if (error)
                *error = readError;
            return nil;
        }
    }
    return self;
}

- (void) initialization
{
    self.warnings = [NSMutableArray array];
}

- (BOOL) shouldReadOnCollecting
{
    return NO;
}

- (NSString *) defaultFileName
{
    return [self.name stringByAppendingString:self.defaultFileExtension];
}

- (NSString *) defaultFileExtension
{
    return @".json";
}

- (BOOL) applyFileName:(NSString *)fileName
{
    return self.fileName ? [fileName hasSuffix:self.fileName] : NO;
}

- (BOOL) exists
{
    return NO;
}

- (void) apply
{
    // non implemented
}

+ (EOASettingsItemType) parseItemType:(id)json error:(NSError * _Nullable *)error
{
    NSString *typeStr = json[@"type"];
    if (!typeStr)
    {
        *error = [NSError errorWithDomain:kSettingsHelperErrorDomain code:kSettingsHelperErrorCodeNoTypeField userInfo:nil];
        return EOASettingsItemTypeUnknown;
    }
    if ([typeStr isEqualToString:@"QUICK_ACTION"])
        typeStr = @"QUICK_ACTIONS";
    
    EOASettingsItemType type = [OASettingsItemType parseType:typeStr];
    if (type == EOASettingsItemTypeUnknown)
    {
        if (error)
            *error = [NSError errorWithDomain:kSettingsHelperErrorDomain code:kSettingsHelperErrorCodeIllegalType userInfo:nil];
    }
    return type;
}

- (void) readFromJson:(id)json error:(NSError * _Nullable *)error
{
    self.pluginId = json[@"pluginId"];
    if (json[@"name"])
        self.fileName = [NSString stringWithFormat:@"%@%@", json[@"name"], self.defaultFileExtension];
    if (json[@"file"])
        self.fileName = json[@"file"];

    NSError* readError;
    [self readItemsFromJson:json error:&readError];
    if (error && readError)
        *error = readError;
}

- (void) writeToJson:(id)json error:(NSError * _Nullable *)error
{
    json[@"type"] = [OASettingsItemType typeName:self.type];
    if (self.pluginId.length > 0)
        json[@"pluginId"] = self.pluginId;
    
    if ([self getWriter]) {
        if (!self.fileName || self.fileName.length == 0)
            self.fileName = self.defaultFileName;
        
        json[@"file"] = self.fileName;
    }

    NSError *writeError;
    [self writeItemsToJson:json error:&writeError];
    if (error && writeError)
        *error = writeError;
}

- (void) readItemsFromJson:(id)json error:(NSError * _Nullable *)error
{
    // override
}

- (void) writeItemsToJson:(id)json error:(NSError * _Nullable *)error
{
    // override
}

- (void) readPreferenceFromJson:(NSString *)key value:(NSString *)value
{
    // override
}

- (nullable NSString *) toJson:(NSError * _Nullable *)error
{
    id JsonDic = [[NSDictionary alloc] init];
    NSError *writeError;
    [self writeToJson:JsonDic error:&writeError];
    if (writeError)
    {
        if (error)
            *error = writeError;
        return nil;
    }
    NSError *jsonError;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:JsonDic options:NSJSONWritingPrettyPrinted error:&jsonError];
    if (jsonError)
    {
        if (error)
            *error = jsonError;
        return nil;
    }
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

- (OASettingsItemReader *) getJsonReader
{
    return [[OASettingsItemJsonReader alloc] initWithItem:self];
}

- (OASettingsItemWriter *) getJsonWriter
{
    return [[OASettingsItemJsonWriter alloc] initWithItem:self];
}

- (OASettingsItemReader *) getReader
{
    return nil;
}

- (OASettingsItemWriter *) getWriter
{
    return nil;
}

- (NSUInteger) hash
{
    NSInteger result = _type;
    result = 31 * result + (self.name != nil ? [self.name hash] : 0);
    result = 31 * result + (self.fileName != nil ? [self.fileName hash] : 0);
    result = 31 * result + (self.pluginId != nil ? [self.pluginId hash] : 0);
    return result;
}

- (BOOL) isEqual:(id)object
{
    if (self == object)
        return YES;
    if (!object)
        return NO;
    
    if ([object isKindOfClass:self.class])
    {
        OASettingsItem *item = (OASettingsItem *) object;
        return _type == item.type
            && (item.name == self.name || [item.name isEqualToString:self.name])
            && (item.fileName == self.fileName || [item.fileName isEqualToString:self.fileName])
            && (item.pluginId == self.pluginId || [item.pluginId isEqualToString:self.pluginId]);
    }
    return NO;
}

@end

#pragma mark - OASettingsItemReader

@interface OASettingsItemReader<__covariant ObjectType : OASettingsItem *>()

@property (nonatomic) ObjectType item;

@end

@implementation OASettingsItemReader

- (instancetype) initWithItem:(id)item
{
    self = [super init];
    if (self) {
        _item = item;
    }
    return self;
}

- (BOOL) readFromFile:(NSString *)filePath error:(NSError * _Nullable *)error
{
    return NO;
}

@end

#pragma mark - OSSettingsItemWriter

@interface OASettingsItemWriter<__covariant ObjectType : OASettingsItem *>()

@property (nonatomic) ObjectType item;

@end

@implementation OASettingsItemWriter

- (instancetype) initWithItem:(id)item
{
    _item = item;
    return self;
}

- (BOOL) writeToFile:(NSString *)filePath error:(NSError * _Nullable *)error
{
    return NO;
}

@end

#pragma mark - OASettingsItemJsonReader

@implementation OASettingsItemJsonReader

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
    NSDictionary *settings = (NSDictionary *) json;
    for (NSString *key in settings)
    {
        [self.item readPreferenceFromJson:key value:settings[key]];
    }
    
    return YES;
}

@end

#pragma mark - OASettingsItemJsonWriter

@implementation OASettingsItemJsonWriter

- (BOOL) writeToFile:(NSString *)filePath error:(NSError * _Nullable *)error
{
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    NSError *writeItemsError;
    [self.item writeItemsToJson:json error:&writeItemsError];
    if (writeItemsError)
    {
        if (error)
            *error = writeItemsError;
        return NO;
    }
    if (json.count > 0)
    {
        NSError *writeJsonError;
        NSData *data = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:&writeJsonError];
        if (writeJsonError)
        {
            if (error)
                *error = writeJsonError;
            return NO;
        }
        
        NSError *writeError;
        [data writeToFile:filePath options:NSDataWritingAtomic error:&writeError];
        if (writeError)
        {
            if (error)
                *error = writeError;
            return NO;
        }
        
        return YES;
    }
    if (error)
        *error = [NSError errorWithDomain:kSettingsHelperErrorDomain code:kSettingsHelperErrorCodeEmptyJson userInfo:nil];
    
    return NO;
}

@end

#pragma mark - OADataSettingsItemReader

@implementation OADataSettingsItemReader

- (BOOL) readFromFile:(NSString *)filePath error:(NSError * _Nullable *)error
{
    NSError *readError;
    NSData *data = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:&readError];
    if (error && readError)
    {
        *error = readError;
        return NO;
    }
    self.item.data = data;
    return YES;
}

@end

#pragma mark - OADataSettingsItemWriter

@implementation OADataSettingsItemWriter

- (BOOL) writeToFile:(NSString *)filePath error:(NSError * _Nullable *)error
{
    NSError *writeError;
    [self.item.data writeToFile:filePath options:NSDataWritingAtomic error:&writeError];
    if (error && writeError)
    {
        *error = writeError;
        return NO;
    }
    return YES;
}

@end

#pragma mark - OAProfileSettingsItem

@implementation OAProfileSettingsItem
{
    NSDictionary *_additionalPrefs;
    
    NSSet<NSString *> *_appModeBeanPrefsIds;
}

@dynamic type, name, fileName;

- (instancetype)initWithAppMode:(OAApplicationMode *)appMode
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

- (NSString *)defaultFileName
{
    return [NSString stringWithFormat:@"profile_%@%@", self.name, self.defaultFileExtension];
}

- (BOOL)exists
{
    return [OAApplicationMode valueOfStringKey:_appMode.name def:nil] != nil;
}

- (void)readFromJson:(id)json error:(NSError * _Nullable __autoreleasing *)error
{
    [super readFromJson:json error:error];
    NSDictionary *appModeJson = json[@"appMode"];
    _modeBean = [OAApplicationModeBean fromJson:appModeJson];
    
    OAApplicationMode *am = [OAApplicationMode fromModeBean:_modeBean];
    if (![am isCustomProfile])
        am = [OAApplicationMode valueOfStringKey:am.stringKey def:am];
    _appMode = am;
}

- (void)readItemsFromJson:(id)json error:(NSError * _Nullable __autoreleasing *)error
{
    _additionalPrefs = json[@"prefs"];
}

- (void)readPreferenceFromJson:(NSString *)key value:(NSString *)value
{
    OAAppSettings *settings = OAAppSettings.sharedManager;
    if (!_appModeBeanPrefsIds)
        _appModeBeanPrefsIds = [NSSet setWithArray:settings.appModeBeanPrefsIds];
    
    if (![_appModeBeanPrefsIds containsObject:key])
    {
        if ([key hasPrefix:@"nrenderer_"])
        {
            NSString *paramName = [key substringFromIndex:[key lastIndexOf:@"_"] + 1];
            OAMapStyleSettings *styleSettings = [OAMapStyleSettings sharedInstance];
            OAMapStyleParameter *param = [styleSettings getParameter:paramName];
            if (param)
            {
                param.value = value;
                [styleSettings save:param];
            }
        }
        else
        {
            OAProfileSetting *setting = [settings getSettingById:key];
            if (setting)
                [setting setValueFromString:value appMode:_appMode];
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
            _modeBean.userProfileName = _appMode.name;
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
        [self renameProfile];
        OAApplicationMode *am = [OAApplicationMode fromModeBean:_modeBean];
       
//        app.getSettings().copyPreferencesFromProfile(parent, builder.getApplicationMode());
//        appMode = ApplicationMode.saveProfile(builder, app);
        [OAApplicationMode saveProfile:am];
    }
    else if (!self.shouldReplace && [self exists])
    {
        [self renameProfile];
        _appMode = [OAApplicationMode fromModeBean:_modeBean];
        [OAApplicationMode saveProfile:_appMode];
    }
    else
    {
        _appMode = [OAApplicationMode fromModeBean:_modeBean];
        [OAApplicationMode saveProfile:_appMode];
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

- (void)writeToJson:(id)json error:(NSError * _Nullable __autoreleasing *)error
{
    [super writeToJson:json error:error];
    [json addObject:@{@"appMode" : [_appMode toJson]}];
}

- (OASettingsItemReader *)getReader
{
    return [[OASettingsItemJsonReader alloc] initWithItem:self];
}

- (OASettingsItemWriter *)getWriter
{
    return [[OASettingsItemWriter alloc] initWithItem:self];
}

@end

#pragma mark - OAGlobalSettingsItem

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
    return [[OASettingsItemReader alloc] initWithItem:self];
}

- (OASettingsItemWriter *)getWriter
{
    return [[OASettingsItemWriter alloc] initWithItem:self];
}

@end

#pragma mark - OAPluginSettingsItem

@implementation OAPluginSettingsItem
{
    OAPlugin *_plugin;
    NSArray<OASettingsItem *> *_pluginDependentItems;
}

@dynamic type, name, fileName;

- (EOASettingsItemType) type
{
    return EOASettingsItemTypePlugin;
}

- (NSString *) name
{
    return [_plugin.class getId];
}

- (NSString *) publicName
{
    return _plugin.getName;
}

- (BOOL)exists
{
    return [OAPlugin getPlugin:_plugin.class] != nil;
}

- (void)apply
{
    if (self.shouldReplace || ![self exists])
    {
        // TODO: implement custom plugins
//        for (OASettingsItem *item : _pluginDependentItems)
//        {
//            if ([item isKindOfClass:OAFileSettingsItem.class])
//            {
//                OAFileSettingsItem *fileItem = (OAFileSettingsItem *) item;
//                if (fileItem.subtype == EOASettingsItemFileSubtypeRenderingStyle)
//                {
//                    [_plugin addRenderer:fileItem.name];
//                }
//                else if (fileItem.subtype == EOASettingsItemFileSubtypeRoutingConfig)
//                {
//                    [plugin addRouter:fileItem.name];
//                }
//                else if (fileItem.subtype == EOASettingsItemFileSubtypeOther)
//                {
//                    [plugin setResourceDirName:item.fileName];
//                }
//            }
//            else if ([item isKindOfClass:OASuggestedDownloadsItem.class])
//            {
//                [plugin updateSuggestedDownloads:((OASuggestedDownloadsItem *) item).items];
//            }
//            else if ([item isKindOfClass:OADownloadsItem.class])
//            {
//                [plugin updateDownloadItems:((OADownloadsItem *) item).items];
//            }
//        }
//        [OAPlugin addCusomPlugin:_plugin];
    }
}

- (void) readFromJson:(id)json error:(NSError * _Nullable __autoreleasing *)error
{
    [super readFromJson:json error:error];
//    _plugin = [[OAPlugin alloc] initWithJson:json];
//    new CustomOsmandPlugin(app, json);
}

- (void) writeToJson:(id)json error:(NSError * _Nullable __autoreleasing *)error
{
    [super writeToJson:json error:error];
//    _plugin.writeAdditionalDataToJson(json);
}

@end

#pragma mark - OADataSettingsItem

@interface OADataSettingsItem()

@property (nonatomic) NSString *name;

@end

@implementation OADataSettingsItem

@dynamic type, name, fileName;

- (instancetype) initWithName:(NSString *)name
{
    self = [super init];
    if (self)
        self.name = name;

    return self;
}

- (instancetype) initWithData:(NSData *)data name:(NSString *)name
{
    self = [super init];
    if (self)
    {
        self.name = name;
        _data = data;
    }
    return self;
}

- (EOASettingsItemType) type
{
    return EOASettingsItemTypeData;
}

- (NSString *) defaultFileExtension
{
    return @".dat";
}

- (void) readFromJson:(id)json error:(NSError * _Nullable __autoreleasing *)error
{
    NSError *readError;
    [super readFromJson:json error:&readError];
    if (readError)
    {
        if (error)
            *error = readError;
        return;
    }
    self.name = json[@"name"];
    NSString *fileName = self.fileName;
    if (fileName.length > 0)
        self.name = [fileName stringByDeletingPathExtension];
}

- (OASettingsItemReader *) getReader
{
   return [[OADataSettingsItemReader alloc] initWithItem:self];
}

- (OASettingsItemWriter *) getWriter
{
    return [[OADataSettingsItemWriter alloc] initWithItem:self];
}

@end

#pragma mark - OAFileSettingsItemReader

@implementation OAFileSettingsItemReader

- (BOOL) readFromFile:(NSString *)filePath error:(NSError * _Nullable *)error
{
    NSString *destFilePath = self.item.filePath;
    if (![self.item exists] || [self.item shouldReplace])
        destFilePath = self.item.filePath;
    else
        destFilePath = [self.item renameFile:destFilePath];

    NSError *copyError;
    BOOL res = [[NSFileManager defaultManager] copyItemAtPath:filePath toPath:destFilePath error:&copyError];
    if (error && copyError)
        *error = copyError;
    
    return res;
}

@end

#pragma mark - OAFileSettingsItemWriter

@implementation OAFileSettingsItemWriter

- (BOOL) writeToFile:(NSString *)filePath error:(NSError * _Nullable *)error
{
    NSError *copyError;
    [[NSFileManager defaultManager] copyItemAtPath:self.item.fileName toPath:filePath error:&copyError];
    if (error && copyError)
    {
        *error = copyError;
        return NO;
    }
    return YES;
}

@end

#pragma mark - OAFileSettingsItemFileSubtype

@implementation OAFileSettingsItemFileSubtype

+ (NSString *) getSubtypeName:(EOASettingsItemFileSubtype)subtype
{
    switch (subtype)
    {
        case EOASettingsItemFileSubtypeOther:
            return @"other";
        case EOASettingsItemFileSubtypeRoutingConfig:
            return @"routing_config";
        case EOASettingsItemFileSubtypeRenderingStyle:
            return @"rendering_style";
        case EOASettingsItemFileSubtypeObfMap:
            return @"obf_map";
        case EOASettingsItemFileSubtypeTilesMap:
            return @"tiles_map";
        case EOASettingsItemFileSubtypeGpx:
            return @"gpx";
        case EOASettingsItemFileSubtypeVoice:
            return @"voice";
        case EOASettingsItemFileSubtypeTravel:
            return @"travel";
        default:
            return @"";
    }
}

+ (NSString *) getSubtypeFolder:(EOASettingsItemFileSubtype)subtype
{
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    switch (subtype)
    {
        case EOASettingsItemFileSubtypeOther:
        case EOASettingsItemFileSubtypeObfMap:
        case EOASettingsItemFileSubtypeRoutingConfig:
        case EOASettingsItemFileSubtypeRenderingStyle:
        case EOASettingsItemFileSubtypeTravel:
            return documentsPath;
        case EOASettingsItemFileSubtypeTilesMap:
            return [documentsPath stringByAppendingPathComponent:@"Tiles"];
        case EOASettingsItemFileSubtypeGpx:
            return [documentsPath stringByAppendingPathComponent:@"GPX"];
        case EOASettingsItemFileSubtypeVoice:
            return [documentsPath stringByAppendingPathComponent:@"Voice"];
        default:
            return @"";
    }
}

+ (EOASettingsItemFileSubtype) getSubtypeByName:(NSString *)name
{
    for (int i = 0; i < EOASettingsItemFileSubtypesCount; i++)
    {
        NSString *subtypeName = [self.class getSubtypeName:(EOASettingsItemFileSubtype)i];
        if ([subtypeName isEqualToString:name])
            return (EOASettingsItemFileSubtype)i;
    }
    return EOASettingsItemFileSubtypeUnknown;
}

+ (EOASettingsItemFileSubtype) getSubtypeByFileName:(NSString *)fileName
{
    NSString *name = fileName;
    if ([fileName hasPrefix:@"/"]) {
        name = [fileName substringFromIndex:1];
    }
    for (int i = 0; i < EOASettingsItemFileSubtypesCount; i++)
    {
        EOASettingsItemFileSubtype subtype = (EOASettingsItemFileSubtype)i;
        switch (subtype) {
            case EOASettingsItemFileSubtypeUnknown:
            case EOASettingsItemFileSubtypeOther:
                break;
            case EOASettingsItemFileSubtypeObfMap:
            {
                if ([name hasSuffix:@".obf"])
                    return subtype;
                break;
            }
            case EOASettingsItemFileSubtypeGpx:
            {
                if ([name hasSuffix:@".gpx"])
                    return subtype;
                break;
            }
            case EOASettingsItemFileSubtypeVoice:
            {
                if ([name hasSuffix:@"tts.js"])
                    return subtype;
                break;
            }
            case EOASettingsItemFileSubtypeTravel:
            {
                if ([name hasSuffix:@".sqlite"] && [name.lowercaseString containsString:@"travel"])
                    return subtype;
                break;
            }
            case EOASettingsItemFileSubtypeTilesMap:
            {
                if ([name hasSuffix:@"tts.js"])
                    return subtype;
                break;
            }
            case EOASettingsItemFileSubtypeRoutingConfig:
            {
                if ([name hasSuffix:@".xml"] && ![name hasSuffix:@".render.xml"])
                    return subtype;
                break;
            }
            case EOASettingsItemFileSubtypeRenderingStyle:
            {
                if ([name hasSuffix:@".render.xml"])
                    return subtype;
                break;
            }

            default:
            {
                NSString *subtypeFolder = [self.class getSubtypeFolder:subtype];
                if ([name hasPrefix:subtypeFolder])
                    return subtype;
                break;
            }
        }
    }
    return EOASettingsItemFileSubtypeUnknown;
}

@end

#pragma mark - OAFileSettingsItem

@interface OAFileSettingsItem()

@property (nonatomic) NSString *name;
@property (nonatomic) NSString *docPath;
@property (nonatomic) NSString *libPath;

@end

@implementation OAFileSettingsItem

@dynamic name;

- (void) commonInit
{
    _docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    _libPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
    _subtype = EOASettingsItemFileSubtypeUnknown;
}

- (instancetype) initWithFilePath:(NSString *)filePath error:(NSError * _Nullable *)error
{
    self = [super init];
    if (self)
    {
        [self commonInit];
        if ([filePath hasPrefix:_docPath])
        {
            self.name = [filePath stringByReplacingOccurrencesOfString:_docPath withString:@""];
        }
        else if ([filePath hasPrefix:_libPath])
        {
            self.name = [filePath stringByReplacingOccurrencesOfString:_libPath withString:@""];
        }
        else
        {
            if (error)
                *error = [NSError errorWithDomain:kSettingsHelperErrorDomain code:kSettingsHelperErrorCodeUnknownFilePath userInfo:nil];
            return nil;
        }
            
        _filePath = filePath;
        _subtype = [OAFileSettingsItemFileSubtype getSubtypeByFileName:filePath];
        if (self.subtype == EOASettingsItemFileSubtypeUnknown)
        {
            if (error)
                *error = [NSError errorWithDomain:kSettingsHelperErrorDomain code:kSettingsHelperErrorCodeUnknownFileSubtype userInfo:nil];
            return nil;
        }
    }
    return self;
}

- (instancetype _Nullable) initWithJson:(NSDictionary *)json error:(NSError * _Nullable *)error
{
    NSError *initError;
    self = [super initWithJson:json error:&initError];
    if (initError)
    {
        if (error)
            *error = initError;
        return nil;
    }
    if (self)
    {
        [self commonInit];
        if (self.subtype == EOASettingsItemFileSubtypeOther)
        {
            _filePath = [_docPath stringByAppendingString:self.name];
        }
        else if (self.subtype == EOASettingsItemFileSubtypeUnknown)
        {
            if (error)
                *error = [NSError errorWithDomain:kSettingsHelperErrorDomain code:kSettingsHelperErrorCodeUnknownFileSubtype userInfo:nil];
            return nil;
        }
        else
        {
            _filePath = [[OAFileSettingsItemFileSubtype getSubtypeFolder:_subtype] stringByAppendingString:self.name];
        }
    }
    return self;
}

- (EOASettingsItemType) type
{
    return EOASettingsItemTypeFile;
}

- (NSString *) fileName
{
    return self.name;
}

- (BOOL) exists
{
    return [[NSFileManager defaultManager] fileExistsAtPath:_filePath];
}

- (NSString *) renameFile:(NSString*)filePath
{
    int number = 0;
    NSString *path = [filePath stringByDeletingLastPathComponent];
    NSString *fileName = [filePath lastPathComponent];
    NSString *fileExt = [fileName pathExtension];
    NSString *fileTitle = [fileName stringByDeletingPathExtension];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^(.+)(_(\\d+)\\..+)$" options:0 error:nil];
    NSArray<NSTextCheckingResult *> *matches = [regex matchesInString:fileName options:0 range:NSMakeRange(0, fileName.length)];
    if (matches.count == 1 && matches[0].numberOfRanges == 4)
    {
        NSRange numStrRange = [matches[0] rangeAtIndex:3];
        number = [fileName substringWithRange:numStrRange].intValue;
        fileTitle = [fileName substringToIndex:numStrRange.location - 1];
    }
    NSFileManager *fileManager = [NSFileManager defaultManager];
    while (true)
    {
        number++;
        NSString *newFilePath = [NSString stringWithFormat:@"%@_%d.%@", [path stringByAppendingPathComponent:fileTitle], number, fileExt];
        if (![fileManager fileExistsAtPath:newFilePath])
            return newFilePath;
    }
}

- (NSString *) getPluginPath
{
    if (self.pluginId.length > 0)
        return [[_libPath stringByAppendingPathComponent:@"Plugins"] stringByAppendingPathComponent:self.pluginId];
    
    return @"";
}

- (void) readFromJson:(id)json error:(NSError * _Nullable __autoreleasing *)error
{
    NSError *readError;
    [super readFromJson:json error:&readError];
    if (readError)
    {
        if (error)
            *error = readError;
        return;
    }
    self.name = json[@"name"];
    NSString *fileName = self.fileName;
    if (self.subtype == EOASettingsItemFileSubtypeUnknown)
    {
        NSString *subtypeStr = json[@"subtype"];
        if (subtypeStr.length > 0)
            _subtype = [OAFileSettingsItemFileSubtype getSubtypeByName:subtypeStr];
        else if (fileName.length > 0)
            _subtype = [OAFileSettingsItemFileSubtype getSubtypeByFileName:fileName];
    }
    if (fileName.length > 0)
    {
        if (self.subtype == EOASettingsItemFileSubtypeOther)
            self.name = fileName;
        else if (self.subtype != EOASettingsItemFileSubtypeUnknown)
            self.name = [fileName lastPathComponent];
    }
}

- (void) writeToJson:(id)json error:(NSError * _Nullable __autoreleasing *)error
{
    NSError *writeError;
    [super writeToJson:json error:&writeError];
    if (writeError)
    {
        if (error)
            *error = writeError;
        return;
    }
    if (self.subtype != EOASettingsItemFileSubtypeUnknown)
        json[@"subtype"] = [OAFileSettingsItemFileSubtype getSubtypeName:self.subtype];
}

- (OASettingsItemReader *) getReader
{
    return [[OAFileSettingsItemReader alloc] initWithItem:self];
}

- (OASettingsItemWriter *) getWriter
{
    return [[OAFileSettingsItemWriter alloc] initWithItem:self];
}

@end

#pragma mark - OAResourcesSettingsItem

@interface OAResourcesSettingsItem()

@property (nonatomic) NSString *filePath;
@property (nonatomic) NSString *fileName;
@property (nonatomic) EOASettingsItemFileSubtype subtype;

@end

@implementation OAResourcesSettingsItem

@dynamic filePath, fileName, subtype;

- (instancetype _Nullable) initWithJson:(NSDictionary *)json error:(NSError * _Nullable *)error
{
    NSError *initError;
    self = [super initWithJson:json error:&initError];
    if (initError)
    {
        if (error)
            *error = initError;
        return nil;
    }
    if (self)
    {
        self.shouldReplace = YES;
        [self commonInit];
        NSString *fileName = self.fileName;
        if (fileName.length > 0 && ![fileName hasSuffix:@"/"])
            self.fileName = [fileName stringByAppendingString:@"/"];
    }
    return self;
}

- (EOASettingsItemType) type
{
    return EOASettingsItemTypeResources;
}

- (void) readFromJson:(id)json error:(NSError * _Nullable __autoreleasing *)error
{
    self.subtype = EOASettingsItemFileSubtypeOther;
    NSError *readError;
    [super readFromJson:json error:&readError];
    if (readError)
    {
        if (error)
            *error = readError;
        return;
    }
}

- (void) writeToJson:(id)json error:(NSError * _Nullable __autoreleasing *)error
{
    NSError *writeError;
    [super writeToJson:json error:&writeError];
    if (writeError)
    {
        if (error)
            *error = writeError;
        return;
    }
    NSString *fileName = self.fileName;
    if (fileName.length > 0)
    {
        if ([fileName hasSuffix:@"/"])
        {
            fileName = [fileName substringToIndex:fileName.length - 1];
        }
        json[@"file"] = fileName;
    }
}

- (BOOL) applyFileName:(NSString *)fileName
{
    if ([fileName hasSuffix:@"/"])
        return NO;

    NSString *itemFileName = self.fileName;
    if ([itemFileName hasSuffix:@"/"])
    {
        if ([fileName hasPrefix:itemFileName])
        {
            self.filePath = [[self getPluginPath] stringByAppendingString:fileName];
            return YES;
        }
        else
        {
            return NO;
        }
    }
    else
    {
        return [super applyFileName:fileName];
    }
}

- (OASettingsItemWriter *) getWriter
{
    return nil;
}

@end

#pragma mark - OACollectionSettingsItem

@interface OACollectionSettingsItem()

@property (nonatomic) NSMutableArray<id> *items;
@property (nonatomic) NSMutableArray<id> *appliedItems;
@property (nonatomic) NSMutableArray<id> *duplicateItems;
@property (nonatomic) NSMutableArray<id> *existingItems;

@end

@implementation OACollectionSettingsItem

- (void) initialization
{
    [super initialization];
    
    self.items = [NSMutableArray array];
    self.appliedItems = [NSMutableArray array];
    self.duplicateItems = [NSMutableArray array];
}

- (instancetype) initWithItems:(NSArray<id> *) items
{
    self = [super init];
    if (self)
        _items = items.mutableCopy;
    
    return self;
}

- (EOASettingsItemType) type
{
    return EOASettingsItemTypeUnknown;
}

- (NSArray*) processDuplicateItems
{
    if (_items.count > 0)
    {
        for (id item in _items)
            if ([self isDuplicate:item])
                [_duplicateItems addObject:item];
    }
    return _duplicateItems;
}

- (NSArray<id> *) getNewItems
{
    NSMutableArray<id> *res = [NSMutableArray arrayWithArray:_items];
    [res removeObjectsInArray:_duplicateItems];
    return res;
}

- (BOOL) isDuplicate:(id)item
{
    return [self.existingItems containsObject:item];
}

- (id) renameItem:(id)item
{
    return nil;
}

@end

#pragma mark - OAQuickActionsSettingsItem

@interface OAQuickActionsSettingsItem()

@property (nonatomic) NSMutableArray<OAQuickAction *> *items;
@property (nonatomic) NSMutableArray<OAQuickAction *> *appliedItems;
@property (nonatomic) NSMutableArray<NSString *> *warnings;

@end

@implementation OAQuickActionsSettingsItem
{
    OAQuickActionRegistry *_actionsRegistry;
}

@dynamic items, appliedItems, warnings;

- (void) initialization
{
    [super initialization];
    
    _actionsRegistry = [OAQuickActionRegistry sharedInstance];
    self.existingItems = [_actionsRegistry getQuickActions].mutableCopy;
}

- (EOASettingsItemType) type
{
    return EOASettingsItemTypeQuickActions;
}

- (BOOL) isDuplicate:(OAQuickAction *)item
{
    return ![_actionsRegistry isNameUnique:item];
}

- (OAQuickAction *) renameItem:(OAQuickAction *)item
{
    return [_actionsRegistry generateUniqueName:item];
}

- (void) apply
{
    NSArray<OAQuickAction *> *newItems = [self getNewItems];
    if (newItems.count > 0 || self.duplicateItems.count > 0)
    {
        self.appliedItems = [NSMutableArray arrayWithArray:newItems];
        NSMutableArray<OAQuickAction *> *newActions = [NSMutableArray arrayWithArray:self.existingItems];
        if (self.duplicateItems.count > 0)
        {
            if (self.shouldReplace)
            {
                for (OAQuickAction *duplicateItem in self.duplicateItems)
                    for (OAQuickAction *savedAction in self.existingItems)
                        if ([duplicateItem.getName isEqualToString:savedAction.name])
                            [newActions removeObject:savedAction];
            }
            else
            {
                for (OAQuickAction * duplicateItem in self.duplicateItems)
                    [self renameItem:duplicateItem];
            }
            [self.appliedItems addObjectsFromArray:self.duplicateItems];
        }
        [newActions addObjectsFromArray:self.appliedItems];
        [_actionsRegistry updateQuickActions:newActions];
    }
}


- (BOOL) shouldReadOnCollecting
{
    return YES;
}

- (NSString *) name
{
    return @"quick_actions";
}

- (OASettingsItemReader *) getReader
{
    return [self getJsonReader];
}

- (void) readItemsFromJson:(id)json error:(NSError * _Nullable __autoreleasing *)error
{
    NSArray* itemsJson = [json mutableArrayValueForKey:@"items"];
    if (itemsJson.count == 0)
        return;
    
    for (id object in itemsJson)
    {
        NSString *name = object[@"name"];
        NSString *actionType = object[@"actionType"];
        NSString *type = object[@"type"];
        OAQuickAction *quickAction = nil;
        if (actionType)
            quickAction = [_actionsRegistry newActionByStringType:actionType];
        else if (type)
            quickAction = [_actionsRegistry newActionByType:type.integerValue];
        
        if (quickAction)
        {
            NSDictionary *params = object[@"params"];
            if (name.length > 0)
                [quickAction setName:name];
            
            [quickAction setParams:params];
            [self.items addObject:quickAction];
        } else {
            [self.warnings addObject:OALocalizedString(@"settings_item_read_error", self.name)];
        }
    }
}

- (void) writeItemsToJson:(id)json error:(NSError * _Nullable __autoreleasing *)error
{
    NSMutableArray *jsonArray = [NSMutableArray array];
    if (self.items.count > 0)
    {
        for (OAQuickAction *action in self.items)
        {
            NSMutableDictionary *jsonObject = [NSMutableDictionary dictionary];
            jsonObject[@"name"] = [action hasCustomName] ? [action getName] : @"";
            jsonObject[@"actionType"] = action.actionType.stringId;
            jsonObject[@"params"] = [action getParams];
            [jsonArray addObject:jsonObject];
        }
        json[@"items"] = jsonArray;
    }
}

@end


#pragma mark - OAPoiUiFilterSettingsItem

@interface OAPoiUiFilterSettingsItem()

@property (nonatomic) NSMutableArray<OAPOIUIFilter *> *items;
@property (nonatomic) NSMutableArray<OAPOIUIFilter *> *appliedItems;

@end

@implementation OAPoiUiFilterSettingsItem
{
    OAPOIHelper *_helper;
    OAPOIFiltersHelper *_filtersHelper;
}

@dynamic items, appliedItems;

- (void) initialization
{
    [super initialization];

    _helper = [OAPOIHelper sharedInstance];
    _filtersHelper = [OAPOIFiltersHelper sharedInstance];
    self.existingItems = [_filtersHelper getUserDefinedPoiFilters].mutableCopy;
}

- (void) apply
{
    NSArray<OAPOIUIFilter *> *newItems = [self getNewItems];
    if (newItems.count > 0 || self.duplicateItems.count > 0)
    {
        self.appliedItems = [NSMutableArray arrayWithArray:newItems];
        for (OAPOIUIFilter *duplicate in self.duplicateItems)
            [self.appliedItems addObject:self.shouldReplace ? duplicate : [self renameItem:duplicate]];
        
        for (OAPOIUIFilter *filter in self.appliedItems)
            [_filtersHelper createPoiFilter:filter];

        [[OAQuickSearchHelper instance] refreshCustomPoiFilters];
    }
}

- (BOOL) isDuplicate:(OAPOIUIFilter *)item
{
    NSString *savedName = item.name;
    for (OAPOIUIFilter *filter in self.existingItems)
        if ([filter.name isEqualToString:savedName])
            return YES;

    return NO;
}

- (OAPOIUIFilter *) renameItem:(OAPOIUIFilter *)item
{
    int number = 0;
    while (true)
    {
        number++;
        OAPOIUIFilter *renamedItem = [[OAPOIUIFilter alloc] initWithFilter:item name:[NSString stringWithFormat:@"%@_%d", item.name, number] filterId:[NSString stringWithFormat:@"%@_%d", item.filterId, number]];
        if (![self isDuplicate:renamedItem])
            return renamedItem;
    }
}

- (NSString *) name
{
    return @"poi_ui_filters";
}

- (BOOL) shouldReadOnCollecting
{
    return YES;
}

- (OASettingsItemReader *) getReader
{
    return [self getJsonReader];
}

- (void) readItemsFromJson:(id)json error:(NSError * _Nullable __autoreleasing *)error
{
    NSArray* itemsJson = [json mutableArrayValueForKey:@"items"];
    if (itemsJson.count == 0)
        return;
    
    for (id object in itemsJson)
    {
        NSString *name = object[@"name"];
        NSString *filterId = object[@"filterId"];
        NSDictionary<NSString *, NSMutableSet<NSString *> *> *acceptedTypes = object[@"acceptedTypes"];
        NSMapTable<OAPOICategory *, NSMutableSet<NSString *> *> *acceptedTypesDone = [NSMapTable strongToStrongObjectsMapTable];
        for (NSString *key in acceptedTypes.allKeys)
        {
            NSMutableSet<NSString *> *value = acceptedTypes[key];
            OAPOICategory *a = [_helper getPoiCategoryByName:key];
            [acceptedTypesDone setObject:value forKey:a];
        }
        OAPOIUIFilter *filter = [[OAPOIUIFilter alloc] initWithName:name filterId:filterId acceptedTypes:acceptedTypesDone];
        [self.items addObject:filter];
    }
}

- (void) writeItemsToJson:(id)json error:(NSError * _Nullable __autoreleasing *)error
{
    NSMutableArray *jsonArray = [NSMutableArray array];
    if (self.items.count > 0)
    {
        for (OAPOIUIFilter *filter in self.items)
        {
            NSMutableDictionary *jsonObject = [NSMutableDictionary dictionary];
            jsonObject[@"name"] = filter.name;
            jsonObject[@"filterId"] = filter.filterId;
            jsonObject[@"acceptedTypes"] = [filter getAcceptedTypes];
            [jsonArray addObject:jsonObject];
        }
        json[@"items"] = jsonArray;
    }
}

@end

#pragma mark - OAMapSourcesSettingsItem

@interface OAMapSourcesSettingsItem()

@property (nonatomic) NSMutableArray<OALocalResourceItem *> *items;
@property (nonatomic) NSMutableArray<OALocalResourceItem *> *appliedItems;
@property (nonatomic) NSMutableArray<OALocalResourceItem *> *existingItems;

@end

@implementation OAMapSourcesSettingsItem
{
    QHash<QString, std::shared_ptr<const OsmAnd::IOnlineTileSources::Source>> _newSources;
    NSMutableDictionary<NSString *, NSMutableDictionary *> *_newSqliteData;
}

@dynamic items, appliedItems, existingItems;

- (void) initialization
{
    [super initialization];
    
    _newSqliteData = [NSMutableDictionary dictionary];
    
    OsmAndAppInstance app = [OsmAndApp instance];
    for (NSString *filePath in [OAMapCreatorHelper sharedInstance].files.allValues)
    {
        OASqliteDbResourceItem *item = [[OASqliteDbResourceItem alloc] init];
        item.title = [[filePath.lastPathComponent stringByDeletingPathExtension] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
        item.fileName = filePath.lastPathComponent;
        item.path = filePath;
        item.size = [[[NSFileManager defaultManager] attributesOfItemAtPath:item.path error:nil] fileSize];
        [self.existingItems addObject:item];
    }
    const auto& resource = app.resourcesManager->getResource(QStringLiteral("online_tiles"));
    if (resource != nullptr)
    {
        const auto& onlineTileSources = std::static_pointer_cast<const OsmAnd::ResourcesManager::OnlineTileSourcesMetadata>(resource->metadata)->sources;
        for(const auto& onlineTileSource : onlineTileSources->getCollection())
        {
            OAOnlineTilesResourceItem* item = [[OAOnlineTilesResourceItem alloc] init];
            item.title = onlineTileSource->name.toNSString();
            item.path = [app.cachePath stringByAppendingPathComponent:item.title];
            [self.existingItems addObject:item];
        }
    }
}

- (instancetype) initWithItems:(NSArray<OALocalResourceItem *> *)items
{
    self = [super initWithItems:items];
    if (self)
    {
        if (self.items.count > 0)
        {
            for (OALocalResourceItem *localItem in self.items)
            {
                if ([localItem isKindOfClass:OASqliteDbResourceItem.class])
                {
                    OASqliteDbResourceItem *item = (OASqliteDbResourceItem *)localItem;
                    OASQLiteTileSource *sqliteSource = [[OASQLiteTileSource alloc] initWithFilePath:item.path];
                    NSMutableDictionary *params = [NSMutableDictionary dictionary];
                    params[@"minzoom"] = [NSString stringWithFormat:@"%d", sqliteSource.minimumZoomSupported];
                    params[@"maxzoom"] = [NSString stringWithFormat:@"%d", sqliteSource.maximumZoomSupported];
                    params[@"url"] = sqliteSource.urlTemplate;
                    params[@"title"] = sqliteSource.title;
                    params[@"ellipsoid"] = sqliteSource.isEllipticYTile ? @(1) : @(0);
                    params[@"inverted_y"] = sqliteSource.isInvertedYTile ? @(1) : @(0);
                    params[@"expireminutes"] = sqliteSource.getExpirationTimeMillis != -1 ? [NSString stringWithFormat:@"%ld", sqliteSource.getExpirationTimeMillis / 60000] : @"";
                    params[@"timecolumn"] = sqliteSource.isTimeSupported ? @"yes" : @"no";
                    params[@"rule"] = sqliteSource.rule;
                    params[@"randoms"] = sqliteSource.randoms;
                    params[@"referer"] = sqliteSource.referer;
                    params[@"inversiveZoom"] = sqliteSource.isInversiveZoom ? @(1) : @(0);
                    params[@"ext"] = sqliteSource.tileFormat;
                    params[@"tileSize"] = [NSString stringWithFormat:@"%d", sqliteSource.tileSize];
                    params[@"bitDensity"] = [NSString stringWithFormat:@"%d", sqliteSource.bitDensity];

                    _newSqliteData[item.title] = params;
                }
                else if ([localItem isKindOfClass:OAOnlineTilesResourceItem.class])
                {
                    OAOnlineTilesResourceItem *item = (OAOnlineTilesResourceItem *)localItem;
                    std::shared_ptr<const OsmAnd::IOnlineTileSources::Source> tileSource;
                    const auto& resource = [OsmAndApp instance].resourcesManager->getResource(QStringLiteral("online_tiles"));
                    if (resource)
                    {
                        const auto& onlineTileSources = std::static_pointer_cast<const OsmAnd::ResourcesManager::OnlineTileSourcesMetadata>(resource->metadata)->sources;
                        for(const auto& onlineTileSource : onlineTileSources->getCollection())
                        {
                            if (QString::compare(QString::fromNSString(item.title), onlineTileSource->name) == 0)
                            {
                                tileSource = onlineTileSource;
                                break;
                            }
                        }
                    }
                    if (tileSource)
                        _newSources[QString::fromNSString(item.title)] = tileSource;
                }
            }
        }
    }
    return self;
}

- (EOASettingsItemType) type
{
    return EOASettingsItemTypeMapSources;
}

- (void) apply
{
    NSArray<OALocalResourceItem *> *newItems = [self getNewItems];
    if (newItems.count > 0 || self.duplicateItems.count > 0)
    {
        OsmAndAppInstance app = [OsmAndApp instance];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        self.appliedItems = [NSMutableArray arrayWithArray:newItems];
        if ([self shouldReplace])
        {
            for (OALocalResourceItem *localItem in self.duplicateItems)
            {
                if ([localItem isKindOfClass:OASqliteDbResourceItem.class])
                {
                    OASqliteDbResourceItem *item = (OASqliteDbResourceItem *)localItem;
                    if (item.path && [fileManager fileExistsAtPath:item.path])
                    {
                        [[OAMapCreatorHelper sharedInstance] removeFile:item.path];
                        [self.appliedItems addObject:localItem];
                    }
                }
                else if ([localItem isKindOfClass:OAOnlineTilesResourceItem.class])
                {
                    OAOnlineTilesResourceItem *item = (OAOnlineTilesResourceItem *)localItem;
                    if (item.path)
                    {
                        [[NSFileManager defaultManager] removeItemAtPath:item.path error:nil];
                        app.resourcesManager->uninstallTilesResource(QString::fromNSString([item.path lastPathComponent]));
                        [self.appliedItems addObject:localItem];
                    }
                }
            }
        }
        else
        {
            for (OALocalResourceItem *localItem in self.duplicateItems)
                [self.appliedItems addObject:[self renameItem:localItem]];
        }
        for (OALocalResourceItem *localItem in self.appliedItems)
        {
            if ([localItem isKindOfClass:OASqliteDbResourceItem.class])
            {
                NSMutableDictionary *params = _newSqliteData[localItem.title];
                if (params)
                {
                    NSString *path = [[NSTemporaryDirectory() stringByAppendingPathComponent:localItem.title] stringByAppendingPathExtension:@"sqlitedb"];
                    if ([OASQLiteTileSource createNewTileSourceDbAtPath:path parameters:params])
                        [[OAMapCreatorHelper sharedInstance] installFile:path newFileName:nil];
                }
            }
            else if ([localItem isKindOfClass:OAOnlineTilesResourceItem.class])
            {
                const auto source = _newSources.value(QString::fromNSString(localItem.title));
                if (source)
                {
                    OsmAnd::OnlineTileSources::installTileSource(source, QString::fromNSString(app.cachePath));
                    app.resourcesManager->installTilesResource(source);
                }
            }
        }
    }
}

- (OALocalResourceItem *) renameItem:(OALocalResourceItem *)localItem
{
    int number = 0;
    while (true)
    {
        number++;
        if ([localItem isKindOfClass:OASqliteDbResourceItem.class])
        {
            OASqliteDbResourceItem *oldItem = (OASqliteDbResourceItem *)localItem;
            OASqliteDbResourceItem *renamedItem = [[OASqliteDbResourceItem alloc] init];
            renamedItem.fileName = [NSString stringWithFormat:@"%@_%d", oldItem.fileName, number];
            if (![self isDuplicate:renamedItem])
            {
                renamedItem.title = [[renamedItem.fileName stringByDeletingPathExtension] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
                renamedItem.path = oldItem.path;
                renamedItem.size = oldItem.size;
                _newSqliteData[renamedItem.fileName] = _newSqliteData[oldItem.fileName];
                [_newSqliteData removeObjectForKey:oldItem.fileName];
                return renamedItem;
            }
        }
        else if ([localItem isKindOfClass:OAOnlineTilesResourceItem.class])
        {
            OAOnlineTilesResourceItem *oldItem = (OAOnlineTilesResourceItem *)localItem;
            OAOnlineTilesResourceItem *renamedItem = [[OAOnlineTilesResourceItem alloc] init];
            renamedItem.title = [NSString stringWithFormat:@"%@_%d", oldItem.title, number];
            if (![self isDuplicate:renamedItem])
            {
                renamedItem.path = oldItem.path;
                _newSources[QString::fromNSString(renamedItem.title)] = _newSources[QString::fromNSString(oldItem.title)];
                _newSources.remove(QString::fromNSString(oldItem.title));
                return renamedItem;
            }
        }
    }
}

- (BOOL) isDuplicate:(OALocalResourceItem *)item
{
    for (OALocalResourceItem *existingItem in self.existingItems)
        if ([existingItem.title isEqualToString:item.title])
            return YES;

    return NO;
}

- (NSString *) name
{
    return @"map_sources";
}

- (BOOL) shouldReadOnCollecting
{
    return YES;
}

- (OASettingsItemReader *) getReader
{
    return [self getJsonReader];
}

- (void) readItemsFromJson:(id)json error:(NSError * _Nullable __autoreleasing *)error
{
    NSArray* itemsJson = [json mutableArrayValueForKey:@"items"];
    if (itemsJson.count == 0)
        return;
    
    OsmAndAppInstance app = [OsmAndApp instance];
    for (id object in itemsJson)
    {
        BOOL sql = [object[@"sql"] boolValue];
        NSString *name = object[@"name"];
        NSString *title = object[@"title"];
        if (title.length == 0)
            title = name;

        int minZoom = [object[@"minZoom"] intValue];
        int maxZoom = [object[@"maxZoom"] intValue];
        NSString *url = object[@"url"];
        NSString *randoms = object[@"randoms"];
        BOOL ellipsoid = object[@"ellipsoid"] ? [object[@"ellipsoid"] boolValue] : NO;
        BOOL invertedY = object[@"inverted_y"] ? [object[@"inverted_y"] boolValue] : NO;
        NSString *referer = object[@"referer"];
        BOOL timesupported = object[@"timesupported"] ? [object[@"timesupported"] boolValue] : NO;
        long expire = [object[@"expire"] longValue];
        BOOL inversiveZoom = object[@"inversiveZoom"] ? [object[@"inversiveZoom"] boolValue] : NO;
        NSString *ext = object[@"ext"];
        int tileSize = [object[@"tileSize"] intValue];
        int bitDensity = [object[@"bitDensity"] intValue];
        int avgSize = [object[@"avgSize"] intValue];
        NSString *rule = object[@"rule"];
        
        if (!sql)
        {
            const auto result = std::make_shared<OsmAnd::IOnlineTileSources::Source>(QString::fromNSString(name));

            result->urlToLoad = QString::fromNSString(url);
            result->minZoom = OsmAnd::ZoomLevel(minZoom);
            result->maxZoom = OsmAnd::ZoomLevel(maxZoom);
            result->expirationTimeMillis = expire;
            result->ellipticYTile = ellipsoid;
            //result->priority = _tileSource->priority;
            result->tileSize = tileSize;
            result->ext = QString::fromNSString(ext);
            result->avgSize = avgSize;
            result->bitDensity = bitDensity;
            result->invertedYTile = invertedY;
            result->randoms = QString::fromNSString(randoms);
            result->randomsArray = OsmAnd::OnlineTileSources::parseRandoms(QString::fromNSString(randoms));
            result->rule = QString::fromNSString(rule);

            OsmAnd::OnlineTileSources::installTileSource(result, QString::fromNSString(app.cachePath));
            app.resourcesManager->installTilesResource(result);

            OAOnlineTilesResourceItem *item = [[OAOnlineTilesResourceItem alloc] init];
            item.path = [app.cachePath stringByAppendingPathComponent:name];
            item.title = name;
            _newSources[QString::fromNSString(name)] = result;

            [self.items addObject:item];
        }
        else
        {
            NSMutableDictionary *params = [NSMutableDictionary new];
            params[@"minzoom"] = [NSString stringWithFormat:@"%d", minZoom];
            params[@"maxzoom"] = [NSString stringWithFormat:@"%d", maxZoom];
            params[@"url"] = url;
            params[@"title"] = title;
            params[@"ellipsoid"] = ellipsoid ? @(1) : @(0);
            params[@"inverted_y"] = invertedY ? @(1) : @(0);
            params[@"expireminutes"] = expire != -1 ? [NSString stringWithFormat:@"%ld", expire / 60000] : @"";
            params[@"timecolumn"] = timesupported ? @"yes" : @"no";
            params[@"rule"] = rule;
            params[@"randoms"] = randoms;
            params[@"referer"] = referer;
            params[@"inversiveZoom"] = inversiveZoom ? @(1) : @(0);
            params[@"ext"] = ext;
            params[@"tileSize"] = [NSString stringWithFormat:@"%d", tileSize];
            params[@"bitDensity"] = [NSString stringWithFormat:@"%d", bitDensity];

            NSString *path = [[NSTemporaryDirectory() stringByAppendingPathComponent:name] stringByAppendingPathExtension:@"sqlitedb"];
            if ([OASQLiteTileSource createNewTileSourceDbAtPath:path parameters:params])
            {
                [[OAMapCreatorHelper sharedInstance] installFile:path newFileName:nil];
                OASqliteDbResourceItem *item = [[OASqliteDbResourceItem alloc] init];
                item.title = [[name stringByDeletingPathExtension] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
                item.fileName = name;
                item.path = [[[OAMapCreatorHelper sharedInstance].filesDir stringByAppendingPathComponent:name] stringByAppendingPathExtension:@"sqlitedb"];
                item.size = [[[NSFileManager defaultManager] attributesOfItemAtPath:item.path error:nil] fileSize];
                _newSqliteData[name] = params;
                
                [self.items addObject:item];
            }
        }
    }
}

- (void) writeItemsToJson:(id)json error:(NSError * _Nullable __autoreleasing *)error
{
    NSMutableArray *jsonArray = [NSMutableArray array];
    if (self.items.count > 0)
    {
        for (OALocalResourceItem *localItem in self.items)
        {
            NSMutableDictionary *jsonObject = [NSMutableDictionary dictionary];
            if ([localItem isKindOfClass:OASqliteDbResourceItem.class])
            {
                OASqliteDbResourceItem *item = (OASqliteDbResourceItem *)localItem;
                NSDictionary *params = _newSqliteData[item.title];
                jsonObject[@"sql"] = @(YES);
                jsonObject[@"name"] = item.title;
                jsonObject[@"minZoom"] = params[@"minzoom"];
                jsonObject[@"maxZoom"] = params[@"maxzoom"];
                jsonObject[@"url"] = params[@"url"];
                jsonObject[@"randoms"] = params[@"randoms"];
                jsonObject[@"ellipsoid"] = [@(1) isEqual:params[@"ellipsoid"]] ? @"true" : @"false";
                jsonObject[@"inverted_y"] = [@(1) isEqual:params[@"inverted_y"]] ? @"true" : @"false";
                jsonObject[@"referer"] = params[@"referer"];
                jsonObject[@"timesupported"] = params[@"timecolumn"];
                NSString *expMinStr = params[@"expireminutes"];
                jsonObject[@"expire"] = expMinStr ? [NSString stringWithFormat:@"%lld", expMinStr.longLongValue * 60000] : @"0";
                jsonObject[@"inversiveZoom"] = [@(1) isEqual:params[@"inversiveZoom"]] ? @"true" : @"false";
                jsonObject[@"ext"] = params[@"ext"];
                jsonObject[@"tileSize"] = params[@"tileSize"];
                jsonObject[@"bitDensity"] = params[@"bitDensity"];
                jsonObject[@"rule"] = params[@"rule"];
            }
            else if ([localItem isKindOfClass:OAOnlineTilesResourceItem.class])
            {
                OAOnlineTilesResourceItem *item = (OAOnlineTilesResourceItem *)localItem;
                const auto& source = _newSources[QString::fromNSString(item.title)];
                if (source)
                {
                    jsonObject[@"sql"] = @(NO);
                    jsonObject[@"name"] = item.title;
                    jsonObject[@"minZoom"] = [NSString stringWithFormat:@"%d", source->minZoom];
                    jsonObject[@"maxZoom"] = [NSString stringWithFormat:@"%d", source->maxZoom];
                    jsonObject[@"url"] = source->urlToLoad.toNSString();
                    jsonObject[@"randoms"] = source->randoms.toNSString();
                    jsonObject[@"ellipsoid"] = source->ellipticYTile ? @"true" : @"false";
                    jsonObject[@"inverted_y"] = source->invertedYTile ? @"true" : @"false";
                    jsonObject[@"timesupported"] = source->expirationTimeMillis != -1 ? @"true" : @"false";
                    jsonObject[@"expire"] = [NSString stringWithFormat:@"%ld", source->expirationTimeMillis];
                    jsonObject[@"ext"] = source->ext.toNSString();
                    jsonObject[@"tileSize"] = [NSString stringWithFormat:@"%d", source->tileSize];
                    jsonObject[@"bitDensity"] = [NSString stringWithFormat:@"%d", source->bitDensity];
                    jsonObject[@"avgSize"] = [NSString stringWithFormat:@"%d", source->avgSize];
                    jsonObject[@"rule"] = source->rule.toNSString();
                }
            }
            [jsonArray addObject:jsonObject];
        }
        json[@"items"] = jsonArray;
    }
}

@end

#pragma mark - OAAvoidRoadsSettingsItem

@interface OAAvoidRoadsSettingsItem()

@property (nonatomic) NSMutableArray<OAAvoidRoadInfo *> *items;
@property (nonatomic) NSMutableArray<OAAvoidRoadInfo *> *appliedItems;
@property (nonatomic) NSMutableArray<OAAvoidRoadInfo *> *existingItems;

@end

@implementation OAAvoidRoadsSettingsItem
{
    OAAvoidSpecificRoads *_specificRoads;
    OAAppSettings *_settings;
}

@dynamic items, appliedItems, existingItems;

- (void) initialization
{
    [super initialization];
    
    _specificRoads = [OAAvoidSpecificRoads instance];
    _settings = [OAAppSettings sharedManager];
    self.existingItems = [[_specificRoads getImpassableRoads] mutableCopy];
}

- (EOASettingsItemType) type
{
    return EOASettingsItemTypeAvoidRoads;
}

- (NSString *) name
{
    return @"avoid_roads";
}

- (BOOL) isDuplicate:(OAAvoidRoadInfo *)item
{
    return [self.existingItems containsObject:item];
}

- (void) apply
{
    NSArray<OAAvoidRoadInfo *> *newItems = [self getNewItems];
    if (newItems.count > 0 || self.duplicateItems.count > 0)
    {
        self.appliedItems = [NSMutableArray arrayWithArray:newItems];
        for (OAAvoidRoadInfo *duplicate in self.duplicateItems)
        {
            if ([self shouldReplace])
            {
                if ([_settings removeImpassableRoad:duplicate.location])
                    [_settings addImpassableRoad:duplicate];
            }
            else
            {
                OAAvoidRoadInfo *roadInfo = [self renameItem:duplicate];
                [_settings addImpassableRoad:roadInfo];
            }
        }
        for (OAAvoidRoadInfo *roadInfo in self.appliedItems)
            [_settings addImpassableRoad:roadInfo];

        [_specificRoads loadImpassableRoads];
        [_specificRoads initRouteObjects:YES];
    }
}

- (OAAvoidRoadInfo *) renameItem:(OAAvoidRoadInfo *)item
{
    int number = 0;
    while (true)
    {
        number++;
        OAAvoidRoadInfo *renamedItem = [[OAAvoidRoadInfo alloc] init];
        renamedItem.name = [NSString stringWithFormat:@"%@_%d", item.name, number];
        if (![self isDuplicate:renamedItem])
        {
            renamedItem.roadId = item.roadId;
            renamedItem.location = item.location;
            renamedItem.appModeKey = item.appModeKey;
            return renamedItem;
        }
    }
}

- (BOOL) shouldReadOnCollecting
{
    return YES;
}

- (OASettingsItemReader *) getReader
{
    return [self getJsonReader];
}

- (void) readItemsFromJson:(id)json error:(NSError * _Nullable __autoreleasing *)error
{
    NSArray* itemsJson = [json mutableArrayValueForKey:@"items"];
    if (itemsJson.count == 0)
        return;
    
    for (id object in itemsJson)
    {
        double latitude = [object[@"latitude"] doubleValue];
        double longitude = [object[@"longitude"] doubleValue];
        NSString *name = object[@"name"];
        NSString *appModeKey = object[@"appModeKey"];
        OAAvoidRoadInfo *roadInfo = [[OAAvoidRoadInfo alloc] init];
        roadInfo.roadId = 0;
        roadInfo.location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
        roadInfo.name = name;
        if ([OAApplicationMode valueOfStringKey:appModeKey def:nil])
            roadInfo.appModeKey = appModeKey;
        else
            roadInfo.appModeKey = [[OARoutingHelper sharedInstance] getAppMode].stringKey;

        [self.items addObject:roadInfo];
    }
}

- (void) writeItemsToJson:(id)json error:(NSError * _Nullable __autoreleasing *)error
{
    NSMutableArray *jsonArray = [NSMutableArray array];
    if (self.items.count > 0)
    {
        for (OAAvoidRoadInfo *avoidRoad in self.items)
        {
            NSMutableDictionary *jsonObject = [NSMutableDictionary dictionary];
            jsonObject[@"latitude"] = [NSString stringWithFormat:@"%0.5f", avoidRoad.location.coordinate.latitude];
            jsonObject[@"longitude"] = [NSString stringWithFormat:@"%0.5f", avoidRoad.location.coordinate.longitude];
            jsonObject[@"name"] = avoidRoad.name;
            jsonObject[@"appModeKey"] = avoidRoad.appModeKey;
            [jsonArray addObject:jsonObject];
        }        
        json[@"items"] = jsonArray;
    }
}

@end
