//
//  OAGPXDatabase.m
//  OsmAnd
//
//  Created by Alexey Kulish on 15/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGPXDatabase.h"
#import "OARootViewController.h"
#import "OsmAndApp.h"
#import "OAGPXDocumentPrimitives.h"
#import "Localization.h"
#import "OAUtilities.h"
#import "OASavingTrackHelper.h"
#import "OAGPXAppearanceCollection.h"
#import "OAGPXUIHelper.h"
#import "OAPOI.h"
#import "OAAppData.h"
#import "OASharedUtil.h"
#import "OsmAnd_Maps-Swift.h"
#import "OALog.h"

#define kDbName @"gpx.db"
#define GPX_EXT @"gpx"
#define KML_EXT @"kml"
#define KMZ_EXT @"kmz"


@interface OAGPXDatabase ()
    
@property (nonatomic) NSString *dbFilePath;

@end

@implementation OAGPXDatabase
{
    NSObject *_fetchLock;
}

+ (OAGPXDatabase *)sharedDb
{
    static OAGPXDatabase *_sharedDb = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedDb = [[OAGPXDatabase alloc] init];
    });
    return _sharedDb;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        self.dbFilePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:kDbName];
        _fetchLock = [[NSObject alloc] init];
    }
    return self;
}

+ (EOAGpxSplitType) splitTypeByName:(NSString *)splitName
{
    if (splitName.length == 0 || [splitName isEqualToString:@"no_split"])
        return EOAGpxSplitTypeNone;
    else if ([splitName isEqualToString:@"distance"])
        return EOAGpxSplitTypeDistance;
    else if ([splitName isEqualToString:@"time"])
        return EOAGpxSplitTypeTime;
    
    return EOAGpxSplitTypeNone;
}

+ (NSString *) splitTypeNameByValue:(EOAGpxSplitType)splitType
{
    switch (splitType)
    {
        case EOAGpxSplitTypeDistance:
            return @"distance";
        case EOAGpxSplitTypeTime:
            return @"time";
            
        default:
            return @"no_split";
    }
}

+ (NSString *)lineVisualizationByTypeNameForType:(EOAGPX3DLineVisualizationByType)type
{
    switch (type)
    {
        case EOAGPX3DLineVisualizationByTypeAltitude:
            return @"altitude";
        case EOAGPX3DLineVisualizationByTypeSpeed:
            return @"speed";
        case EOAGPX3DLineVisualizationByTypeHeartRate:
            return @"hr";
        case EOAGPX3DLineVisualizationByTypeBicycleCadence:
            return @"cad";
        case EOAGPX3DLineVisualizationByTypeBicyclePower:
            return @"power";
        case EOAGPX3DLineVisualizationByTypeTemperatureA:
            return @"atemp";
        case EOAGPX3DLineVisualizationByTypeTemperatureW:
            return @"wtemp";
        case EOAGPX3DLineVisualizationByTypeSpeedSensor:
            return @"speed_sensor";
        case EOAGPX3DLineVisualizationByTypeFixedHeight:
            return @"fixed_heigh";
        default:
            return @"none";
    }
}

+ (EOAGPX3DLineVisualizationByType)lineVisualizationByTypeForName:(NSString *)name
{
    if ([name isEqualToString:@"altitude"])
        return EOAGPX3DLineVisualizationByTypeAltitude;
    else if ([name isEqualToString:@"speed"])
        return EOAGPX3DLineVisualizationByTypeSpeed;
    else if ([name isEqualToString:@"hr"])
        return EOAGPX3DLineVisualizationByTypeHeartRate;
    else if ([name isEqualToString:@"cad"])
        return EOAGPX3DLineVisualizationByTypeBicycleCadence;
    else if ([name isEqualToString:@"power"])
        return EOAGPX3DLineVisualizationByTypeBicyclePower;
    else if ([name isEqualToString:@"atemp"])
        return EOAGPX3DLineVisualizationByTypeTemperatureA;
    else if ([name isEqualToString:@"wtemp"])
        return EOAGPX3DLineVisualizationByTypeTemperatureW;
    else if ([name isEqualToString:@"speed_sensor"])
        return EOAGPX3DLineVisualizationByTypeSpeedSensor;
    else if ([name isEqualToString:@"fixed_heigh"])
        return EOAGPX3DLineVisualizationByTypeFixedHeight;
    return EOAGPX3DLineVisualizationByTypeNone;
}

+ (NSString *)lineVisualizationWallColorTypeNameForType:(EOAGPX3DLineVisualizationWallColorType)type
{
    switch (type) {
        case EOAGPX3DLineVisualizationWallColorTypeSolid:
            return @"solid";
            break;
        case EOAGPX3DLineVisualizationWallColorTypeDownwardGradient:
            return @"downward_gradient";
            break;
        case EOAGPX3DLineVisualizationWallColorTypeUpwardGradient:
            return @"upward_gradient";
            break;
        case EOAGPX3DLineVisualizationWallColorTypeAltitude:
            return @"altitude";
            break;
        case EOAGPX3DLineVisualizationWallColorTypeSlope:
            return @"slope";
            break;
        case EOAGPX3DLineVisualizationWallColorTypeSpeed:
            return @"speed";
            break;
        default:
            return @"none";
    }
}

