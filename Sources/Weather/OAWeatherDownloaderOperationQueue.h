//
//  OAWeatherDownloaderOperationQueue.h
//  OsmAnd Maps
//
//  Created by Skalii on 19.07.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OAWeatherDownloaderOperation;

@interface OAWeatherDownloaderOperationQueue : NSOperationQueue

- (void)addOperation:(OAWeatherDownloaderOperation *)operation key:(NSString *)key;
- (void)cancelOperations:(NSString *)key;
- (void)removeOperations:(NSString *)key;
- (void)clearOperations:(NSString *)regionId;

@end
