//
//  MissingMapsCalculator.h
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 27.03.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAWorldRegion.h"

#include <routingContext.h>

NS_ASSUME_NONNULL_BEGIN

@interface MissingMapsCalculator : NSObject
@property (nonatomic) NSArray<OAWorldRegion *> *potentiallyUsedMaps;
@property (nonatomic) NSArray<OAWorldRegion *> * missingMaps;
@property (nonatomic) NSArray<OAWorldRegion *> * mapsToUpdate;

@property (nonatomic) CLLocation *startPoint;
@property (nonatomic) CLLocation *endPoint;

- (instancetype)init;

- (BOOL)checkIfThereAreMissingMaps:(std::shared_ptr<RoutingContext>)ctx
                             start:(CLLocation *)start
                           targets:(NSArray<CLLocation *> *)targets
                   checkHHEditions:(BOOL)checkHHEditions;
- (BOOL)checkIfThereAreMissingMapsWithStart:(CLLocation *)start
                                    targets:(NSArray<CLLocation *> *)targets
                            checkHHEditions:(BOOL)checkHHEditions;
- (NSString *)getErrorMessage;

@end

NS_ASSUME_NONNULL_END
