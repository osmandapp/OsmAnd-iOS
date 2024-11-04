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
#import "OsmAnd_Maps-Swift.h"

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
        case EOASettingsItemFileSubtypeNauticalDepth:
            return @"nautical_depth";
        case EOASettingsItemFileSubtypeTerrainMap:
            return @"terrain";  
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
        case EOASettingsItemFileSubtypeColorPalette:
            return @"colors_palette";
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
            return documentsPath;
        case EOASettingsItemFileSubtypeObfMap:
        case EOASettingsItemFileSubtypeWikiMap:
        case EOASettingsItemFileSubtypeSrtmMap:
        case EOASettingsItemFileSubtypeNauticalDepth:
        case EOASettingsItemFileSubtypeTerrainMap:
        case EOASettingsItemFileSubtypeRoadMap:
        case EOASettingsItemFileSubtypeTilesMap:
            return [documentsPath stringByAppendingPathComponent:RESOURCES_DIR];
        case EOASettingsItemFileSubtypeRenderingStyle:
            return [documentsPath stringByAppendingPathComponent:RENDERERS_DIR];
        case EOASettingsItemFileSubtypeRoutingConfig:
            return [documentsPath stringByAppendingPathComponent:ROUTING_PROFILES_DIR];
        case EOASettingsItemFileSubtypeGpx:
            return OsmAndApp.instance.gpxPath;
            // unsupported
//        case EOASettingsItemFileSubtypeTravel:
//        case EOASettingsItemFileSubtypeVoice:
//            return [documentsPath stringByAppendingPathComponent:@"Voice"];
        case EOASettingsItemFileSubtypeColorPalette:
            return [documentsPath stringByAppendingPathComponent:COLOR_PALETTE_DIR];
        default:
            return @"";
    }
}

