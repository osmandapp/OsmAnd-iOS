//
//  OAWeatherDownloaderOperationQueue.mm
//  OsmAnd Maps
//
//  Created by Skalii on 19.07.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAWeatherDownloaderOperationQueue.h"
#import "OAWeatherDownloaderOperation.h"

@implementation OAWeatherDownloaderOperationQueue
{
    NSMutableDictionary<NSString *, NSMutableArray<OAWeatherDownloaderOperation *> *> *_operations;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _operations = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)addOperation:(OAWeatherDownloaderOperation *)operation key:(NSString *)key
{
    NSMutableArray<OAWeatherDownloaderOperation *> *regionOperations = _operations[key];
    if (!regionOperations)
    {
        regionOperations = [NSMutableArray array];
        _operations[key] = regionOperations;
    }
    [regionOperations addObject:operation];

    [super addOperation:operation];
}

- (void)cancelOperations:(NSString *)key
{
    NSMutableArray<OAWeatherDownloaderOperation *> *regionOperations = _operations[key];
    for (OAWeatherDownloaderOperation *operation in regionOperations)
    {
        [operation cancel];
    }
    [self removeOperations:key];
}

- (void)removeOperations:(NSString *)key
{
    [_operations removeObjectForKey:key];
}

- (void)clearOperations:(NSString *)regionId
{
    for (NSString *key in _operations.allKeys)
    {
        if ([key hasPrefix:regionId])
            [self cancelOperations:key];
    }
}

@end
