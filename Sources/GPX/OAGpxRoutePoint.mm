//
//  OAGpxRoutePoint.m
//  OsmAnd
//
//  Created by Alexey Kulish on 02/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGpxRoutePoint.h"
#import "OAGPXDocument.h"

@implementation OAGpxRoutePoint

- (instancetype)initWithWpt:(OAGpxWpt *)gpxWpt
{
    self = [super init];
    if (self)
    {
        [self fillWithWpt:gpxWpt];
        [self readRouteInfo];
    }
    return self;
}

- (void)readRouteInfo
{
    if (self.extraData)
    {
        OAGpxExtensions *exts = (OAGpxExtensions *)self.extraData;
        for (OAGpxExtension *e in exts.extensions)
        {
            if ([e.name isEqualToString:@"routeInfo"])
            {
                id visitedStr = [e.attributes objectForKey:@"visited"];
                id visitedTimeStr = [e.attributes objectForKey:@"visitedTime"];
                id disabledStr = [e.attributes objectForKey:@"disabled"];
                id indexStr = [e.attributes objectForKey:@"index"];
                
                if (visitedStr)
                    self.visited = [visitedStr boolValue];
                if (visitedTimeStr)
                    self.visitedTime = [visitedStr longValue];
                if (disabledStr)
                    self.disabled = [visitedStr boolValue];
                if (indexStr)
                    self.index = [visitedStr intValue];
            }
        }
    }
}

- (void)applyRouteInfo
{
    NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
    [attrs setValue:[NSNumber numberWithBool:self.visited] forKey:@"visited"];
    [attrs setValue:[NSNumber numberWithLong:self.visitedTime] forKey:@"visitedTime"];
    [attrs setValue:[NSNumber numberWithBool:self.disabled] forKey:@"disabled"];
    [attrs setValue:[NSNumber numberWithInt:self.index] forKey:@"index"];
    
    BOOL found = NO;
    if (self.extraData)
    {
        OAGpxExtensions *exts = (OAGpxExtensions *)self.extraData;
        for (OAGpxExtension *e in exts.extensions)
        {
            if ([e.name isEqualToString:@"routeInfo"])
            {
                e.attributes = [NSDictionary dictionaryWithDictionary:attrs];
                found = YES;
                break;
            }
        }
    }
    else
    {
        self.extraData = [[OAGpxExtensions alloc] init];
    }
    
    if (!found)
    {
        OAGpxExtensions *exts = (OAGpxExtensions *)self.extraData;
        OAGpxExtension *e = [[OAGpxExtension alloc] init];
        e.name = @"routeInfo";
        e.attributes = [NSDictionary dictionaryWithDictionary:attrs];
        
        if (exts.extensions)
            [exts.extensions arrayByAddingObjectsFromArray:@[e]];
        else
            exts.extensions = @[e];
    }
    
    [OAGPXDocument fillWpt:self.wpt usingWpt:self];
}

@end
