//
//  OASharedUtil.m
//  OsmAnd Maps
//
//  Created by Alexey K on 14.06.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import "OASharedUtil.h"
#import <OsmAndShared/OsmAndShared.h>

@implementation OASharedUtil

+ (void)initSharedLib
{
    [OASPlatformUtil.shared initializeAppDir:@"" gpxDir:@"" xmlPullParserApi:nil xmlSerializerApi:nil];
}

@end
