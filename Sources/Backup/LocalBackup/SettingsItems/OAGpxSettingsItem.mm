//
//  OAGpxSettingsItem.m
//  OsmAnd
//
//  Created by Anna Bibyk on 29.01.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAGpxSettingsItem.h"
#import "OAGPXUIHelper.h"
#import "OsmAndApp.h"
#import "OAGPXAppearanceCollection.h"
#import "OsmAnd_Maps-Swift.h"

@interface OAGpxSettingsItem()

@end

@implementation OAGpxSettingsItem
{
    GpxAppearanceInfo *_appearanceInfo;
}

- (instancetype) initWithFilePath:(NSString *)filePath error:(NSError * _Nullable *)error
{
    NSError *initError;
    self = [super initWithFilePath:filePath error:error];
    if (initError)
    {
        if (error)
            *error = initError;
        return nil;
    }
    if (self)
        [self createGpxAppearanceInfo];
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
    return self;
}

- (GpxAppearanceInfo *) getAppearanceInfo
{
    return _appearanceInfo;
}

- (EOASettingsItemType)type
{
    return EOASettingsItemTypeGpx;
}

- (EOAFileSettingsItemFileSubtype)subtype
{
    return EOAFileSettingsItemFileSubtypeGpx;
}

- (NSString *)getPublicName
{
    return [self.filePath.lastPathComponent stringByDeletingPathExtension];
}

- (void)remove
{
    [super remove];
    NSFileManager *manager = NSFileManager.defaultManager;
    NSError *err = nil;
    [manager removeItemAtPath:self.filePath error:&err];
    if (!err)
    {
        NSString *parentDir = [self.filePath stringByDeletingLastPathComponent];
        if (![parentDir isEqualToString:OsmAndApp.instance.gpxPath] && [manager contentsOfDirectoryAtPath:parentDir error:nil].count == 0)
            [manager removeItemAtPath:parentDir error:nil];
    }
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
    // NOTE: example
    /*
     {
     file = "tracks/3041434.gpx";
     type = GPX;
     }
     */
    _appearanceInfo = [GpxAppearanceInfo fromJson:json];
}

- (NSString *)fileNameWithFolder
{
    NSString *gpxPath = [self.filePath stringByReplacingOccurrencesOfString:OsmAndApp.instance.documentsPath withString:@""];

    if ([gpxPath hasPrefix:@"/GPX"])
    {
        gpxPath = [@"/tracks" stringByAppendingString:[gpxPath substringFromIndex:4]];
    }
    
    if ([gpxPath isEqualToString:self.fileName])
    {
        return self.fileName;
    }

    NSString *folderName = @"";
    NSArray<NSString *> *pathComponents = self.filePath.pathComponents;
    if (pathComponents.count > 1)
        folderName = pathComponents[pathComponents.count - 2];
    
    NSString *tracksName = @"/tracks";
    if ([folderName isEqualToString:@"GPX"])
        folderName = tracksName;
    else
        folderName = [tracksName stringByAppendingPathComponent:folderName];
    return [folderName stringByAppendingPathComponent:self.fileName.lastPathComponent];
}

- (void) writeToJson:(id)json
{
    json[@"type"] = [OASettingsItemType typeName:self.type];
    json[@"file"] = self.fileNameWithFolder;
    if (self.subtype != EOAFileSettingsItemFileSubtypeUnknown)
        json[@"subtype"] = [OAFileSettingsItemFileSubtype getSubtypeName:self.subtype];
    
    if (_appearanceInfo)
    {
        id newJson = [_appearanceInfo toJson:json];
        [json addEntriesFromDictionary:newJson];
    }
}

- (OASettingsItemWriter *) getWriter
{
    return [[OAFileSettingsItemWriter alloc] initWithItem:self];
}

- (void)applyAdditionalParams:(NSString *)filePath
{
    if (_appearanceInfo)
        [self updateGpxParams];
}

- (void)updateGpxParams
{
    OASKFile *file = [[OASKFile alloc] initWithFilePath:self.filePath];
    OASGpxDbHelper *gpxDbHelper = [OASGpxDbHelper shared];
    BOOL readItem = [gpxDbHelper hasGpxDataItemFile:file];
    OASGpxDataItem *dataItem = nil;
    if (!readItem)
    {
        dataItem = [[OASGpxDataItem alloc] initWithFile:file];
        readItem = ![gpxDbHelper addItem:dataItem];
    }
    if (readItem)
    {
        __weak __typeof(self) weakSelf = self;
        GpxDataItemHandler *handler = [GpxDataItemHandler new];
        handler.onGpxDataItemReady = ^(OASGpxDataItem *item) {
            [weakSelf updateParamsForGpxDataItem:item];
        };
        dataItem = [gpxDbHelper getItemFile:file callback:handler];
    }
    if (dataItem)
    {
        [self updateParamsForGpxDataItem:dataItem];
    }
}

- (void)updateParamsForGpxDataItem:(OASGpxDataItem *)gpx
{
    if (gpx)
    {
        gpx.color = _appearanceInfo.color;
        gpx.coloringType = _appearanceInfo.coloringType;
        gpx.width = _appearanceInfo.width;
        gpx.showArrows = _appearanceInfo.showArrows;
        gpx.showStartFinish = _appearanceInfo.showStartFinish;
        gpx.joinSegments = _appearanceInfo.isJoinSegments;
        gpx.verticalExaggerationScale = _appearanceInfo.verticalExaggeration;
        gpx.elevationMeters = _appearanceInfo.elevationMeters;
        gpx.visualization3dByType = _appearanceInfo.trackVisualizationType;
        gpx.visualization3dWallColorType = _appearanceInfo.trackWallColorType;
        gpx.visualization3dPositionType = _appearanceInfo.trackLinePositionType;
        gpx.splitType = _appearanceInfo.splitType;
        gpx.splitInterval = _appearanceInfo.splitInterval;
        
        [[OAGPXDatabase sharedDb] updateDataItem:gpx];
        if (gpx.color != 0)
            [[OAGPXAppearanceCollection sharedInstance] getColorItemWithValue:gpx.color];
    }
    else
    {
        NSLog(@"[ERROR] -> OAGpxSettingsItem -> gpx for self.filePath: %@ is empty", self.filePath);
    }
}

- (void)configureGpxAppearanceInfo:(OASGpxDataItem *)dataItem
{
    if (dataItem)
        _appearanceInfo = [[GpxAppearanceInfo alloc] initWithDataItem:dataItem];
}

- (void)createGpxAppearanceInfo
{
    GpxDataItemHandler *handler = [GpxDataItemHandler new];
    __weak __typeof(self) weakSelf = self;
    handler.onGpxDataItemReady = ^(OASGpxDataItem *item) {
        [weakSelf configureGpxAppearanceInfo:item];
    };
    OASKFile *file = [[OASKFile alloc] initWithFilePath:self.filePath];
    OASGpxDataItem *dataItem = [[OASGpxDbHelper shared] getItemFile:file callback:handler];
    
    if (dataItem)
        _appearanceInfo = [[GpxAppearanceInfo alloc] initWithDataItem:dataItem];
}


@end
