//
//  OABackupImporter.m
//  OsmAnd Maps
//
//  Created by Paul on 09.04.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OABackupImporter.h"
#import "OABackupHelper.h"
#import "OABackupListeners.h"
#import "OABackupDbHelper.h"
#import "OAPrepareBackupResult.h"
#import "OARemoteFile.h"
#import "OABackupInfo.h"
#import "OASettingsItem.h"
#import "OASettingsItemReader.h"
#import "OAFileSettingsItem.h"
#import "OASettingsImporter.h"
#import "OAGpxSettingsItem.h"
#import "OAOperationLog.h"

@interface OAItemFileDownloadTask : NSOperation

- (instancetype)initWithFilePath:(NSString *)filePath reader:(OASettingsItemReader *)reader;

@end

@implementation OAItemFileDownloadTask
{
    NSString *_filePath;
    OASettingsItemReader *_reader;
}

- (instancetype)initWithFilePath:(NSString *)filePath reader:(OASettingsItemReader *)reader
{
    self = [super init];
    if (self) {
        _filePath = filePath;
        _reader = reader;
    }
    return self;
}

- (void) main
{
    [self downloadItemFile:_filePath reader:_reader];
}

- (void) downloadItemFile:(NSString *)tempFilePath reader:(OASettingsItemReader *)reader
{
    OASettingsItem *item = reader.item;
    NSError *err = nil;
    [reader readFromFile:tempFilePath error:&err];
    [item applyAdditionalParams:tempFilePath];
    if (err)
        NSLog(@"Error reading downloaded item: %@", tempFilePath);
}

@end

@interface OAFileDownloadTask : NSOperation

- (instancetype)initWithFilePath:(NSString *)filePath remoteFile:(OARemoteFile *)remoteFile onDownloadFileListener:(id<OAOnDownloadFileListener>)onDownloadFileListener;

@property (nonatomic, readonly) NSString *error;

@end

@implementation OAFileDownloadTask
{
    NSString *_filePath;
    OARemoteFile *_remoteFile;
    
    __weak id<OAOnDownloadFileListener> _onDownloadFileListener;
}

- (instancetype)initWithFilePath:(NSString *)filePath remoteFile:(OARemoteFile *)remoteFile onDownloadFileListener:(id<OAOnDownloadFileListener>)onDownloadFileListener
{
    self = [super init];
    if (self) {
        _filePath = filePath;
        _remoteFile = remoteFile;
        _onDownloadFileListener = onDownloadFileListener;
    }
    return self;
}

- (void)main
{
    _error = [OABackupHelper.sharedInstance downloadFile:_filePath remoteFile:_remoteFile listener:_onDownloadFileListener];
}

@end

@implementation OACollectItemsResult

@end

@interface OABackupImporter () <OAOnDownloadFileListener>

- (void) importItemFile:(OARemoteFile *)remoteFile item:(OASettingsItem *)item forceReadData:(BOOL)forceReadData;

@end

@implementation OAItemFileImportTask
{
    OARemoteFile *_remoteFile;
    OASettingsItem *_item;
    BOOL _forceReadData;
    __weak OABackupImporter *_importer;
}

- (instancetype) initWithRemoteFile:(OARemoteFile *)remoteFile item:(OASettingsItem *)item importer:(OABackupImporter *)importer forceReadData:(BOOL)forceReadData
{
    self = [super init];
    if (self) {
        _remoteFile = remoteFile;
        _item = item;
        _forceReadData = forceReadData;
        _importer = importer;
    }
    return self;
}

- (void)main
{
    [_importer importItemFile:_remoteFile item:_item forceReadData:_forceReadData];
}

@end

@implementation OABackupImporter
{
    OABackupHelper *_backupHelper;
    id<OANetworkImportProgressListener> _listener;
    
    BOOL _cancelled;
    
    NSOperationQueue *_queue;
    
    NSString *_tmpFilesDir;
}

- (instancetype) initWithListener:(id<OANetworkImportProgressListener>)listener
{
    self = [super init];
    if (self) {
        _listener = listener;
        _backupHelper = OABackupHelper.sharedInstance;
        _queue = [[NSOperationQueue alloc] init];
        
        _tmpFilesDir = NSTemporaryDirectory();
        _tmpFilesDir = [_tmpFilesDir stringByAppendingPathComponent:@"backupTmp"];
    }
    return self;
}

