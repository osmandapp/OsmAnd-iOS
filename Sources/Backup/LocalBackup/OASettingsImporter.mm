//
//  OASettingsImporter.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 07.04.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OASettingsImporter.h"
#import "OsmAndApp.h"
#import "OAObservable.h"
#import "OAAppSettings.h"
#import "OASettingsHelper.h"
#import "OAOsmNotesSettingsItem.h"
#import "OAOsmEditsSettingsItem.h"
#import "Localization.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OAMapWidgetRegistry.h"
#import "OAMapLayers.h"
#import "OARouteLayer.h"
#import "OASettingsItem.h"
#import "OAAvoidRoadsSettingsItem.h"
#import "OAMapSourcesSettingsItem.h"
#import "OAPoiUiFilterSettingsItem.h"
#import "OAQuickActionsSettingsItem.h"
#import "OAResourcesSettingsItem.h"
#import "OAFileSettingsItem.h"
#import "OADataSettingsItem.h"
#import "OAPluginSettingsItem.h"
#import "OAProfileSettingsItem.h"
#import "OAGlobalSettingsItem.h"
#import "OAFavoritesSettingsItem.h"
#import "OAExportSettingsType.h"
#import "OAFavoritesHelper.h"
#import "OAMarkersSettingsItem.h"
#import "OAHistoryMarkersSettingsItem.h"
#import "OADestination.h"
#import "OAGpxSettingsItem.h"
#import "OASearchHistorySettingsItem.h"
#import "OADownloadsItem.h"
#import "OAResourcesSettingsItem.h"
#import "OASuggestedDownloadsItem.h"
#import "OAExportAsyncTask.h"
#import "OAApplicationMode.h"
#import "OALog.h"

#include <OsmAndCore/ArchiveReader.h>
#include <OsmAndCore/ResourcesManager.h>

#define kTmpProfileFolder @"tmpProfileData"

@interface OAImportItemsAsyncTask()

@property (nonatomic) NSString *file;
@property (nonatomic) NSArray<OASettingsItem *> *items;

@property (nonatomic, copy) OAOnImportComplete onImportComplete;
@property (nonatomic, weak) id<OASettingsImportExportDelegate> delegate;

@end

#pragma mark - OASettingsImporter

@implementation OASettingsImporter
{
    OsmAndAppInstance _app;
    NSString *_tmpFilesDir;
}

- (instancetype) init
{
    self = [super init];
    if (self) {
        _app = [OsmAndApp instance];
        _tmpFilesDir = NSTemporaryDirectory();
        _tmpFilesDir = [_tmpFilesDir stringByAppendingPathComponent:kTmpProfileFolder];
    }
    return self;
}

- (NSArray<OASettingsItem *> *) collectItems:(NSString *)file
{
    return [self processItems:file items:nil];
}

- (void) importItems:(NSString *)file items:(NSArray<OASettingsItem *> *)items
{
    [self processItems:file items:items];
}

