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
#import "OAOsmAndContextImpl.h"
#import <OsmAndShared/OsmAndShared.h>

@implementation OASharedUtil

+ (void)initSharedLib:(NSString *)documentsPath gpxPath:(NSString *)gpxPath
{
    [OASPlatformUtil.shared initializeOsmAndContext:[[OAOsmAndContextImpl alloc] init]
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

+ (void) testGpxDatabase:(NSString *)gpxFileName
{
    NSLog(@"GPX DB TEST - BEGIN");

    OASGpxDatabase *db = [[OASGpxDatabase alloc] init];

    OASKFile *file = [[OASKFile alloc] initWithFilePath:gpxFileName];
    OASGpxDataItem *item = [[OASGpxDataItem alloc] initWithFile:file];

    NSLog(@"GPX DB TEST - ADD");
    BOOL res = [db addItem:item];

    NSLog(@"GPX DB TEST - GET");
    OASGpxDataItem *read = [db getGpxDataItemFile:file];

    NSLog(@"GPX DB TEST - UPDATE");
    res = [db updateDataItemItem:item];

    NSLog(@"GPX DB TEST - REMOVE");
    res = [db removeFile:file];

    NSLog(@"GPX DB TEST - GET");
    read = [db getGpxDataItemFile:file];

    NSLog(@"GPX DB TEST - DONE");
}

@end