- (OACollectItemsResult *) collectItems:(BOOL)readItems
{
    OACollectItemsResult *result = [[OACollectItemsResult alloc] init];
    __block NSString *error = nil;
    OAOperationLog *operationLog = [[OAOperationLog alloc] initWithOperationName:@"collectRemoteItems" debug:BACKUP_DEBUG_LOGS];
    [operationLog startOperation];
    @try {
        [_backupHelper downloadFileList:^(NSInteger status, NSString * _Nonnull message, NSArray<OARemoteFile *> * _Nonnull remoteFiles) {
            if (status == STATUS_SUCCESS)
            {
                result.remoteFiles = remoteFiles;
                @try {
                    result.items = [self getRemoteItems:remoteFiles readItems:readItems];
                } @catch (NSException *e) {
                    error = e.reason;
                }
            }
            else
            {
                error = message;
            }
        }];
    } @catch (NSException *e) {
        NSLog(@"Failed to collect items for backup");
    }
    [operationLog finishOperation];
    if (error.length > 0)
        @throw [NSException exceptionWithName:@"IllegalArgumentException" reason:error userInfo:nil];
    
    return result;
}

- (void) importItems:(NSArray<OASettingsItem *> *)items forceReadData:(BOOL)forceReadData
{
    if (items.count == 0)
        @throw [NSException exceptionWithName:@"IllegalArgumentException" reason:@"No setting items" userInfo:nil];

    NSArray<OARemoteFile *> *remoteFiles = [_backupHelper.backup getRemoteFiles:EOARemoteFilesTypeUnique].allValues;
    if (remoteFiles.count == 0)
        @throw [NSException exceptionWithName:@"IllegalArgumentException" reason:@"No remote files" userInfo:nil];
    OAOperationLog *operationLog = [[OAOperationLog alloc] initWithOperationName:@"importItems" debug:BACKUP_DEBUG_LOGS];
    [operationLog startOperation];
    NSMutableArray<OAItemFileImportTask *> *tasks = [NSMutableArray array];
    NSMutableDictionary<OARemoteFile *, OASettingsItem *> *remoteFileItems = [NSMutableDictionary dictionary];
    for (OARemoteFile *remoteFile in remoteFiles)
    {
        OASettingsItem *item = nil;
        for (OASettingsItem *settingsItem in items)
        {
            NSString *fileName = remoteFile.item != nil ? remoteFile.item.fileName : nil;
            if (fileName != nil && [settingsItem applyFileName:fileName])
            {
                item = settingsItem;
                remoteFileItems[remoteFile] = item;
                break;
            }
        }
        if (item != nil && (!item.shouldReadOnCollecting || forceReadData))
        {
            [tasks addObject:[[OAItemFileImportTask alloc] initWithRemoteFile:remoteFile item:item importer:self forceReadData:forceReadData]];
        }
    }
    [_queue addOperations:tasks waitUntilFinished:YES];

    [remoteFileItems enumerateKeysAndObjectsUsingBlock:^(OARemoteFile * _Nonnull key, OASettingsItem * _Nonnull obj, BOOL * _Nonnull stop) {
        obj.localModifiedTime = key.clienttimems / 1000;
    }];

    [operationLog finishOperation];
}

- (void) importItemFile:(OARemoteFile *)remoteFile item:(OASettingsItem *)item forceReadData:(BOOL)forceReadData
{
    OASettingsItemReader *reader = item.getReader;
    NSString *fileName = remoteFile.getTypeNamePath;
    NSString *tempFilePath = [_tmpFilesDir stringByAppendingPathComponent:fileName];
    if (reader)
    {
        NSString *error = [_backupHelper downloadFile:tempFilePath remoteFile:remoteFile listener:self];
        if (error.length == 0)
        {
            [reader readFromFile:tempFilePath error:nil];
            if (forceReadData)
                [item apply];

            [_backupHelper updateFileUploadTime:remoteFile.type fileName:remoteFile.name uploadTime:remoteFile.clienttimems];
            
            if ([item isKindOfClass:OAFileSettingsItem.class])
            {
                NSString *itemFileName = [OABackupHelper getItemFileName:item];
                if (itemFileName.pathExtension.length == 0)
                {
                    [_backupHelper updateFileUploadTime:[OASettingsItemType typeName:item.type] fileName:itemFileName
                                            uploadTime:remoteFile.clienttimems];
                }
            }
        }
        else
        {
            @throw [NSException exceptionWithName:@"IOException" reason:[NSString stringWithFormat:@"Error reading temp item file %@: %@", fileName, error] userInfo:nil];
        }
        
    }
    [item applyAdditionalParams:tempFilePath];
}