- (NSArray<OASettingsItem *> *) processItems:(NSString *)file items:(NSArray<OASettingsItem *> *)items
{
    NSFileManager *fileManager = NSFileManager.defaultManager;
    
    BOOL collecting = items == nil;
    if (collecting)
        items = [self getItemsFromJson:file];
    else if ([items count] == 0)
    {
        OALog(@"No items");
        return nil;
    }

    OsmAnd::ArchiveReader archive(QString::fromNSString(file));
    bool ok = false;
    const auto archiveItems = archive.getItems(&ok, false);
    if (!ok)
    {
        OALog(@"Error reading zip file");
        return items;
    }

    for (const auto& archiveItem : constOf(archiveItems))
    {
        if (!archiveItem.isValid())
            continue;
        
        QString filename = archiveItem.name;
        OASettingsItem *item = nil;
        for (OASettingsItem *settingsItem in items)
        {
            if ([settingsItem applyFileName:filename.toNSString()])
            {
                item = settingsItem;
                break;
            }
        }
        
        if (item && ((collecting && item.shouldReadOnCollecting) || (!collecting && !item.shouldReadOnCollecting)))
        {
            OASettingsItemReader *reader = item.getReader;
            NSError *err = nil;
            if (reader)
            {
                NSString *fileName = archiveItem.name.toNSString();
                NSString *tmpFileName = [_tmpFilesDir stringByAppendingString:[@"/" stringByAppendingString:fileName]];
                BOOL isDir = [fileName hasSuffix:@"/"];
                if (isDir)
                {
                    // Collect all items for this directory
                    for (const auto& archiveItem : constOf(archiveItems))
                    {
                        NSString *itemName = archiveItem.name.toNSString();
                        if ([itemName hasPrefix:fileName] && ![itemName isEqualToString:fileName])
                        {
                            if (!archive.extractItemToFile(archiveItem.name, QString::fromNSString([_tmpFilesDir stringByAppendingPathComponent:itemName])))
                            {
                                OALog(@"Error processing directory item");
                                continue;
                            }
                        }
                    }
                }
                else
                {
                    if (!archive.extractItemToFile(archiveItem.name, QString::fromNSString(tmpFileName)))
                    {
                        OALog(@"Error processing items");
                        continue;
                    }
                }
                [reader readFromFile:tmpFileName error:&err];
                [item applyAdditionalParams:tmpFileName];
            }
            
            if (err)
                [item.warnings addObject:[NSString stringWithFormat:OALocalizedString(@"err_profile_import"), item.name]];
        }
    }
    
    [fileManager removeItemAtPath:_tmpFilesDir error:nil];
    
    return items;
}

- (NSMutableArray<OASettingsItem *> *) getItemsFromJson:(NSString *)file
{
    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSMutableArray<OASettingsItem *> *items = [NSMutableArray new];
    OsmAnd::ArchiveReader archive(QString::fromNSString(file));
    
    bool ok = false;
    const auto archiveItems = archive.getItems(&ok, false);
    if (!ok)
    {
        OALog(@"Error reading zip file");
        return items;
    }

    for (const auto& archiveItem : constOf(archiveItems))
    {
        if (!archiveItem.isValid())
            continue;
        
        if (archiveItem.name == QStringLiteral("items.json"))
        {
            auto itemsJsonData = archive.extractItemToArray(archiveItem.name);
            if (itemsJsonData.isEmpty())
            {
                [fileManager removeItemAtPath:_tmpFilesDir error:nil];
                OALog(@"Error reading or empty items.json");
                return items;
            }
            OASettingsItemsFactory *factory = [[OASettingsItemsFactory alloc] initWithJSONData:itemsJsonData.toRawNSData()];
            [items addObjectsFromArray:factory.getItems];
            break;
        }
    }
    return items;
}

@end


#pragma mark - OASettingsItemsFactory

@implementation OASettingsItemsFactory
{
    NSMutableArray<OASettingsItem *> *_items;
    OsmAndAppInstance _app;
}

- (instancetype) initWithJSON:(NSString *)jsonStr
{
    self = [super init];
    if (self) {
        [self commonItit];
        [self collectItems:jsonStr];
    }
    return self;
}

- (instancetype) initWithJSONData:(NSData *)jsonUtf8Data;
{
    self = [super init];
    if (self) {
        [self commonItit];
        [self collectItemsFromData:jsonUtf8Data];
    }
    return self;
}

- (instancetype) initWithParsedJSON:(NSDictionary *)json
{
    self = [super init];
    if (self) {
        [self commonItit];
        [self collectItemsFromDictioanry:json];
    }
    return self;
}

- (void) commonItit
{
    _app = [OsmAndApp instance];
    _items = [NSMutableArray new];
}

