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
}

@end
