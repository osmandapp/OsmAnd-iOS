//
//  OsmAndApp.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 8/22/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import "OsmAndApp.h"

#import "OsmAndAppProtocol.h"
#import "OsmAndAppCppProtocol.h"
#import "OsmAndAppImpl.h"

@implementation OsmAndApp

+ (id<OsmAndAppProtocol, OsmAndAppCppProtocol>)instance
{
    static OsmAndAppImpl* instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[OsmAndAppImpl alloc] init];
    });
    return instance;
}

+ (id<OsmAndAppProtocol>)swiftInstance
{
    return self.instance;
}

@end