- (void)collectItemsFromDictioanry:(NSDictionary *)json {
    NSArray* itemsJson = json[@"items"];
    NSInteger version = json[@"version"] ? [json[@"version"] integerValue] : kVersion;
    if (version > kVersion)
    {
        OALog(@"Error: unsupported version");
        return;
    }
    [[OASettingsHelper sharedInstance] setCurrentBackupVersion:version];

    NSMutableDictionary<NSString *, NSMutableArray<OASettingsItem *> *> *pluginItems = [NSMutableDictionary new];
    for (NSDictionary* itemJSON in itemsJson)
    {
        //TODO: Remove after complete implementation of the classes
        if (![itemJSON[@"type"] isEqualToString:@"DATA"])
        {
            OASettingsItem *item = [self createItem:itemJSON];
            if (!item)
                continue;

            [_items addObject:item];
            NSString *pluginId = item.pluginId;
            if (pluginId != nil && item.type != EOASettingsItemTypePlugin)
            {
                NSMutableArray<OASettingsItem *> *items = pluginItems[pluginId];
                if (items != nil)
                {
                    [items addObject:item];
                }
                else {
                    items = [NSMutableArray new];
                    [items addObject:item];
                    pluginItems[pluginId] = items;
                }
            }
        }
    }
    if ([_items count] == 0)
    {
        OALog(@"No items");
        return;
    }
    for (OASettingsItem *item in _items)
    {
        if ([item isKindOfClass:OAPluginSettingsItem.class])
        {
            OAPluginSettingsItem *pluginSettingsItem = (OAPluginSettingsItem *) item;
            NSMutableArray<OASettingsItem *> *pluginDependentItems = pluginItems[pluginSettingsItem.name];
            if (pluginDependentItems.count > 0)
                pluginSettingsItem.pluginDependentItems = [pluginSettingsItem.pluginDependentItems arrayByAddingObjectsFromArray:pluginDependentItems];
        }
    }
}

- (void) collectItems:(NSString *)jsonStr
{
    NSData* jsonData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
    [self collectItemsFromData:jsonData];
}

- (void) collectItemsFromData:(NSData *)jsonUtf8Data
{
    NSError *jsonError;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:jsonUtf8Data options:kNilOptions error:&jsonError];
    if (jsonError)
    {
        OALog(@"Error reading json");
        return;
    }

    [self collectItemsFromDictioanry:json];
}

- (NSArray<OASettingsItem *> *) getItems
{
    return _items;
}

- (OASettingsItem *) getItemByFileName:(NSString*)fileName
{
    for (OASettingsItem * item in _items)
    {
        if ([item.fileName isEqualToString:fileName])
            return item;
    }
    return nil;
}

