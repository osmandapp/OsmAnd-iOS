//
//  OAFileSettingsItem.mm
//  OsmAnd
//
//  Created by Anna Bibyk on 19.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAFileSettingsItem.h"
#import "OASettingsHelper.h"
#import "OAAppSettings.h"
#import "OsmAndApp.h"
#import "OAGPXDatabase.h"
#import "OAIndexConstants.h"
#import "OASettingsItemReader.h"
#import "OASettingsItemWriter.h"
#import "OARendererRegistry.h"
#import "OASelectedGPXHelper.h"
#import "OAFileNameTranslationHelper.h"
#import "OAMapCreatorHelper.h"
#import "OsmAnd_Maps-Swift.h"

@implementation OAFileSettingsItemFileSubtype

+ (NSString *) getSubtypeName:(EOAFileSettingsItemFileSubtype)subtype
{
    switch (subtype)
    {
        case EOAFileSettingsItemFileSubtypeOther:
            return @"other";
        case EOAFileSettingsItemFileSubtypeRoutingConfig:
            return @"routing_config";
        case EOAFileSettingsItemFileSubtypeRenderingStyle:
            return @"rendering_style";
        case EOAFileSettingsItemFileSubtypeWikiMap:
            return @"wiki_map";
        case EOAFileSettingsItemFileSubtypeSrtmMap:
            return @"srtm_map";
        case EOAFileSettingsItemFileSubtypeTerrainMap:
            return @"terrain";
        case EOAFileSettingsItemFileSubtypeObfMap:
            return @"obf_map";
        case EOAFileSettingsItemFileSubtypeTilesMap:
            return @"tiles_map";
        case EOAFileSettingsItemFileSubtypeRoadMap:
            return @"road_map";
        case EOAFileSettingsItemFileSubtypeGpx:
            return @"gpx";
        case EOAFileSettingsItemFileSubtypeVoiceTTS:
            return @"tts_voice";
        case EOAFileSettingsItemFileSubtypeVoice:
            return @"voice";
        case EOAFileSettingsItemFileSubtypeTravel:
            return @"travel";
        case EOAFileSettingsItemFileSubtypeMultimediaNotes:
            return @"multimedia_notes";
        case EOAFileSettingsItemFileSubtypeNauticalDepth:
            return @"nautical_depth";
        case EOAFileSettingsItemFileSubtypeFavoritesBackup:
            return @"favorites_backup";
        case EOAFileSettingsItemFileSubtypeColorPalette:
            return @"colors_palette";
        default:
            return @"";
    }
}

+ (NSString *) getSubtypeFolder:(EOAFileSettingsItemFileSubtype)subtype
{
    switch (subtype)
    {
        case EOAFileSettingsItemFileSubtypeUnknown:
            return nil;
        case EOAFileSettingsItemFileSubtypeOther:
            return @"";
        case EOAFileSettingsItemFileSubtypeRoutingConfig:
            return ROUTING_PROFILES_DIR;
        case EOAFileSettingsItemFileSubtypeRenderingStyle:
            return RENDERERS_DIR;
        case EOAFileSettingsItemFileSubtypeWikiMap:
            return RESOURCES_DIR;       //android: WIKI_INDEX_DIR
        case EOAFileSettingsItemFileSubtypeSrtmMap:
            return RESOURCES_DIR;       //android: SRTM_INDEX_DIR
        case EOAFileSettingsItemFileSubtypeTerrainMap:
            return RESOURCES_DIR;       //android: GEOTIFF_DIR
        case EOAFileSettingsItemFileSubtypeObfMap:
            return RESOURCES_DIR;       //android: MAPS_PATH
        case EOAFileSettingsItemFileSubtypeTilesMap:
            return MAP_CREATOR_DIR;       //android: TILES_INDEX_DIR
        case EOAFileSettingsItemFileSubtypeRoadMap:
            return RESOURCES_DIR;       //android: ROADS_INDEX_DIR
        case EOAFileSettingsItemFileSubtypeGpx:
            return GPX_DIR;             //android: GPX_INDEX_DIR ("GPX" vs "tracks")
        case EOAFileSettingsItemFileSubtypeVoiceTTS:
            return nil;                 //android: VOICE_INDEX_DIR
        case EOAFileSettingsItemFileSubtypeVoice:
            return nil;                 //android: VOICE_INDEX_DIR
        case EOAFileSettingsItemFileSubtypeTravel:
            return RESOURCES_DIR;       //android: WIKIVOYAGE_INDEX_DIR
        case EOAFileSettingsItemFileSubtypeMultimediaNotes:
            return nil;                 //android: ROADS_INDEX_DIRAV_INDEX_DIR
        case EOAFileSettingsItemFileSubtypeNauticalDepth:
            return RESOURCES_DIR;       //android: NAUTICAL_INDEX_DIR
        case EOAFileSettingsItemFileSubtypeFavoritesBackup:
            return nil;                 //android: BACKUP_INDEX_DIR
        case EOAFileSettingsItemFileSubtypeColorPalette:
            return COLOR_PALETTE_DIR;
            
        default:
            return nil;
    }
}