- (NSArray<OASettingsItem *> *) getRemoteItems:(NSArray<OARemoteFile *> *)remoteFiles readItems:(BOOL)readItems
{
    if (remoteFiles.count == 0)
        return @[];
    NSMutableArray<OASettingsItem *> *items = [NSMutableArray array];
    @try {
        OAOperationLog *operationLog = [[OAOperationLog alloc] initWithOperationName:@"getRemoteItems" debug:BACKUP_DEBUG_LOGS];
        [operationLog startOperation];
        NSMutableDictionary *json = [NSMutableDictionary dictionary];
        NSMutableArray *itemsJson = [NSMutableArray array];
        json[@"items"] = itemsJson;
        NSMutableDictionary<NSString *, OARemoteFile *> *remoteInfoFilesMap = [NSMutableDictionary dictionary];
        NSMutableDictionary<NSString *, OARemoteFile *> *remoteItemFilesMap = [NSMutableDictionary dictionary];
        NSMutableArray<OARemoteFile *> *remoteInfoFiles = [NSMutableArray array];
        NSMutableSet<NSString *> *remoteInfoNames = [NSMutableSet set];
        NSMutableArray<OARemoteFile *> *noInfoRemoteItemFiles = [NSMutableArray array];

        NSMutableArray<OARemoteFile *> *uniqueRemoteFiles = [NSMutableArray array];
        NSMutableOrderedSet<NSString *> *uniqueFileIds = [NSMutableOrderedSet orderedSet];
        for (OARemoteFile *rf in remoteFiles)
        {
            NSString *fileId = rf.getTypeNamePath;
            if (![uniqueFileIds containsObject:fileId] && !rf.isDeleted)
            {
                [uniqueFileIds addObject:fileId];
                [uniqueRemoteFiles addObject:rf];
            }
        }
        [operationLog log:@"build uniqueRemoteFiles"];

        NSDictionary<NSString *, OAUploadedFileInfo *> *infoMap = [OABackupDbHelper.sharedDatabase getUploadedFileInfoMap];
        OABackupInfo *backupInfo = _backupHelper.backup.backupInfo;
        NSArray<OARemoteFile *> *filesToDelete = backupInfo != nil ? backupInfo.filesToDelete : @[];
        for (OARemoteFile *remoteFile in uniqueRemoteFiles)
        {
            NSString *fileName = remoteFile.getTypeNamePath;
            if ([fileName hasSuffix:OABackupHelper.INFO_EXT])
            {
                BOOL delete = NO;
                NSString *origFileName = [remoteFile.name stringByDeletingPathExtension];
                for (OARemoteFile *file in filesToDelete)
                {
                    if ([file.name isEqualToString:origFileName])
                    {
                        delete = YES;
                        break;
                    }
                }
                OAUploadedFileInfo *fileInfo = infoMap[[NSString stringWithFormat:@"%@___%@", remoteFile.type, origFileName]];
                long uploadTime = fileInfo != nil ? fileInfo.uploadTime : 0;
                if (readItems && (uploadTime != remoteFile.clienttimems || delete))
                    remoteInfoFilesMap[[_tmpFilesDir stringByAppendingPathComponent:fileName]] = remoteFile;
                
                NSString *itemFileName = [fileName stringByDeletingPathExtension];
                [remoteInfoNames addObject:itemFileName];
                [remoteInfoFiles addObject:remoteFile];
            }
            else if (!remoteItemFilesMap[fileName])
            {
                remoteItemFilesMap[fileName] = remoteFile;
            }
        }
        [operationLog log:@"build maps"];
        
        [remoteItemFilesMap enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull itemFileName, OARemoteFile * _Nonnull remoteFile, BOOL * _Nonnull stop) {
            BOOL hasInfo = NO;
            for (NSString *remoteInfoName in remoteInfoNames)
            {
                if ([itemFileName isEqualToString:remoteInfoName] || [itemFileName hasPrefix:[remoteInfoName stringByAppendingString:@"/"]])
                {
                    hasInfo = YES;
                    break;
                }
            }
            if (!hasInfo && !remoteFile.isRecordedVoiceFile)
            {
                [noInfoRemoteItemFiles addObject:remoteFile];
            }
        }];
        
        [operationLog log:@"build noInfoRemoteItemFiles"];

        if (readItems)
            [self generateItemsJsonByDictionary:itemsJson remoteInfoFiles:remoteInfoFilesMap noInfoRemoteItemFiles:noInfoRemoteItemFiles];
        else
            [self generateItemsJson:itemsJson remoteInfoFiles:remoteInfoFiles noInfoRemoteItemFiles:noInfoRemoteItemFiles];
        
        [operationLog log:@"generateItemsJson"];

        OASettingsItemsFactory *itemsFactory = [[OASettingsItemsFactory alloc] initWithParsedJSON:json];
        
        [operationLog log:@"create setting items"];
        NSArray<OASettingsItem *> *settingsItemList = itemsFactory.getItems;
        if (settingsItemList.count == 0)
            return @[];
        
        [self updateFilesInfo:remoteItemFilesMap settingsItemList:settingsItemList];
        [items addObjectsFromArray:settingsItemList];
        [operationLog log:@"updateFilesInfo"];
        
        if (readItems)
        {
            NSMutableDictionary<OARemoteFile *, OASettingsItemReader *> *remoteFilesForRead = [NSMutableDictionary dictionary];
            for (OASettingsItem *item in settingsItemList)
            {
                if (item.shouldReadOnCollecting)
                {
                    NSArray<OARemoteFile *> *foundRemoteFiles = [self getItemRemoteFiles:item remoteFiles:remoteItemFilesMap];
                    for (OARemoteFile *remoteFile in foundRemoteFiles)
                    {
                        OASettingsItemReader *reader = item.getReader;
                        if (reader != nil)
                        {
                            remoteFilesForRead[remoteFile] = reader;
                        }
                    }
                }
            }
            NSMutableDictionary<NSString *, OARemoteFile *> *remoteFilesForDownload = [NSMutableDictionary dictionary];
            for (OARemoteFile *remoteFile in remoteFilesForRead.allKeys)
            {
                NSString *fileName = remoteFile.getTypeNamePath;
                remoteFilesForDownload[[_tmpFilesDir stringByAppendingPathComponent:fileName]] = remoteFile;
            }
            if (remoteFilesForDownload.count > 0)
                [self downloadAndReadItemFiles:remoteFilesForRead remoteFilesForDownload:remoteFilesForDownload];

            [operationLog log:@"readItems"];
        }
        [operationLog finishOperation];
    }
    @catch (NSException *e)
    {
        @throw [NSException exceptionWithName:e.name reason:e.reason userInfo:nil];
    }
    return items;
}