+ (NSString *) getSubtypeFolderName:(EOASettingsItemFileSubtype)subtype
{
    switch (subtype)
    {
        case EOASettingsItemFileSubtypeRenderingStyle:
            return RENDERERS_DIR;
        case EOASettingsItemFileSubtypeRoutingConfig:
            return ROUTING_PROFILES_DIR;
        case EOASettingsItemFileSubtypeGpx:
            return @"tracks";
            // unsupported
//        case EOASettingsItemFileSubtypeTravel:
//        case EOASettingsItemFileSubtypeVoice:
//            return [documentsPath stringByAppendingPathComponent:@"Voice"];
        case EOASettingsItemFileSubtypeColorPalette:
            return COLOR_PALETTE_DIR;
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
            case EOASettingsItemFileSubtypeSrtmMap:
            {
                if ([name hasSuffix:BINARY_SRTM_MAP_INDEX_EXT] || [name hasSuffix:BINARY_SRTMF_MAP_INDEX_EXT])
                    return subtype;
                break;
            }
            case EOASettingsItemFileSubtypeTerrainMap:
            {
                if ([name hasSuffix:TIF_EXT])
                    return subtype;
                break;
            }
            case EOASettingsItemFileSubtypeWikiMap:
            {
                if ([name hasSuffix:BINARY_WIKI_MAP_INDEX_EXT])
                    return subtype;
                break;
            }
            case EOASettingsItemFileSubtypeObfMap:
            {
                if ([name hasSuffix:BINARY_MAP_INDEX_EXT] && ![name hasSuffix:BINARY_TRAVEL_GUIDE_MAP_INDEX_EXT])
                    return subtype;
                break;
            }
            case EOASettingsItemFileSubtypeVoice:
            {
                if ([name hasSuffix:@"tts.js"])
                    return subtype;
                break;
            }
            case EOASettingsItemFileSubtypeNauticalDepth:
            {
                if ([name hasSuffix:BINARY_DEPTH_MAP_INDEX_EXT])
                    return subtype;
                break;
            }
            case EOASettingsItemFileSubtypeColorPalette:
            {
                if ([name hasSuffix:TXT_EXT])
                    return subtype;
                break;
            }
            case EOASettingsItemFileSubtypeGpx:
            {
                if ([name hasSuffix:GPX_FILE_EXT])
                    return subtype;
                break;
            }
            case EOASettingsItemFileSubtypeTravel:
            {
                if ([name hasSuffix:BINARY_TRAVEL_GUIDE_MAP_INDEX_EXT] || ([name hasSuffix:BINARY_WIKIVOYAGE_MAP_INDEX_EXT] && [name.lowercaseString containsString:@"travel"]))
                    return subtype;
                break;
            }
            case EOASettingsItemFileSubtypeTilesMap:
            {
                if ([name hasSuffix:SQLITE_EXT] || name.pathExtension.length == 0)
                    return subtype;
                break;
            }
            case EOASettingsItemFileSubtypeRoutingConfig:
            {
                if ([name hasSuffix:ROUTING_FILE_EXT] && ![name hasSuffix:RENDERER_INDEX_EXT])
                    return subtype;
                break;
            }
            case EOASettingsItemFileSubtypeRenderingStyle:
            {
                if ([name hasSuffix:RENDERER_INDEX_EXT])
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
    return type == EOASettingsItemFileSubtypeObfMap || type == EOASettingsItemFileSubtypeWikiMap || type == EOASettingsItemFileSubtypeSrtmMap || type == EOASettingsItemFileSubtypeTilesMap || type == EOASettingsItemFileSubtypeRoadMap || type == EOASettingsItemFileSubtypeNauticalDepth || type == EOASettingsItemFileSubtypeTravel;
}

+ (NSString *) getIcon:(EOASettingsItemFileSubtype)subtype
{
    switch (subtype)
    {
        case EOASettingsItemFileSubtypeObfMap:
        case EOASettingsItemFileSubtypeTilesMap:
        case EOASettingsItemFileSubtypeRoadMap:
        case EOASettingsItemFileSubtypeNauticalDepth:
            return @"ic_custom_map";
        case EOASettingsItemFileSubtypeSrtmMap:
            return @"ic_custom_contour_lines";
        case EOASettingsItemFileSubtypeWikiMap:
            return @"ic_custom_wikipedia";
        case EOASettingsItemFileSubtypeGpx:
            return @"ic_custom_trip";
        case EOASettingsItemFileSubtypeVoice:
            return @"ic_custom_sound";
        case EOASettingsItemFileSubtypeTravel:
            return @"ic_custom_wikipedia";
        case EOASettingsItemFileSubtypeRoutingConfig:
            return @"ic_custom_route";
        case EOASettingsItemFileSubtypeRenderingStyle:
            return @"ic_custom_map_style";
        case EOASettingsItemFileSubtypeColorPalette:
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
        _subtype = [OAFileSettingsItemFileSubtype getSubtypeByFileName:filePath.lastPathComponent];
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
            self.filePath = [_docPath stringByAppendingString:self.name];
        }
        else if (self.subtype == EOASettingsItemFileSubtypeUnknown || !self.subtype)
        {
            if (error)
                *error = [NSError errorWithDomain:kSettingsHelperErrorDomain code:kSettingsHelperErrorCodeUnknownFileSubtype userInfo:nil];
            return nil;
        }
        else if (self.subtype == EOASettingsItemFileSubtypeGpx)
        {
            NSString *file = json[@"file"];
            if (![file hasPrefix:@"/"])
                file = [@"/" stringByAppendingString:file];
            NSString *path = [[file substringFromIndex:1] stringByReplacingOccurrencesOfString:@"tracks/" withString:@""];
            self.filePath = [[OAFileSettingsItemFileSubtype getSubtypeFolder:_subtype] stringByAppendingPathComponent:path];
        }
        else
        {
            self.filePath = [[OAFileSettingsItemFileSubtype getSubtypeFolder:_subtype] stringByAppendingPathComponent:self.name];
        }
    }
    return self;
}

- (void) installItem:(NSString *)destFilePath
{
    switch (_subtype)
    {
        case EOASettingsItemFileSubtypeGpx:
        {
            
            OAGPXDatabase *gpxDb = [OAGPXDatabase sharedDb];
            OASGpxDataItem *gpx = [gpxDb getGPXItem:destFilePath];
            if (!gpx)
            {
                gpx = [gpxDb addGPXFileToDBIfNeeded:destFilePath];
                if (gpx)
                {
                    OASGpxTrackAnalysis *analysis = [gpx getAnalysis];
                    
                    if (analysis.locationStart)
                    {
                        OAPOI *nearestCityPOI = [OAGPXUIHelper searchNearestCity:analysis.locationStart.position];
                        NSString *nearestCityString =  nearestCityPOI ? nearestCityPOI.nameLocalized : @"";
                        [[OASGpxDbHelper shared] updateDataItemParameterItem:gpx
                                                                   parameter:OASGpxParameter.nearestCityName
                                                                       value:nearestCityString];
                    }
                }
            }

            NSDictionary<NSString *, OASGpxFile *> *activeGpx = OASelectedGPXHelper.instance.activeGpx;
            NSString *gpxFilePath = gpx.gpxFilePath;
            if ([activeGpx.allKeys containsObject:gpxFilePath])
            {
                [OAAppSettings.sharedManager showGpx:@[gpxFilePath]];
            }

            break;
        }
        case EOASettingsItemFileSubtypeRenderingStyle:
        case EOASettingsItemFileSubtypeObfMap:
        case EOASettingsItemFileSubtypeRoadMap:
        case EOASettingsItemFileSubtypeWikiMap:
        case EOASettingsItemFileSubtypeSrtmMap:
        case EOASettingsItemFileSubtypeTilesMap:
        case EOASettingsItemFileSubtypeColorPalette:
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
            return attrs.fileModificationDate.timeIntervalSince1970;
    }
    return 0;
}

- (void)setLocalModifiedTime:(long)localModifiedTime
{
    NSFileManager *manager = NSFileManager.defaultManager;
    if ([manager fileExistsAtPath:self.filePath])
    {
        [manager setAttributes:@{ NSFileModificationDate : [NSDate dateWithTimeIntervalSince1970:localModifiedTime] } ofItemAtPath:self.filePath error:nil];
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
    if ([OAFileSettingsItemFileSubtype isMap:_subtype])
    {
        return [OAFileNameTranslationHelper getMapName:_filePath.lastPathComponent];
    }
    else if (_subtype == EOASettingsItemFileSubtypeVoiceTTS || _subtype == EOASettingsItemFileSubtypeVoice)
    {
        return [OAFileNameTranslationHelper getVoiceName:_filePath.lastPathComponent];
    }
    else if (_subtype == EOASettingsItemFileSubtypeRenderingStyle)
    {
        NSString *name = [[self.name lastPathComponent] stringByReplacingOccurrencesOfString:@".render.xml" withString:@""];
        return [OARendererRegistry getMapStyleInfo:name][@"title"];
    }
    else if (_subtype == EOASettingsItemFileSubtypeRoutingConfig)
    {
        return self.name.lastPathComponent;
    }
//    else if (subtype == FileSubtype.MULTIMEDIA_NOTES) {
//        if (file.exists()) {
//            return new Recording(file).getName(app, true);
//        } else {
//            return Recording.getNameForMultimediaFile(app, file.getName(), getLastModifiedTime());
//        }
//    }
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

- (BOOL) needMd5Digest
{
    return _subtype == EOASettingsItemFileSubtypeVoice || _subtype == EOASettingsItemFileSubtypeVoiceTTS;
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
