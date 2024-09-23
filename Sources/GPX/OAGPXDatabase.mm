//
//  OAGPXDatabase.m
//  OsmAnd
//
//  Created by Alexey Kulish on 15/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGPXDatabase.h"
#import "OARootViewController.h"
#import "OAGPXTrackAnalysis.h"
#import "OsmAndApp.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAGPXDocument.h"
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

- (NSString *) getNiceTitle
{
    if (self.newGpx)
        return OALocalizedString(@"create_new_trip");

    if (self.gpxTitle)
        return [[self.gpxFileName lastPathComponent] stringByDeletingPathExtension];

    return self.gpxTitle;
}

- (void)setVerticalExaggerationScale:(CGFloat)verticalExaggerationScale {
    _verticalExaggerationScale = verticalExaggerationScale;
}

- (void)setElevationMeters:(NSInteger)elevationMeters {
    _elevationMeters = elevationMeters;
}

- (BOOL)isTempTrack
{
    return [self.gpxFilePath hasPrefix:@"Temp/"];
}

- (void)removeHiddenGroups:(NSString *)groupName
{
    if (!self.hiddenGroups)
    {
        self.hiddenGroups = [NSSet set];
        return;
    }

    NSMutableSet *newHiddenGroups = [self.hiddenGroups mutableCopy];
    [newHiddenGroups removeObject:groupName];
    self.hiddenGroups = newHiddenGroups;
}

- (void)addHiddenGroups:(NSString *)groupName
{
    self.hiddenGroups = self.hiddenGroups ? [self.hiddenGroups setByAddingObject:groupName] : [NSSet setWithObject:groupName];
}

- (NSString *)absolutePath
{
    if (self.gpxFilePath)
        return [OsmAndApp.instance.gpxPath stringByAppendingPathComponent:self.gpxFilePath];
    return @"";
}

- (NSString *)width
{
    return _width ? _width : @"";
}

- (NSString *)coloringType
{
    return _coloringType ? _coloringType : @"";
}

- (NSString *)gradientPaletteName
{
    return _gradientPaletteName ? _gradientPaletteName : @"";
}

- (EOAGpxSplitType)splitType
{
    return _splitType == 0 ? EOAGpxSplitTypeNone : _splitType;
}

- (void)resetAppearanceToOriginal
{
    OAGPXDocument *document = [_gpxTitle isEqualToString:OALocalizedString(@"shared_string_currently_recording_track")]
            ? (OAGPXDocument *) [OASavingTrackHelper sharedInstance].currentTrack
            : [[OAGPXDocument alloc] initWithGpxFile:[[OsmAndApp instance].gpxPath stringByAppendingPathComponent:_gpxFilePath]];
    if (document)
    {
        _splitType = [OAGPXDatabase splitTypeByName:[document getSplitType]];
        _splitInterval = [document getSplitInterval];
        _color = [document getColor:0];
        _coloringType = [document getColoringType];
        _gradientPaletteName = [document getGradientColorPalette];
        _width = [document getWidth:nil];
        _showArrows = [document isShowArrows];
        _showStartFinish = [document isShowStartFinish];
        _verticalExaggerationScale = [document getVerticalExaggerationScale];
        _elevationMeters = [document getElevationMeters];
        _visualization3dByType = [OAGPXDatabase lineVisualizationByTypeForName:[document getVisualization3dByTypeValue]];
        _visualization3dWallColorType = [OAGPXDatabase lineVisualizationWallColorTypeForName:[document getVisualization3dWallColorTypeValue]];
        _visualization3dPositionType = [OAGPXDatabase lineVisualizationPositionTypeForName:[document getVisualization3dPositionTypeValue]];
    }
}

- (void)updateFolderName:(NSString *)newFilePath
{
    _gpxFilePath = newFilePath;
    _gpxFileName = [_gpxFilePath lastPathComponent];
    _gpxTitle = [_gpxFileName stringByDeletingPathExtension];
    _gpxFolderName = [newFilePath stringByDeletingLastPathComponent];
}

@end


@interface OAGPXDatabase ()
    
@property (nonatomic) NSString *dbFilePath;

@end

@implementation OAGPXDatabase
{
    NSObject *_fetchLock;
    OASGpxDatabase *_db;
}