- (void) updateFilesInfo:(NSDictionary<NSString *, OARemoteFile *> *)remoteFiles
        settingsItemList:(NSArray<OASettingsItem *> *)settingsItemList
{
    NSMutableDictionary<NSString *, OARemoteFile *> *remoteFilesMap = [NSMutableDictionary dictionaryWithDictionary:remoteFiles];
    for (OASettingsItem *settingsItem in settingsItemList)
    {
        NSArray<OARemoteFile *> *foundRemoteFiles = [self getItemRemoteFiles:settingsItem remoteFiles:remoteFilesMap];
        for (OARemoteFile *remoteFile in foundRemoteFiles)
        {
            settingsItem.lastModifiedTime = remoteFile.clienttimems / 1000;
            remoteFile.item = settingsItem;
            if ([settingsItem isKindOfClass:OAFileSettingsItem.class])
            {
                OAFileSettingsItem *fileSettingsItem = (OAFileSettingsItem *) settingsItem;
                fileSettingsItem.size = remoteFile.filesize;
            }
        }
    }
}

- (NSArray<OARemoteFile *> *) getItemRemoteFiles:(OASettingsItem *)item remoteFiles:(NSMutableDictionary<NSString *, OARemoteFile *> *)remoteFiles
{
    NSMutableArray<OARemoteFile *> *res = [NSMutableArray array];
    NSString *fileName = item.fileName;
    if (fileName.length > 0)
    {
        if ([fileName characterAtIndex:0] != '/')
            fileName = [@"/" stringByAppendingString:fileName];
        
        if ([item isKindOfClass:OAGpxSettingsItem.class])
        {
            NSString *folder = @"/tracks";
            if ([fileName hasPrefix:folder])
                fileName = [fileName substringFromIndex:folder.length];
        }
        NSString *typeFileName = [[OASettingsItemType typeName:item.type] stringByAppendingString:fileName];
        OARemoteFile *remoteFile = remoteFiles[typeFileName];
        [remoteFiles removeObjectForKey:typeFileName];
        if (remoteFile != nil)
            [res addObject:remoteFile];
        NSMutableArray<NSString *> *toDelete = [NSMutableArray array];
        [remoteFiles enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull remoteFileName, OARemoteFile * _Nonnull obj, BOOL * _Nonnull stop) {
            if ([remoteFileName hasPrefix:[typeFileName stringByAppendingString:@"/"]])
            {
                [res addObject:obj];
                [toDelete addObject:remoteFileName];
            }
        }];
        for (NSString *key in toDelete)
            [remoteFiles removeObjectForKey:key];
    }
    return res;
}

