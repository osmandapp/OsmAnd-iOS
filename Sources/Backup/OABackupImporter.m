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
#import "OAPrepareBackupResult.h"
#import "OARemoteFile.h"
#import "OASettingsItem.h"
#import "OAFileSettingsItem.h"

@implementation OACollectItemsResult

@end

@interface OABackupImporter () <OAOnDownloadFileListListener, OAOnDownloadFileListener>

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
    BOOL _readItems;
    
    NSMutableString *_error;
    
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
//    OACollectItemsResult *result = [[OACollectItemsResult alloc] init];
//    _error = [NSMutableString string];
//    _readItems = readItems;
////    OperationLog operationLog = new OperationLog("collectRemoteItems", BackupHelper.DEBUG);
////    operationLog.startOperation();
//    @try {
//        [_backupHelper downloadFileList:self];
//    } @catch (NSException *e) {
//        NSLog(@"Failed to collect items for backup");
//    }
////    operationLog.finishOperation();
//    if (_error.length > 0)
//        @throw [NSException exceptionWithName:@"IllegalArgumentException" reason:_error userInfo:nil];
//    
//    return result;
}

- (void) importItems:(NSArray<OASettingsItem *> *)items forceReadData:(BOOL)forceReadData
{
    if (items.count == 0)
        @throw [NSException exceptionWithName:@"IllegalArgumentException" reason:@"No setting items" userInfo:nil];

    NSArray<OARemoteFile *> *remoteFiles = [_backupHelper.backup getRemoteFiles:EOARemoteFilesTypeUnique].allValues;
    if (remoteFiles.count == 0)
        @throw [NSException exceptionWithName:@"IllegalArgumentException" reason:@"No remote files" userInfo:nil];
//    OperationLog operationLog = new OperationLog("importItems", BackupHelper.DEBUG);
//    operationLog.startOperation();
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
        obj.localModifiedTime = key.clienttimems;
    }];

//    operationLog.finishOperation();
}

- (void) importItemFile:(OARemoteFile *)remoteFile item:(OASettingsItem *)item forceReadData:(BOOL)forceReadData
{
//    NSString *fileName = remoteFile.getTypeNamePath;
//    NSString *tempFilePath = [_tmpFilesDir stringByAppendingPathComponent:fileName];
//    NSString *itemFileName = [OABackupHelper getItemFileName:item];
//    NSString *error = [_backupHelper downloadFile:tempFilePath remoteFile:remoteFile listener:self itemFileName:itemFileName];
//    if (error.length == 0)
//    {
//        if (forceReadData)
//            [item apply];
//
//        [_backupHelper updateFileUploadTime:remoteFile.type name:remoteFile.name clienttimems:remoteFile.clienttimems];
//        if ([item isKindOfClass:OAFileSettingsItem.class])
//        {
//            NSString *itemFileName = [OABackupHelper getFileItemName:(OAFileSettingsItem *)item];
//            if (app.getAppPath(itemFileName).isDirectory()) {
//                backupHelper.updateFileUploadTime(item.getType().name(), itemFileName,
//                                                  remoteFile.getClienttimems());
//            }
//        }
//    } else {
//        throw new IOException("Error reading temp item file " + fileName + ": " + error);
//    }
//    item.applyAdditionalParams(reader);
}

