//
//  OAHeightsResolverTask.h
//  OsmAnd
//
//  Created by Skalii on 01.05.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^ HeightsResolverTaskCallback)(NSArray<NSNumber *> *heights);

@interface OAHeightsResolverTask : NSObject

- (instancetype)initWithPoints:(NSArray<CLLocation *> *)points
                      callback:(HeightsResolverTaskCallback)callback;

- (void)execute;

@end
