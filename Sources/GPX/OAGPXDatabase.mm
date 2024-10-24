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

#define kDbName @"gpx.db"
#define GPX_EXT @"gpx"
#define KML_EXT @"kml"
#define KMZ_EXT @"kmz"

@implementation OAGPX
@end

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
            NSLog(@"[%@] added to db | %@", status, dataItem.file.path);
            // app.getSmartFolderHelper().addTrackItemToSmartFolder(new TrackItem(SharedUtil.kFile(file)));

            return dataItem;
        }
        else
        {
            NSLog(@"[ERROR] loadGpxFileFile: %@ | %@", file.path, gpxFile.error.message);
        }
    }
    else
    {
        NSLog(@"[INFO] file: %@ | already exist", file.path);
    }
    return nil;
}

- (void)save
{
    NSLog(@"[WARNING] is empty save");
}

// FIXME: FileUtils.java renameGpxFile
- (void)renameGPX:(OASGpxDataItem *)gpx newFilePath:(NSString *)filePath {
    
    OASKFile *newFile = [[OASKFile alloc] initWithFilePath:filePath];
    [gpx.file renameToToFile:newFile];
    [[OASGpxDbHelper shared] renameCurrentFile:gpx.file newFile:newFile];
}

- (NSDictionary *)generateGpxData:(OAGPX *)gpx
{
    NSMutableDictionary *d = [NSMutableDictionary dictionary];

    [d setObject:gpx.gpxFileName forKey:@"gpxFileName"];
    [d setObject:gpx.gpxFolderName ? gpx.gpxFolderName : [gpx.gpxFilePath stringByDeletingLastPathComponent] forKey:@"gpxFolderName"];
    [d setObject:gpx.gpxFilePath ? gpx.gpxFilePath : gpx.gpxTitle forKey:@"gpxFilePath"];
    [d setObject:gpx.gpxTitle forKey:@"gpxTitle"];
    [d setObject:gpx.gpxDescription forKey:@"gpxDescription"];
    [d setObject:gpx.importDate forKey:@"importDate"];
    [d setObject:gpx.creationDate forKey:@"creationDate"];

    [d setObject:@((int) gpx.color) forKey:@"color"];

    [d setObject:@(gpx.bounds.center.latitude) forKey:@"center_lat"];
    [d setObject:@(gpx.bounds.center.longitude) forKey:@"center_lon"];
    [d setObject:@(gpx.bounds.topLeft.latitude) forKey:@"top_left_lat"];
    [d setObject:@(gpx.bounds.topLeft.longitude) forKey:@"top_left_lon"];
    [d setObject:@(gpx.bounds.bottomRight.latitude) forKey:@"bottom_right_lat"];
    [d setObject:@(gpx.bounds.bottomRight.longitude) forKey:@"bottom_right_lon"];

    [d setObject:@(gpx.totalDistance) forKey:@"totalDistance"];
    [d setObject:@(gpx.totalTracks) forKey:@"totalTracks"];
    [d setObject:@(gpx.startTime) forKey:@"startTime"];
    [d setObject:@(gpx.endTime) forKey:@"endTime"];
    [d setObject:@(gpx.timeSpan) forKey:@"timeSpan"];
    [d setObject:@(gpx.timeMoving) forKey:@"timeMoving"];
    [d setObject:@(gpx.totalDistanceMoving) forKey:@"totalDistanceMoving"];
    [d setObject:@(gpx.diffElevationUp) forKey:@"diffElevationUp"];
    [d setObject:@(gpx.diffElevationDown) forKey:@"diffElevationDown"];

    [d setObject:@(gpx.avgElevation) forKey:@"avgElevation"];
    [d setObject:@(gpx.minElevation) forKey:@"minElevation"];
    [d setObject:@(gpx.maxElevation) forKey:@"maxElevation"];
    [d setObject:@(gpx.maxSpeed) forKey:@"maxSpeed"];
    [d setObject:@(gpx.avgSpeed) forKey:@"avgSpeed"];
    [d setObject:@(gpx.points) forKey:@"points"];

    [d setObject:@(gpx.wptPoints) forKey:@"wptPoints"];
    [d setObject:gpx.hiddenGroups ? gpx.hiddenGroups.allObjects : [NSArray array] forKey:@"hiddenGroups"];
    [d setObject:@(gpx.metricEnd) forKey:@"metricEnd"];

    [d setObject:@(gpx.showStartFinish) forKey:@"showStartFinish"];
    [d setObject:@(gpx.verticalExaggerationScale) forKey:@"verticalExaggerationScale"];
    [d setObject:@(gpx.elevationMeters) forKey:@"elevationMeters"];
    [d setObject:@(gpx.visualization3dByType) forKey:@"line3dVisualizationByType"];
    [d setObject:@(gpx.visualization3dWallColorType) forKey:@"line3dVisualizationWallColorType"];
    [d setObject:@(gpx.visualization3dPositionType) forKey:@"line3dVisualizationPositionType"];
    
    
    [d setObject:@(gpx.joinSegments) forKey:@"joinSegments"];
    [d setObject:@(gpx.showArrows) forKey:@"showArrows"];
    [d setObject:gpx.width forKey:@"width"];
    [d setObject:gpx.coloringType forKey:@"coloringType"];
    [d setObject:gpx.gradientPaletteName forKey:@"gradientPaletteName"];
    
    [d setObject:@(gpx.splitType) forKey:@"splitType"];
    [d setObject:@(gpx.splitInterval) forKey:@"splitInterval"];

    if (gpx.locationStart)
    {
        NSMutableDictionary *wpt = [NSMutableDictionary dictionary];
        [wpt setObject:@(gpx.locationStart.position.latitude) forKey:@"position_lat"];
        [wpt setObject:@(gpx.locationStart.position.longitude) forKey:@"position_lon"];
        [wpt setObject:(gpx.locationStart.name ? gpx.locationStart.name : @"") forKey:@"name"];
        [wpt setObject:(gpx.locationStart.desc ? gpx.locationStart.desc : @"") forKey:@"desc"];
        [wpt setObject:@(gpx.locationStart.ele) forKey:@"elevation"];
        [wpt setObject:@(gpx.locationStart.time) forKey:@"time"];
        [wpt setObject:(gpx.locationStart.comment ? gpx.locationStart.comment : @"") forKey:@"comment"];
        [wpt setObject:(gpx.locationStart.category ? gpx.locationStart.category : @"") forKey:@"type"];
        [wpt setObject:@(gpx.locationStart.speed) forKey:@"speed"];
        [d setObject:wpt forKey:@"locationStart"];
    }

    if (gpx.locationEnd)
    {
        NSMutableDictionary *wpt = [NSMutableDictionary dictionary];
        [wpt setObject:@(gpx.locationEnd.position.latitude) forKey:@"position_lat"];
        [wpt setObject:@(gpx.locationEnd.position.longitude) forKey:@"position_lon"];
        [wpt setObject:(gpx.locationEnd.name ? gpx.locationEnd.name : @"") forKey:@"name"];
        [wpt setObject:(gpx.locationEnd.desc ? gpx.locationEnd.desc : @"") forKey:@"desc"];
        [wpt setObject:@(gpx.locationEnd.ele) forKey:@"elevation"];
        [wpt setObject:@(gpx.locationEnd.time) forKey:@"time"];
        [wpt setObject:(gpx.locationEnd.comment ? gpx.locationEnd.comment : @"") forKey:@"comment"];
        [wpt setObject:(gpx.locationEnd.category ? gpx.locationEnd.category : @"") forKey:@"type"];
        [wpt setObject:@(gpx.locationEnd.speed) forKey:@"speed"];
        [d setObject:wpt forKey:@"locationEnd"];
    }
    if (gpx.nearestCity)
    	[d setObject:gpx.nearestCity forKey:@"nearestCity"];

    return d;
}

