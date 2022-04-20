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
#import "OAGPXDocument.h"
#import "OAGPXTrackAnalysis.h"
#import "OAGPXDatabase.h"
#import "OAIndexConstants.h"
#import "OASettingsItemReader.h"
#import "OASettingsItemWriter.h"

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
            return documentsPath;
        case EOASettingsItemFileSubtypeRenderingStyle:
            return [documentsPath stringByAppendingPathComponent:@"rendering"];
        case EOASettingsItemFileSubtypeTilesMap:
            return [OsmAndApp.instance.dataPath stringByAppendingPathComponent:@"Resources"];
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
                if ([name hasSuffix:@".sqlitedb"] || name.pathExtension.length == 0)
                    return subtype;
                break;
            }
            case EOASettingsItemFileSubtypeRoutingConfig:
            {
                if ([name hasSuffix:@".xml"] && ![name hasSuffix:RENDERER_INDEX_EXT])
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
    return type == EOASettingsItemFileSubtypeObfMap || type == EOASettingsItemFileSubtypeWikiMap || type == EOASettingsItemFileSubtypeSrtmMap || type == EOASettingsItemFileSubtypeTilesMap || type == EOASettingsItemFileSubtypeRoadMap;
}

+ (NSString *) getIcon:(EOASettingsItemFileSubtype)subtype
{
    switch (subtype)
    {
        case EOASettingsItemFileSubtypeObfMap:
        case EOASettingsItemFileSubtypeTilesMap:
        case EOASettingsItemFileSubtypeRoadMap:
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
            
        default:
            return @"ic_custom_save_as_new_file";
    }
}

@end

@interface OAFileSettingsItem()

@property (nonatomic) NSString *name;
@property (nonatomic) NSString *docPath;
@property (nonatomic) NSString *libPath;

@end

@implementation OAFileSettingsItem
{
    NSString *_name;
    OsmAndAppInstance _app;
}

@dynamic name;
@synthesize filePath = _filePath;

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
        if ([self.name hasPrefix:_libPath])
            self.name = [@"/" stringByAppendingString:self.name.lastPathComponent];
        self.name = [self.name stringByReplacingOccurrencesOfString:@"/GPX/" withString:@"/tracks/"];
        self.fileName = self.name;
        if (error)
        {
            *error = [NSError errorWithDomain:kSettingsHelperErrorDomain code:kSettingsHelperErrorCodeUnknownFilePath userInfo:nil];
            return nil;
        }
            
        _filePath = filePath;
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
            _filePath = [_docPath stringByAppendingString:self.name];
        }
        else if (self.subtype == EOASettingsItemFileSubtypeUnknown || !self.subtype)
        {
            if (error)
                *error = [NSError errorWithDomain:kSettingsHelperErrorDomain code:kSettingsHelperErrorCodeUnknownFileSubtype userInfo:nil];
            return nil;
        }
        else if (self.subtype == EOASettingsItemFileSubtypeGpx)
        {
            NSString *path = [[json[@"file"] substringFromIndex:1] stringByReplacingOccurrencesOfString:@"tracks/" withString:@""];
            _filePath = [[OAFileSettingsItemFileSubtype getSubtypeFolder:_subtype] stringByAppendingPathComponent:path];
        }
        else
        {
            _filePath = [[OAFileSettingsItemFileSubtype getSubtypeFolder:_subtype] stringByAppendingPathComponent:self.name];
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
            OAGPXDocument *doc = [[OAGPXDocument alloc] initWithGpxFile:destFilePath];
            [doc saveTo:destFilePath];
            [[OAGPXDatabase sharedDb] addGpxItem:destFilePath title:doc.metadata.name desc:doc.metadata.desc bounds:doc.bounds document:doc];
            [[OAGPXDatabase sharedDb] save];
            break;
        }
        case EOASettingsItemFileSubtypeRenderingStyle:
        case EOASettingsItemFileSubtypeObfMap:
        case EOASettingsItemFileSubtypeRoadMap:
        case EOASettingsItemFileSubtypeWikiMap:
        case EOASettingsItemFileSubtypeSrtmMap:
        {
            OsmAndApp.instance.resourcesManager->rescanUnmanagedStoragePaths();
            break;
        }
        case EOASettingsItemFileSubtypeTilesMap:
        {
            NSString *path = [destFilePath stringByDeletingLastPathComponent];
            NSString *fileName = destFilePath.lastPathComponent;
            NSString *ext = fileName.pathExtension;
            fileName = [fileName stringByDeletingPathExtension].lowerCase;
            NSString *newFileName = fileName;
            BOOL isHillShade = [fileName containsString:@"hillshade"];
            BOOL isSlope = [fileName containsString:@"slope"];
            if (isHillShade)
            {
                newFileName = [fileName stringByReplacingOccurrencesOfString:@"hillshade" withString:@""];
                newFileName = [newFileName trim];
                newFileName = [newFileName stringByAppendingString:@".hillshade"];
            }
            else if (isSlope)
            {
                newFileName = [fileName stringByReplacingOccurrencesOfString:@"slope" withString:@""];
                newFileName = [newFileName trim];
                newFileName = [newFileName stringByAppendingString:@".slope"];
            }
            newFileName = [newFileName stringByAppendingPathExtension:ext];
            newFileName = [newFileName stringByReplacingOccurrencesOfString:@" " withString:@"_"];
            path = [path stringByAppendingPathComponent:newFileName];
            
            NSFileManager *fileManager = NSFileManager.defaultManager;
            [fileManager moveItemAtPath:destFilePath toPath:path error:nil];
            OsmAnd::ResourcesManager::ResourceType resType = OsmAnd::ResourcesManager::ResourceType::Unknown;
            if (isHillShade)
                resType = OsmAnd::ResourcesManager::ResourceType::HillshadeRegion;
            else if (isSlope)
                resType = OsmAnd::ResourcesManager::ResourceType::SlopeRegion;
            
            if (resType != OsmAnd::ResourcesManager::ResourceType::Unknown)
            {
                // TODO: update exisitng sqlite
                OsmAndApp.instance.resourcesManager->installFromFile(QString::fromNSString(path), resType);
            }
        }
        default:
            break;
    }
}

- (EOASettingsItemType) type
{
    return EOASettingsItemTypeFile;
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

    while (true)
    {
        number++;
        NSString *newFilePath = [NSString stringWithFormat:@"%@_%d%@", prefix, number, suffix];
        if (![fileManager fileExistsAtPath:newFilePath])
            return newFilePath;
    }
}

- (void) setFilePath:(NSString *)filePath
{
    _filePath = filePath;
}

- (NSString *)filePath
{
    return _filePath;
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
    BOOL isDir = destFilePath.pathExtension.length == 0;
    BOOL exists = [fileManager fileExistsAtPath:destFilePath];
    if (isDir && !exists)
    {
        [fileManager createDirectoryAtPath:destFilePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    else if (!exists)
    {
        NSString *directory = [destFilePath stringByDeletingLastPathComponent];
        [fileManager createDirectoryAtPath:directory withIntermediateDirectories:NO attributes:nil error:nil];
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
