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

@synthesize subtype;

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

- (EOASettingsItemType) getType
{
    return EOASettingsItemTypeGpx;
}
 
- (void) readFromJson:(id)json error:(NSError * _Nullable __autoreleasing *)error
{
    subtype = EOASettingsItemFileSubtypeGpx;
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

- (void) writeToJson:(id)json
{
    [super writeToJson:json];
    if (_appearanceInfo)
    {
        [_appearanceInfo toJson:json];
    }
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
