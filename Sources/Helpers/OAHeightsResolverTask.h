//
//  OAHeightsResolverTask.h
//  OsmAnd
//
//  Created by Skalii on 01.05.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^ HeightsResolverTaskCallback)(NSArray<NSNumber *> * _Nonnull heights);

@interface OAHeightsResolverTask : NSObject

- (instancetype _Nonnull)initWithPoints:(NSArray<CLLocation *> * _Nonnull)points
                               callback:(HeightsResolverTaskCallback _Nullable)callback;

- (void)execute;

@end
