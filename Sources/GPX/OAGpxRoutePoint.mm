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
        self.visited = NO;
        self.visitedTime = 0;
        self.disabled = NO;
        self.index = 0;
        
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
                NSString *visitedStr = [e.attributes objectForKey:@"visited"];
                NSString *visitedTimeStr = [e.attributes objectForKey:@"visitedTime"];
                NSString *disabledStr = [e.attributes objectForKey:@"disabled"];
                NSString *indexStr = [e.attributes objectForKey:@"index"];
                
                if (visitedStr)
                    self.visited = [visitedStr boolValue];
                if (visitedTimeStr)
                    self.visitedTime = (long)[visitedTimeStr longLongValue];
                if (disabledStr)
                    self.disabled = [disabledStr boolValue];
                if (indexStr)
                    self.index = [indexStr intValue];
            }
        }
    }
}

- (void)applyRouteInfo
{
    NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
    [attrs setValue:[NSString stringWithFormat:@"%d", self.visited] forKey:@"visited"];
    [attrs setValue:[NSString stringWithFormat:@"%ld", self.visitedTime] forKey:@"visitedTime"];
    [attrs setValue:[NSString stringWithFormat:@"%d", self.disabled] forKey:@"disabled"];
    [attrs setValue:[NSString stringWithFormat:@"%d", self.index] forKey:@"index"];
    
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
            exts.extensions = [exts.extensions arrayByAddingObjectsFromArray:@[e]];
        else
            exts.extensions = @[e];
    }
    
    [OAGPXDocument fillWpt:self.wpt usingWpt:self];
}

- (void)clearRouteInfo
{
    if (self.extraData)
    {
        OAGpxExtensions *exts = (OAGpxExtensions *)self.extraData;

        NSMutableArray *newArray = [NSMutableArray arrayWithArray:exts.extensions];
        
        for (OAGpxExtension *e in newArray)
        {
            if ([e.name isEqualToString:@"routeInfo"])
            {
                [newArray removeObject:e];
                break;
            }
        }
        exts.extensions = [NSArray arrayWithArray:newArray];
        
        [OAGPXDocument fillWpt:self.wpt usingWpt:self];
    }
}

@end