- (OASettingsItem *) createItem:(NSDictionary *)json
{
    OASettingsItem * item = nil;
    NSError *parseError;
    EOASettingsItemType type = [OASettingsItem parseItemType:json error:&parseError];
    if (parseError)
        return nil;
    
    NSError *error;
    // TODO: import other item types later and clean up
    switch (type)
    {
        case EOASettingsItemTypeGlobal:
            item = [[OAGlobalSettingsItem alloc] initWithJson:json error:&error];
            break;
        case EOASettingsItemTypeProfile:
            item = [[OAProfileSettingsItem alloc] initWithJson:json error:&error];
            break;
        case EOASettingsItemTypePlugin:
            item = [[OAPluginSettingsItem alloc] initWithJson:json error:&error];
            break;
        case EOASettingsItemTypeData:
            item = [[OADataSettingsItem alloc] initWithJson:json error:&error];
            break;
        case EOASettingsItemTypeFile:
            item = [[OAFileSettingsItem alloc] initWithJson:json error:&error];
            break;
        case EOASettingsItemTypeQuickActions:
            item = [[OAQuickActionsSettingsItem alloc] initWithJson:json error:&error];
            break;
        case EOASettingsItemTypePoiUIFilters:
            item = [[OAPoiUiFilterSettingsItem alloc] initWithJson:json error:&error];
            break;
        case EOASettingsItemTypeMapSources:
            item = [[OAMapSourcesSettingsItem alloc] initWithJson:json error:&error];
            break;
        case EOASettingsItemTypeAvoidRoads:
            item = [[OAAvoidRoadsSettingsItem alloc] initWithJson:json error:&error];
            break;
        case EOASettingsItemTypeSuggestedDownloads:
            item = [[OASuggestedDownloadsItem alloc] initWithJson:json error:&error];
            break;
        case EOASettingsItemTypeFavorites:
            item = [[OAFavoritesSettingsItem alloc] initWithJson:json error:&error];
            break;
        case EOASettingsItemTypeOsmNotes:
            item = [[OAOsmNotesSettingsItem alloc] initWithJson:json error:&error];
            break;
        case EOASettingsItemTypeOsmEdits:
            item = [[OAOsmEditsSettingsItem alloc] initWithJson:json error:&error];
            break;
        case EOASettingsItemTypeActiveMarkers:
            item = [[OAMarkersSettingsItem alloc] initWithJson:json error:&error];
            break;
        case EOASettingsItemTypeHistoryMarkers:
            item = [[OAHistoryMarkersSettingsItem alloc] initWithJson:json error:&error];
            break;
        case EOASettingsItemTypeGpx:
            item = [[OAGpxSettingsItem alloc] initWithJson:json error:&error];
            break;
        case EOASettingsItemTypeSearchHistory:
            item = [[OASearchHistorySettingsItem alloc] initWithJson:json error:&error];
            break;
        case EOASettingsItemTypeNavigationHistory:
            item = [[OASearchHistorySettingsItem alloc] initWithJson:json error:&error fromNavigation:YES];
            break;
        case EOASettingsItemTypeDownloads:
            item = [[OADownloadsItem alloc] initWithJson:json error:&error];
            break;
        case EOASettingsItemTypeResources:
            item = [[OAResourcesSettingsItem alloc] initWithJson:json error:&error];
            break;
        default:
            item = nil;
            break;
    }
    if (error)
        return nil;

    return item;
}

@end

#pragma mark - OAImportAsyncTask

@interface OAImportAsyncTask()

@property (nonatomic) NSString *filePath;
@property (nonatomic) NSString *latestChanges;
@property (nonatomic, assign) NSInteger version;
@property (nonatomic, assign) EOAImportType importType;
@property (nonatomic) NSArray<OASettingsItem *> *items;
@property (nonatomic) NSArray<OASettingsItem *> *selectedItems;
@property (nonatomic) NSArray<OASettingsItem *> *duplicates;

@end

@implementation OAImportAsyncTask
{
    BOOL _importDone;
    OASettingsHelper *_settingsHelper;
    OASettingsImporter *_importer;
}

- (instancetype) initWithFile:(NSString *)filePath latestChanges:(NSString *)latestChanges version:(NSInteger)version
{
    self = [super init];
    if (self)
    {
        _settingsHelper = [OASettingsHelper sharedInstance];
        _filePath = filePath;
        _latestChanges = latestChanges;
        _version = version;
        _importer = [[OASettingsImporter alloc] init];
        _importType = EOAImportTypeCollect;
    }
    return self;
}

- (instancetype) initWithFile:(NSString *)filePath items:(NSArray<OASettingsItem *> *)items latestChanges:(NSString *)latestChanges version:(NSInteger)version
{
    self = [super init];
    if (self)
    {
        _settingsHelper = [OASettingsHelper sharedInstance];
        _filePath = filePath;
        _items = items;
        _latestChanges = latestChanges;
        _version = version;
        _importer = [[OASettingsImporter alloc] init];
        _importType = EOAImportTypeImport;
    }
    return self;
}

- (instancetype) initWithFile:(NSString *)filePath items:(NSArray<OASettingsItem *> *)items selectedItems:(NSArray<OASettingsItem *> *)selectedItems
 {
     self = [super init];
     if (self)
     {
         _settingsHelper = [OASettingsHelper sharedInstance];
         _filePath = filePath;
         _items = items;
         _selectedItems = selectedItems;
         _importer = [[OASettingsImporter alloc] init];
         _importType = EOAImportTypeCheckDuplicates;
     }
     return self;
 }

