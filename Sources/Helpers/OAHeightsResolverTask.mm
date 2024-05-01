//
//  OAHeightsResolverTask.m
//  OsmAnd Maps
//
//  Created by Skalii on 01.05.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import "OAHeightsResolverTask.h"
#import "OARootViewController.h"

@implementation OAHeightsResolverTask
{
    NSArray<CLLocation *> *_points;
    HeightsResolverTaskCallback _callback;
}

- (instancetype)initWithPoints:(NSArray<CLLocation *> *)points
                    callback:(HeightsResolverTaskCallback)callback
{
    self = [super init];
    if (self)
    {
        _points = points;
        _callback = callback;
    }
    return self;
}

- (void)execute
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray<NSNumber *> *heights = [self doInBackground];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self onPostExecute:heights];
        });
    });
}

- (NSArray<NSNumber *> *)doInBackground
{
    return [[OARootViewController instance].mapPanel.mapViewController getHeightsForPoints:_points];
}

- (void)onPostExecute:(NSArray<NSNumber *> *)heights
{
    if (_callback)
        _callback(heights);
}

@end