//private List<SettingsItem> getRemoteItems(@NonNull List<RemoteFile> remoteFiles, boolean readItems) throws IllegalArgumentException, IOException {
//    if (remoteFiles.isEmpty()) {
//        return Collections.emptyList();
//    }
//    List<SettingsItem> items = new ArrayList<>();
//    try {
//        OperationLog operationLog = new OperationLog("getRemoteItems", BackupHelper.DEBUG);
//        operationLog.startOperation();
//        JSONObject json = new JSONObject();
//        JSONArray itemsJson = new JSONArray();
//        json.put("items", itemsJson);
//        Map<File, RemoteFile> remoteInfoFilesMap = new HashMap<>();
//        Map<String, RemoteFile> remoteItemFilesMap = new HashMap<>();
//        List<RemoteFile> remoteInfoFiles = new ArrayList<>();
//        Set<String> remoteInfoNames = new HashSet<>();
//        List<RemoteFile> noInfoRemoteItemFiles = new ArrayList<>();
//        OsmandApplication app = backupHelper.getApp();
//        File tempDir = FileUtils.getTempDir(app);
//
//        List<RemoteFile> uniqueRemoteFiles = new ArrayList<>();
//        Set<String> uniqueFileIds = new TreeSet<>();
//        for (RemoteFile rf : remoteFiles) {
//            String fileId = rf.getTypeNamePath();
//            if (uniqueFileIds.add(fileId) && !rf.isDeleted()) {
//                uniqueRemoteFiles.add(rf);
//            }
//        }
//        operationLog.log("build uniqueRemoteFiles");
//
//        Map<String, UploadedFileInfo> infoMap = backupHelper.getDbHelper().getUploadedFileInfoMap();
//        BackupInfo backupInfo = backupHelper.getBackup().getBackupInfo();
//        List<RemoteFile> filesToDelete = backupInfo != null ? backupInfo.filesToDelete : Collections.emptyList();
//        for (RemoteFile remoteFile : uniqueRemoteFiles) {
//            String fileName = remoteFile.getTypeNamePath();
//            if (fileName.endsWith(INFO_EXT)) {
//                boolean delete = false;
//                String origFileName = remoteFile.getName().substring(0, remoteFile.getName().length() - INFO_EXT.length());
//                for (RemoteFile file : filesToDelete) {
//                    if (file.getName().equals(origFileName)) {
//                        delete = true;
//                        break;
//                    }
//                }
//                UploadedFileInfo fileInfo = infoMap.get(remoteFile.getType() + "___" + origFileName);
//                long uploadTime = fileInfo != null ? fileInfo.getUploadTime() : 0;
//                if (readItems && (uploadTime != remoteFile.getClienttimems() || delete)) {
//                    remoteInfoFilesMap.put(new File(tempDir, fileName), remoteFile);
//                }
//                String itemFileName = fileName.substring(0, fileName.length() - INFO_EXT.length());
//                remoteInfoNames.add(itemFileName);
//                remoteInfoFiles.add(remoteFile);
//            } else if (!remoteItemFilesMap.containsKey(fileName)) {
//                remoteItemFilesMap.put(fileName, remoteFile);
//            }
//        }
//        operationLog.log("build maps");
//
//        for (Entry<String, RemoteFile> remoteFileEntry : remoteItemFilesMap.entrySet()) {
//            String itemFileName = remoteFileEntry.getKey();
//            RemoteFile remoteFile = remoteFileEntry.getValue();
//            boolean hasInfo = false;
//            for (String remoteInfoName : remoteInfoNames) {
//                if (itemFileName.equals(remoteInfoName) || itemFileName.startsWith(remoteInfoName + "/")) {
//                    hasInfo = true;
//                    break;
//                }
//            }
//            if (!hasInfo && !remoteFile.isRecordedVoiceFile()) {
//                noInfoRemoteItemFiles.add(remoteFile);
//            }
//        }
//        operationLog.log("build noInfoRemoteItemFiles");
//
//        if (readItems) {
//            generateItemsJson(itemsJson, remoteInfoFilesMap, noInfoRemoteItemFiles);
//        } else {
//            generateItemsJson(itemsJson, remoteInfoFiles, noInfoRemoteItemFiles);
//        }
//        operationLog.log("generateItemsJson");
//
//        SettingsItemsFactory itemsFactory = new SettingsItemsFactory(app, json);
//        operationLog.log("create setting items");
//        List<SettingsItem> settingsItemList = itemsFactory.getItems();
//        if (settingsItemList.isEmpty()) {
//            return Collections.emptyList();
//        }
//        updateFilesInfo(remoteItemFilesMap, settingsItemList);
//        items.addAll(settingsItemList);
//        operationLog.log("updateFilesInfo");
//
//        if (readItems) {
//            Map<RemoteFile, SettingsItemReader<? extends SettingsItem>> remoteFilesForRead = new HashMap<>();
//            for (SettingsItem item : settingsItemList) {
//                if (item.shouldReadOnCollecting()) {
//                    List<RemoteFile> foundRemoteFiles = getItemRemoteFiles(item, remoteItemFilesMap);
//                    for (RemoteFile remoteFile : foundRemoteFiles) {
//                        SettingsItemReader<? extends SettingsItem> reader = item.getReader();
//                        if (reader != null) {
//                            remoteFilesForRead.put(remoteFile, reader);
//                        }
//                    }
//                }
//            }
//            Map<File, RemoteFile> remoteFilesForDownload = new HashMap<>();
//            for (RemoteFile remoteFile : remoteFilesForRead.keySet()) {
//                String fileName = remoteFile.getTypeNamePath();
//                remoteFilesForDownload.put(new File(tempDir, fileName), remoteFile);
//            }
//            if (!remoteFilesForDownload.isEmpty()) {
//                downloadAndReadItemFiles(remoteFilesForRead, remoteFilesForDownload);
//            }
//            operationLog.log("readItems");
//        }
//        operationLog.finishOperation();
//    } catch (IllegalArgumentException e) {
//        throw new IllegalArgumentException("Error reading items", e);
//    } catch (JSONException e) {
//        throw new IllegalArgumentException("Error parsing items", e);
//    } catch (IOException e) {
//        throw new IOException(e);
//    }
//    return items;
//}
//
//@NonNull
//private List<RemoteFile> getItemRemoteFiles(@NonNull SettingsItem item, @NonNull Map<String, RemoteFile> remoteFiles) {
//    List<RemoteFile> res = new ArrayList<>();
//    String fileName = item.getFileName();
//    if (!Algorithms.isEmpty(fileName)) {
//        if (fileName.charAt(0) != '/') {
//            fileName = "/" + fileName;
//        }
//        if (item instanceof GpxSettingsItem) {
//            GpxSettingsItem gpxItem = (GpxSettingsItem) item;
//            String folder = gpxItem.getSubtype().getSubtypeFolder();
//            if (!Algorithms.isEmpty(folder) && folder.charAt(0) != '/') {
//                folder = "/" + folder;
//            }
//            if (fileName.startsWith(folder)) {
//                fileName = fileName.substring(folder.length() - 1);
//            }
//        }
//        String typeFileName = item.getType().name() + fileName;
//        RemoteFile remoteFile = remoteFiles.remove(typeFileName);
//        if (remoteFile != null) {
//            res.add(remoteFile);
//        }
//        Iterator<Entry<String, RemoteFile>> it = remoteFiles.entrySet().iterator();
//        while (it.hasNext()) {
//            Entry<String, RemoteFile> fileEntry = it.next();
//            String remoteFileName = fileEntry.getKey();
//            if (remoteFileName.startsWith(typeFileName + "/")) {
//                res.add(fileEntry.getValue());
//                it.remove();
//            }
//        }
//    }
//    return res;
//}
//
//private void generateItemsJson(@NonNull JSONArray itemsJson,
//                               @NonNull List<RemoteFile> remoteInfoFiles,
//                               @NonNull List<RemoteFile> noInfoRemoteItemFiles) throws JSONException {
//    for (RemoteFile remoteFile : remoteInfoFiles) {
//        String fileName = remoteFile.getName();
//        fileName = fileName.substring(0, fileName.length() - INFO_EXT.length());
//        String type = remoteFile.getType();
//        JSONObject itemJson = new JSONObject();
//        itemJson.put("type", type);
//        if (SettingsItemType.GPX.name().equals(type)) {
//            fileName = FileSubtype.GPX.getSubtypeFolder() + fileName;
//        }
//        if (SettingsItemType.PROFILE.name().equals(type)) {
//            JSONObject appMode = new JSONObject();
//            String name = fileName.replaceFirst("profile_", "");
//            if (name.endsWith(".json")) {
//                name = name.substring(0, name.length() - 5);
//            }
//            appMode.put("stringKey", name);
//            itemJson.put("appMode", appMode);
//        }
//        itemJson.put("file", fileName);
//        itemsJson.put(itemJson);
//    }
//    addRemoteFilesToJson(itemsJson, noInfoRemoteItemFiles);
//}
//
//private void generateItemsJson(@NonNull JSONArray itemsJson,
//                               @NonNull Map<File, RemoteFile> remoteInfoFiles,
//                               @NonNull List<RemoteFile> noInfoRemoteItemFiles) throws JSONException, IOException {
//    List<FileDownloadTask> tasks = new ArrayList<>();
//    for (Entry<File, RemoteFile> fileEntry : remoteInfoFiles.entrySet()) {
//        tasks.add(new FileDownloadTask(fileEntry.getKey(), fileEntry.getValue()));
//    }
//    ThreadPoolTaskExecutor<FileDownloadTask> executor = createExecutor();
//    executor.run(tasks);
//
//    boolean hasDownloadErrors = hasDownloadErrors(tasks);
//    if (!hasDownloadErrors) {
//        for (File file : remoteInfoFiles.keySet()) {
//            String jsonStr = Algorithms.getFileAsString(file);
//            if (!Algorithms.isEmpty(jsonStr)) {
//                itemsJson.put(new JSONObject(jsonStr));
//            } else {
//                throw new IOException("Error reading item info: " + file.getName());
//            }
//        }
//    } else {
//        throw new IOException("Error downloading items info");
//    }
//    addRemoteFilesToJson(itemsJson, noInfoRemoteItemFiles);
//}
//
//private void addRemoteFilesToJson(@NonNull JSONArray itemsJson, @NonNull List<RemoteFile> noInfoRemoteItemFiles) throws JSONException {
//    Set<String> fileItems = new HashSet<>();
//    for (RemoteFile remoteFile : noInfoRemoteItemFiles) {
//        String type = remoteFile.getType();
//        String fileName = remoteFile.getName();
//        if (type.equals(SettingsItemType.FILE.name()) && fileName.startsWith(FileSubtype.VOICE.getSubtypeFolder())) {
//            FileSubtype subtype = FileSubtype.getSubtypeByFileName(fileName);
//            int lastSeparatorIndex = fileName.lastIndexOf('/');
//            if (lastSeparatorIndex > 0) {
//                fileName = fileName.substring(0, lastSeparatorIndex);
//            }
//            String typeName = subtype + "___" + fileName;
//            if (!fileItems.contains(typeName)) {
//                fileItems.add(typeName);
//                JSONObject itemJson = new JSONObject();
//                itemJson.put("type", type);
//                itemJson.put("file", fileName);
//                itemJson.put("subtype", subtype);
//                itemsJson.put(itemJson);
//            }
//        } else {
//            JSONObject itemJson = new JSONObject();
//            itemJson.put("type", type);
//            itemJson.put("file", fileName);
//            itemsJson.put(itemJson);
//        }
//    }
//}
//
//private void downloadAndReadItemFiles(@NonNull Map<RemoteFile, SettingsItemReader<? extends SettingsItem>> remoteFilesForRead,
//                                      @NonNull Map<File, RemoteFile> remoteFilesForDownload) throws IOException {
//    OsmandApplication app = backupHelper.getApp();
//    List<FileDownloadTask> fileDownloadTasks = new ArrayList<>();
//    for (Entry<File, RemoteFile> fileEntry : remoteFilesForDownload.entrySet()) {
//        fileDownloadTasks.add(new FileDownloadTask(fileEntry.getKey(), fileEntry.getValue()));
//    }
//    ThreadPoolTaskExecutor<FileDownloadTask> filesDownloadExecutor = createExecutor();
//    filesDownloadExecutor.run(fileDownloadTasks);
//
//    boolean hasDownloadErrors = hasDownloadErrors(fileDownloadTasks);
//    if (!hasDownloadErrors) {
//        List<ItemFileDownloadTask> itemFileDownloadTasks = new ArrayList<>();
//        for (Entry<File, RemoteFile> entry : remoteFilesForDownload.entrySet()) {
//            File tempFile = entry.getKey();
//            RemoteFile remoteFile = entry.getValue();
//            if (tempFile.exists()) {
//                SettingsItemReader<? extends SettingsItem> reader = remoteFilesForRead.get(remoteFile);
//                if (reader != null) {
//                    itemFileDownloadTasks.add(new ItemFileDownloadTask(app, tempFile, reader));
//                } else {
//                    throw new IOException("No reader for: " + tempFile.getName());
//                }
//            } else {
//                throw new IOException("No temp item file: " + tempFile.getName());
//            }
//        }
//        ThreadPoolTaskExecutor<ItemFileDownloadTask> itemFilesDownloadExecutor = createExecutor();
//        itemFilesDownloadExecutor.run(itemFileDownloadTasks);
//    } else {
//        throw new IOException("Error downloading temp item files");
//    }
//}
//
//private boolean hasDownloadErrors(@NonNull List<FileDownloadTask> tasks) {
//    boolean hasError = false;
//    for (FileDownloadTask task : tasks) {
//        if (!Algorithms.isEmpty(task.error)) {
//            hasError = true;
//            break;
//        }
//    }
//    return hasError;
//}
//
//private void downloadItemFile(@NonNull OsmandApplication app, @NonNull File tempFile,
//                              @NonNull SettingsItemReader<? extends SettingsItem> reader) {
//    SettingsItem item = reader.getItem();
//    FileInputStream is = null;
//    try {
//        is = new FileInputStream(tempFile);
//        reader.readFromStream(is, item.getFileName());
//        item.applyAdditionalParams(reader);
//    } catch (IllegalArgumentException e) {
//        item.getWarnings().add(app.getString(R.string.settings_item_read_error, item.getName()));
//        LOG.error("Error reading item data: " + item.getName(), e);
//    } catch (IOException e) {
//        item.getWarnings().add(app.getString(R.string.settings_item_read_error, item.getName()));
//        LOG.error("Error reading item data: " + item.getName(), e);
//    } finally {
//        Algorithms.closeStream(is);
//    }
//}
//
//private void updateFilesInfo(@NonNull Map<String, RemoteFile> remoteFiles,
//                             @NonNull List<SettingsItem> settingsItemList) {
//    Map<String, RemoteFile> remoteFilesMap = new HashMap<>(remoteFiles);
//    for (SettingsItem settingsItem : settingsItemList) {
//        List<RemoteFile> foundRemoteFiles = getItemRemoteFiles(settingsItem, remoteFilesMap);
//        for (RemoteFile remoteFile : foundRemoteFiles) {
//            settingsItem.setLastModifiedTime(remoteFile.getClienttimems());
//            remoteFile.item = settingsItem;
//            if (settingsItem instanceof FileSettingsItem) {
//                FileSettingsItem fileSettingsItem = (FileSettingsItem) settingsItem;
//                fileSettingsItem.setSize(remoteFile.getFilesize());
//            }
//        }
//    }
//}
//
//public boolean isCancelled() {
//    return cancelled;
//}
//
//public void cancel() {
//    this.cancelled = true;
//}
//
//private <T extends ThreadPoolTaskExecutor.Task> ThreadPoolTaskExecutor<T> createExecutor() {
//    ThreadPoolTaskExecutor<T> executor = new ThreadPoolTaskExecutor<>(null);
//    executor.setInterruptOnError(true);
//    return executor;
//}
//
//private OnDownloadFileListener getOnDownloadFileListener() {
//    return new OnDownloadFileListener() {
//        @Override
//        public void onFileDownloadStarted(@NonNull String type, @NonNull String fileName, int work) {
//            if (listener != null) {
//                listener.itemExportStarted(type, fileName, work);
//            }
//        }
//
//        @Override
//        public void onFileDownloadProgress(@NonNull String type, @NonNull String fileName, int progress, int deltaWork) {
//            if (listener != null) {
//                listener.updateItemProgress(type, fileName, progress);
//            }
//        }
//
//        @Override
//        public void onFileDownloadDone(@NonNull String type, @NonNull String fileName, @Nullable String error) {
//            if (listener != null) {
//                listener.itemExportDone(type, fileName);
//            }
//        }
//
//        @Override
//        public boolean isDownloadCancelled() {
//            return isCancelled();
//        }
//    };
//}
//
//private OnDownloadFileListener getOnDownloadItemFileListener(@NonNull SettingsItem item) {
//    String itemFileName = BackupHelper.getItemFileName(item);
//    return new OnDownloadFileListener() {
//        @Override
//        public void onFileDownloadStarted(@NonNull String type, @NonNull String fileName, int work) {
//            if (listener != null) {
//                listener.itemExportStarted(type, itemFileName, work);
//            }
//        }
//
//        @Override
//        public void onFileDownloadProgress(@NonNull String type, @NonNull String fileName, int progress, int deltaWork) {
//            if (listener != null) {
//                listener.updateItemProgress(type, itemFileName, progress);
//            }
//        }
//
//        @Override
//        public void onFileDownloadDone(@NonNull String type, @NonNull String fileName, @Nullable String error) {
//            if (listener != null) {
//                listener.itemExportDone(type, itemFileName);
//            }
//        }
//
//        @Override
//        public boolean isDownloadCancelled() {
//            return isCancelled();
//        }
//    };
//}
//
//// MARK: OAOnDownloadFileListListener
//
//- (void) onDownloadFileList:(NSInteger)status message:(NSString *)message remoteFiles:(NSArray<OARemoteFile *> *)remoteFiles
//{
//    if (status == STATUS_SUCCESS)
//    {
//        _result.remoteFiles = remoteFiles;
//        @try {
//            result.items = [self getRemoteItems:remoteFiles readItems:_readItems];
//        } @catch (NSException *e) {
//            [_error appendString:e.message];
//        }
//    }
//    else
//    {
//        [error appendString:message];
//    }
//}

// MARK: OAOnDownloadFileListener

- (void)onDownloadFileList:(NSInteger)status message:(NSString *)message remoteFiles:(NSArray<OARemoteFile *> *)remoteFiles {
    
}

- (BOOL)isDownloadCancelled {
    
}

- (void)onFileDownloadDone:(NSString *)type fileName:(NSString *)fileName error:(NSString *)error itemFileName:(NSString *)itemFileName {
    
}

- (void)onFileDownloadProgress:(NSString *)type fileName:(NSString *)fileName progress:(NSInteger)progress deltaWork:(NSInteger)deltaWork itemFileName:(NSString *)itemFileName {
    
}

- (void)onFileDownloadStarted:(NSString *)type fileName:(NSString *)fileName work:(NSInteger)work itemFileName:(NSString *)itemFileName {
    
}

@end