+ (NSString *) getSubtypeFolderName:(EOAFileSettingsItemFileSubtype)subtype
{
    switch (subtype)
    {
        case EOAFileSettingsItemFileSubtypeRenderingStyle:
            return RENDERERS_DIR;
        case EOAFileSettingsItemFileSubtypeRoutingConfig:
            return ROUTING_PROFILES_DIR;
        case EOAFileSettingsItemFileSubtypeGpx:
            return @"tracks";
            // unsupported
//        case EOAFileSettingsItemFileSubtypeTravel:
//        case EOAFileSettingsItemFileSubtypeVoice:
//            return [documentsPath stringByAppendingPathComponent:@"Voice"];
        case EOAFileSettingsItemFileSubtypeColorPalette:
            return COLOR_PALETTE_DIR;
        default:
            return @"";
    }
}

+ (EOAFileSettingsItemFileSubtype) getSubtypeByName:(NSString *)name
{
    for (int i = 0; i < EOAFileSettingsItemFileSubtypesCount; i++)
    {
        NSString *subtypeName = [self.class getSubtypeName:(EOAFileSettingsItemFileSubtype)i];
        if ([subtypeName isEqualToString:name])
            return (EOAFileSettingsItemFileSubtype)i;
    }
    return EOAFileSettingsItemFileSubtypeUnknown;
}

