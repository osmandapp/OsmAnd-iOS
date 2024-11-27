//
//  OAGpxSettingsItem.m
//  OsmAnd
//
//  Created by Anna Bibyk on 29.01.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAGpxSettingsItem.h"
#import "OAGpxAppearanceInfo.h"
#import "OAGPXUIHelper.h"
#import "OsmAndApp.h"
#import "OAGPXAppearanceCollection.h"
#import "OsmAnd_Maps-Swift.h"

@interface OAGpxLoadCallback : NSObject <OASGpxDbHelperGpxDataItemCallback>

@property (nonatomic, weak) OAGpxSettingsItem *host;

@end


@implementation OAGpxLoadCallback

- (BOOL)isCancelled
{
    return NO;
}

- (void)onGpxDataItemReadyItem:(nonnull OASGpxDataItem *)item
{
    if (_host)
        [_host updateGpxParams:item];
}

@end


@interface OAGpxSettingsItem()

@end

@implementation OAGpxSettingsItem
{
    OAGpxAppearanceInfo *_appearanceInfo;
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

- (OAGpxAppearanceInfo *) getAppearanceInfo
{
    return _appearanceInfo;
}

- (EOASettingsItemType)type
{
    return EOASettingsItemTypeGpx;
}

- (EOASettingsItemFileSubtype)subtype
{
    return EOASettingsItemFileSubtypeGpx;
}

- (NSString *)getPublicName
{
    return [OASGpxHelper.shared getGpxTitleName:self.filePath];
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
    _appearanceInfo = [OAGpxAppearanceInfo fromJson:json];
}

- (NSString *)fileNameWithFolder
{
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
    if (self.subtype != EOASettingsItemFileSubtypeUnknown)
        json[@"subtype"] = [OAFileSettingsItemFileSubtype getSubtypeName:self.subtype];
    if (_appearanceInfo)
        [_appearanceInfo toJson:json];
}

- (OASettingsItemWriter *) getWriter
{
    return [[OAFileSettingsItemWriter alloc] initWithItem:self];
}



//TODO: new

//TODO: implement

- (void) applyAdditionalParams:(NSString *)filePath reader:(OASettingsItemReader *)reader
{
    if (_appearanceInfo)
    {
        NSString *savedFile = nil;
        if ([reader isKindOfClass:OAFileSettingsItemReader.class])
        {
            savedFile = filePath;
            //savedFile = ((FileSettingsItemReader) reader).getSavedFile();
        }
        if (savedFile)
        {
            OASKFile *kSavedFile = [[OASKFile alloc] initWithFilePath:savedFile];
            OAGPXDatabase *gpxDb = [OAGPXDatabase sharedDb];
            BOOL readItem = [[OASGpxDbHelper shared] hasGpxDataItemFile:kSavedFile];
            OASGpxDataItem *dataItem = nil;
            if (!readItem)
            {
                OASGpxFile *gpxFile = [OASGpxUtilities.shared loadGpxFileFile:kSavedFile];
                if (!gpxFile.error)
                {
                    OASGpxTrackAnalysis *trackAnalysis = [gpxFile getAnalysisFileTimestamp:gpxFile.modifiedTime];
                    
                    dataItem = [[OASGpxDataItem alloc] initWithFile:kSavedFile];
                    [dataItem setAnalysisAnalysis:trackAnalysis];
                    [dataItem readGpxParamsGpxFile:gpxFile];
                    
                    readItem = ![[OASGpxDbHelper shared] addItem:dataItem];
                }
            }
            if (readItem)
            {
                OAGpxLoadCallback *callback = [[OAGpxLoadCallback alloc] init];
                callback.host = self;
                dataItem = [[OASGpxDbHelper shared] getItemFile:kSavedFile callback:callback];
            }
            if (dataItem)
            {
                [self updateGpxParams:dataItem];
            }
        }
    }
}

// TODO: New - check

- (void)updateGpxParams:(OASGpxDataItem *)dataItem
{
    [dataItem setColor:_appearanceInfo.color];
    [dataItem setWidth:_appearanceInfo.width];
    [dataItem setShowArrows:_appearanceInfo.showArrows];
    [dataItem setShowStartFinish:_appearanceInfo.showStartFinish];
    [OAGPXDatabase splitTypeNameByValue:_appearanceInfo.splitType];
    [dataItem setSplitInterval:_appearanceInfo.splitInterval];
    [dataItem setColoringType:_appearanceInfo.coloringType];
    [dataItem setGradientPaletteName:_appearanceInfo.gradientPaletteName];
    [[OASGpxDbHelper shared] updateDataItemItem:dataItem];
}

// TODO: Old - delete

//- (void) applyAdditionalParams:(NSString *)filePath reader:(OASettingsItemReader *)reader
//{
//    if (_appearanceInfo)
//        [self updateGpxParams:filePath];
//}


// TODO: Old - delete

/*
- (void)updateGpxParams:(NSString *)filePath
{
    OAGPXDatabase *gpxDb = [OAGPXDatabase sharedDb];
    OASGpxDataItem *gpx = [gpxDb getGPXItem:self.filePath];
    if (!gpx)
    {
        gpx = [gpxDb addGPXFileToDBIfNeeded:filePath];
        OASGpxTrackAnalysis *analysis = [gpx getAnalysis];
        
        if (analysis.locationStart)
        {
            OAPOI *nearestCityPOI = [OAGPXUIHelper searchNearestCity:analysis.locationStart.position];
            gpx.nearestCity = nearestCityPOI ? nearestCityPOI.nameLocalized : @"";
        }
    }
    gpx.color = _appearanceInfo.color;
    gpx.coloringType = _appearanceInfo.coloringType;
    gpx.width = _appearanceInfo.width;
    gpx.showArrows = _appearanceInfo.showArrows;
    gpx.showStartFinish = _appearanceInfo.showStartFinish;
    gpx.verticalExaggerationScale = _appearanceInfo.verticalExaggerationScale;
    gpx.elevationMeters = _appearanceInfo.elevationMeters;
    gpx.visualization3dByType = _appearanceInfo.visualization3dByType;
    gpx.visualization3dWallColorType = _appearanceInfo.visualization3dWallColorType;
    gpx.visualization3dPositionType = _appearanceInfo.visualization3dPositionType;
    gpx.splitType = _appearanceInfo.splitType;
    gpx.splitInterval = _appearanceInfo.splitInterval;
    
    [gpxDb updateDataItem:gpx];

    if (gpx.color != 0)
        [[OAGPXAppearanceCollection sharedInstance] getColorItemWithValue:gpx.color];
}
 */

- (void) createGpxAppearanceInfo
{
    OASGpxDataItem *gpx = [[OAGPXDatabase sharedDb] getGPXItem:[OAUtilities getGpxShortPath:self.filePath]];
    if (gpx)
        _appearanceInfo = [[OAGpxAppearanceInfo alloc] initWithItem:gpx];
}


@end
