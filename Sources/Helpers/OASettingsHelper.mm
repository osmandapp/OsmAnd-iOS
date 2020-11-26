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
#import "OAIndexConstants.h"

#import "OAVoiceRouter.h"
#import "OARoutingHelper.h"
#import "OARouteProvider.h"
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
#import "OAMapStyleTitles.h"
#import "OrderedDictionary.h"
#import "OAImportSettingsViewController.h"
#import "OAGPXDocument.h"
#import "OAGPXDatabase.h"
#import "OAGPXTrackAnalysis.h"
#import "OAOsmEditingPlugin.h"
#import "OAOsmBugsDBHelper.h"
#import "OAOpenstreetmapsDbHelper.h"
#import "OAOsmNotesPoint.h"
#import "OAEntity.h"
#import "OANode.h"
#import "OAWay.h"
#import "OAOpenStreetMapPoint.h"

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


#pragma mark - OASettingsItem

@interface OASettingsItem()

@property (nonatomic) NSString *pluginId;
@property (nonatomic) NSString *defaultName;
@property (nonatomic) NSString *defaultFileExtension;
@property (nonatomic) NSMutableArray<NSString *> *warnings;

- (void) initialization;
- (void) readFromJson:(id)json error:(NSError * _Nullable *)error;
- (void) readItemsFromJson:(id)json error:(NSError * _Nullable *)error;
- (void) writeItemsToJson:(id)json;
- (void) readPreferenceFromJson:(NSString *)key value:(NSString *)value;
- (void) applyRendererPreferences:(NSDictionary<NSString *, NSString *> *)prefs;
- (void) applyRoutingPreferences:(NSDictionary<NSString *, NSString *> *)prefs;

@end

@implementation OASettingsItem

- (instancetype) init
{
    self = [super init];
    if (self)
        [self initialization];
    
    return self;
}

- (instancetype) initWithBaseItem:(OASettingsItem *)baseItem
{
    self = [self init];
    if (self)
    {
        if (baseItem)
        {
            _pluginId = baseItem.pluginId;
            _fileName = baseItem.fileName;
        }
    }
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
    return [_name stringByAppendingString:self.defaultFileExtension];
}

- (NSString *) defaultFileExtension
{
    return @".json";
}

- (BOOL) applyFileName:(NSString *)fileName
{
    return self.fileName ? ([fileName hasSuffix:self.fileName] || [fileName hasPrefix:[self.fileName stringByAppendingString:@"/"]] || [fileName isEqualToString:self.fileName]) : NO;
}

- (BOOL) exists
{
    return NO;
}

- (void) apply
{
    // non implemented
}

- (NSDictionary *) getSettingsJson
{
    // override
    return @{};
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

- (void) writeToJson:(id)json
{
    json[@"type"] = [OASettingsItemType typeName:self.type];
    if (self.pluginId.length > 0)
        json[@"pluginId"] = self.pluginId;
    
    if ([self getWriter])
    {
        if (!self.fileName || self.fileName.length == 0)
            self.fileName = self.defaultFileName;
        
        json[@"file"] = self.fileName;
    }
    [self writeItemsToJson:json];
}

- (void) readItemsFromJson:(id)json error:(NSError * _Nullable *)error
{
    // override
}

- (void) writeItemsToJson:(id)json
{
    // override
}

- (void) readPreferenceFromJson:(NSString *)key value:(NSString *)value
{
    // override
}

- (void) applyRendererPreferences:(NSDictionary<NSString *, NSString *> *)prefs
{
    // override
}

- (void) applyRoutingPreferences:(NSDictionary<NSString *, NSString *> *)prefs
{
    // override
}

- (OASettingsItemReader *) getJsonReader
{
    return [[OASettingsItemReader alloc] initWithItem:self];
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
    result = 31 * result + (_name != nil ? [_name hash] : 0);
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
            && (item.name == _name || [item.name isEqualToString:_name])
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
    NSError *parsingError;
    [self.item readFromJson:json error:&parsingError];
    if (parsingError)
    {
        NSLog(@"Json parsing error");
        return NO;
    }
    return YES;
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
    NSDictionary<NSString *, NSString *> *settings = (NSDictionary *) json;
    NSMutableDictionary<NSString *, NSString *> *rendererSettings = [NSMutableDictionary new];
    NSMutableDictionary<NSString *, NSString *> *routingSettings = [NSMutableDictionary new];
    [settings enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        if ([key hasPrefix:@"nrenderer_"] || [key isEqualToString:@"displayed_transport_settings"])
            [rendererSettings setObject:obj forKey:key];
        else if ([key hasPrefix:@"prouting_"])
            [routingSettings setObject:obj forKey:key];
        else
            [self.item readPreferenceFromJson:key value:obj];
    }];
    [self.item applyRendererPreferences:rendererSettings];
    [self.item applyRoutingPreferences:routingSettings];
    return YES;
}

