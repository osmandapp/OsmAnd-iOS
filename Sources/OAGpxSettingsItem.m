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
    NSString *fileName = self.fileName;
    NSArray<NSString *> *pathComponents = self.filePath.pathComponents;
    if (pathComponents.count > 1)
    {
        folderName = pathComponents[pathComponents.count - 2];
        fileName = pathComponents[pathComponents.count - 1];
    }
    
    NSString *tracksName = @"/tracks";
    if ([folderName isEqualToString:@"GPX"])
        folderName = tracksName;
    else
        folderName = [tracksName stringByAppendingPathComponent:folderName];
    return [folderName stringByAppendingPathComponent:fileName];
}

- (void) writeToJson:(id)json
{
    json[@"type"] = [OASettingsItemType typeName:self.type];
    json[@"file"] = self.fileNameWithFolder;
    if (self.subtype != EOASettingsItemFileSubtypeUnknown)
        json[@"subtype"] = [OAFileSettingsItemFileSubtype getSubtypeName:self.subtype];
    if (_appearanceInfo)
    {
        [_appearanceInfo toJson:json];
    }
}

- (OASettingsItemWriter *) getWriter
{
    return [[OAFileSettingsItemWriter alloc] initWithItem:self];
}
 
 /*
    @Override
    public void applyAdditionalParams() {
        if (appearanceInfo != null) {
            GpxDataItem dataItem = app.getGpxDbHelper().getItem(savedFile, new GpxDataItemCallback() {
                @Override
                public boolean isCancelled() {
                    return false;
                }

                @Override
                public void onGpxDataItemReady(GpxDataItem item) {
                    updateGpxParams(item);
                }
            });
            if (dataItem != null) {
                updateGpxParams(dataItem);
            }
        }
    }
 */

 /*
    private void updateGpxParams(@NonNull GPXDatabase.GpxDataItem dataItem) {
        GpxDbHelper gpxDbHelper = app.getGpxDbHelper();
        GpxSplitType splitType = GpxSplitType.getSplitTypeByTypeId(appearanceInfo.splitType);
        gpxDbHelper.updateColor(dataItem, appearanceInfo.color);
        gpxDbHelper.updateWidth(dataItem, appearanceInfo.width);
        gpxDbHelper.updateShowArrows(dataItem, appearanceInfo.showArrows);
        gpxDbHelper.updateShowStartFinish(dataItem, appearanceInfo.showStartFinish);
        gpxDbHelper.updateSplit(dataItem, splitType, appearanceInfo.splitInterval);
        gpxDbHelper.updateGradientScaleType(dataItem, appearanceInfo.scaleType);
    }
 */
 
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
    //OAGPX *dataItem = [OAGPXDatabase.sharedDb getGPXItem:gpx.fileName];
}


@end
