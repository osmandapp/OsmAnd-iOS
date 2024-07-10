//
//  OAMapLayersConfiguration.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/8/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAMapLayersConfiguration.h"
#import "OAAppData.h"
#import "OsmAndApp.h"
#import "OAObservable.h"

@implementation OAMapLayersConfiguration
{
    NSObject* _lock;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self commonInit];
        _hiddenLayers = [NSMutableSet set];
    }
    return self;
}

- (instancetype) initWithHiddenLayers:(NSMutableSet *)hiddenLayers
{
    self = [super init];
    if (self)
    {
        _hiddenLayers = hiddenLayers;
    }
    return self;
}

- (void)commonInit
{
    _lock = [[NSObject alloc] init];
}

- (void) resetConfigutation
{
    _hiddenLayers = [NSMutableSet new];
}

- (BOOL)isLayerVisible:(NSString*)layerId
{
    @synchronized(_lock)
    {
        return ![_hiddenLayers containsObject:layerId];
    }
}

- (void)setLayer:(NSString*)layerId Visibility:(BOOL)isVisible
{
    @synchronized(_lock)
    {
        if (isVisible)
            [_hiddenLayers removeObject:layerId];
        else
            [_hiddenLayers addObject:layerId];

        OAAppData *data = OsmAndApp.instance.data;
        [data.mapLayersConfigurationChangeObservable notifyEventWithKey:self andValue:layerId];
    }
}

- (BOOL)toogleLayerVisibility:(NSString*)layerId
{
    @synchronized(_lock)
    {
        BOOL isVisibleNow;
        if([_hiddenLayers containsObject:layerId])
        {
            [_hiddenLayers removeObject:layerId];
            isVisibleNow = YES;
        }
        else
        {
            [_hiddenLayers addObject:layerId];
            isVisibleNow = NO;
        }
        OAAppData *data = OsmAndApp.instance.data;
        [data.mapLayersConfigurationChangeObservable notifyEventWithKey:self andValue:layerId];

        return isVisibleNow;
    }
}

@end