- (void) generateItemsJson:(NSMutableArray *)itemsJson
           remoteInfoFiles:(NSArray<OARemoteFile *> *)remoteInfoFiles
     noInfoRemoteItemFiles:(NSArray<OARemoteFile *> *)noInfoRemoteItemFiles
{
    for (OARemoteFile *remoteFile in remoteInfoFiles)
    {
        NSString *fileName = remoteFile.name;
        fileName = [fileName stringByDeletingPathExtension];
        NSString *type = remoteFile.type;
        NSMutableDictionary *itemJson = [NSMutableDictionary dictionary];
        itemJson[@"type"] = type;
        if ([[OASettingsItemType typeName:EOASettingsItemTypeGpx] isEqualToString:type])
        {
            fileName = [@"tracks" stringByAppendingPathComponent:fileName];
        }
        
        if ([[OASettingsItemType typeName:EOASettingsItemTypeProfile] isEqualToString:type])
        {
            NSMutableDictionary *appMode = [NSMutableDictionary dictionary];
            NSRange rOriginal = [@"profile_" rangeOfString:fileName];
            NSString *name = fileName;
            if (NSNotFound != rOriginal.location)
                name = [fileName stringByReplacingCharactersInRange:rOriginal withString:@""];
            
            if ([name.pathExtension isEqualToString:@"json"])
                name = [name stringByDeletingPathExtension];
            appMode[@"stringKey"] = name;
            itemJson[@"appMode"] = appMode;
        }
        itemJson[@"file"] = fileName;
        [itemsJson addObject:itemJson];
    }
    [self addRemoteFilesToJson:itemsJson noInfoRemoteItemFiles:noInfoRemoteItemFiles];
}

- (void) generateItemsJsonByDictionary:(NSMutableArray *)itemsJson
           remoteInfoFiles:(NSDictionary<NSString *, OARemoteFile *> *)remoteInfoFiles
     noInfoRemoteItemFiles:(NSArray<OARemoteFile *> *)noInfoRemoteItemFiles
{
    NSMutableArray<OAFileDownloadTask *> *tasks = [NSMutableArray array];
    __weak OABackupImporter *weakSelf = self;
    [remoteInfoFiles enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, OARemoteFile * _Nonnull obj, BOOL * _Nonnull stop) {
        [tasks addObject:[[OAFileDownloadTask alloc] initWithFilePath:key remoteFile:obj onDownloadFileListener:weakSelf]];
    }];
    
    [_queue addOperations:tasks waitUntilFinished:YES];

    BOOL hasDownloadErrors = [self hasDownloadErrors:tasks];
    if (!hasDownloadErrors)
    {
        for (NSString *filePath in remoteInfoFiles.allKeys)
        {
            NSError *err = nil;
            NSData *data = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:&err];
            if (!err && data)
            {
                NSError *jsonErr = nil;
                id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonErr];
                if (json && ! jsonErr)
                    [itemsJson addObject:json];
                else
                    NSLog(@"generateItemsJson error: filePath:%@ %@", filePath, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            }
            else
            {
                @throw [NSException exceptionWithName:@"IOException" reason:[NSString stringWithFormat:@"Error reading item info: %@", filePath.lastPathComponent] userInfo:nil];
            }
        }
    }
    else
    {
        @throw [NSException exceptionWithName:@"IOException" reason:@"Error downloading items info" userInfo:nil];
    }
    [self addRemoteFilesToJson:itemsJson noInfoRemoteItemFiles:noInfoRemoteItemFiles];
}