@synthesize gpxList;

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
        _db = [[OASGpxDatabase alloc] init];
        [self load];
        [self newLoad];
    }
    return self;
}

- (OAGPX *) addGpxItem:(NSString *)filePath title:(NSString *)title desc:(NSString *)desc bounds:(OAGpxBounds)bounds document:(OAGPXDocument *)document
{
    OAGPX *gpx = [self buildGpxItem:filePath.lastPathComponent path:filePath title:title desc:desc bounds:bounds document:document fetchNearestCity:YES];
    NSMutableArray *res = [NSMutableArray array];
    for (OAGPX *item in gpxList)
    {
        if (![item.gpxFilePath isEqualToString:gpx.gpxFilePath])
            [res addObject:item];
    }
    
    [res addObject:gpx];
    gpxList = res;
    return gpx;
}

- (void) replaceGpxItem:(OAGPX *)gpx
{
    NSMutableArray *res = [NSMutableArray arrayWithArray:gpxList];
    OAGPX *existing = [self getGPXItem:gpx.gpxFilePath];
    if (existing)
        [res removeObject:existing];
    [res addObject:gpx];
    gpxList = res;
}

- (OAGPX *) buildGpxItem:(NSString *)fileName title:(NSString *)title desc:(NSString *)desc bounds:(OAGpxBounds)bounds document:(OAGPXDocument *)document fetchNearestCity:(BOOL)fetchNearestCity
{
    return [self buildGpxItem:fileName.lastPathComponent path:[OsmAndApp.instance.gpxPath stringByAppendingPathComponent:fileName] title:title desc:desc bounds:bounds document:document  fetchNearestCity:fetchNearestCity];
}