- (void) execute
{
    [self executeWithCompletionBlock:nil];
}

- (void) executeWithCompletionBlock:(void(^)(BOOL succeed, NSArray<OASettingsItem *> *items))onComplete
{
    [self onPreExecute];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray<OASettingsItem *> *items = [self doInBackground];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self onPostExecute:items];
            if (onComplete)
                onComplete(YES, _items);
        });
    });
}

- (void) onPreExecute
{
    OAImportAsyncTask* importTask = _settingsHelper.importTask;
    if (importTask != nil && ![importTask isImportDone] && (self.delegate || self.onImportComplete))
    {
        if (self.delegate)
            [self.delegate onSettingsImportFinished:NO items:_items];
        if (self.onImportComplete)
            self.onImportComplete(NO, _items);
    }
    
    _settingsHelper.importTask = self;
}
 
- (NSArray<OASettingsItem *> *) doInBackground
{
    switch (_importType) {
        case EOAImportTypeCollect:
            @try {
                return [_importer collectItems:_filePath];
            } @catch (NSException *exception) {
                OALog(@"Failed to collect items from: %@ %@", _filePath, exception);
            }
            break;
        case EOAImportTypeCheckDuplicates:
            _duplicates = [self getDuplicatesData:_selectedItems];
            return _selectedItems;
        case EOAImportTypeImport:
            return _items;
    }
    return nil;
}

- (void) onPostExecute:(NSArray<OASettingsItem *> *)items
{
    if (items != nil && _importType != EOAImportTypeCheckDuplicates)
        _items = items;
    else
        _selectedItems = items;
    switch (_importType) {
        case EOAImportTypeCollect:
            _importDone = YES;
            if (_delegate)
                [_delegate onSettingsCollectFinished:YES empty:_items.count == 0 items:_items];
            if (self.onSettingsCollected)
                self.onSettingsCollected(YES, NO, _items);
            break;
        case EOAImportTypeCheckDuplicates:
            _importDone = YES;
            if (_delegate)
                [_delegate onDuplicatesChecked:_duplicates items:_selectedItems];
            if (self.onDuplicatesChecked)
                self.onDuplicatesChecked(_duplicates, _selectedItems);
            break;
        case EOAImportTypeImport:
            if (items != nil && items.count > 0)
            {
                for (OASettingsItem *item in items)
                    [item apply];
                OAImportItemsAsyncTask *task = [[OAImportItemsAsyncTask alloc] initWithFile:_filePath items:_items];
                task.delegate = _delegate;
                task.onImportComplete = self.onImportComplete;
                [task execute];
            }
            break;
        default:
            break;
    }
}

- (NSArray<OASettingsItem *> *) getItems
{
    return _items;
}

- (NSString *) getFile
{
    return _filePath;
}

- (EOAImportType) getImportType
{
    return _importType;
}

- (BOOL) isImportDone
{
    return _importDone;
}
 
- (NSArray<OASettingsItem *> *) getDuplicates
{
    return _duplicates;
}
 
- (NSArray<OASettingsItem *> *) getSelectedItems
{
    return _selectedItems;
}
 