+ (EOAFileSettingsItemFileSubtype) getSubtypeByFileName:(NSString *)fileName
{
    NSString *name = fileName;
    if ([fileName hasPrefix:@"/"])
        name = [fileName substringFromIndex:1];

    for (int i = 0; i < EOAFileSettingsItemFileSubtypesCount; i++)
    {
        EOAFileSettingsItemFileSubtype subtype = (EOAFileSettingsItemFileSubtype) i;
        switch (subtype) {
            case EOAFileSettingsItemFileSubtypeUnknown:
            case EOAFileSettingsItemFileSubtypeOther:
                break;
            case EOAFileSettingsItemFileSubtypeSrtmMap:
            {
                if ([name hasSuffix:BINARY_SRTM_MAP_INDEX_EXT] || [name hasSuffix:BINARY_SRTMF_MAP_INDEX_EXT])
                    return subtype;
                break;
            }
            case EOAFileSettingsItemFileSubtypeTerrainMap:
            {
                if ([name hasSuffix:TIF_EXT])
                    return subtype;
                break;
            }
            case EOAFileSettingsItemFileSubtypeWikiMap:
            {
                if ([name hasSuffix:BINARY_WIKI_MAP_INDEX_EXT])
                    return subtype;
                break;
            }
            case EOAFileSettingsItemFileSubtypeTravel:
            {
                if ([name hasSuffix:BINARY_TRAVEL_GUIDE_MAP_INDEX_EXT])
                    return subtype;
                break;
            }
            case EOAFileSettingsItemFileSubtypeObfMap:
            {
                // android has additions check:
                // if (name.endsWith(IndexConstants.BINARY_MAP_INDEX_EXT) && !name.contains(File.separator)) {
                // if ([name hasSuffix:BINARY_MAP_INDEX_EXT] && ![name containsString:@"/"])

                if ([name hasSuffix:BINARY_MAP_INDEX_EXT] )
                    return subtype;
                break;
            }
            case EOAFileSettingsItemFileSubtypeVoice:
            {
                if ([name hasSuffix:VOICE_PROVIDER_SUFFIX])
                    return subtype;
                else if ([name hasSuffix:TTSVOICE_INDEX_EXT_JS])
                {
                    NSArray<NSString *> *pathComponents = [name componentsSeparatedByString:@"/"];
                    if (pathComponents.count > 1 && [pathComponents[0] hasSuffix:VOICE_PROVIDER_SUFFIX])
                        return subtype;
                }
            }
            case EOAFileSettingsItemFileSubtypeNauticalDepth:
            {
                if ([name hasSuffix:BINARY_DEPTH_MAP_INDEX_EXT])
                    return subtype;
                break;
            }
            case EOAFileSettingsItemFileSubtypeColorPalette:
            {
                if ([name hasSuffix:TXT_EXT])
                    return subtype;
                break;
            }
            default:
            {
                NSString *subtypeFolder = [self.class getSubtypeFolder:subtype];
                if (subtypeFolder && [name hasPrefix:subtypeFolder])
                    return subtype;
                break;
            }
        }
    }
    return EOAFileSettingsItemFileSubtypeUnknown;
}

+ (BOOL) isMap:(EOAFileSettingsItemFileSubtype)type
{
    return type == EOAFileSettingsItemFileSubtypeObfMap || type == EOAFileSettingsItemFileSubtypeWikiMap || type == EOAFileSettingsItemFileSubtypeTravel || type == EOAFileSettingsItemFileSubtypeSrtmMap || type == EOAFileSettingsItemFileSubtypeTerrainMap || type == EOAFileSettingsItemFileSubtypeTilesMap || type == EOAFileSettingsItemFileSubtypeRoadMap || type == EOAFileSettingsItemFileSubtypeNauticalDepth;
}

+ (NSString *) getIcon:(EOAFileSettingsItemFileSubtype)subtype
{
    switch (subtype)
    {
        case EOAFileSettingsItemFileSubtypeObfMap:
        case EOAFileSettingsItemFileSubtypeTilesMap:
        case EOAFileSettingsItemFileSubtypeRoadMap:
            return @"ic_custom_map";
        case EOAFileSettingsItemFileSubtypeSrtmMap:
            return @"ic_custom_contour_lines";
        case EOAFileSettingsItemFileSubtypeTerrainMap:
            return @"ic_custom_terrain";
        case EOAFileSettingsItemFileSubtypeNauticalDepth:
            return @"ic_custom_nautical_depth";
        case EOAFileSettingsItemFileSubtypeWikiMap:
            return @"ic_custom_wikipedia";
        case EOAFileSettingsItemFileSubtypeGpx:
            return @"ic_custom_trip";
        case EOAFileSettingsItemFileSubtypeVoice:
            return @"ic_custom_sound";
        case EOAFileSettingsItemFileSubtypeTravel:
            return @"ic_custom_wikipedia";
        case EOAFileSettingsItemFileSubtypeRoutingConfig:
            return @"ic_custom_route";
        case EOAFileSettingsItemFileSubtypeRenderingStyle:
            return @"ic_custom_map_style";
        case EOAFileSettingsItemFileSubtypeColorPalette:
            return @"ic_custom_file_color_palette";
            
        default:
            return @"ic_custom_save_as_new_file";
    }
}

@end

@implementation OAFileSettingsItem
{
    OsmAndAppInstance _app;
    
    NSString *_docPath;
    NSString *_libPath;
}