- (OAGPX *) buildGpxItem:(NSString *)fileName path:(NSString *)filepath title:(NSString *)title desc:(NSString *)desc bounds:(OAGpxBounds)bounds document:(OAGPXDocument *)document fetchNearestCity:(BOOL)fetchNearestCity
{
    OAGPXTrackAnalysis *analysis = [document getAnalysis:0];

    NSString *nearestCity;
    if (fetchNearestCity && analysis.locationStart)
    {
        OAPOI *nearestCityPOI = [OAGPXUIHelper searchNearestCity:analysis.locationStart.position];
        nearestCity = nearestCityPOI ? nearestCityPOI.nameLocalized : @"";
    }

    OAGPX *gpx = [[OAGPX alloc] init];
    NSString *pathToRemove = [OsmAndApp.instance.gpxPath stringByAppendingString:@"/"];
    gpx.bounds = bounds;
    gpx.gpxFileName = fileName;
    gpx.gpxFolderName = [[filepath stringByReplacingOccurrencesOfString:pathToRemove withString:@""] stringByDeletingLastPathComponent];
    gpx.gpxFilePath = [filepath stringByReplacingOccurrencesOfString:pathToRemove withString:@""];
    title = [title length] != 0 ? title : nil;
    if (title)
        gpx.gpxTitle = title;
    else
        gpx.gpxTitle = [fileName stringByDeletingPathExtension];
    
    if (desc)
        gpx.gpxDescription = desc;
    else
        gpx.gpxDescription = @"";
    
    gpx.importDate = [NSDate date];
    gpx.creationDate = [self getCreationDateForGPX:gpx document:document];
    
    gpx.totalDistance = analysis.totalDistance;
    gpx.totalTracks = analysis.totalTracks;
    gpx.startTime = analysis.startTime;
    gpx.endTime = analysis.endTime;
    gpx.timeSpan = analysis.timeSpan;
    gpx.timeMoving = analysis.timeMoving;
    gpx.totalDistanceMoving = analysis.totalDistanceMoving;
    gpx.diffElevationUp = analysis.diffElevationUp;
    gpx.diffElevationDown = analysis.diffElevationDown;
    
    gpx.avgElevation = analysis.avgElevation;
    gpx.minElevation = analysis.minElevation;
    gpx.maxElevation = analysis.maxElevation;
    gpx.maxSpeed = analysis.maxSpeed;
    gpx.avgSpeed = analysis.avgSpeed;
    gpx.points = analysis.points;
    
    gpx.wptPoints = analysis.wptPoints;
    gpx.metricEnd = analysis.metricEnd;
    gpx.locationStart = analysis.locationStart;
    gpx.locationEnd = analysis.locationEnd;
    gpx.nearestCity = nearestCity;

    gpx.splitType = [self.class splitTypeByName:document.getSplitType];

    gpx.splitInterval = [document getSplitInterval];
    gpx.color = [document getColor:0];
    gpx.coloringType = [document getColoringType];
    gpx.gradientPaletteName = [document getGradientColorPalette];
    gpx.width = [document getWidth:nil];
    gpx.showArrows = [document isShowArrows];
    gpx.showStartFinish = [document isShowStartFinish];
    gpx.verticalExaggerationScale = [document getVerticalExaggerationScale];
    gpx.elevationMeters = [document getElevationMeters];
    gpx.visualization3dByType = [self.class lineVisualizationByTypeForName:document.getVisualization3dByTypeValue];
    gpx.visualization3dWallColorType = [self.class lineVisualizationWallColorTypeForName:document.getVisualization3dWallColorTypeValue];
    gpx.visualization3dPositionType = [self.class lineVisualizationPositionTypeForName:document.getVisualization3dPositionTypeValue];
    
    return gpx;
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

- (OASGpxDataItem *)getNewGPXItem:(NSString *)filePath
{
    for (OASGpxDataItem *item in self.gpxNewList)
    {
        if ([item.gpxFilePath isEqualToString:filePath])
        {
            return item;
        }
    }
    return nil;
}

- (OASGpxDataItem *)getNewGPXItemByFileName:(NSString *)fileName
{
    for (OASGpxDataItem *item in self.gpxNewList)
    {
        if ([item.gpxFileName isEqualToString:fileName])
        {
            return item;
        }
    }
    return nil;
}

- (void)removeNewGpxItem:(NSString *)filePath
{
    OASGpxDataItem *gpx = [self getNewGPXItem:filePath];
    if (!gpx)
        gpx = [self getNewGPXItemByFileName:filePath];
    if (gpx)
    {
        NSMutableArray *newGpxList = [_gpxNewList mutableCopy];
        [newGpxList removeObject:gpx];
        _gpxNewList = newGpxList;
        
        // Remove from DB
        BOOL success = [_db removeFile:gpx.file];
        NSString *status = success ? @"SUCCESS" : @"ERROR";
        NSLog(@" [%@] remove from db | %@", status, gpx.file.path);
        
        // Remove local file
        [[NSFileManager defaultManager] removeItemAtPath:gpx.file.absolutePath error:nil];
    }
}


- (OAGPX *)getGPXItem:(NSString *)filePath
{
    for (OAGPX *item in gpxList)
    {
        if ([item.gpxFilePath isEqualToString:filePath])
        {
            return item;
        }
    }
    return nil;
}

-(OAGPX *)getGPXItemByFileName:(NSString *)fileName
{
    for (OAGPX *item in gpxList)
    {
        if ([item.gpxFileName isEqualToString:fileName])
        {
            return item;
        }
    }
    return nil;
}

-(void)removeGpxItem:(NSString *)filePath
{
    OAGPX *gpx = [self getGPXItem:filePath];
    if (!gpx)
        gpx = [self getGPXItemByFileName:filePath];
    if (gpx)
    {
        NSMutableArray *newGpxList = [gpxList mutableCopy];
        [newGpxList removeObject:gpx];
        gpxList = newGpxList;
        [[NSFileManager defaultManager] removeItemAtPath:gpx.absolutePath error:nil];
    }
}

- (NSString *) getFileDir:(NSString *)filePath
{
    NSString *pathToDelete = [OsmAndApp.instance.gpxPath stringByAppendingString:@"/"];
    return [[filePath stringByReplacingOccurrencesOfString:pathToDelete withString:@""] stringByDeletingLastPathComponent];
}

- (NSDate *)getCreationDateForGPX:(OAGPX *)gpx document:(OAGPXDocument *)document
{
    NSDate *creationDate = nil;
    if (gpx.creationDate)
    {
        creationDate = gpx.creationDate;
    }
    else if (document)
    {
        if (document.metadata && document.metadata.time > 0)
            creationDate = [NSDate dateWithTimeIntervalSince1970:document.metadata.time];
        else
            creationDate = [NSDate dateWithTimeIntervalSince1970:[document getLastPointTime]];
        
        if ([creationDate timeIntervalSince1970] <= 0)
            creationDate = gpx.importDate;
    }
    
    if (!creationDate)
        creationDate = [NSDate date];
    
    return creationDate;
}

- (BOOL)containsGPXItem:(NSString *)filePath
{
    for (OASGpxDataItem *item in self.gpxNewList)
    {
        if ([item.gpxFilePath isEqualToString:filePath])
        {
            return YES;
        }
    }
    return NO;
}

-(BOOL)containsGPXItemByFileName:(NSString *)fileName
{
    for (OAGPX *item in gpxList)
    {
        if ([item.gpxFileName isEqualToString:fileName])
        {
            return YES;
        }
    }
    return NO;
}

-(BOOL)updateGPXItemColor:(OAGPX *)item color:(int)color
{
    for (OAGPX *gpx in gpxList)
    {
        if ([gpx.gpxFilePath isEqualToString:item.gpxFilePath])
        {
            gpx.color = color;
            return YES;
        }
    }
    return NO;
}

-(BOOL)updateGPXItemPointsCount:(NSString *)filePath pointsCount:(int)pointsCount
{
    for (OAGPX *item in gpxList)
    {
        if ([item.gpxFilePath isEqualToString:filePath])
        {
            item.wptPoints = pointsCount;
            NSString *path = [[OsmAndApp instance].gpxPath stringByAppendingPathComponent:item.gpxFilePath];
            OAGPXDocument *doc = [[OAGPXDocument alloc] initWithGpxFile:path];
            item.bounds = doc.bounds;
            return YES;
        }
    }
    return NO;
}

- (BOOL)addNewGPXFilesTest:(NSSet<NSString *> *)existingFilePaths
{
    @synchronized (_fetchLock)
    {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSURL *documentsURL = [NSURL fileURLWithPath:OsmAndApp.instance.documentsPath];
        NSArray *keys = @[NSURLIsDirectoryKey];
        NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtURL:documentsURL
                                              includingPropertiesForKeys:keys
                                                                 options:0
                                                            errorHandler:^(NSURL *url, NSError *error) {
            return YES;
        }];
        NSString *gpxPath = OsmAndApp.instance.gpxPath;
        for (NSURL *url in enumerator)
        {
            NSURL *fileUrl = url.URLByResolvingSymlinksInPath;
            NSNumber *isDirectory = nil;
            if ([fileUrl isFileURL])
            {
                [fileUrl getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
                if ([isDirectory boolValue] && ![fileUrl.path hasPrefix:gpxPath])
                {
                    [enumerator skipDescendants];
                }
                else if (![isDirectory boolValue] &&
                        ([fileUrl.pathExtension.lowercaseString isEqualToString:GPX_EXT] ||
                                [fileUrl.pathExtension.lowercaseString isEqualToString:KML_EXT] ||
                                [fileUrl.pathExtension.lowercaseString isEqualToString:KMZ_EXT]) &&
                        ![fileUrl.lastPathComponent isEqualToString:@"favourites.gpx"])
                {
                    NSLog(@"%@", fileUrl.path);
                    if (![existingFilePaths containsObject:fileUrl.path])
                    {
                        if (![fileUrl.path hasPrefix:gpxPath])
                        {
                            NSURL *newFileUrl = [NSURL fileURLWithPath:[gpxPath stringByAppendingPathComponent:fileUrl.lastPathComponent]];
                            [fileManager moveItemAtURL:fileUrl toURL:newFileUrl error:nil];
                        }
                        [self addGPXFileToDBIfNeeded:fileUrl.path withUpdateDataSource:YES];
                    }
                }
            }
        }
    }
}

- (OASGpxDataItem *)addGPXFileToDBIfNeeded:(NSString *)filePath
                      withUpdateDataSource:(BOOL)withUpdateDataSource
{
    OASKFile *file = [[OASKFile alloc] initWithFilePath:filePath];
    OASGpxDataItem *dataItem;
    dataItem = [_db getGpxDataItemFile:file];
    if (!dataItem)
    {
        OASGpxFile *gpxFile = [OASGpxUtilities.shared loadGpxFileFile:file];
        if (!gpxFile.error)
        {
            OASGpxTrackAnalysis *trackAnalysis = [gpxFile getAnalysisFileTimestamp:gpxFile.modifiedTime];
            dataItem = [[OASGpxDataItem alloc] initWithFile:file];
            [dataItem setAnalysisAnalysis:trackAnalysis];
            [dataItem readGpxParamsGpxFile:gpxFile];

            BOOL success = [_db addItem:dataItem];
            NSString *status = success ? @"SUCCESS" : @"ERROR";
            NSLog(@"[%@] added to db | %@", status, dataItem.file.path);
            if (withUpdateDataSource)
            {
                NSArray<OASGpxDataItem *> *items = [_db getGpxDataItems];
                _gpxNewList = items;
            }
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

- (NSArray<NSString *> *)findGPXFilesInDirectory:(NSString *)directoryPath {
    NSMutableArray<NSString *> *result = [NSMutableArray array];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *directoryURL = [NSURL fileURLWithPath:directoryPath];
    
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtURL:directoryURL
                                              includingPropertiesForKeys:@[NSURLIsDirectoryKey]
                                                                 options:0
                                                            errorHandler:^BOOL(NSURL *url, NSError *error) {
        NSLog(@"Error enumerating %@: %@", [url path], error);
        return YES;
    }];
    
    for (NSURL *fileURL in enumerator) {
        NSError *error = nil;
        NSNumber *isDirectory = nil;
        [fileURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error];
        
        if (error) {
            NSLog(@"Error getting resource value for %@: %@", [fileURL path], error);
            continue;
        }
        
        if (![isDirectory boolValue]) {
            NSString *pathExtension = [fileURL pathExtension];
            if ([pathExtension isEqualToString:GPX_EXT] || [pathExtension isEqualToString:KML_EXT] || [pathExtension isEqualToString:KMZ_EXT]) {
                [result addObject:[fileURL path]];
            }
        }
    }
    
    return [result copy];
}

- (void)newLoad
{
    NSArray<NSString *> *paths = [self findGPXFilesInDirectory:OsmAndApp.instance.gpxPath];
    NSMutableSet<NSString *> *existingGpxPaths = [NSMutableSet set];
    
    for (NSString *filePath in paths)
    {
        [self addGPXFileToDBIfNeeded:filePath withUpdateDataSource:false];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath])
        {
            [existingGpxPaths addObject:filePath];
        }
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        BOOL didAddFiles = [self addNewGPXFilesTest:existingGpxPaths];
        
        if (didAddFiles)
        {
            NSLog(@"newLoad:didAddFiles");
        }
        NSArray<OASGpxDataItem *> *items = [_db getGpxDataItems];
       _gpxNewList = items;
        [[NSNotificationCenter defaultCenter] postNotificationName:kGPXDBTracksLoaded object:self];
    });
}


