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
#import "OsmAnd_Maps-Swift.h"

@implementation OASharedUtil

+ (void)initSharedLib:(NSString *)documentsPath gpxPath:(NSString *)gpxPath
{
    [OASPlatformUtil.shared initializeOsmAndContext:[[OAOsmAndContextImpl alloc] init]
                                      xmlFactoryApi:[[OAXmlFactory alloc] init]];
    (void)[SharedLibSmartFolderHelper shared]; // AppInitializer on Android
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


@end
