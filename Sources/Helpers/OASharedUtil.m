//
//  OASharedUtil.m
//  OsmAnd Maps
//
//  Created by Alexey K on 14.06.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import "OASharedUtil.h"
#import "OsmAndApp.h"
#import "OAXmlFactory.h"
#import <OsmAndShared/OsmAndShared.h>

@implementation OASharedUtil

+ (void)initSharedLib:(NSString *)documentsPath gpxPath:(NSString *)gpxPath
{
    [OASPlatformUtil.shared initializeAppDir:documentsPath
                                      gpxDir:gpxPath
                               xmlFactoryApi:[[OAXmlFactory alloc] init]];

    //[self.class testGpxReadWrite:@"" outputFile:@""];
    //[self.class testGpxDatabase:@""];
}

// Temporary test code
+ (void) testGpxReadWrite:(NSString *)inputFile outputFile:(NSString *)outputFile
{
    NSLog(@"GPX TEST - READ");

    OASKFile *file = [[OASKFile alloc] initWithFilePath:inputFile];
    OASGpxFile *gpxFile = [OASGpxUtilities.shared loadGpxFileFile:file];

    NSLog(@"GPX TEST - WRITE");

    file = [[OASKFile alloc] initWithFilePath:outputFile];
    [OASGpxUtilities.shared writeGpxFileFile:file gpxFile:gpxFile];

    NSLog(@"GPX TEST - DONE");
}

+ (void)fooGPXDatabase:(NSString *)gpxFileName
{
    NSLog(@"GPX DB TEST - BEGIN");
    
//    OASKFile *file = [[OASKFile alloc] initWithFilePath:gpxFileName];
//    OASGpxFile *gpxFile = [OASGpxUtilities.shared loadGpxFileFile:file];
//    OASGpxTrackAnalysis *trackAnalysis = [gpxFile getAnalysisFileTimestamp:gpxFile.pointsModifiedTime];

   
//    OASGpxDatabase *db = [[OASGpxDatabase alloc] init];
//    
   // NSArray<OASGpxDataItem *> *items = [db getGpxDataItems];
    NSLog(@"");
    
    //auto items = [db ]
//    OASGpxDataItem *item = [[OASGpxDataItem alloc] initWithFile:file];
//    [item setAnalysisAnalysis:trackAnalysis];
//    [item readGpxParamsGpxFile:gpxFile];
//    NSLog(@"GPX DB TEST - ADD");
//    BOOL res = [db addItem:item];

//    OASGpxDatabase *db = [[OASGpxDatabase alloc] init];
//
//    OASKFile *file = [[OASKFile alloc] initWithFilePath:gpxFileName];
//    OASGpxDataItem *item = [[OASGpxDataItem alloc] initWithFile:file];
    
//    OASGpxFile *gpxFile = [OASGpxUtilities.shared loadGpxFileFile:file];
//
//    NSLog(@"GPX DB TEST - ADD");
//    BOOL res = [db addItem:item];
//
//    NSLog(@"GPX DB TEST - GET");
//    OASGpxDataItem *read = [db getGpxDataItemFile:file];
//    OASGpxTrackAnalysis *analysis = [read getAnalysis];
//    // (float) _totalDistance = 295919.656
//    int totalDistance = analysis.totalDistance;
//    //(long) _startTime = 1691937496 
//    int startTime = analysis.startTime;

    NSLog(@"GPX DB TEST - UPDATE");
//    res = [db updateDataItemItem:item];
//
//    NSLog(@"GPX DB TEST - REMOVE");
//    res = [db removeFile:file];
//
//    NSLog(@"GPX DB TEST - GET");
//    read = [db getGpxDataItemFile:file];
//
//    NSLog(@"GPX DB TEST - DONE");
}

//+ (OASGpxFile *)loadGpx:(NSString *)fileName
//{
//    OASGpxFile *gpxFileKotlin = [KSharedUtil loadGpx:fileName];
//    return gpxFileKotlin;
//}

@end