+ (EOAGPX3DLineVisualizationWallColorType)lineVisualizationWallColorTypeForName:(NSString *)name
{
    if ([name isEqualToString:@"none"])
        return EOAGPX3DLineVisualizationWallColorTypeNone;
    if ([name isEqualToString:@"solid"])
        return EOAGPX3DLineVisualizationWallColorTypeSolid;
    else if ([name isEqualToString:@"downward_gradient"])
        return EOAGPX3DLineVisualizationWallColorTypeDownwardGradient;
    else if ([name isEqualToString:@"upward_gradient"])
        return EOAGPX3DLineVisualizationWallColorTypeUpwardGradient;
    else if ([name isEqualToString:@"altitude"])
        return EOAGPX3DLineVisualizationWallColorTypeAltitude;
    else if ([name isEqualToString:@"slope"])
        return EOAGPX3DLineVisualizationWallColorTypeSlope;
    else if ([name isEqualToString:@"speed"])
        return EOAGPX3DLineVisualizationWallColorTypeSpeed;
    return EOAGPX3DLineVisualizationWallColorTypeUpwardGradient;
}

+ (NSString *)lineVisualizationPositionTypeNameForType:(EOAGPX3DLineVisualizationPositionType)type
{
    switch (type) {
        case EOAGPX3DLineVisualizationPositionTypeBottom:
            return @"bottom";
            break;
        case EOAGPX3DLineVisualizationPositionTypeTopBottom:
            return @"top_bottom";
            break;
        default:
            return @"top";
    }
}

+ (EOAGPX3DLineVisualizationPositionType)lineVisualizationPositionTypeForName:(NSString *)name
{
    if ([name isEqualToString:@"bottom"])
       return EOAGPX3DLineVisualizationPositionTypeBottom;
   else if ([name isEqualToString:@"top_bottom"])
       return EOAGPX3DLineVisualizationPositionTypeTopBottom;
   return EOAGPX3DLineVisualizationPositionTypeTop;
}

- (OASGpxDataItem *_Nullable)getGPXItem:(NSString *)filePath
{
    if (![@"current_track" isEqualToString:filePath] && ![filePath containsString:OsmAndApp.instance.gpxPath]) {
        filePath = [[OsmAndApp instance].gpxPath stringByAppendingPathComponent:filePath];
    }
    OASKFile *file = [[OASKFile alloc] initWithFilePath:filePath];
    return [[OASGpxDbHelper shared] getItemFile:file];
}

- (void)removeGpxItem:(OASGpxDataItem *)item withLocalRemove:(BOOL)withLocalRemove
{
    [[OASGpxDbHelper shared] removeItem:item];
    if (withLocalRemove)
    {
        [[NSFileManager defaultManager] removeItemAtPath:item.file.absolutePath error:nil];
    }
}

- (BOOL)updateDataItem:(OASGpxDataItem *)item
{
    return [[OASGpxDbHelper shared] updateDataItemItem:item];
}

- (NSArray<OASGpxDataItem *> *)getDataItems
{
    return [[OASGpxDbHelper shared] getItems];
}

- (OASGpxDataItem *)getGPXItemByFileName:(NSString *)fileName
{
    for (OASGpxDataItem *item in [self getDataItems])
    {
        if ([item.gpxFileName isEqualToString:fileName])
        {
            return item;
        }
    }
    return nil;
}

- (NSString *) getFileDir:(NSString *)filePath
{
    NSString *pathToDelete = [OsmAndApp.instance.gpxPath stringByAppendingString:@"/"];
    return [[filePath stringByReplacingOccurrencesOfString:pathToDelete withString:@""] stringByDeletingLastPathComponent];
}

- (BOOL)containsGPXItem:(NSString *)filePath
{
    return [[OASGpxDbHelper shared] hasGpxDataItemFile:[[OASKFile alloc] initWithFilePath:filePath]];
}

- (OASGpxDataItem *)addGPXFileToDBIfNeeded:(NSString *)filePath
{
    if (![@"current_track" isEqualToString:filePath] && ![filePath containsString:OsmAndApp.instance.gpxPath]) {
        filePath = [[OsmAndApp instance].gpxPath stringByAppendingPathComponent:filePath];
    }
    
    OASKFile *file = [[OASKFile alloc] initWithFilePath:filePath];
    
    OASGpxDataItem *dataItem = [[OASGpxDbHelper shared] getItemFile:file];
    if (!dataItem)
    {
        OASGpxFile *gpxFile = [OASGpxUtilities.shared loadGpxFileFile:file];
        if (!gpxFile.error)
        {
            OASGpxTrackAnalysis *trackAnalysis = [gpxFile getAnalysisFileTimestamp:gpxFile.modifiedTime];
            dataItem = [[OASGpxDataItem alloc] initWithFile:file];
            [dataItem setAnalysisAnalysis:trackAnalysis];
            [dataItem readGpxParamsGpxFile:gpxFile];

            BOOL success = [[OASGpxDbHelper shared] addItem:dataItem];
            NSString *status = success ? @"SUCCESS" : @"ERROR";
            OALog(@"[%@] added to db | %@", status, dataItem.file.path);
            // app.getSmartFolderHelper().addTrackItemToSmartFolder(new TrackItem(SharedUtil.kFile(file)));

            return dataItem;
        }
        else
        {
            OALog(@"[ERROR] loadGpxFileFile: %@ | %@", file.path, gpxFile.error.message);
        }
    }
    else
    {
        OALog(@"[INFO] file: %@ | already exist", file.path);
    }
    return nil;
}

- (void)save
{
    OALog(@"[WARNING] is empty save");
}

@end
