//
//  CYSimpleEntityResolver.h
//  BRCybertron
//
//  Created by Matt on 8/03/16.
//  Copyright © 2016 Blue Rocket, Inc. Distributable under the terms of the MIT License.
//

#import "CYEntityResolver.h"

NS_ASSUME_NONNULL_BEGIN

@interface CYSimpleEntityResolver : NSObject <CYEntityResolver>

/**
 Get a global shared resolver instance. This resolver is safe to use across multiple threads.
 
 @return The global shared resolver.
 */
+ (instancetype)sharedResolver;

/**
 Register a set of internal entities with the resolver.
 
 @param entities A dictionary of entity name keys with associated content values.
 */
- (void)addInternalEntities:(NSDictionary<NSString *, NSString *> *)entities;

/**
 Reset all registered internal entities to just those provided.
 
 @param entities A dictionary of entity name keys with associated content values. Pass @nil to remove all entities.
 */
- (void)setInternalEntities:(nullable NSDictionary<NSString *, NSString *> *)entities;

@end

NS_ASSUME_NONNULL_END