- (void)load
{
    NSMutableArray *res = [NSMutableArray array];
    NSArray *dbContent = [NSArray arrayWithContentsOfFile:self.dbFilePath];
    NSString *gpxFolderPath = [OsmAndApp instance].gpxPath;
    [NSFileManager.defaultManager removeItemAtPath:[gpxFolderPath stringByAppendingPathComponent:@"Temp"] error:nil];
    NSMutableSet<NSString *> *existingGpxPaths = [NSMutableSet set];

    for (NSDictionary *gpxData in dbContent)
    {
        OAGPX *gpx = [self generateGpxItem:gpxData];

        // Make compatible with old database data
        gpx.creationDate = [self getCreationDateForGPX:gpx document:nil];
        NSString *filePath = [gpx.gpxFilePath hasPrefix:gpxFolderPath] ? gpx.gpxFilePath : [gpxFolderPath stringByAppendingPathComponent:gpx.gpxFilePath];
        
        if (!gpx.gpxFilePath)
            gpx.gpxFilePath = gpx.gpxFileName;
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath])
        {
            [res addObject:gpx];
            [existingGpxPaths addObject:filePath];
        }
    }
    gpxList = res;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        BOOL didAddFiles = [self addNewGpxFiles:existingGpxPaths];
        if (didAddFiles)
        {
            [self save];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:kGPXDBTracksLoaded object:self];
    });
}