@end

#pragma mark - OASettingsItemJsonWriter

@implementation OASettingsItemJsonWriter

- (BOOL) writeToFile:(NSString *)filePath error:(NSError * _Nullable *)error
{
    NSDictionary *json = [self.item getSettingsJson];
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
    return [OAApplicationMode valueOfStringKey:_appMode.stringKey def:nil] != nil;
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
    const auto router = [OARouteProvider getRouter:self.appMode];
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
        OAProfileSetting *setting = [settings getSettingById:key];
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
        OAProfileSetting *setting = [settings.getRegisteredSettings objectForKey:key];
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
    
    const auto router = [OARouteProvider getRouter:self.appMode];
    if (router)
    {
        const auto& parameters = router->getParametersList();
        for (const auto& p : parameters)
        {
            if (p.type == RoutingParameterType::BOOLEAN)
            {
                OAProfileBoolean *boolSetting = [settings getCustomRoutingBooleanProperty:[NSString stringWithUTF8String:p.id.c_str()] defaultValue:p.defaultBoolean];
                res[[@"prouting_" stringByAppendingString:[NSString stringWithUTF8String:p.id.c_str()]]] = [boolSetting toStringValue:self.appMode];
            }
            else
            {
                OAProfileString *stringSetting = [settings getCustomRoutingProperty:[NSString stringWithUTF8String:p.id.c_str()] defaultValue:p.type == RoutingParameterType::NUMERIC ? @"0.0" : @"-"];
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

- (OASettingsItemReader *)getReader
{
    return [[OASettingsItemJsonReader alloc] initWithItem:self];
}

- (OASettingsItemWriter *)getWriter
{
    return [[OASettingsItemJsonWriter alloc] initWithItem:self];
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
    NSMutableArray<OASettingsItem *> *_pluginDependentItems;
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

- (NSMutableArray<OASettingsItem *> *) getPluginDependentItems
{
    return _pluginDependentItems;
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

- (void) writeToJson:(id)json
{
    // TODO: Finish later
    [super writeToJson:json];
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
    
    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSString *directory = [destFilePath stringByDeletingLastPathComponent];
    if (![fileManager fileExistsAtPath:directory])
        [fileManager createDirectoryAtPath:directory withIntermediateDirectories:NO attributes:nil error:nil];

    NSError *copyError;
    BOOL res = [[NSFileManager defaultManager] copyItemAtPath:filePath toPath:destFilePath error:&copyError];
    if (error && copyError)
        *error = copyError;
    
    [self.item installItem:destFilePath];
    
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
        case EOASettingsItemFileSubtypeWikiMap:
            return @"wiki_map";
        case EOASettingsItemFileSubtypeSrtmMap:
            return @"srtm_map";
        case EOASettingsItemFileSubtypeRoadMap:
            return @"road_map";
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
    NSString *documentsPath = OsmAndApp.instance.documentsPath;
    switch (subtype)
    {
        case EOASettingsItemFileSubtypeOther:
        case EOASettingsItemFileSubtypeObfMap:
        case EOASettingsItemFileSubtypeWikiMap:
        case EOASettingsItemFileSubtypeRoadMap:
        case EOASettingsItemFileSubtypeSrtmMap:
        case EOASettingsItemFileSubtypeRenderingStyle:
        case EOASettingsItemFileSubtypeTilesMap:
            return documentsPath;
        case EOASettingsItemFileSubtypeRoutingConfig:
            return [documentsPath stringByAppendingPathComponent:@"routing"];
        case EOASettingsItemFileSubtypeGpx:
            return OsmAndApp.instance.gpxPath;
            // unsupported
//        case EOASettingsItemFileSubtypeTravel:
//        case EOASettingsItemFileSubtypeVoice:
//            return [documentsPath stringByAppendingPathComponent:@"Voice"];
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
    if ([fileName hasPrefix:@"/"])
        name = [fileName substringFromIndex:1];

    for (int i = 0; i < EOASettingsItemFileSubtypesCount; i++)
    {
        EOASettingsItemFileSubtype subtype = (EOASettingsItemFileSubtype) i;
        switch (subtype) {
            case EOASettingsItemFileSubtypeUnknown:
            case EOASettingsItemFileSubtypeOther:
                break;
            case EOASettingsItemFileSubtypeObfMap:
            {
                if ([name hasSuffix:BINARY_MAP_INDEX_EXT] && ![name containsString:@"/"])
                    return subtype;
                break;
            }
            case EOASettingsItemFileSubtypeSrtmMap:
            {
                if ([name hasSuffix:BINARY_SRTM_MAP_INDEX_EXT])
                    return subtype;
                break;
            }
            case EOASettingsItemFileSubtypeWikiMap:
            {
                if ([name hasSuffix:BINARY_WIKI_MAP_INDEX_EXT])
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
                if ([name hasSuffix:@".sqlitedb"])
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
            case EOASettingsItemFileSubtypeRoadMap:
            {
                if ([name containsString:@"road"])
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

+ (BOOL) isMap:(EOASettingsItemFileSubtype)type
{
    return type == EOASettingsItemFileSubtypeObfMap || type == EOASettingsItemFileSubtypeWikiMap || type == EOASettingsItemFileSubtypeSrtmMap || type == EOASettingsItemFileSubtypeTilesMap || type == EOASettingsItemFileSubtypeRoadMap;
}

@end

#pragma mark - OAFileSettingsItem

@interface OAFileSettingsItem()

@property (nonatomic) NSString *name;
@property (nonatomic) NSString *docPath;
@property (nonatomic) NSString *libPath;

@end

@implementation OAFileSettingsItem
{
    NSString *_name;
}

@dynamic name;

- (void) commonInit
{
    _docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    _libPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
}

- (instancetype) initWithFilePath:(NSString *)filePath error:(NSError * _Nullable *)error
{
    self = [super init];
    if (self)
    {
        [self commonInit];
        self.name = [filePath lastPathComponent];
        if (error)
        {
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
        else if (self.subtype == EOASettingsItemFileSubtypeUnknown || !self.subtype)
        {
            if (error)
                *error = [NSError errorWithDomain:kSettingsHelperErrorDomain code:kSettingsHelperErrorCodeUnknownFileSubtype userInfo:nil];
            return nil;
        }
        else
        {
            _filePath = [[OAFileSettingsItemFileSubtype getSubtypeFolder:_subtype] stringByAppendingPathComponent:self.name];
        }
    }
    return self;
}

- (NSString *) fileNameWithSubtype:(EOASettingsItemFileSubtype)subtype name:(NSString *)name
{
    if ([OAFileSettingsItemFileSubtype isMap:subtype])
    {
        switch (subtype)
        {
            case EOASettingsItemFileSubtypeTilesMap:
            {
                NSString *ext = name.pathExtension;
                NSString *newFileName = [name stringByDeletingPathExtension].lowerCase;
                
                NSString *hillshadeExt = @"hillshade";
                NSString *slopeExt = @"slope";
                BOOL isHillShade = [newFileName containsString:hillshadeExt];
                BOOL isSlope = [newFileName containsString:slopeExt];
                NSString *typeExt = @"";
                if (isHillShade)
                {
                    newFileName = [newFileName stringByReplacingOccurrencesOfString:hillshadeExt withString:@""];
                    typeExt = hillshadeExt;
                }
                else if (isSlope)
                {
                    newFileName = [newFileName stringByReplacingOccurrencesOfString:slopeExt withString:@""];
                    typeExt = slopeExt;
                }
                newFileName = [newFileName trim];
                newFileName = [newFileName stringByAppendingPathExtension:typeExt];
                newFileName = [newFileName stringByAppendingPathExtension:ext];
                newFileName = [newFileName stringByReplacingOccurrencesOfString:@" " withString:@"_"];
                
                return newFileName;
            }
            case EOASettingsItemFileSubtypeObfMap:
            {
                NSString *newName = [name stringByDeletingPathExtension].lowerCase;
                NSString *ext = name.pathExtension;
                return [[newName stringByAppendingPathExtension:@"map"] stringByAppendingPathExtension:ext];
            }
            case EOASettingsItemFileSubtypeSrtmMap:
            case EOASettingsItemFileSubtypeWikiMap:
            case EOASettingsItemFileSubtypeRoadMap:
            {
                return name.lowerCase;
            }

            default:
                break;
        }
    }
    return name;
}

- (void) installItem:(NSString *)destFilePath
{
    switch (_subtype)
    {
        case EOASettingsItemFileSubtypeGpx:
        {
            OAGPXDocument *doc = [[OAGPXDocument alloc] initWithGpxFile:destFilePath];
            [doc saveTo:destFilePath];
            OAGPXTrackAnalysis *analysis = [doc getAnalysis:0];
            [[OAGPXDatabase sharedDb] addGpxItem:[destFilePath lastPathComponent] title:doc.metadata.name desc:doc.metadata.desc bounds:doc.bounds analysis:analysis];
            [[OAGPXDatabase sharedDb] save];
            break;
        }
        case EOASettingsItemFileSubtypeRenderingStyle:
        {
            OsmAndApp.instance.resourcesManager->rescanUnmanagedStoragePaths();
            break;
        }
        case EOASettingsItemFileSubtypeObfMap:
        {
            OsmAndApp.instance.resourcesManager->installImportedResource(QString::fromNSString(destFilePath), QString::fromNSString([self fileNameWithSubtype:self.subtype name:destFilePath.lastPathComponent]), OsmAnd::ResourcesManager::ResourceType::MapRegion);
            break;
        }
        case EOASettingsItemFileSubtypeRoadMap:
        {
            OsmAndApp.instance.resourcesManager->installImportedResource(QString::fromNSString(destFilePath), QString::fromNSString([self fileNameWithSubtype:self.subtype name:destFilePath.lastPathComponent]), OsmAnd::ResourcesManager::ResourceType::RoadMapRegion);
            break;
        }
        case EOASettingsItemFileSubtypeWikiMap:
        {
            OsmAndApp.instance.resourcesManager->installImportedResource(QString::fromNSString(destFilePath), QString::fromNSString([self fileNameWithSubtype:self.subtype name:destFilePath.lastPathComponent]), OsmAnd::ResourcesManager::ResourceType::WikiMapRegion);
            break;
        }
        case EOASettingsItemFileSubtypeSrtmMap:
        {
            OsmAndApp.instance.resourcesManager->installImportedResource(QString::fromNSString(destFilePath), QString::fromNSString([self fileNameWithSubtype:self.subtype name:destFilePath.lastPathComponent]), OsmAnd::ResourcesManager::ResourceType::SrtmMapRegion);
            break;
        }
        case EOASettingsItemFileSubtypeTilesMap:
        {
            NSString *newName = [self fileNameWithSubtype:_subtype name:destFilePath.lastPathComponent];
            if ([newName containsString:@"hillshade"])
                OsmAndApp.instance.resourcesManager->installImportedResource(QString::fromNSString(destFilePath), QString::fromNSString(newName), OsmAnd::ResourcesManager::ResourceType::HillshadeRegion);
            else if ([newName containsString:@"slope"])
                OsmAndApp.instance.resourcesManager->installImportedResource(QString::fromNSString(destFilePath), QString::fromNSString(newName), OsmAnd::ResourcesManager::ResourceType::SlopeRegion);
            break;
        }
        default:
            break;
    }
    if ([OAFileSettingsItemFileSubtype isMap:_subtype])
        [NSFileManager.defaultManager removeItemAtPath:destFilePath error:nil];
}

- (EOASettingsItemType) type
{
    return EOASettingsItemTypeFile;
}

- (NSString *) fileName
{
    return self.name;
}

- (void) setName:(NSString *)name
{
    _name = name;
}

- (NSString *) name
{
    return _name;
}

- (BOOL) exists
{
    if ([OAFileSettingsItemFileSubtype isMap:self.subtype])
    {
        NSString *destPath = [OsmAndApp.instance.dataPath stringByAppendingPathComponent:@"Resources"];
        destPath = [destPath stringByAppendingPathComponent:[self fileNameWithSubtype:self.subtype name:self.name]];
        return [[NSFileManager defaultManager] fileExistsAtPath:destPath];
    }
    return [[NSFileManager defaultManager] fileExistsAtPath:_filePath];
}

- (NSString *) renameFile:(NSString*)filePath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    int number = 0;
    NSString *prefix;
    if ([filePath hasSuffix:BINARY_WIKI_MAP_INDEX_EXT])
        prefix = [filePath substringToIndex:[filePath lastIndexOf:BINARY_WIKI_MAP_INDEX_EXT]];
    else if ([filePath hasSuffix:BINARY_SRTM_MAP_INDEX_EXT])
        prefix = [filePath substringToIndex:[filePath lastIndexOf:BINARY_SRTM_MAP_INDEX_EXT]];
    else if ([filePath hasSuffix:BINARY_ROAD_MAP_INDEX_EXT])
        prefix = [filePath substringToIndex:[filePath lastIndexOf:BINARY_ROAD_MAP_INDEX_EXT]];
    else
        prefix = [filePath substringToIndex:[filePath lastIndexOf:@"."]];
    
    NSString *suffix = [filePath stringByReplacingOccurrencesOfString:prefix withString:@""];
    if ([OAFileSettingsItemFileSubtype isMap:_subtype])
        return [self renameMap:suffix prefix:prefix];

    while (true)
    {
        number++;
        NSString *newFilePath = [NSString stringWithFormat:@"%@_%d%@", prefix, number, suffix];
        if (![fileManager fileExistsAtPath:newFilePath])
            return newFilePath;
    }
}

- (NSString *) renameMap:(NSString *)suffix prefix:(NSString *)prefix
{
    int number = 0;
    const auto& resManager = OsmAndApp.instance.resourcesManager;
    while (true)
    {
        number++;
        NSString *newFileName = [NSString stringWithFormat:@"%@_%d%@", prefix, number, suffix];
        NSString *localId = [self fileNameWithSubtype:self.subtype name:newFileName.lastPathComponent];
        if (!resManager->getLocalResource(QString::fromNSString(localId)))
            return newFileName;
    }
}

- (NSString *) getIconName
{
    switch (_subtype)
    {
        case EOASettingsItemFileSubtypeWikiMap:
            return @"ic_custom_wikipedia";
        case EOASettingsItemFileSubtypeSrtmMap:
            return @"ic_custom_contour_lines";
        default:
            return @"ic_custom_show_on_map";
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
    NSString *fileName = json[@"file"];
    if (!_subtype)
    {
        NSString *subtypeStr = json[@"subtype"];
        if (subtypeStr.length > 0)
            _subtype = [OAFileSettingsItemFileSubtype getSubtypeByName:subtypeStr];
        else if (fileName.length > 0)
            _subtype = [OAFileSettingsItemFileSubtype getSubtypeByFileName:fileName];
        else
            _subtype = EOASettingsItemFileSubtypeUnknown;
    }
    if (fileName.length > 0)
    {
        if (self.subtype == EOASettingsItemFileSubtypeOther)
            self.name = fileName;
        else if (self.subtype != EOASettingsItemFileSubtypeUnknown)
            self.name = [fileName lastPathComponent];
    }
}

- (void) writeToJson:(id)json
{
    [super writeToJson:json];
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

- (void) writeToJson:(id)json
{
    [super writeToJson:json];
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

- (instancetype) initWithItems:(NSArray<id> *)items
{
    self = [super init];
    if (self)
        _items = items.mutableCopy;
    
    return self;
}

- (instancetype) initWithItems:(NSArray<id> *)items baseItem:(OACollectionSettingsItem<id> *)baseItem
{
    self = [super initWithBaseItem:baseItem];
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

- (void) writeItemsToJson:(id)json
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
    self.existingItems = [_filtersHelper getUserDefinedPoiFilters:NO].mutableCopy;
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

@property (nonatomic) NSArray<NSDictionary *> *items;
@property (nonatomic) NSMutableArray<NSDictionary *> *appliedItems;

@end

@implementation OAMapSourcesSettingsItem
{
    NSArray<NSString *> *_existingItemNames;
}

@dynamic items, appliedItems;

- (void) initialization
{
    [super initialization];
    
    NSMutableArray<NSString *> *existingItemNames = [NSMutableArray array];
    
    OsmAndAppInstance app = [OsmAndApp instance];
    for (NSString *filePath in [OAMapCreatorHelper sharedInstance].files.allValues)
    {
        [existingItemNames addObject:[filePath.lastPathComponent stringByDeletingPathExtension]];
    }
    const auto& resource = app.resourcesManager->getResource(QStringLiteral("online_tiles"));
    if (resource != nullptr)
    {
        const auto& onlineTileSources = std::static_pointer_cast<const OsmAnd::ResourcesManager::OnlineTileSourcesMetadata>(resource->metadata)->sources;
        for(const auto& onlineTileSource : onlineTileSources->getCollection())
        {
            [existingItemNames addObject:onlineTileSource->name.toNSString()];
        }
    }
    _existingItemNames = existingItemNames;
}

- (instancetype) initWithItems:(NSArray<NSDictionary *> *)items
{
    self = [super initWithItems:items];
    return self;
}

- (EOASettingsItemType) type
{
    return EOASettingsItemTypeMapSources;
}

- (void) apply
{
    NSArray<NSDictionary *> *newItems = [self getNewItems];
    if (newItems.count > 0 || self.duplicateItems.count > 0)
    {
        OsmAndAppInstance app = [OsmAndApp instance];
        self.appliedItems = [NSMutableArray arrayWithArray:newItems];
        if ([self shouldReplace])
        {
            OAMapCreatorHelper *helper = [OAMapCreatorHelper sharedInstance];
            for (NSDictionary *item in self.duplicateItems)
            {
                BOOL isSqlite = [item[@"sql"] boolValue];
                if (isSqlite)
                {
                    NSString *name = [item[@"name"] stringByAppendingPathExtension:@"sqlitedb"];
                    if (name && helper.files[name])
                    {
                        [[OAMapCreatorHelper sharedInstance] removeFile:name];
                        [self.appliedItems addObject:item];
                    }
                }
                else
                {
                    NSString *name = item[@"name"];
                    if (name)
                    {
                        NSString *path = [app.cachePath stringByAppendingPathComponent:name];
                        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
                        app.resourcesManager->uninstallTilesResource(QString::fromNSString(name));
                        [self.appliedItems addObject:item];
                    }
                }
            }
        }
        else
        {
            for (NSDictionary *localItem in self.duplicateItems)
                [self.appliedItems addObject:[self renameItem:localItem]];
        }
        for (NSDictionary *localItem in self.appliedItems)
        {
            // TODO: migrate localItem to a custom class while extracting items into separate files
            BOOL isSql = [localItem[@"sql"] boolValue];
            
            NSString *name = localItem[@"name"];
            NSString *title = localItem[@"title"];
            if (title.length == 0)
                title = name;

            int minZoom = [localItem[@"minZoom"] intValue];
            int maxZoom = [localItem[@"maxZoom"] intValue];
            NSString *url = localItem[@"url"];
            NSString *randoms = localItem[@"randoms"];
            BOOL ellipsoid = localItem[@"ellipsoid"] ? [localItem[@"ellipsoid"] boolValue] : NO;
            BOOL invertedY = localItem[@"inverted_y"] ? [localItem[@"inverted_y"] boolValue] : NO;
            NSString *referer = localItem[@"referer"];
            BOOL timesupported = localItem[@"timesupported"] ? [localItem[@"timesupported"] boolValue] : NO;
            long expire = [localItem[@"expire"] longValue];
            BOOL inversiveZoom = localItem[@"inversiveZoom"] ? [localItem[@"inversiveZoom"] boolValue] : NO;
            NSString *ext = localItem[@"ext"];
            int tileSize = [localItem[@"tileSize"] intValue];
            int bitDensity = [localItem[@"bitDensity"] intValue];
            int avgSize = [localItem[@"avgSize"] intValue];
            NSString *rule = localItem[@"rule"];
            
            if (isSql)
            {
                NSString *path = [[NSTemporaryDirectory() stringByAppendingPathComponent:localItem[@"name"]] stringByAppendingPathExtension:@"sqlitedb"];
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
                if ([OASQLiteTileSource createNewTileSourceDbAtPath:path parameters:params])
                    [[OAMapCreatorHelper sharedInstance] installFile:path newFileName:nil];
            }
            else
            {
                const auto result = std::make_shared<OsmAnd::IOnlineTileSources::Source>(QString::fromNSString(localItem[@"name"]));

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
                result->randomsArray = OsmAnd::OnlineTileSources::parseRandoms(result->randoms);
                result->rule = QString::fromNSString(rule);

                OsmAnd::OnlineTileSources::installTileSource(result, QString::fromNSString(app.cachePath));
                app.resourcesManager->installTilesResource(result);
            }
        }
    }
}

- (NSDictionary *) renameItem:(NSDictionary *)localItem
{
    NSMutableDictionary *item = [NSMutableDictionary dictionaryWithDictionary:localItem];
    NSString *name = item[@"name"];
    if (name)
    {
        int number = 0;
        while (true)
        {
            number++;
            
            NSString *newName = [NSString stringWithFormat:@"%@_%d", name, number];
            NSMutableDictionary *newItem = [NSMutableDictionary dictionaryWithDictionary:item];
            newItem[@"name"] = newName;
            if (![self isDuplicate:newItem])
            {
                item = newItem;
                break;
            }
        }
    }
    return item;
}



- (BOOL) isDuplicate:(NSDictionary *)item
{
    NSString *itemName = item[@"name"];
    if (itemName)
        return [_existingItemNames containsObject:itemName];
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
    self.items = itemsJson;
}

- (void) writeItemsToJson:(id)json error:(NSError * _Nullable __autoreleasing *)error
{
    NSMutableArray *jsonArray = [NSMutableArray array];
    if (self.items.count > 0)
    {
        // TODO: fixme in export!
        for (NSDictionary *localItem in self.items)
        {
            NSMutableDictionary *jsonObject = [NSMutableDictionary dictionary];
            if ([localItem isKindOfClass:OASqliteDbResourceItem.class])
            {
                OASqliteDbResourceItem *item = (OASqliteDbResourceItem *)localItem;
                NSDictionary *params = localItem;
                // TODO: check if this writes true/false while implementing export
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
//                OAOnlineTilesResourceItem *item = (OAOnlineTilesResourceItem *)localItem;
//                const auto& source = _newSources[QString::fromNSString(item.title)];
//                if (source)
//                {
//                    jsonObject[@"sql"] = @(NO);
//                    jsonObject[@"name"] = item.title;
//                    jsonObject[@"minZoom"] = [NSString stringWithFormat:@"%d", source->minZoom];
//                    jsonObject[@"maxZoom"] = [NSString stringWithFormat:@"%d", source->maxZoom];
//                    jsonObject[@"url"] = source->urlToLoad.toNSString();
//                    jsonObject[@"randoms"] = source->randoms.toNSString();
//                    jsonObject[@"ellipsoid"] = source->ellipticYTile ? @"true" : @"false";
//                    jsonObject[@"inverted_y"] = source->invertedYTile ? @"true" : @"false";
//                    jsonObject[@"timesupported"] = source->expirationTimeMillis != -1 ? @"true" : @"false";
//                    jsonObject[@"expire"] = [NSString stringWithFormat:@"%ld", source->expirationTimeMillis];
//                    jsonObject[@"ext"] = source->ext.toNSString();
//                    jsonObject[@"tileSize"] = [NSString stringWithFormat:@"%d", source->tileSize];
//                    jsonObject[@"bitDensity"] = [NSString stringWithFormat:@"%d", source->bitDensity];
//                    jsonObject[@"avgSize"] = [NSString stringWithFormat:@"%d", source->avgSize];
//                    jsonObject[@"rule"] = source->rule.toNSString();
//                }
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

#pragma mark - OAOsmNotesSettingsItem

@interface OAOsmNotesSettingsItem()

@property (nonatomic) NSMutableArray<OAOsmNotesPoint *> *items;
@property (nonatomic) NSMutableArray<OAOsmNotesPoint *> *appliedItems;
@property (nonatomic) NSMutableArray<OAOsmNotesPoint *> *duplicateItems;

@end

@implementation OAOsmNotesSettingsItem

@dynamic items, appliedItems, duplicateItems;

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        OAOsmEditingPlugin *osmEditingPlugin = (OAOsmEditingPlugin *)[OAPlugin getPlugin:OAOsmEditingPlugin.class];
        if (osmEditingPlugin)
            [self setExistingItems: [NSMutableArray arrayWithArray:[[osmEditingPlugin getDBBug] getOsmbugsPoints]]];
    }
    return self;
}

- (EOASettingsItemType) type
{
    return EOASettingsItemTypeOsmNotes;
}

- (void) apply
{
    NSArray<OAOsmNotesPoint *>*newItems = [self getNewItems];
    if (newItems.count > 0 || [self duplicateItems].count > 0)
    {
        self.appliedItems = [NSMutableArray arrayWithArray:newItems];
        
        for (OAOsmNotesPoint *duplicate in [self duplicateItems])
        {
            [self.appliedItems addObject: self.shouldReplace ? duplicate : [self renameItem:duplicate]];
        }
        OAOsmEditingPlugin *osmEditingPlugin = (OAOsmEditingPlugin *)[OAPlugin getPlugin:OAOsmEditingPlugin.class];
        if (osmEditingPlugin)
        {
            OAOsmBugsDBHelper *db = [osmEditingPlugin getDBBug];
            for (OAOsmNotesPoint *point in self.appliedItems)
            {
                [db addOsmbugs:point];
            }
        }
    }
}

- (BOOL) isDuplicate:(OAOsmNotesPoint *)item
{
    return NO;
}

- (OAOsmNotesPoint *) renameItem:(OAOsmNotesPoint *)item
{
    return item;
}

- (NSString *) getName
{
    return @"osm_notes";
}

- (NSString *) getPublicName
{
    return OALocalizedString(@"osm_notes");
}

- (BOOL) shouldReadOnCollecting
{
    return YES;
}

- (void) readItemsFromJson:(id)json error:(NSError * _Nullable *)error
{
    NSArray* itemsJson = [json mutableArrayValueForKey:@"items"];
    if (itemsJson.count == 0)
        return;
    
    for (id object in itemsJson)
    {
        long long iD = [object[@"id"] longLongValue];
        NSString *text = object[@"text"];
        double lat = [object[@"lat"] doubleValue];
        double lon = [object[@"lon"] doubleValue];
        NSString *author = object[@"author"];
        author = author.length > 0 ? author : nil;        
        NSString *action = object[@"action"];
        OAOsmNotesPoint *point = [[OAOsmNotesPoint alloc] init];
        [point setId:iD];
        [point setText:text];
        [point setLatitude:lat];
        [point setLongitude:lon];
        [point setAuthor:author];
        [point setAction:[OAOsmPoint getActionByName:action]];
        [self.items addObject:point];
    }
}

- (void) writeItemsToJson:(id)json
{
    NSMutableArray *jsonArray = [NSMutableArray array];
    if (self.items.count > 0)
    {
        for (OAOsmNotesPoint *point in self.items)
        {
            NSMutableDictionary *jsonObject = [NSMutableDictionary dictionary];
            jsonObject[@"id"] = [NSNumber numberWithLongLong: [point getId]];
            jsonObject[@"text"] = [point getText];
            jsonObject[@"lat"] = [NSString stringWithFormat:@"%0.5f", [point getLatitude]];
            jsonObject[@"lon"] = [NSString stringWithFormat:@"%0.5f", [point getLongitude]];
            jsonObject[@"author"] = [point getAuthor];
            jsonObject[@"action"] = [OAOsmPoint getStringAction][[NSNumber numberWithInteger:[point getAction]]];
            [jsonArray addObject:jsonObject];
        }
        json[@"items"] = jsonArray;
    }
}

- (OASettingsItemReader *) getReader
{
    return [self getJsonReader];
}

- (OASettingsItemWriter *) getWriter
{
    return [self getJsonWriter];
}

@end

#pragma mark - OAOsmEditsSettingsItem

@interface OAOsmEditsSettingsItem()

@property (nonatomic) NSMutableArray<OAOpenStreetMapPoint *> *items;
@property (nonatomic) NSMutableArray<OAOpenStreetMapPoint *> *appliedItems;
@property (nonatomic) NSMutableArray<OAOpenStreetMapPoint *> *duplicateItems;
@property (nonatomic) NSMutableArray<OAOpenStreetMapPoint *> *existingItems;

@end

@implementation OAOsmEditsSettingsItem

@dynamic items, appliedItems, duplicateItems, existingItems;

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        OAOsmEditingPlugin *osmEditingPlugin = (OAOsmEditingPlugin *)[OAPlugin getPlugin:OAOsmEditingPlugin.class];
        if (osmEditingPlugin)
            [self setExistingItems: [NSMutableArray arrayWithArray:[[osmEditingPlugin getDBPOI] getOpenstreetmapPoints]]];
    }
    return self;
}

- (EOASettingsItemType) type
{
    return EOASettingsItemTypeOsmEdits;
}

- (void) apply
{
    NSArray<OAOpenStreetMapPoint *>*newItems = [self getNewItems];
    if (newItems.count > 0 || [self duplicateItems].count > 0)
    {
        self.appliedItems = [NSMutableArray arrayWithArray:newItems];
        
        for (OAOpenStreetMapPoint *duplicate in [self duplicateItems])
        {
            [self.appliedItems addObject: self.shouldReplace ? duplicate : [self renameItem:duplicate]];
        }
        OAOsmEditingPlugin *osmEditingPlugin = (OAOsmEditingPlugin *)[OAPlugin getPlugin:OAOsmEditingPlugin.class];
        if (osmEditingPlugin)
        {
            OAOpenstreetmapsDbHelper *db = [osmEditingPlugin getDBPOI];
            for (OAOpenStreetMapPoint *point in self.appliedItems)
            {
                [db addOpenstreetmap:point];
            }
        }
    }
}

- (BOOL) isDuplicate:(OAOpenStreetMapPoint *)item
{
    return NO;
}

- (OAOpenStreetMapPoint *) renameItem:(OAOpenStreetMapPoint *)item
{
    return item;
}

- (NSString *) getName
{
    return @"osm_edits";
}

- (NSString *) getPublicName
{
    return OALocalizedString(@"osm_edits");
}

- (BOOL) shouldReadOnCollecting
{
    return YES;
}

- (void) readItemsFromJson:(id)json error:(NSError * _Nullable *)error
{
    NSArray* itemsJson = [json mutableArrayValueForKey:@"items"];
    if (itemsJson.count == 0)
        return;
    
    for (id jsonPoint in itemsJson)
    {
        NSString *comment = jsonPoint[@"comment"];
        comment = comment.length > 0 ? comment : nil;
        NSDictionary *entityJson = jsonPoint[@"entity"];
        long long iD = [entityJson[@"id"] longLongValue];
        double lat = [entityJson[@"lat"] doubleValue];
        double lon = [entityJson[@"lon"] doubleValue];
        NSDictionary *tagMap = entityJson[@"tags"];
        NSString *action = entityJson[@"action"];
        OAEntity *entity;
        if ([entityJson[@"type"] isEqualToString: [OAEntity stringType:NODE]])
        {
            entity = [[OANode alloc] initWithId:iD latitude:lat longitude:lon];
        }
        else
        {
            entity = [[OAWay alloc] initWithId:iD latitude:lat longitude:lon];
        }
        [entity replaceTags:tagMap];
        OAOpenStreetMapPoint *point = [[OAOpenStreetMapPoint alloc] init];
        [point setComment:comment];
        [point setEntity:entity];
        [point setAction:[OAOsmPoint getActionByName:action]];
        [self.items addObject:point];
    }
}

- (void) writeItemsToJson:(id)json
{
    NSMutableArray *jsonArray = [NSMutableArray array];
    if (self.items.count > 0)
    {
        for (OAOpenStreetMapPoint *point in self.items)
        {
            NSMutableDictionary *jsonPoint = [NSMutableDictionary dictionary];
            NSMutableDictionary *jsonEntity = [NSMutableDictionary dictionary];
            jsonEntity[@"id"] = [NSNumber numberWithLongLong: [point getId]];
            jsonEntity[@"text"] = [point getTagsString];
            jsonEntity[@"lat"] = [NSString stringWithFormat:@"%0.5f", [point getLatitude]];
            jsonEntity[@"lon"] = [NSString stringWithFormat:@"%0.5f", [point getLongitude]];
            jsonEntity[@"type"] = [OAEntity stringTypeOf:[point getEntity]];
            NSDictionary *jsonTags = [NSDictionary dictionaryWithDictionary:[[point getEntity] getTags]];
            jsonEntity[@"tags"] = jsonTags;
            jsonPoint[@"comment"] = [point getComment];
            jsonEntity[@"action"] = [OAOsmPoint getStringAction][[NSNumber numberWithInteger:[point getAction]]];
            jsonPoint[@"entity"] = jsonEntity;
            [jsonArray addObject:jsonPoint];
        }
        json[@"items"] = jsonArray;
    }
}

- (OASettingsItemReader *) getReader
{
    return [self getJsonReader];
}

- (OASettingsItemWriter *) getWriter
{
    return [self getJsonWriter];
}

@end