- (void) commonInit
{
    _app = OsmAndApp.instance;
    _docPath = _app.documentsPath;
    _libPath = _app.dataPath;
}

- (instancetype) initWithFilePath:(NSString *)filePath error:(NSError * _Nullable *)error
{
    self = [super init];
    if (self)
    {
        [self commonInit];
        self.name = [filePath stringByReplacingOccurrencesOfString:_docPath withString:@""];
        self.name = [self.name stringByReplacingOccurrencesOfString:_libPath withString:@""];
        if ([self.name hasPrefix:@"/Resources/"])
            self.name = [@"/" stringByAppendingString:self.name.lastPathComponent];
        self.name = [self.name stringByReplacingOccurrencesOfString:@"/GPX/" withString:@"/tracks/"];
        self.fileName = self.name;
        if (error)
        {
            *error = [NSError errorWithDomain:kSettingsHelperErrorDomain code:kSettingsHelperErrorCodeUnknownFilePath userInfo:nil];
            return nil;
        }
        
        self.filePath = filePath;
        _subtype = [OAFileSettingsItemFileSubtype getSubtypeByFileName:[filePath stringByReplacingOccurrencesOfString:OsmAndApp.instance.documentsPath withString:@""]];
        if (self.subtype == EOAFileSettingsItemFileSubtypeUnknown)
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
        if (self.subtype == EOAFileSettingsItemFileSubtypeOther)
        {
            self.filePath = [_docPath stringByAppendingString:self.name];
        }
        else if (self.subtype == EOAFileSettingsItemFileSubtypeUnknown || !self.subtype)
        {
            if (error)
                *error = [NSError errorWithDomain:kSettingsHelperErrorDomain code:kSettingsHelperErrorCodeUnknownFileSubtype userInfo:nil];
            return nil;
        }
        else if (self.subtype == EOAFileSettingsItemFileSubtypeGpx)
        {
            NSString *file = json[@"file"];
            if (![file hasPrefix:@"/"])
                file = [@"/" stringByAppendingString:file];
            NSString *path = [[file substringFromIndex:1] stringByReplacingOccurrencesOfString:@"tracks/" withString:@""];
            self.filePath = [OsmAndApp.instance.documentsPath stringByAppendingPathComponent:[[OAFileSettingsItemFileSubtype getSubtypeFolder:self.subtype] stringByAppendingPathComponent:path]];
        }
        else
        {
            self.filePath = OsmAndApp.instance.documentsPath;
            NSString *folderName = [OAFileSettingsItemFileSubtype getSubtypeFolder:self.subtype];
            if (folderName && folderName.length > 0)
                self.filePath = [self.filePath stringByAppendingPathComponent:folderName];
            self.filePath = [self.filePath stringByAppendingPathComponent:self.name];
        }
    }
    return self;
}

- (void) installItem:(NSString *)destFilePath
{
    switch (self.subtype)
    {
        case EOAFileSettingsItemFileSubtypeGpx:
        {
            OASGpxDbHelper *gpxDbHelper = [OASGpxDbHelper shared];
            OASKFile *file = [[OASKFile alloc] initWithFilePath:destFilePath];
            if (![gpxDbHelper hasGpxDataItemFile:file])
                [gpxDbHelper addItem:[[OASGpxDataItem alloc] initWithFile:file]];
            break;
        }
        case EOAFileSettingsItemFileSubtypeTilesMap:
        {
            [[OAMapCreatorHelper sharedInstance] fetchSQLiteDBFiles:YES];
            break;
        }
        case EOAFileSettingsItemFileSubtypeRenderingStyle:
        case EOAFileSettingsItemFileSubtypeObfMap:
        case EOAFileSettingsItemFileSubtypeRoadMap:
        case EOAFileSettingsItemFileSubtypeWikiMap:
        case EOAFileSettingsItemFileSubtypeSrtmMap:
        case EOAFileSettingsItemFileSubtypeColorPalette:
        {
            OsmAndApp.instance.resourcesManager->rescanUnmanagedStoragePaths(true);
            break;
        }
        default:
            break;
    }
}