- (void)save
{
    NSMutableArray *dbContent = [NSMutableArray array];
    for (OAGPX *gpx in gpxList)
    {
        [dbContent addObject:[self generateGpxData:gpx]];
    }
    [dbContent writeToFile:self.dbFilePath atomically:YES];
}

- (BOOL) addNewGpxFiles:(NSSet<NSString *> *)existingFilePaths
{
    @synchronized (_fetchLock)
    {
        BOOL newFilesAdded = NO;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSURL *documentsURL = [NSURL fileURLWithPath:OsmAndApp.instance.documentsPath];
        NSArray *keys = @[NSURLIsDirectoryKey];
        NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtURL:documentsURL
                                              includingPropertiesForKeys:keys
                                                                 options:0
                                                            errorHandler:^(NSURL *url, NSError *error) {
            // Return YES for the enumeration to continue after the error.
            return YES;
        }];
        NSString *gpxPath = OsmAndApp.instance.gpxPath;
        for (NSURL *url in enumerator)
        {
            NSURL *fileUrl = url.URLByResolvingSymlinksInPath;
            NSNumber *isDirectory = nil;
            if ([fileUrl isFileURL])
            {
                [fileUrl getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
                if ([isDirectory boolValue] && ![fileUrl.path hasPrefix:gpxPath])
                {
                    [enumerator skipDescendants];
                }
                else if (![isDirectory boolValue] &&
                        ([fileUrl.pathExtension.lowercaseString isEqualToString:GPX_EXT] ||
                                [fileUrl.pathExtension.lowercaseString isEqualToString:KML_EXT] ||
                                [fileUrl.pathExtension.lowercaseString isEqualToString:KMZ_EXT]) &&
                        ![fileUrl.lastPathComponent isEqualToString:@"favourites.gpx"])
                {
                    if (![existingFilePaths containsObject:fileUrl.path])
                    {
                        if (![fileUrl.path hasPrefix:gpxPath])
                        {
                            NSURL *newFileUrl = [NSURL fileURLWithPath:[gpxPath stringByAppendingPathComponent:fileUrl.lastPathComponent]];
                            [fileManager moveItemAtURL:fileUrl toURL:newFileUrl error:nil];
                        }
                        OAGPXDocument *doc = [[OAGPXDocument alloc] initWithGpxFile:fileUrl.path];
                        [self addGpxItem:fileUrl.path title:doc.metadata.name desc:doc.metadata.desc bounds:doc.bounds document:doc];
                        newFilesAdded = YES;
                    }
                }
            }
        }
        return newFilesAdded;
    }
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
        [wpt setObject:@(gpx.locationStart.elevation) forKey:@"elevation"];
        [wpt setObject:@(gpx.locationStart.time) forKey:@"time"];
        [wpt setObject:(gpx.locationStart.comment ? gpx.locationStart.comment : @"") forKey:@"comment"];
        [wpt setObject:(gpx.locationStart.type ? gpx.locationStart.type : @"") forKey:@"type"];
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
        [wpt setObject:@(gpx.locationEnd.elevation) forKey:@"elevation"];
        [wpt setObject:@(gpx.locationEnd.time) forKey:@"time"];
        [wpt setObject:(gpx.locationEnd.comment ? gpx.locationEnd.comment : @"") forKey:@"comment"];
        [wpt setObject:(gpx.locationEnd.type ? gpx.locationEnd.type : @"") forKey:@"type"];
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
            OAWptPt *wpt = [[OAWptPt alloc] init];
            wpt.position = CLLocationCoordinate2DMake([value[@"position_lat"] doubleValue], [value[@"position_lon"] doubleValue]) ;
            wpt.name = value[@"name"];
            wpt.desc = value[@"desc"];
            wpt.elevation = [value[@"elevation"] doubleValue];
            wpt.time = [value[@"time"] longValue];
            wpt.comment = value[@"comment"];
            wpt.type = value[@"type"];
            wpt.speed = [value[@"speed"] doubleValue];
            gpx.locationStart = wpt;
        } else if ([key isEqualToString:@"locationEnd"]) {
            OAWptPt *wpt = [[OAWptPt alloc] init];
            wpt.position = CLLocationCoordinate2DMake([value[@"position_lat"] doubleValue], [value[@"position_lon"] doubleValue]) ;
            wpt.name = value[@"name"];
            wpt.desc = value[@"desc"];
            wpt.elevation = [value[@"elevation"] doubleValue];
            wpt.time = [value[@"time"] longValue];
            wpt.comment = value[@"comment"];
            wpt.type = value[@"type"];
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
