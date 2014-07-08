//
//  OAMapLayersConfiguration.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/8/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAMapLayersConfiguration.h"

@implementation OAMapLayersConfiguration
{
    NSObject* _lock;
    NSMutableSet* _hiddenLayers;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self ctor];
        _hiddenLayers = [NSMutableSet set];
    }
    return self;
}

- (void)ctor
{
    _lock = [[NSObject alloc] init];
    _changeObservable = [[OAObservable alloc] init];
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

        [_changeObservable notifyEventWithKey:self andValue:layerId];
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

        [_changeObservable notifyEventWithKey:self andValue:layerId];

        return isVisibleNow;
    }
}

@synthesize changeObservable = _changeObservable;

#pragma mark - NSCoding

#define kHiddenLayers @"hidden_layers"

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_hiddenLayers forKey:kHiddenLayers];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        [self ctor];
        _hiddenLayers = [aDecoder decodeObjectForKey:kHiddenLayers];
    }
    return self;
}

#pragma mark -

@end