- (long)localModifiedTime
{
    NSFileManager *manager = NSFileManager.defaultManager;
    if ([manager fileExistsAtPath:self.filePath])
    {
        NSError *err = nil;
        NSDictionary *attrs = [manager attributesOfItemAtPath:self.filePath error:&err];
        if (!err)
            return attrs.fileModificationDate.timeIntervalSince1970 * 1000;
    }
    return 0;
}

- (void)setLocalModifiedTime:(long)localModifiedTime
{
    NSFileManager *manager = NSFileManager.defaultManager;
    if ([manager fileExistsAtPath:self.filePath])
    {
        [manager setAttributes:@{ NSFileModificationDate : [NSDate dateWithTimeIntervalSince1970:localModifiedTime / 1000] } ofItemAtPath:self.filePath error:nil];
    }
}

- (EOASettingsItemType) type
{
    return EOASettingsItemTypeFile;
}

- (long)getEstimatedSize
{
    return self.size;
}

- (NSString *)getPublicName
{
    if ([OAFileSettingsItemFileSubtype isMap:self.subtype])
    {
        return [OAFileNameTranslationHelper getMapName:_filePath.lastPathComponent];
    }
    else if (self.subtype == EOAFileSettingsItemFileSubtypeVoiceTTS || self.subtype == EOAFileSettingsItemFileSubtypeVoice)
    {
        return [OAFileNameTranslationHelper getVoiceName:_filePath.lastPathComponent];
    }
    else if (self.subtype == EOAFileSettingsItemFileSubtypeRenderingStyle)
    {
        NSString *name = [[self.name lastPathComponent] stringByReplacingOccurrencesOfString:@".render.xml" withString:@""];
        return [OARendererRegistry getMapStyleInfo:name][@"title"];
    }
    else if (self.subtype == EOAFileSettingsItemFileSubtypeRoutingConfig)
    {
        return self.name.lastPathComponent;
    }
    else if (self.subtype == EOAFileSettingsItemFileSubtypeMultimediaNotes)
    {
//        if (file.exists()) {
//            return new Recording(file).getName(app, true);
//        } else {
//            return Recording.getNameForMultimediaFile(app, file.getName(), getLastModifiedTime());
//        }
    }
    return self.name;
}

- (BOOL) exists
{
    return [[NSFileManager defaultManager] fileExistsAtPath:self.filePath];
}

- (void)remove
{
    [super remove];
    // TODO: remove file
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
    else if ([filePath containsString:@"."])
        prefix = [filePath substringToIndex:[filePath lastIndexOf:@"."]];
    else
        prefix = filePath;
    
    NSString *suffix = [filePath stringByReplacingOccurrencesOfString:prefix withString:@""];

    while (true)
    {
        number++;
        NSString *newFilePath = [NSString stringWithFormat:@"%@_%d%@", prefix, number, suffix];
        if (![fileManager fileExistsAtPath:newFilePath])
            return newFilePath;
    }
}

- (NSString *) getIconName
{
    switch (self.subtype)
    {
        case EOAFileSettingsItemFileSubtypeWikiMap:
            return @"ic_custom_wikipedia";
        case EOAFileSettingsItemFileSubtypeSrtmMap:
            return @"ic_custom_contour_lines";
        default:
            return @"ic_custom_show_on_map";
    }
}

- (NSString *) getPluginPath
{
    if (self.pluginId.length > 0)
        return [[_libPath stringByAppendingPathComponent:PLUGINS_DIR] stringByAppendingPathComponent:self.pluginId];
    
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
    if (![fileName hasPrefix:@"/"])
        fileName = [@"/" stringByAppendingString:fileName];
    if (!self.subtype)
    {
        NSString *subtypeStr = json[@"subtype"];
        if (subtypeStr.length > 0)
            _subtype = [OAFileSettingsItemFileSubtype getSubtypeByName:subtypeStr];
        else if (fileName.length > 0)
            _subtype = [OAFileSettingsItemFileSubtype getSubtypeByFileName:fileName];
        else
            _subtype = EOAFileSettingsItemFileSubtypeUnknown;
    }
    if (fileName.length > 0)
    {
        if (self.subtype == EOAFileSettingsItemFileSubtypeOther)
            self.name = fileName;
        else if (self.subtype != EOAFileSettingsItemFileSubtypeUnknown)
            self.name = [fileName lastPathComponent];
    }
}

