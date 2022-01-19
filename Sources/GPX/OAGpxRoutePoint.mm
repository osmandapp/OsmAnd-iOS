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
    if (self.extensions)
    {
        for (OAGpxExtension *e in self.extensions)
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

    for (OAGpxExtension *e in self.extensions)
    {
        if ([e.name isEqualToString:@"routeInfo"])
        {
            e.attributes = [NSDictionary dictionaryWithDictionary:attrs];
            found = YES;
            break;
        }
    }

    if (!found)
    {
        OAGpxExtension *e = [[OAGpxExtension alloc] init];
        e.name = @"routeInfo";
        e.attributes = [NSDictionary dictionaryWithDictionary:attrs];

        self.extensions = self.extensions.count > 0 ? [self.extensions arrayByAddingObject:e] : @[e];
    }
    
    [OAGPXDocument fillWpt:self.wpt usingWpt:self];
}

- (void)clearRouteInfo
{
    if (self.extensions.count > 0)
    {
        NSMutableArray *newArray = [self.extensions mutableCopy];
        
        for (OAGpxExtension *e in newArray)
        {
            if ([e.name isEqualToString:@"routeInfo"])
            {
                [newArray removeObject:e];
                break;
            }
        }
        self.extensions = newArray;

        [OAGPXDocument fillWpt:self.wpt usingWpt:self];
    }
}

@end
