//
//  OAGpxSettingsItem.m
//  OsmAnd
//
//  Created by Anna Bibyk on 29.01.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAGpxSettingsItem.h"
#import "OAGpxAppearanceInfo.h"

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

- (void)applyAdditionalParams:(NSString *)filePath
{
    if (_appearanceInfo)
        [self updateGpxParams:filePath];
}

- (void)updateGpxParams:(NSString *)filePath
{
    OAGPX *gpx = [[OAGPXDatabase sharedDb] getGPXItem:[OAUtilities getGpxShortPath:self.filePath]];
    gpx.color = _appearanceInfo.color;
    gpx.coloringType = _appearanceInfo.coloringType;
    gpx.width = _appearanceInfo.width;
    gpx.showArrows = _appearanceInfo.showArrows;
    gpx.showStartFinish = _appearanceInfo.showStartFinish;
    gpx.splitType = _appearanceInfo.splitType;
    gpx.splitInterval = _appearanceInfo.splitInterval;
    [[OAGPXDatabase sharedDb] save];
}

 /*
    private void createGpxAppearanceInfo() {
        GpxDataItem dataItem = app.getGpxDbHelper().getItem(file, new GpxDataItemCallback() {
            @Override
            public boolean isCancelled() {
                return false;
            }

            @Override
            public void onGpxDataItemReady(GPXDatabase.GpxDataItem item) {
                appearanceInfo = new GpxAppearanceInfo(item);
            }
        });
        if (dataItem != null) {
            appearanceInfo = new GpxAppearanceInfo(dataItem);
        }
    }
}
*/

- (void) createGpxAppearanceInfo
{
    OAGPX *gpx = [[OAGPXDatabase sharedDb] getGPXItem:[OAUtilities getGpxShortPath:self.filePath]];
    if (gpx)
        _appearanceInfo = [[OAGpxAppearanceInfo alloc] initWithItem:gpx];
}


@end