- (void) writeToJson:(id)json
{
    [super writeToJson:json];
    if (self.subtype != EOAFileSettingsItemFileSubtypeUnknown)
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

- (BOOL) needMd5Digest
{
    return self.subtype == EOAFileSettingsItemFileSubtypeVoice
        || self.subtype == EOAFileSettingsItemFileSubtypeVoiceTTS
        || self.subtype == EOAFileSettingsItemFileSubtypeGpx;
}

@end

#pragma mark - OAFileSettingsItemReader

@implementation OAFileSettingsItemReader

- (BOOL) readFromFile:(NSString *)filePath error:(NSError * _Nullable *)error
{
    if (self.item.read)
    {
        if (error)
            *error = [NSError errorWithDomain:kSettingsItemErrorDomain code:kSettingsItemErrorCodeAlreadyRead userInfo:nil];

        return NO;
    }

    NSString *destFilePath = self.item.filePath;
    if (![self.item exists] || [self.item shouldReplace])
        destFilePath = self.item.filePath;
    else
        destFilePath = [self.item renameFile:destFilePath];
    
    NSFileManager *fileManager = NSFileManager.defaultManager;
    BOOL isDir = destFilePath.pathExtension.length == 0;
    BOOL exists = [fileManager fileExistsAtPath:destFilePath];
    if (isDir && !exists)
    {
        [fileManager createDirectoryAtPath:destFilePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    else if (!exists)
    {
        NSString *directory = [destFilePath stringByDeletingLastPathComponent];
        [fileManager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    BOOL res = NO;
    if (!isDir)
    {
        NSError *removeError;
        if (exists)
        {
            [[NSFileManager defaultManager] removeItemAtPath:destFilePath error:&removeError];
            if (error && removeError)
                *error = removeError;
        }
        if (!exists || !removeError)
        {
            NSError *copyError;
            res = [[NSFileManager defaultManager] copyItemAtPath:filePath toPath:destFilePath error:&copyError];
            
            if (res)
            {
                // Exclude map resources (.obf) from iCloud backup
                if ([[destFilePath.pathExtension lowercaseString] isEqualToString:@"obf"])
                    [destFilePath applyExcludedFromBackup];
            }
            else
            {
                NSLog(@"Failed to copy file from %@ to %@, error: %@", filePath, destFilePath, copyError);
            }
            
            if (error && copyError)
                *error = copyError;
        }
    }
    else
    {
        NSArray<NSString *> *files = [fileManager contentsOfDirectoryAtPath:filePath error:error];
        for (NSString *file in files)
        {
            [fileManager moveItemAtPath:[filePath stringByAppendingPathComponent:file]
                                 toPath:[destFilePath stringByAppendingPathComponent:file]
                                  error:error];
        }
    }
    
    [self.item installItem:destFilePath];

    self.item.read = res;
    return res;
}

@end

#pragma mark - OAFileSettingsItemWriter

@implementation OAFileSettingsItemWriter

- (BOOL) writeToFile:(NSString *)filePath error:(NSError * _Nullable *)error
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *targetFolder = filePath.stringByDeletingLastPathComponent;
    if (![fileManager fileExistsAtPath:targetFolder])
        [fileManager createDirectoryAtPath:targetFolder withIntermediateDirectories:YES attributes:nil error:nil];
    NSError *copyError;
    [fileManager copyItemAtPath:self.item.filePath toPath:filePath error:&copyError];
    if (error && copyError)
    {
        *error = copyError;
        return NO;
    }
    return YES;
}

@end
