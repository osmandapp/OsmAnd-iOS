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

#define kDbName @"gpx.db"

@implementation OAGPX

- (NSString *) getNiceTitle
{
    if (self.newGpx)
        return OALocalizedString(@"create_new_trip");

    if (self.gpxTitle)
        return [[[[self.gpxFileName lastPathComponent] stringByDeletingPathExtension] stringByReplacingOccurrencesOfString:@"_" withString:@" "] trim];

    return self.gpxTitle;
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

- (NSString *)width
{
    return _width ? _width : @"";
}

- (NSString *)coloringType
{
    return _coloringType ? _coloringType : @"";
}

- (EOAGpxSplitType)splitType
{
    return _splitType == 0 ? EOAGpxSplitTypeNone : _splitType;
}

- (void)resetAppearanceToOriginal
{
    OAGPXDocument *document = [[OAGPXDocument alloc] initWithGpxFile:[[OsmAndApp instance].gpxPath stringByAppendingPathComponent:_gpxFilePath]];
    if (document)
    {
        _splitType = [OAGPXDatabase splitTypeByName:[document getSplitType]];
        _splitInterval = [document getSplitInterval];
        _color = [document getColor:0];
        _coloringType = [document getColoringType];
        _width = [document getWidth:nil];
        _showArrows = [document isShowArrows];
        _showStartFinish = [document isShowStartFinish];
    }
}

@end


@interface OAGPXDatabase ()
    
@property (nonatomic) NSString *dbFilePath;

@end

@implementation OAGPXDatabase

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
        [self load];
    }
    return self;
}

- (OAGPX *) addGpxItem:(NSString *)filePath title:(NSString *)title desc:(NSString *)desc bounds:(OAGpxBounds)bounds document:(OAGPXDocument *)document
{
    OAGPX *gpx = [self buildGpxItem:filePath.lastPathComponent path:filePath title:title desc:desc bounds:bounds document:document];
    NSMutableArray *res = [NSMutableArray array];
    for (OAGPX *item in gpxList)
        if (![item.gpxFilePath isEqualToString:gpx.gpxFilePath])
            [res addObject:item];
    
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

- (OAGPX *) buildGpxItem:(NSString *)fileName title:(NSString *)title desc:(NSString *)desc bounds:(OAGpxBounds)bounds document:(OAGPXDocument *)document
{
    return [self buildGpxItem:fileName path:[OsmAndApp.instance.gpxPath stringByAppendingPathComponent:fileName] title:title desc:desc bounds:bounds document:document];
}

- (OAGPX *) buildGpxItem:(NSString *)fileName path:(NSString *)filepath title:(NSString *)title desc:(NSString *)desc bounds:(OAGpxBounds)bounds document:(OAGPXDocument *)document
{
    OAGPXTrackAnalysis *analysis = [document getAnalysis:0];
    
    OAGPX *gpx = [[OAGPX alloc] init];
    NSString *pathToRemove = [OsmAndApp.instance.gpxPath stringByAppendingString:@"/"];
    gpx.bounds = bounds;
    gpx.gpxFileName = fileName;
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
    
    gpx.splitType = [self.class splitTypeByName:document.getSplitType];
    gpx.splitInterval = [document getSplitInterval];
    gpx.color = [document getColor:0];
    gpx.coloringType = [document getColoringType];
    gpx.width = [document getWidth:nil];
    gpx.showArrows = [document isShowArrows];
    gpx.showStartFinish = [document isShowStartFinish];
    
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

-(OAGPX *)getGPXItem:(NSString *)filePath
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
        if ([[item.gpxFilePath lastPathComponent] isEqualToString:fileName])
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
        [[NSFileManager defaultManager] removeItemAtPath:[[OsmAndApp instance].gpxPath stringByAppendingPathComponent:gpx.gpxFilePath] error:nil];
    }
}

- (NSString *) getFileDir:(NSString *)filePath
{
    NSString *pathToDelete = [OsmAndApp.instance.gpxPath stringByAppendingString:@"/"];
    return [[filePath stringByReplacingOccurrencesOfString:pathToDelete withString:@""] stringByDeletingLastPathComponent];
}

-(BOOL)containsGPXItem:(NSString *)filePath
{
    for (OAGPX *item in gpxList)
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
        if ([[item.gpxFilePath lastPathComponent] isEqualToString:fileName])
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

-(BOOL)updateGPXFolderName:(NSString *)newFilePath oldFilePath:(NSString *)oldFilePath
{
    for (OAGPX *item in gpxList)
    {
        if ([item.gpxFilePath isEqualToString:oldFilePath])
        {
            item.gpxFilePath = newFilePath;
            item.gpxFileName = [item.gpxFilePath lastPathComponent];
            item.gpxTitle = [item.gpxFileName stringByDeletingPathExtension];
            return YES;
        }
    }
    return NO;
}

- (void)load
{
    NSMutableArray *res = [NSMutableArray array];
    NSArray *dbContent = [NSArray arrayWithContentsOfFile:self.dbFilePath];
    
    for (NSDictionary *gpxData in dbContent)
    {
        OAGPX *gpx = [self generateGpxItem:gpxData];

        NSString *gpxFolderPath = [OsmAndApp instance].gpxPath;
        // Make compatible with old database data
        NSString *filePath = [gpx.gpxFilePath hasPrefix:gpxFolderPath] ? gpx.gpxFilePath : [gpxFolderPath stringByAppendingPathComponent:gpx.gpxFilePath];
        if (!gpx.gpxFilePath)
            gpx.gpxFilePath = gpx.gpxFileName;
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath])
             [res addObject:gpx];
    }
    gpxList = res;
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

- (NSDictionary *)generateGpxData:(OAGPX *)gpx
{
    NSMutableDictionary *d = [NSMutableDictionary dictionary];

    [d setObject:gpx.gpxFileName forKey:@"gpxFileName"];
    [d setObject:gpx.gpxFilePath ? gpx.gpxFilePath : gpx.gpxTitle forKey:@"gpxFilePath"];
    [d setObject:gpx.gpxTitle forKey:@"gpxTitle"];
    [d setObject:gpx.gpxDescription forKey:@"gpxDescription"];
    [d setObject:gpx.importDate forKey:@"importDate"];

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
    [d setObject:@(gpx.joinSegments) forKey:@"joinSegments"];
    [d setObject:@(gpx.showArrows) forKey:@"showArrows"];
    [d setObject:gpx.width forKey:@"width"];
    [d setObject:gpx.coloringType forKey:@"coloringType"];
    
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

    for (NSString *key in gpxData)
    {
        id value = gpxData[key];

        if ([key isEqualToString:@"gpxFileName"]) {
            gpx.gpxFileName = value;
        } else if ([key isEqualToString:@"gpxTitle"]) {
            gpx.gpxTitle = value;
        } else if ([key isEqualToString:@"gpxFilePath"]) {
            gpx.gpxFilePath = value;
        } else if ([key isEqualToString:@"gpxDescription"]) {
            gpx.gpxDescription = value;
        } else if ([key isEqualToString:@"importDate"]) {
            gpx.importDate = value;
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
        else if ([key isEqualToString:@"hiddenGroups"])
        {
            gpx.hiddenGroups = [NSSet setWithArray:value];
        }
    }
    if (!gpx.hiddenGroups)
        gpx.hiddenGroups = [NSSet set];

    return gpx;
}

@end
