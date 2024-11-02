//
//  OAGPXDatabase.h
//  OsmAnd
//
//  Created by Alexey Kulish on 15/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OACommonTypes.h"

static NSInteger const kDefaultTrackColor = 0xFFFF0000;
static NSString * const kGPXDBTracksLoaded = @"kGPXDBTracksLoaded";

typedef NS_ENUM(NSInteger, EOAGpxSplitType) {
    EOAGpxSplitTypeNone = -1,
    EOAGpxSplitTypeDistance = 1,
    EOAGpxSplitTypeTime
};

typedef NS_ENUM(NSInteger, EOAGPX3DLineVisualizationByType) {
    EOAGPX3DLineVisualizationByTypeNone = 0,
    EOAGPX3DLineVisualizationByTypeAltitude,
    EOAGPX3DLineVisualizationByTypeSpeed,
    EOAGPX3DLineVisualizationByTypeHeartRate,
    EOAGPX3DLineVisualizationByTypeBicycleCadence,
    EOAGPX3DLineVisualizationByTypeBicyclePower,
    EOAGPX3DLineVisualizationByTypeTemperatureA,
    EOAGPX3DLineVisualizationByTypeTemperatureW,
    EOAGPX3DLineVisualizationByTypeSpeedSensor,
    EOAGPX3DLineVisualizationByTypeFixedHeight
};

typedef NS_ENUM(NSInteger, EOAGPX3DLineVisualizationWallColorType) {
    EOAGPX3DLineVisualizationWallColorTypeNone = 0,
    EOAGPX3DLineVisualizationWallColorTypeSolid,
    EOAGPX3DLineVisualizationWallColorTypeDownwardGradient,
    EOAGPX3DLineVisualizationWallColorTypeUpwardGradient,
    EOAGPX3DLineVisualizationWallColorTypeAltitude,
    EOAGPX3DLineVisualizationWallColorTypeSlope,
    EOAGPX3DLineVisualizationWallColorTypeSpeed
};

typedef NS_ENUM(NSInteger, EOAGPX3DLineVisualizationPositionType) {
    EOAGPX3DLineVisualizationPositionTypeTop = 0,
    EOAGPX3DLineVisualizationPositionTypeBottom,
    EOAGPX3DLineVisualizationPositionTypeTopBottom,
};

@class OASGpxTrackAnalysis;
@class OASWptPt, OASGpxDataItem;

NS_ASSUME_NONNULL_BEGIN

@interface OAGPXDatabase : NSObject

+ (OAGPXDatabase *)sharedDb;

- (BOOL)containsGPXItem:(NSString *)filePath;
- (OASGpxDataItem *)addGPXFileToDBIfNeeded:(NSString *)filePath;
- (void)removeGpxItem:(OASGpxDataItem *)item withLocalRemove:(BOOL)withLocalRemove;
- (OASGpxDataItem *_Nullable)getGPXItem:(NSString *)filePath;

- (BOOL)updateDataItem:(OASGpxDataItem *_Nonnull)item;
- (NSArray<OASGpxDataItem *> *)getDataItems;
- (OASGpxDataItem *)getGPXItemByFileName:(NSString *)fileName;
- (NSString *)getFileDir:(NSString *)filePath;

- (void)save;

+ (EOAGpxSplitType)splitTypeByName:(NSString *_Nullable)splitName;
+ (NSString *)splitTypeNameByValue:(EOAGpxSplitType)splitType;

+ (NSString *)lineVisualizationByTypeNameForType:(EOAGPX3DLineVisualizationByType)type;
+ (EOAGPX3DLineVisualizationByType)lineVisualizationByTypeForName:(NSString *_Nullable)name;

+ (NSString *)lineVisualizationWallColorTypeNameForType:(EOAGPX3DLineVisualizationWallColorType)type;
+ (EOAGPX3DLineVisualizationWallColorType)lineVisualizationWallColorTypeForName:(NSString *_Nullable)name;

+ (NSString *)lineVisualizationPositionTypeNameForType:(EOAGPX3DLineVisualizationPositionType)type;
+ (EOAGPX3DLineVisualizationPositionType)lineVisualizationPositionTypeForName:(NSString *_Nullable)name;

@end
NS_ASSUME_NONNULL_END