- (OAGPX *)generateGpxItem:(NSDictionary *)gpxData
{
    OAGPX *gpx = [[OAGPX alloc] init];

    OAGpxBounds bounds;
    bounds.center = CLLocationCoordinate2DMake([gpxData[@"center_lat"] doubleValue], [gpxData[@"center_lon"] doubleValue]);
    bounds.topLeft = CLLocationCoordinate2DMake([gpxData[@"top_left_lat"] doubleValue], [gpxData[@"top_left_lon"] doubleValue]);
    bounds.bottomRight = CLLocationCoordinate2DMake([gpxData[@"bottom_right_lat"] doubleValue], [gpxData[@"bottom_right_lon"] doubleValue]);
    gpx.bounds = bounds;
    gpx.visualization3dWallColorType = EOAGPX3DLineVisualizationWallColorTypeUpwardGradient;
    gpx.verticalExaggerationScale = kExaggerationDefScale;
    gpx.elevationMeters = kElevationDefMeters;

    for (NSString *key in gpxData)
    {
        id value = gpxData[key];

        if ([key isEqualToString:@"gpxFileName"]) {
            gpx.gpxFileName = value;
        } else if ([key isEqualToString:@"gpxTitle"]) {
            gpx.gpxTitle = value;
        } else if ([key isEqualToString:@"gpxFolderName"]) {
            gpx.gpxFolderName = value;
        } else if ([key isEqualToString:@"gpxFilePath"]) {
            gpx.gpxFilePath = value;
        } else if ([key isEqualToString:@"gpxDescription"]) {
            gpx.gpxDescription = value;
        } else if ([key isEqualToString:@"importDate"]) {
            gpx.importDate = value;
        } else if ([key isEqualToString:@"creationDate"]) {
            gpx.creationDate = value;
        } else if ([key isEqualToString:@"totalDistance"]) {
            gpx.totalDistance = [value floatValue];
        } else if ([key isEqualToString:@"totalTracks"]) {
            gpx.totalTracks = [value intValue];
        } else if ([key isEqualToString:@"startTime"]) {
            gpx.startTime = [value longValue];
        } else if ([key isEqualToString:@"endTime"]) {
            gpx.endTime = [value longValue];
        } else if ([key isEqualToString:@"timeSpan"]) {
            gpx.timeSpan = [value longValue];
        } else if ([key isEqualToString:@"timeMoving"]) {
            gpx.timeMoving = [value longValue];
        } else if ([key isEqualToString:@"totalDistanceMoving"]) {
            gpx.totalDistanceMoving = [value floatValue];
        } else if ([key isEqualToString:@"diffElevationUp"]) {
            gpx.diffElevationUp = [value doubleValue];
        } else if ([key isEqualToString:@"diffElevationDown"]) {
            gpx.diffElevationDown = [value doubleValue];
        } else if ([key isEqualToString:@"avgElevation"]) {
            gpx.avgElevation = [value doubleValue];
        } else if ([key isEqualToString:@"minElevation"]) {
            gpx.minElevation = [value doubleValue];
        } else if ([key isEqualToString:@"maxElevation"]) {
            gpx.maxElevation = [value doubleValue];
        } else if ([key isEqualToString:@"maxSpeed"]) {
            gpx.maxSpeed = [value floatValue];
        } else if ([key isEqualToString:@"avgSpeed"]) {
            gpx.avgSpeed = [value floatValue];
        } else if ([key isEqualToString:@"points"]) {
            gpx.points = [value intValue];
        } else if ([key isEqualToString:@"wptPoints"]) {
            gpx.wptPoints = [value intValue];
        } else if ([key isEqualToString:@"metricEnd"]) {
            gpx.metricEnd = [value doubleValue];
        } else if ([key isEqualToString:@"color"]) {
            gpx.color = [value intValue];
        } else if ([key isEqualToString:@"splitType"]) {
            gpx.splitType = (EOAGpxSplitType) [value integerValue];
        } else if ([key isEqualToString:@"splitInterval"]) {
            gpx.splitInterval = [value doubleValue];
        } else if ([key isEqualToString:@"locationStart"]) {
            OASWptPt *wpt = [[OASWptPt alloc] init];
            wpt.position = CLLocationCoordinate2DMake([value[@"position_lat"] doubleValue], [value[@"position_lon"] doubleValue]) ;
            wpt.name = value[@"name"];
            wpt.desc = value[@"desc"];
            wpt.ele = [value[@"elevation"] doubleValue];
            wpt.time = [value[@"time"] longValue];
            wpt.comment = value[@"comment"];
            wpt.category = value[@"type"];
            wpt.speed = [value[@"speed"] doubleValue];
            gpx.locationStart = wpt;
        } else if ([key isEqualToString:@"locationEnd"]) {
            OASWptPt *wpt = [[OASWptPt alloc] init];
            wpt.position = CLLocationCoordinate2DMake([value[@"position_lat"] doubleValue], [value[@"position_lon"] doubleValue]) ;
            wpt.name = value[@"name"];
            wpt.desc = value[@"desc"];
            wpt.ele = [value[@"elevation"] doubleValue];
            wpt.time = [value[@"time"] longValue];
            wpt.comment = value[@"comment"];
            wpt.category = value[@"type"];
            wpt.speed = [value[@"speed"] doubleValue];
            gpx.locationEnd = wpt;
        }
        else if ([key isEqualToString:@"showStartFinish"])
        {
            gpx.showStartFinish = [value boolValue];
        }
        else if ([key isEqualToString:@"verticalExaggerationScale"])
        {
            gpx.verticalExaggerationScale = [value floatValue];
        }
        else if ([key isEqualToString:@"elevationMeters"])
        {
            gpx.elevationMeters = [value integerValue];
        }
        else if ([key isEqualToString:@"line3dVisualizationByType"])
        {
            gpx.visualization3dByType = (EOAGPX3DLineVisualizationByType)[value integerValue];
        }
        else if ([key isEqualToString:@"line3dVisualizationWallColorType"])
        {
            gpx.visualization3dWallColorType = (EOAGPX3DLineVisualizationWallColorType)[value integerValue];
        }
        else if ([key isEqualToString:@"line3dVisualizationPositionType"])
        {
            gpx.visualization3dPositionType = (EOAGPX3DLineVisualizationPositionType)[value integerValue];
        }
        else if ([key isEqualToString:@"joinSegments"])
        {
            gpx.joinSegments = [value boolValue];
        }
        else if ([key isEqualToString:@"showArrows"])
        {
            gpx.showArrows = [value boolValue];
        }
        else if ([key isEqualToString:@"width"])
        {
            gpx.width = value;
        }
        else if ([key isEqualToString:@"coloringType"])
        {
            gpx.coloringType = value;
        }
        else if ([key isEqualToString:@"gradientPaletteName"])
        {
            gpx.gradientPaletteName = value;
        }
        else if ([key isEqualToString:@"hiddenGroups"])
        {
            gpx.hiddenGroups = [NSSet setWithArray:value];
        }
        else if ([key isEqualToString:@"nearestCity"])
        {
            gpx.nearestCity = value;
        }
    }
    if (!gpx.hiddenGroups)
        gpx.hiddenGroups = [NSSet set];

    return gpx;
}

@end