- (NSArray*) getDuplicatesData:(NSMutableArray<OASettingsItem *> *)items
{
    NSMutableArray* duplicateItems = [NSMutableArray new];
    for (OASettingsItem *item in items)
    {
        if ([item isKindOfClass:OAProfileSettingsItem.class]) {
            if ([item exists])
                [duplicateItems addObject:((OAProfileSettingsItem *)item).modeBean];
        }
        else if ([item isKindOfClass:OACollectionSettingsItem.class])
        {
            OACollectionSettingsItem *settingsItem = (OACollectionSettingsItem *) item;
            NSArray *duplicates = [settingsItem processDuplicateItems];
            if (duplicates.count > 0 && settingsItem.shouldShowDuplicates)
                [duplicateItems addObjectsFromArray:duplicates];
        }
        else if ([item isKindOfClass:OAFileSettingsItem.class])
        {
            if ([item exists])
                [duplicateItems addObject:item.fileName];
        }
        else if ([item isKindOfClass:OAQuickActionsSettingsItem.class] && [item exists])
        {
            [duplicateItems addObject:[((OAQuickActionsSettingsItem *) item) getButtonState]];
        }
    }
    return duplicateItems;
}

@end

#pragma mark - OAImportItemsAsyncTask

@implementation OAImportItemsAsyncTask
{
    OASettingsHelper *_settingsHelper;
    OASettingsImporter *_importer;
}

- (instancetype) initWithFile:(NSString *)file items:(NSArray<OASettingsItem *> *)items
{
    self = [super init];
    if (self) {
        _importer = [[OASettingsImporter alloc] init];
        _settingsHelper = [OASettingsHelper sharedInstance];
        _file = file;
        _items = items;
    }
    return self;
}

- (void) execute
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self doInBackground];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self onPostExecute:YES];
        });
    });
}

- (BOOL) doInBackground
{
    [_importer importItems:_file items:_items];
    
    NSString *tempDir = [[OsmAndApp instance].documentsPath stringByAppendingPathComponent:@"backup"];
    [NSFileManager.defaultManager createDirectoryAtPath:tempDir withIntermediateDirectories:YES attributes:nil error:nil];

    for (OASettingsItem *item in _items)
    {
        if ([item isKindOfClass:OAProfileSettingsItem.class])
        {
            NSString *backupPath = [[tempDir stringByAppendingPathComponent:((OAProfileSettingsItem *)item).appMode.stringKey] stringByAppendingPathExtension:@"osf"];
            if ([[NSFileManager defaultManager] fileExistsAtPath:backupPath])
            {
                [[NSFileManager defaultManager] removeItemAtPath:backupPath error:nil];
            }
            OAExportAsyncTask *backupTask = [[OAExportAsyncTask alloc] initWithFile:backupPath items:@[item] exportItemFiles:YES extensionsFilter:nil];
            [backupTask execute];
        }
    }
    return YES;
}
 
- (void)updateDataIfNeeded
{
    OsmAndAppInstance app = OsmAndApp.instance;
    BOOL updateRoutingFiles = NO;
    BOOL updateResources = NO;
    BOOL updateColorPalette = NO;
    for (OASettingsItem *item in _items)
    {
        if ([item isKindOfClass:OAFileSettingsItem.class])
        {
            OAFileSettingsItem *fileItem = (OAFileSettingsItem *)item;
            updateResources = updateResources || fileItem.subtype != EOASettingsItemFileSubtypeUnknown;
            updateRoutingFiles = updateRoutingFiles || fileItem.subtype == EOASettingsItemFileSubtypeRoutingConfig;
            updateColorPalette = updateColorPalette || fileItem.subtype == EOASettingsItemFileSubtypeColorPalette;
            
            if (updateResources && updateRoutingFiles && updateColorPalette)
                break;
        }
    }

    if (updateColorPalette)
    {
        [app.updateGpxTracksOnMapObservable notifyEvent];
    }
    if (updateRoutingFiles)
        [app loadRoutingFiles];
    if (updateResources)
    {
        app.resourcesManager->rescanUnmanagedStoragePaths(true);
        [app.localResourcesChangedObservable notifyEvent];
    }
    [[OARootViewController instance].mapPanel recreateAllControls];
}

- (void) onPostExecute:(BOOL)success
{
    [self updateDataIfNeeded];
    
    if (_delegate)
        [_delegate onSettingsImportFinished:success items:_items];
    if (self.onImportComplete)
        self.onImportComplete(success, _items);
}

@end