- (void) addRemoteFilesToJson:(NSMutableArray *)itemsJson noInfoRemoteItemFiles:(NSArray<OARemoteFile *> *)noInfoRemoteItemFiles
{
    NSMutableSet<NSString *> *fileItems = [NSMutableSet set];
    for (OARemoteFile *remoteFile in noInfoRemoteItemFiles)
    {
        NSString *type = remoteFile.type;
        NSString *fileName = remoteFile.name;
        if ([type isEqualToString:[OASettingsItemType typeName:EOASettingsItemTypeFile]] && [fileName hasPrefix:[OAFileSettingsItemFileSubtype getSubtypeFolder:EOASettingsItemFileSubtypeVoice]])
        {
            // TODO: support voice
//            EOAFileSubtype subtype = [OAFileSubtype getSubtypeByFileName:fileName];
//            fileName = fileName.lastPathComponent;
//            NSString *typeName = [NSString stringWithFormat:@"%@___%@", subtype, fileName];
//            if (![fileItems containsObject:typeName])
//            {
//                [fileItems addObject:typeName];
//                NSDictionary *itemJson = @{
//                    @"type" : type,
//                    @"file" : fileName,
//                    @"subtype" : [OAFileSettingsItemFileSubtype getSubtypeName:subtype] // TODO: check what is actually passed here
//                };
//                [itemsJson addObject:itemJson];
//            }
        }
        else
        {
            [itemsJson addObject:@{
                @"type" : type,
                @"file" : fileName
            }];
        }
    }
}

- (BOOL) hasDownloadErrors:(NSArray<OAFileDownloadTask *> *)tasks
{
    BOOL hasError = NO;
    for (OAFileDownloadTask *task in tasks)
    {
        if (task.error.length > 0)
        {
            hasError = YES;
            break;
        }
    }
    return hasError;
}

- (void) downloadAndReadItemFiles:(NSDictionary<OARemoteFile *, OASettingsItemReader *> *)remoteFilesForRead
           remoteFilesForDownload:(NSDictionary<NSString *, OARemoteFile *> *)remoteFilesForDownload
{
    NSMutableArray<OAFileDownloadTask *> *fileDownloadTasks = [NSMutableArray array];
    __weak OABackupImporter *weakSelf = self;
    [remoteFilesForDownload enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, OARemoteFile * _Nonnull obj, BOOL * _Nonnull stop) {
        [fileDownloadTasks addObject:[[OAFileDownloadTask alloc] initWithFilePath:key remoteFile:obj onDownloadFileListener:weakSelf]];
    }];
    [_queue addOperations:fileDownloadTasks waitUntilFinished:YES];
    
    BOOL hasDownloadErrors = [self hasDownloadErrors:fileDownloadTasks];
    if (!hasDownloadErrors)
    {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSMutableArray<OAItemFileDownloadTask *> *itemFileDownloadTasks = [NSMutableArray array];
        [remoteFilesForDownload enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull tempFile, OARemoteFile * _Nonnull remoteFile, BOOL * _Nonnull stop) {
            if ([fileManager fileExistsAtPath:tempFile])
            {
                OASettingsItemReader *reader = remoteFilesForRead[remoteFile];
                if (reader)
                {
                    [itemFileDownloadTasks addObject:[[OAItemFileDownloadTask alloc] initWithFilePath:tempFile reader:reader]];
                }
                else
                {
                    @throw [NSException exceptionWithName:@"IOException" reason:[@"No reader for: " stringByAppendingString:tempFile.lastPathComponent] userInfo:nil];
                }
            }
            else
            {
                @throw [NSException exceptionWithName:@"IOException" reason:[@"No temp item file: " stringByAppendingString:tempFile.lastPathComponent] userInfo:nil];
            }
        }];
        [_queue addOperations:itemFileDownloadTasks waitUntilFinished:YES];
    }
    else
    {
        @throw [NSException exceptionWithName:@"IOException" reason:@"Error downloading temp item files" userInfo:nil];
    }
}

// MARK: OAOnDownloadFileListener

- (BOOL)isDownloadCancelled {
    return self.cancelled;
}

- (void)onFileDownloadDone:(NSString *)type fileName:(NSString *)fileName error:(NSString *)error {
    if (_listener)
        [_listener itemExportDone:type fileName:fileName];
}

- (void)onFileDownloadProgress:(NSString *)type fileName:(NSString *)fileName progress:(NSInteger)progress deltaWork:(NSInteger)deltaWork itemFileName:(NSString *)itemFileName {
    if (_listener)
        [_listener updateItemProgress:type fileName:fileName progress:(int)progress];
}

- (void)onFileDownloadStarted:(NSString *)type fileName:(NSString *)fileName work:(NSInteger)work itemFileName:(NSString *)itemFileName
{
    if (_listener)
        [_listener itemExportStarted:type fileName:fileName work:work];
}

@end
